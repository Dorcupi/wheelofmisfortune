extends Node2D
enum SPINNING_STATE {
	ACCELERATING,
	SPINNING,
	LANDING
}
enum GAME_STATE {
	GAMBLING,
	PURCHASING
}
enum PURCHASING_STATE {
	GOOD,
	BAD
}
const SPIN_COUNTER = preload("res://resources/spin_counter.tscn")
const SHOP_UPGRADE = preload("res://resources/shop_upgrade.tscn")
const SEGMENT_ITEM = preload("res://resources/segment_item.tscn")
@export var owned_segments: Array[WheelSegment]
var uninserted_segments: Array[WheelSegment] = []
@export var background: ColorRect
@export var screen_shake: ColorRect
@export var segment_spots: Array[Segment]
@export var shop_items: Array[ShopItem]
@export var spinning_wheel: Node2D
@export var wheel_particles: CPUParticles2D
@export var wheel_particles_2: CPUParticles2D
@export var transition_player: AnimationPlayer
@export var side_panel_player: AnimationPlayer
@export var side_panel: Control
@export var side_panel_button: Control
@export var talk_timer: Timer
@export var person_mouth: TextureRect
@export var talk_label: Label
@export var money: Label
@export var spin_button: Button
@export var wheel_neutral_spinning_speed: float
@export var wheel_max_acceleration_speed: float
@export var wheel_minimum_time_spinning: float
@export var wheel_maximum_time_spinning: float
@export var wheel_minimum_loops_around: int
@export var wheel_maximum_loops_around: int
@export var talk_player: AudioStreamPlayer
@export var scroll_player: AudioStreamPlayer
@export var result_player_1: AudioStreamPlayer
@export var result_player_2: AudioStreamPlayer
@export var result_player_3: AudioStreamPlayer
@export var result_player_4: AudioStreamPlayer
@export var collect_player_1: AudioStreamPlayer
@export var collect_player_2: AudioStreamPlayer
@export var transition_audio_player: AudioStreamPlayer
@export var transition_back_audio_player: AudioStreamPlayer
@export var buy_player_1: AudioStreamPlayer
@export var buy_player_2: AudioStreamPlayer
@export var delete_slice_player_1: AudioStreamPlayer
@export var delete_slice_player_2: AudioStreamPlayer
@export var alarm_audio_player: AudioStreamPlayer
@export var fail_audio_player: AudioStreamPlayer
@export var win_audio_player: AudioStreamPlayer
@export var spin_counter_spawner: Node2D
@export var dice_particles: Control
@export var shop_box_container: VBoxContainer
@export var inventory_box_container: GridContainer
@export var ascend_button: Button
var side_panel_open: bool = false
var wheel_current_speed: float
var is_spinning: bool = false
var can_spin: bool = true
var can_buy: bool = true
var current_segment: Segment
var spinning_state: SPINNING_STATE
var is_talking: bool = false
var is_shaking: bool = false
var in_negatives: bool = false
var negative_timer: float = 0
var game_state: GAME_STATE = GAME_STATE.GAMBLING:
	set(new_value):
		game_state = new_value
		if new_value == GAME_STATE.GAMBLING:
			background.material.set_shader_parameter("color1", Color("#220f10"))
			background.material.set_shader_parameter("color2", Color("#371219"))
			wheel_particles.color = Color("#d26c7c")
			wheel_particles_2.color = Color("#7e3542")
		if new_value == GAME_STATE.PURCHASING:
			background.material.set_shader_parameter("color1", Color("#081a0a"))
			background.material.set_shader_parameter("color2", Color("#0a2712"))
			wheel_particles.color = Color("48b566ff")
			wheel_particles_2.color = Color("276839ff")
var purchasing_state: PURCHASING_STATE
var segment_goal: int
var segment_angle_goal: float
var segment_angle_away: float
var time_to_spin: float
var money_label_tween: Tween
var need_to_update_label: bool = true
var need_to_update_dice: bool = true
var tweening_label: bool = false
var first_time_label_tweening: bool = true
var highest_score: float = 0
var score: float = 12.50:
	set(new_value):
		score = new_value
		if new_value > highest_score:
			highest_score = new_value
		need_to_update_label = true
		need_to_update_dice = true
		if new_value < 0.0 and in_negatives == false:
			in_negatives = true
			negative_timer = 0
			alarm_audio_player.play()
		elif new_value >= 0.0 and in_negatives == true:
			in_negatives = false
			alarm_audio_player.stop()
var time: float = 0
var rarity_passes: int = 0
var bad_items_storage: Array[WheelSegment]
var regular_items_storage: Array[WheelSegment]
var purchased_upgrades: Array[Upgrade] = []
var active_upgrades: Array[Upgrade] = []
var avaliable_upgrades: Array[Dictionary] = [
	{
		"title": "Auto Spin",
		"description": "Never press the spin button again! After one second, it will spin again!",
		"price": 99.98,
		"upgrade": Upgrade.new(Callable(), Callable(), Callable(), func ():
			if game_state == GAME_STATE.GAMBLING and can_spin:
				var time_left: float = 0.75
				while time_left >= 0:
					await get_tree().physics_frame
					time_left -= get_process_delta_time()
				if not is_spinning and can_spin and game_state == GAME_STATE.GAMBLING:
					spin())
	},
	{
		"title": "Never Negative",
		"description": "Never go into the negatives ever again! If you are going to, you'll just get set to $0 instead!",
		"price": 4899.99,
		"upgrade": Upgrade.new(Callable(), Callable(), func (data: ScoreUpdate) -> ScoreUpdate:
			if data.new_score < 0.0:
				data.new_score = 0.0
			return data, Callable())
	},
	{
		"title": "Rarity Pass I",
		"description": "Deal with one less negative slice on your spinner! You can put one more positive slice on your spinner without needing to put a negative of the same rarity!",
		"price": 989.99,
		"upgrade": Upgrade.new(func () -> void:
			rarity_passes += 1, Callable(), Callable(), Callable())
	},
	{
		"title": "Rarity Pass II",
		"description": "Even less negative slices! You can put one more positive slice on your spinner without needing to put a negative of the same rarity!",
		"price": 4679.89,
		"upgrade": Upgrade.new(func () -> void:
			rarity_passes += 1, Callable(), Callable(), Callable())
	}
]

var nem_messages: Array[String] = [
	"Dang it, I don't have enough money!",
	"Low on money again, as usual.",
	"One day, I'll have enough money to buy this",
	"If anyone could give me some spare change, I could buy this!",
	"I don't have enough money?? Dang it!",
	"I don't have enough money for this.",
	"I wish I had enough money for this.",
	"One day I'll get lucky and have enough money!"
]

var still_spinning_messages: Array[String] = [
	"Oh wait! The wheel is still spinning!",
	"I have to wait for the wheel to finish spinning.",
	"Can this wheel finish spinning any faster??",
	"This wheel is taking its sweet time",
	"One day this wheel will finish spinning."
]

var have_all_messages: Array[String] = [
	"Oh, look at that! I have all the avaliable rewards!",
	"Dang, I have all the rewards from this one. Who would've guessed?",
	"Oh wait, I have all the rewards from this!"
]

var no_space_messages: Array[String] = [
	"Oh dang, there's no space on my spinner to fit this slice!",
	"Oh no! There's no open spots on my spinner",
	"I need to free up some space on my spinner first",
	"There's no empty slots on my spinner!"
]

var no_rarity_messages: Array[String] = [
	"Oh shoot! For every positive slice of a certain rarity, I have to have a matching negative!",
	"Oh no! For every positive slice of a certain rarity, I have to have a matching negative!",
	"I can't believe I forgot to give a matching negative slice for every positive slice of a certain rarity!",
	"Why must I have a matching negative slice for every positive slice of a certain rarity!"
]

var positive_score_messages: Array[String] = [
	"Let's go! Ranking up my money!",
	"I just keep getting money!",
	"I am so lucky!",
	"More money for me!",
	"Soon, I'll be rich!"
]

var negative_score_message: Array[String] = [
	"No! I'm losing money!",
	"I keep losing money!",
	"Why am I so unlucky!",
	"I need money for myself!",
	"I came here to be rich, not poor!"
]

var in_negatives_positive_score_message: Array[String] = [
	"Soon I'll be out of the negatives!",
	"Any second now!",
	"Keep it up! I can't stay in the negatives for long!",
	"I need to make progress to get out of here!"
]

var in_negatives_negative_score_message: Array[String] = [
	"No! I can't keep going down!",
	"If I keep going down, I lose the challenge and get kicked out!",
	"I can't stay bankrupt!"
]

var caused_negative_score_message: Array[String] = [
	"NO! I'm in the negatives now!",
	"This can't happen! I don't have long before I lose!",
	"Oh no, I'm in the negatives now! I have to get out quick!"
]

# Planned rarities (balances may be needed):
# Rarity II - $14.99: +4, +6, +8
# Rarity III - $36.99: +10, x1.1, x1.2
# Rarity IV - $95.99: x1.25, x1.3 repeating, x1.5
# Rarity V - $389.99: x2, +150, +200
# Rarity VI - $976.89: +500, +750, x3

func _ready() -> void:
	for i in shop_items:
		i.connect("purchase_item", buy_item)
	for i in segment_spots:
		i.connect("delete_slice", delete_slice)
	for i in avaliable_upgrades:
		var instance: Node = SHOP_UPGRADE.instantiate()
		shop_box_container.add_child(instance)
		instance.owner = shop_box_container
		instance.title = i["title"]
		instance.description = i["description"]
		instance.price = i["price"]
		instance.upgrade = i["upgrade"]
		instance.connect("purchase_item", buy_upgrade)
		instance.connect("toggle_item", toggle_upgrade)
	uninserted_segments = calculate_uninserted_segments(owned_segments)
	insert_inventory(uninserted_segments)
	transition_player.play("in")

func _physics_process(delta: float) -> void:
	for i in dice_particles.get_children():
		if i is CPUParticles2D:
			i.emission_rect_extents  = Vector2(get_viewport().get_visible_rect().size.x, 1)
	ascend_button.visible = score >= 10000
	match game_state:
		GAME_STATE.GAMBLING:
			time += delta
			if need_to_update_label and not tweening_label:
				stop_money_label(false)
				update_money_label()
			elif not tweening_label:
				money.text = "$%.2f" % score
			if need_to_update_dice:
				for i in dice_particles.get_children():
					if i is CPUParticles2D:
						i.emitting = score >= 1.0
						var max_money: float = 1000000
						var max_particles: int = 3000
						var new_amount: float = clamp(score / max_money, 0, 1)
						new_amount = sqrt(new_amount)
						new_amount = int(new_amount * max_particles)
						if new_amount < 1:
							new_amount = 1
						if i.amount != new_amount:
							i.amount = new_amount
				need_to_update_dice = false
			if in_negatives:
				negative_timer += delta
				if negative_timer >= 30 and negative_timer != -100:
					negative_timer = -100
					can_spin = false
					can_buy = false
					Overheader.update_score(highest_score, time, false)
					if not fail_audio_player.playing:
						fail_audio_player.play()
					if not result_player_3.playing:
						result_player_3.play()
					alarm_audio_player.stop()
					transition_player.play("out")
					await transition_player.animation_finished
					if get_tree():
						get_tree().change_scene_to_file("res://end_screen.tscn")
				elif negative_timer != -100:
					spin_button.text = "%.0f" % (30 - negative_timer)
			else:
				spin_button.text = "SPIN"
				if alarm_audio_player.playing: alarm_audio_player.stop()
		GAME_STATE.PURCHASING:
			money.text = "SPIN TO GET!"
			for i in dice_particles.get_children():
				if i is CPUParticles2D:
					if not i.emitting:
						i.emitting = true
					if i.amount != 10:
						i.amount = 10
	if not is_spinning:
		spinning_wheel.rotate(wheel_neutral_spinning_speed * delta)
	else:
		match spinning_state:
			SPINNING_STATE.ACCELERATING:
				wheel_current_speed = lerp(wheel_current_speed, wheel_max_acceleration_speed, 0.1)
				spinning_wheel.rotate(wheel_current_speed * delta)
				scroll_player.pitch_scale = lerp(scroll_player.pitch_scale, clampf(wheel_current_speed / wheel_max_acceleration_speed, 0.15, 0.7), 0.1)
				set_screen_shake_strength(lerp(get_screen_shake_strength(), clampf(wheel_current_speed / wheel_max_acceleration_speed, 0.01, 0.05), 0.1))
				if is_equal_approx(wheel_current_speed, wheel_max_acceleration_speed):
					wheel_current_speed = wheel_max_acceleration_speed
					time_to_spin = randf_range(wheel_minimum_time_spinning, wheel_maximum_time_spinning)
					spinning_state = SPINNING_STATE.SPINNING
			SPINNING_STATE.SPINNING:
				spinning_wheel.rotate(wheel_current_speed * delta)
				scroll_player.pitch_scale = lerp(scroll_player.pitch_scale, clampf(wheel_current_speed / wheel_max_acceleration_speed, 0.15, 0.7), 0.1)
				set_screen_shake_strength(lerp(get_screen_shake_strength(), clampf(wheel_current_speed / wheel_max_acceleration_speed, 0.01, 0.05), 0.1))
				time_to_spin -= delta
				if time_to_spin <= 0:
					spinning_wheel.rotation = fmod(spinning_wheel.rotation,(2 * PI))
					segment_angle_goal = segment_angle_goal + ((2 * PI) * randi_range(wheel_minimum_loops_around, wheel_maximum_loops_around))
					segment_angle_away = segment_angle_goal - spinning_wheel.rotation
					spinning_state = SPINNING_STATE.LANDING
			SPINNING_STATE.LANDING:
				spinning_wheel.rotation = lerp(spinning_wheel.rotation, segment_angle_goal, 0.1)
				scroll_player.pitch_scale = lerp(scroll_player.pitch_scale, 0.15, 0.1)
				set_screen_shake_strength(lerp(get_screen_shake_strength(), 0.01, 0.1))
				# From or and onwards is a safety precaucion if the first half fails
				if abs(segment_angle_goal - spinning_wheel.rotation) <= 0.005: # or is_equal_approx(spinning_wheel.rotation, segment_angle_goal):
					spinning_wheel.rotation = fmod(spinning_wheel.rotation,(2 * PI))
					is_spinning = false
					scroll_player.stop()
					stop_screen_shake()
					match game_state:
						GAME_STATE.GAMBLING:
							apply_effect(current_segment.segmentData)
							current_segment.start_shine()
						GAME_STATE.PURCHASING:
							owned_segments.append(current_segment.segmentData)
							collect_player_1.play()
							collect_player_2.play()
							if purchasing_state == PURCHASING_STATE.GOOD:
								can_spin = false
								wheel_particles.emitting = true
								await collect_player_2.finished
								transition_player.play("out")
								transition_audio_player.play()
								await transition_player.animation_finished
								for i in segment_spots:
									i.instant_stop_shine()
								purchasing_state = PURCHASING_STATE.BAD
								init_purchasing_wheel(bad_items_storage)
								spinning_wheel.rotation = 0
								transition_player.play("in")
								transition_back_audio_player.play()
								await transition_player.animation_finished
								can_spin = true
							else:
								can_spin = false
								wheel_particles_2.emitting = true
								await collect_player_2.finished
								transition_player.play("out")
								transition_audio_player.play()
								await transition_player.animation_finished
								side_panel.visible = true
								side_panel_button.visible = true
								game_state = GAME_STATE.GAMBLING
								load_wheel(regular_items_storage)
								uninserted_segments = calculate_uninserted_segments(owned_segments)
								insert_inventory(uninserted_segments)
								need_to_update_dice = true
								spinning_wheel.rotation = 0
								transition_player.play("in")
								transition_back_audio_player.play()
								await transition_player.animation_finished
								can_spin = true
								can_buy = true
					for i in active_upgrades:
						if i.after_function: 
							i.after_function.call()

func update_money_label() -> void:
	if money and money.text:
		var current_money: float = float(money.text.replace("$", ""))
		money_label_tween = get_tree().create_tween()
		var trans_time: float = 1
		if first_time_label_tweening:
			trans_time = 2.5
			first_time_label_tweening = false
		money_label_tween.tween_method(set_money_label, current_money, score, trans_time).set_trans(Tween.TRANS_EXPO)
		money_label_tween.tween_callback(stop_money_label.bind(true))
		tweening_label = true
		need_to_update_label = false
		

func set_money_label(a_money: float) -> void:
	money.text = "$%.2f" % a_money

func stop_money_label(to_set: bool) -> void:
	if money_label_tween:
		money_label_tween.kill()
	tweening_label = false
	need_to_update_label = false
	if money and money.text and to_set:
		money.text = "$%.2f" % score

func buy_item(good_items, bad_items, price) -> void:
	var good_clone: Array = good_items.duplicate()
	for i in good_clone:
		if owned_segments.has(i):
			good_items.remove_at(good_items.find(i))
	var bad_clone: Array = bad_items.duplicate()
	for i in bad_clone:
		if owned_segments.has(i):
			bad_items.remove_at(bad_items.find(i))
	if not is_spinning and can_buy and not (good_items.is_empty() and bad_items.is_empty()):
		if score >= price:
			score -= price
			buy_player_1.play()
			buy_player_2.play()
			can_spin = false
			can_buy = false
			transition_player.play("out")
			transition_audio_player.play()
			await transition_player.animation_finished
			for i in segment_spots:
				i.instant_stop_shine()
			stop_money_label(true)
			side_panel.visible = false
			side_panel_button.visible = false
			game_state = GAME_STATE.PURCHASING
			if not good_items.is_empty():
				purchasing_state = PURCHASING_STATE.GOOD
				regular_items_storage = save_wheel()
				init_purchasing_wheel(good_items)
				spinning_wheel.rotation = 0
				bad_items_storage = bad_items
			else:
				purchasing_state = PURCHASING_STATE.BAD
				regular_items_storage = save_wheel()
				init_purchasing_wheel(bad_items)
				spinning_wheel.rotation = 0
			transition_player.play("in")
			transition_back_audio_player.play()
			await transition_player.animation_finished
			can_spin = true
		else:
			make_person_talk(2, nem_messages.pick_random())
	else:
		if is_spinning:
			make_person_talk(2, still_spinning_messages.pick_random())
		elif (good_items.is_empty() and bad_items.is_empty()):
			make_person_talk(2, have_all_messages.pick_random())
	

func save_wheel() -> Array[WheelSegment]:
	regular_items_storage = [WheelSegment.new(), WheelSegment.new(), WheelSegment.new(), WheelSegment.new(), WheelSegment.new(), WheelSegment.new()]
	for i in segment_spots:
		regular_items_storage[segment_spots.find(i)] = i.segmentData
	return regular_items_storage

func load_wheel(data: Array[WheelSegment]) -> void:
	for i in data:
		segment_spots[data.find(i)].segmentData = i

func init_purchasing_wheel(items: Array[WheelSegment]) -> void:
	var clone: Array = items.duplicate()
	for i in clone:
		if owned_segments.has(i):
			items.remove_at(items.find(i))
	var current_position: int = 0
	var amount_of_items: int = items.size()
	var spots_per_item: int = 6 / amount_of_items
	for i in items:
		for x in spots_per_item:
			segment_spots[current_position].segmentData = i
			current_position += 1

func buy_upgrade(node: Node, upgrade: Upgrade, price: float) -> void:
	if not purchased_upgrades.has(upgrade):
		if score >= price:
			score -= price
			buy_player_1.play()
			buy_player_2.play()
			purchased_upgrades.append(upgrade)
			upgrade.init_function.call()
			node.purchased = true
			active_upgrades.append(upgrade)
			node.enabled = true
		else:
			make_person_talk(2, nem_messages.pick_random())
	else:
		make_person_talk(2, have_all_messages.pick_random())

func toggle_upgrade(node, upgrade) -> void:
	if purchased_upgrades.has(upgrade):
		if node.enabled:
			active_upgrades.remove_at(active_upgrades.find(upgrade))
			node.enabled = false
		else:
			active_upgrades.append(upgrade)
			node.enabled = true

func delete_slice(node: Node) -> void:
	delete_slice_player_1.pitch_scale = randf_range(0.95, 1.05)
	delete_slice_player_1.play()
	delete_slice_player_2.play(0.15)
	wheel_particles.emitting = true
	uninserted_segments = calculate_uninserted_segments(owned_segments)
	insert_inventory(uninserted_segments)

func spin() -> void:
	for i in segment_spots:
		i.stop_shine()
	current_segment = segment_spots.pick_random()
	segment_goal = segment_spots.find(current_segment)
	segment_angle_goal = -current_segment.rotation
	wheel_current_speed = wheel_neutral_spinning_speed
	spinning_state = SPINNING_STATE.ACCELERATING
	is_spinning = true
	scroll_player.pitch_scale = 0.15
	scroll_player.play()
	start_screen_shake(0.01)

func apply_effect(segment: WheelSegment) -> String:
	var data: ScoreUpdate = segment.generate_update(score)
	for i in active_upgrades:
		if i.during_function:
			data = i.during_function.call(data)
	var caused_negative: bool = false
	if score >= 0.0 and data.new_score < 0.0 and not data.is_benefitial: caused_negative = true
	score = data.new_score
	if data.is_benefitial:
		result_player_2.play()
		result_player_4.play()
		if not in_negatives:
			var rand: int = randi_range(1, 2)
			print(rand)
			if rand == 2: make_person_talk(2, positive_score_messages.pick_random())
		else: make_person_talk(2, in_negatives_positive_score_message.pick_random())
		wheel_particles.emitting = true
	else:
		result_player_1.play()
		result_player_3.play()
		wheel_particles_2.emitting = true
		if caused_negative:
			make_person_talk(2, caused_negative_score_message.pick_random())
		elif not in_negatives:
			var rand: int = randi_range(1, 2)
			print(rand)
			if rand == 2: make_person_talk(2, negative_score_message.pick_random())
		else: make_person_talk(2, in_negatives_negative_score_message.pick_random())
	summon_counters(data.message)
	return data.message

# Bug, only checks if at least one, not if one per slice
func segment_check() -> bool:
	var has_segments: bool = true
	for i in segment_spots:
		if i.segmentData:
			if owned_segments.has(i.segmentData):
				pass
			else:
				has_segments = false
				printerr("YOU DON'T OWN THE SEGMENT IN SEGMENT %s" % segment_spots.find(i))
		else:
			has_segments = false
			printerr("YOU DON'T HAVE A SEGMENT IN SEGMENT %s" % segment_spots.find(i))
	return has_segments

func rarity_check() -> bool:
	var positive_rarities: Array[int] = []
	var negative_rarities: Array[int] = []
	for i in segment_spots:
		if i.segmentData:
			var update: ScoreUpdate = i.segmentData.generate_update(score)
			if update.is_benefitial:
				positive_rarities.append(i.segmentData.rarity)
			else:
				negative_rarities.append(i.segmentData.rarity)
	var has_all_rarities: bool = true
	var used_rarity_passes: int = 0
	for i in positive_rarities:
		if not negative_rarities.has(i):
			if rarity_passes == used_rarity_passes:
				has_all_rarities = false
		else:
			negative_rarities.erase(i)
	if not has_all_rarities:
		make_person_talk(2, no_rarity_messages.pick_random())
	return has_all_rarities

func _on_spin_button_pressed() -> void:
	if not is_spinning and can_spin:
		if (game_state == GAME_STATE.GAMBLING and segment_check() and rarity_check()) or (game_state == GAME_STATE.PURCHASING):
			spin()
		else:
			pass # Can't spin wheel
	else:
		make_person_talk(2, still_spinning_messages.pick_random())


func _on_texture_button_pressed() -> void:
	if game_state == GAME_STATE.GAMBLING:
		if side_panel_open:
			side_panel_player.play_backwards("open")
			side_panel_open = false
		else:
			side_panel_player.play("open")
			side_panel_open = true
			await side_panel_player.animation_finished


func _on_talk_timer_timeout() -> void:
	person_mouth.material.set_shader_parameter("talk_intensity", 0.0)
	talk_label.text = ""
	is_talking = false

func make_person_talk(talk_time: float, message: String) -> void:
	person_mouth.material.set_shader_parameter("talk_intensity", 0.0)
	talk_label.text = ""
	talk_timer.stop()
	talk_player.stop()
	person_mouth.material.set_shader_parameter("talk_intensity", 1.0)
	talk_timer.start(talk_time)
	talk_label.text = message
	talk_player.play()
	is_talking = true


func _on_audio_stream_player_finished() -> void:
	if is_talking:
		talk_player.play()


func _on_scroll_player_finished() -> void:
	if is_spinning:
		scroll_player.play()

func start_screen_shake(strength: float) -> void:
	screen_shake.material.set_shader_parameter("ShakeStrength", strength)
	is_shaking = true

func set_screen_shake_strength(strength: float) -> void:
	if is_shaking: screen_shake.material.set_shader_parameter("ShakeStrength", strength)

func get_screen_shake_strength() -> float:
	if is_shaking:
		return screen_shake.material.get_shader_parameter("ShakeStrength")
	else:
		return 0

func stop_screen_shake() -> void:
	screen_shake.material.set_shader_parameter("ShakeStrength", 0)
	is_shaking = false

func summon_counter(message: String):
	var instance: Node = SPIN_COUNTER.instantiate()
	spin_counter_spawner.add_child(instance)
	instance.owner = spin_counter_spawner
	instance.position = Vector2(randf_range(-250.0, 250.0), randf_range(100.0, -200.0))
	instance.change = message
	
func summon_counters(message: String):
	var parts: PackedStringArray = message.split(" ", false, 2)
	for i in parts:
		summon_counter(i)

func calculate_uninserted_segments(arr: Array[WheelSegment]) -> Array[WheelSegment]:
	var inserted_segments: Array[WheelSegment] = []
	for i in segment_spots:
		if i.segmentData:
			inserted_segments.append(i.segmentData)
	var _uninserted_segments: Array[WheelSegment] = arr.duplicate()
	for i in inserted_segments:
		if _uninserted_segments.has(i):
			_uninserted_segments.erase(i)
	return _uninserted_segments

func insert_inventory(arr: Array[WheelSegment]) -> void:
	for i in inventory_box_container.get_children():
		if i is SegmentItem:
			i.queue_free()
	for x in arr:
		var instance: Node = SEGMENT_ITEM.instantiate()
		inventory_box_container.add_child(instance)
		instance.owner = inventory_box_container
		instance.item = x
		instance.connect("insert_item", insert_into_wheel)

func insert_into_wheel(node: Node, item: WheelSegment) -> void:
	var space_avaliable: bool = false
	var avaliable_spots: Array[Segment] = []
	for i in segment_spots:
		if not i.segmentData:
			space_avaliable = true
			avaliable_spots.append(i)
	if space_avaliable:
		node.queue_free()
		uninserted_segments.erase(item)
		avaliable_spots[0].segmentData = item
	else:
		make_person_talk(2, no_space_messages.pick_random())


func _on_alarm_audio_player_finished() -> void:
	if in_negatives:
		alarm_audio_player.play()


func _on_ascend_button_pressed() -> void:
	can_spin = false
	can_buy = false
	Overheader.update_score(highest_score, time, true)
	if not win_audio_player.playing:
		win_audio_player.play()
	if not buy_player_2.playing:
		buy_player_2.play()
	transition_player.play("out")
	await transition_player.animation_finished
	if get_tree():
		get_tree().change_scene_to_file("res://end_screen.tscn")

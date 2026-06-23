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
@export var owned_segments: Array[WheelSegment]
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
@export var spin_counter_spawner: Node2D
@export var dice_particles: Control
@export var shop_box_container: VBoxContainer
var side_panel_open: bool = false
var wheel_current_speed: float
var is_spinning: bool = false
var can_spin: bool = true
var can_buy: bool = true
var current_segment: Segment
var spinning_state: SPINNING_STATE
var is_talking: bool = false
var is_shaking: bool = false
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
var score: float = 12.50:
	set(new_value):
		score = new_value
		need_to_update_label = true
		need_to_update_dice = true
var rarity_passes: int = 0
var bad_items_storage: Array[WheelSegment]
var regular_items_storage: Array[WheelSegment]
var purchased_upgrades: Array[Upgrade] = []
var active_upgrades: Array[Upgrade] = []
var avaliable_upgrades: Array[Dictionary] = [
	{
		"title": "Auto Spin",
		"description": "Never press the spin button again! After one second, it will spin again!",
		"price": 100,
		"upgrade": Upgrade.new(Callable(), Callable(), func ():
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
		"price": 25000,
		"upgrade": Upgrade.new(Callable(), func (data: ScoreUpdate) -> ScoreUpdate:
			if data.new_score < 0.0:
				data.new_score = 0.0
			return data, Callable())
	}
]

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

func _physics_process(delta: float) -> void:
	for i in dice_particles.get_children():
		if i is CPUParticles2D:
			i.emission_rect_extents  = Vector2(get_viewport().get_visible_rect().size.x, 1)
	match game_state:
		GAME_STATE.GAMBLING:
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
					print("CURRENT ROTATION IS %s" % str(spinning_wheel.rotation))
					spinning_wheel.rotation = fmod(spinning_wheel.rotation,(2 * PI))
					print("NEW ROTATION IS %s" % str(spinning_wheel.rotation))
					segment_angle_goal = segment_angle_goal + ((2 * PI) * randi_range(wheel_minimum_loops_around, wheel_maximum_loops_around))
					segment_angle_away = segment_angle_goal - spinning_wheel.rotation
					spinning_state = SPINNING_STATE.LANDING
					print("LANDING")
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
							make_person_talk(2, apply_effect(current_segment.segmentData))
							current_segment.start_shine()
						GAME_STATE.PURCHASING:
							owned_segments.append(current_segment.segmentData)
							print("ADDED SEGMENT TO OWNED SEGMENTS")
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
								print("SWITCHED PURCHASING STATE")
								init_purchasing_wheel(bad_items_storage)
								spinning_wheel.rotation = 0
								print("INIT WHEEL, TRANSITIONING")
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
								print("SWITCHED GAME AND PURCHASING STATES")
								load_wheel(regular_items_storage)
								need_to_update_dice = true
								spinning_wheel.rotation = 0
								print("INIT WHEEL, TRANSITIONING")
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
		var time: float = 1
		if first_time_label_tweening:
			time = 2.5
			first_time_label_tweening = false
		money_label_tween.tween_method(set_money_label, current_money, score, time).set_trans(Tween.TRANS_EXPO)
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
			print("TRYING TO BUY SLICE THAT COSTS %.2f" % price)
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
				print("SWITCHED GAME AND PURCHASING STATES")
				regular_items_storage = save_wheel()
				init_purchasing_wheel(good_items)
				spinning_wheel.rotation = 0
				bad_items_storage = bad_items
			else:
				purchasing_state = PURCHASING_STATE.BAD
				print("SWITCHED GAME AND PURCHASING STATES")
				regular_items_storage = save_wheel()
				init_purchasing_wheel(bad_items)
				spinning_wheel.rotation = 0
			print("INIT WHEEL, TRANSITIONING")
			transition_player.play("in")
			transition_back_audio_player.play()
			await transition_player.animation_finished
			can_spin = true
		else:
			printerr("CAN'T BUY, NOT ENOUGH MONEY")
	else:
		printerr("CAN'T BUY FOR ONE OF MANY REASONS")
	

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

func buy_upgrade(node, upgrade, price) -> void:
	if not purchased_upgrades.has(upgrade):
		if score >= price:
			score -= price
			buy_player_1.play()
			buy_player_2.play()
			print("TRYING TO BUY UPGRADE THAT COSTS %.2f" % price)
			purchased_upgrades.append(upgrade)
			node.purchased = true
			active_upgrades.append(upgrade)
			node.enabled = true
		else:
			printerr("CAN'T BUY, NOT ENOUGH MONEY")
	else:
		printerr("CAN'T BUY, ALREADY OWN")

func toggle_upgrade(node, upgrade) -> void:
	if purchased_upgrades.has(upgrade):
		if node.enabled:
			active_upgrades.remove_at(active_upgrades.find(upgrade))
			node.enabled = false
			print("UPGRADE TURNED OFF")
		else:
			active_upgrades.append(upgrade)
			node.enabled = true
			print("UPGRADE TURNED ON")

func delete_slice(node: Node) -> void:
	delete_slice_player_1.pitch_scale = randf_range(0.95, 1.05)
	delete_slice_player_1.play()
	delete_slice_player_2.play(0.15)
	wheel_particles.emitting = true

func spin() -> void:
	for i in segment_spots:
		i.stop_shine()
	current_segment = segment_spots.pick_random()
	segment_goal = segment_spots.find(current_segment)
	print("GOING TO SEGMENT " + str(segment_goal))
	segment_angle_goal = -current_segment.rotation
	print(segment_angle_goal)
	wheel_current_speed = wheel_neutral_spinning_speed
	spinning_state = SPINNING_STATE.ACCELERATING
	is_spinning = true
	scroll_player.pitch_scale = 0.15
	scroll_player.play()
	start_screen_shake(0.01)
	print("STARTING SPIN")

func apply_effect(segment: WheelSegment) -> String:
	var data: ScoreUpdate = segment.generate_update(score)
	for i in active_upgrades:
		if i.during_function:
			data = i.during_function.call(data)
	score = data.new_score
	if data.is_benefitial:
		result_player_2.play()
		result_player_4.play()
		wheel_particles.emitting = true
	else:
		result_player_1.play()
		result_player_3.play()
		wheel_particles_2.emitting = true
	summon_counters(data.message)
	return data.message

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
			if i.segmentData.generate_update(score).is_benefitial:
				if not positive_rarities.has(i.segmentData.rarity):
					positive_rarities.append(i.segmentData.rarity)
			else:
				if not negative_rarities.has(i.segmentData.rarity):
					negative_rarities.append(i.segmentData.rarity)
	var has_all_rarities: bool = true
	var used_rarity_passes: int = 0
	for i in positive_rarities:
		if not negative_rarities.has(i):
			if rarity_passes == used_rarity_passes:
				has_all_rarities = false
				printerr("YOU DON'T HAVE A MATCHING RARITY FOR RARITY %s" % i)
			else:
				push_warning("YOU DON'T HAVE A MATCHING RARITY FOR RARITY %s BUT A RARITY PASS HAS BEEN USED" % i)
		else:
			print("HAVE RARITY %s" % i)
	return has_all_rarities

func _on_spin_button_pressed() -> void:
	if not is_spinning and can_spin:
		if (game_state == GAME_STATE.GAMBLING and segment_check() and rarity_check()) or (game_state == GAME_STATE.PURCHASING):
			spin()
		else:
			print("CAN'T SPIN WHEEL")
	else:
		print("WHEEL STILL SPINNING OR TRANSITION IN PROGRESS")


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

func make_person_talk(time: float, message: String) -> void:
	person_mouth.material.set_shader_parameter("talk_intensity", 0.0)
	talk_label.text = ""
	talk_timer.stop()
	talk_player.stop()
	person_mouth.material.set_shader_parameter("talk_intensity", 1.0)
	talk_timer.start(time)
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

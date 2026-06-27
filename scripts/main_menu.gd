extends Node2D

@export var dice_particles: Control
@export var segment_spots: Array[Segment]
@export var transition_player: AnimationPlayer
@export var main: MarginContainer
@export var credits: MarginContainer

var segment_files: Array = DirAccess.get_files_at("res://resources/wheel_segments") 
var wheel_resources: Array[WheelSegment]

var animating: bool = false
var current_menu: int = 0

var tween: Tween

func _ready() -> void:
	for i in range(6):
		var resource: String = segment_files.pick_random()
		if resource.ends_with(".remap"):
			resource = resource.trim_suffix(".remap")
		wheel_resources.append(load("res://resources/wheel_segments/%s" % resource))
	for i in segment_spots:
		i.segmentData = wheel_resources[segment_spots.find(i)]
	transition_player.play("in")

func _physics_process(delta: float) -> void:
	for i in dice_particles.get_children():
		if i is CPUParticles2D:
			i.emission_rect_extents  = Vector2(get_viewport().get_visible_rect().size.x, 1)


func _on_play_button_pressed() -> void:
	if not animating:
		animating = true
		transition_player.play("out")
		await transition_player.animation_finished
		get_tree().change_scene_to_file("res://main.tscn")


func _on_quit_button_pressed() -> void:
	if not animating:
		animating = true
		transition_player.play("out")
		await transition_player.animation_finished
		get_tree().quit()


func _on_credits_button_pressed() -> void:
	if not animating:
		if current_menu == 0:
			if tween:
				tween.kill()
			
			tween = get_tree().create_tween()
			
			tween.tween_property(main, "position", Vector2(-550.0, main.position.y), 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
			tween.tween_property(credits, "position", Vector2(0.0, credits.position.y), 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
			tween.tween_callback(func ():
				animating = false
				current_menu = 1
				tween.kill())


func _on_back_button_pressed() -> void:
	if not animating:
		if current_menu == 1:
			if tween:
				tween.kill()
			
			tween = get_tree().create_tween()
			
			tween.tween_property(credits, "position", Vector2(-550.0, credits.position.y), 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
			tween.tween_property(main, "position", Vector2(0.0, main.position.y), 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
			tween.tween_callback(func ():
				animating = false
				current_menu = 0
				tween.kill())

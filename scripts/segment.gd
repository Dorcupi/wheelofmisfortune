@tool
extends Node2D
class_name Segment

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var shine_timer: Timer = $ShineTimer
@export var segmentData: WheelSegment:
	set(new_value):
		segmentData = new_value
		if segmentData and sprite_2d:
			sprite_2d.texture = segmentData.texture
var is_shining: bool = false

func _ready() -> void:
	if segmentData and sprite_2d:
		sprite_2d.texture = segmentData.texture

func instant_start_shine() -> void:
	if not is_shining:
		sprite_2d.material.set_shader_parameter("Brightness", 1.5)
		shine_timer.start(5)
		is_shining = true

func start_shine() -> void:
	if not is_shining:
		var tween: Tween = get_tree().create_tween()
		tween.tween_method(set_shine, 0.0, 1.5, 1.5).set_trans(Tween.TRANS_EXPO)
		tween.tween_callback(tween.kill)
		shine_timer.start(5)
		is_shining = true

func stop_shine() -> void:
	if is_shining:
		print("STOPPING SHINE")
		var tween: Tween = get_tree().create_tween()
		tween.tween_method(set_shine, 1.5, 0.0, 1.5).set_trans(Tween.TRANS_EXPO)
		tween.tween_callback(tween.kill)
		shine_timer.stop()
		is_shining = false

func instant_stop_shine() -> void:
	if is_shining:
		sprite_2d.material.set_shader_parameter("Brightness", 0.0)
		shine_timer.stop()
		is_shining = false

func set_shine(value: float) -> void:
	sprite_2d.material.set_shader_parameter("Brightness", value)

func _on_shine_timer_timeout() -> void:
	stop_shine()

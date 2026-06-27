@tool
extends Node2D
class_name Segment

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var shine_timer: Timer = $ShineTimer
@onready var cpu_particles_2d: CPUParticles2D = $CPUParticles2D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var root: Node2D = get_tree().current_scene
@export var segmentData: WheelSegment:
	set(new_value):
		segmentData = new_value
		if segmentData and sprite_2d:
			sprite_2d.texture = segmentData.texture
			cpu_particles_2d.texture = segmentData.texture
		elif sprite_2d:
			sprite_2d.texture = null
			cpu_particles_2d.texture = null
var is_shining: bool = false
var tween: Tween
var deletion_time: float = 0
var mouse_in: bool = false
var mouse_pressed: bool = false

signal delete_slice(node)

func _ready() -> void:
	if segmentData and sprite_2d:
		sprite_2d.texture = segmentData.texture
		cpu_particles_2d.texture = segmentData.texture
	elif sprite_2d:
		sprite_2d.texture = null
		cpu_particles_2d.texture = null

func _physics_process(delta: float) -> void:
	if mouse_in and mouse_pressed and segmentData and root.game_state == root.GAME_STATE.GAMBLING:
		if is_equal_approx(deletion_time, 0):
			audio_stream_player.stop()
			audio_stream_player.pitch_scale = randf_range(0.8, 1.2)
			audio_stream_player.play()
		deletion_time += get_process_delta_time()
		if not cpu_particles_2d.emitting:
			cpu_particles_2d.emitting = true
		if abs(deletion_time - 0.75) <= 0.01:
			audio_stream_player.stop()
			audio_stream_player.pitch_scale = randf_range(0.8, 1.2)
			audio_stream_player.play()
		if abs(deletion_time - 1.5) <= 0.01:
			audio_stream_player.stop()
			audio_stream_player.pitch_scale = randf_range(0.8, 1.2)
			audio_stream_player.play()
		if abs(deletion_time - 2.25) <= 0.01:
			audio_stream_player.stop()
			audio_stream_player.pitch_scale = randf_range(0.8, 1.2)
			audio_stream_player.play()
		if deletion_time >= 2.9:
			segmentData = null
			mouse_in = false
			mouse_pressed = false
			audio_stream_player.stop()
			audio_stream_player.pitch_scale = randf_range(0.8, 1.2)
			audio_stream_player.play()
			deletion_time = 0
			delete_slice.emit(self)
	else:
		deletion_time = 0
		if cpu_particles_2d.emitting:
			cpu_particles_2d.emitting = false

func instant_start_shine() -> void:
	if not is_shining:
		sprite_2d.material.set_shader_parameter("Brightness", 1.5)
		shine_timer.start(5)
		is_shining = true

func start_shine() -> void:
	if not is_shining:
		tween = get_tree().create_tween()
		tween.tween_method(set_shine, 0.0, 1.5, 1.5).set_trans(Tween.TRANS_EXPO)
		tween.tween_callback(tween.kill)
		shine_timer.start(5)
		is_shining = true

func stop_shine() -> void:
	if is_shining:
		tween = get_tree().create_tween()
		tween.tween_method(set_shine, 1.5, 0.0, 1.5).set_trans(Tween.TRANS_EXPO)
		tween.tween_callback(tween.kill)
		shine_timer.stop()
		is_shining = false

func instant_stop_shine() -> void:
	if is_shining:
		if tween: tween.kill()
		shine_timer.stop()
		sprite_2d.material.set_shader_parameter("Brightness", 0.0)
		is_shining = false

func set_shine(value: float) -> void:
	sprite_2d.material.set_shader_parameter("Brightness", value)

func _on_shine_timer_timeout() -> void:
	stop_shine()

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			mouse_pressed = true
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			mouse_pressed = false

func _on_area_2d_mouse_entered() -> void:
	mouse_in = true

func _on_area_2d_mouse_exited() -> void:
	mouse_in = false

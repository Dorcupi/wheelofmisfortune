extends Node2D
enum SPINNING_STATE {
	ACCELERATING,
	SPINNING,
	LANDING
}
@export var segment_spots: Array[Node2D]
@export var spinning_wheel: Node2D
@export var money: Label
@export var wheel_neutral_spinning_speed: float
@export var wheel_max_acceleration_speed: float
@export var wheel_minimum_time_spinning: float
@export var wheel_maximum_time_spinning: float
@export var wheel_minimum_loops_around: int
@export var wheel_maximum_loops_around: int
var wheel_current_speed: float
var is_spinning: bool = false
var current_segment: Segment
var spinning_state: SPINNING_STATE
var segment_goal: int
var segment_angle_goal: float
var segment_angle_away: float
var time_to_spin: float
var score: float = 10.0

func _physics_process(delta: float) -> void:
	money.text = "$%.2f" % score
	if not is_spinning:
		spinning_wheel.rotate(wheel_neutral_spinning_speed * delta)
	else:
		match spinning_state:
			SPINNING_STATE.ACCELERATING:
				wheel_current_speed = lerp(wheel_current_speed, wheel_max_acceleration_speed, 0.1)
				spinning_wheel.rotate(wheel_current_speed * delta)
				if is_equal_approx(wheel_current_speed, wheel_max_acceleration_speed):
					wheel_current_speed = wheel_max_acceleration_speed
					time_to_spin = randf_range(wheel_minimum_time_spinning, wheel_maximum_time_spinning)
					spinning_state = SPINNING_STATE.SPINNING
			SPINNING_STATE.SPINNING:
				spinning_wheel.rotate(wheel_current_speed * delta)
				time_to_spin -= delta
				if time_to_spin <= 0:
					# This entire section of code is broken
					print("CURRENT ROTATION IS %s" % str(spinning_wheel.rotation))
					spinning_wheel.rotation = fmod(spinning_wheel.rotation,(2 * PI))
					print("NEW ROTATION IS %s" % str(spinning_wheel.rotation))
					segment_angle_goal = segment_angle_goal + ((2 * PI) * randi_range(wheel_minimum_loops_around, wheel_maximum_loops_around))
					segment_angle_away = segment_angle_goal - spinning_wheel.rotation
					spinning_state = SPINNING_STATE.LANDING
					print("LANDING")
			SPINNING_STATE.LANDING:
				# Does not work to slow down, need better solution
				spinning_wheel.rotation = lerp(spinning_wheel.rotation, segment_angle_goal, 0.1)
				# Seems to be broken, don't know how to fix yet
				if is_equal_approx(spinning_wheel.rotation, segment_angle_goal):
					spinning_wheel.rotation = fmod(spinning_wheel.rotation,(2 * PI))
					is_spinning = false
					apply_effect(current_segment.segmentData)

func spin() -> void:
	current_segment = segment_spots.pick_random()
	segment_goal = segment_spots.find(current_segment)
	print("GOING TO SEGMENT " + str(segment_goal))
	segment_angle_goal = -current_segment.rotation
	print(segment_angle_goal)
	wheel_current_speed = wheel_neutral_spinning_speed
	spinning_state = SPINNING_STATE.ACCELERATING
	is_spinning = true
	print("STARTING SPIN")

func apply_effect(segment: WheelSegment):
	var data: ScoreUpdate = segment.generate_update(score)
	score = data.new_score
	print(data.message)

func _on_button_pressed() -> void:
	if not is_spinning: spin()

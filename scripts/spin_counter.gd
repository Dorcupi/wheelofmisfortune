extends Node2D
class_name SpinCounter

@onready var label: Label = $Mover/Label
@onready var mover: Node2D = $Mover
@export var change: String:
	set(new_value):
		change = new_value
		if label and label.text:
			label.text = new_value
var tween: Tween

func _ready() -> void:
	tween = get_tree().create_tween()
	tween.tween_property(mover, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_QUINT)
	tween.tween_callback(tween_part_2)

func tween_part_2() -> void:
	tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(mover, "modulate", Color("#ffffff00"), 1).set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	tween.tween_property(mover, "position", Vector2(mover.position.x, mover.position.y - 100), 1).set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

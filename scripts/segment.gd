extends Node2D
class_name Segment

@onready var sprite_2d: Sprite2D = $Sprite2D
@export var segmentData: WheelSegment

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if segmentData:
		sprite_2d.texture = segmentData.texture

extends Resource
class_name Upgrade
## A upgrade for the wheel which can have an effect before, during, or after spinning.

@export var init_function: Callable
@export var before_function: Callable
@export var during_function: Callable
@export var after_function: Callable

func _init(_init_function: Callable = Callable(), _before_function: Callable = Callable(), _during_function: Callable = Callable(), _after_function: Callable = Callable()) -> void:
	init_function = _init_function
	before_function = _before_function
	during_function = _during_function
	after_function = _after_function

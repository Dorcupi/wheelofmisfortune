extends Node2D

@export var transition_player: AnimationPlayer
@export var newspaper: TextureRect
@export var result_text: Label
@export var score_text: Label
@export var time_text: Label
@export var new_pb_text: Label

var score: float = 0
var time: float = 0
var beat_pb: bool = false
var won: bool = false
var times_played: int = 0

@export var lose_first_newspapers: Array[Texture]
@export var lose_not_first_newspapers: Array[Texture]
@export var lose_either_newspapers: Array[Texture]
@export var win_newspapers: Array[Texture]

var used_newspapers: Array[Texture]

func _ready() -> void:
	if Overheader.current_score: score = Overheader.current_score
	if Overheader.current_time: time = Overheader.current_time
	if Overheader.beat_pb: beat_pb = Overheader.beat_pb
	if Overheader.beat_game: won = Overheader.beat_game
	if won:
		for i in win_newspapers:
			used_newspapers.append(i)
	else:
		if times_played <= 1:
			for i in lose_first_newspapers:
				used_newspapers.append(i)
		else:
			for i in lose_not_first_newspapers:
				used_newspapers.append(i)
		for i in lose_either_newspapers:
			used_newspapers.append(i)
	var resource: Texture = used_newspapers.pick_random()
	newspaper.texture = resource
	if won:
		result_text.text = "You Won!"
	else:
		result_text.text = "You Lost!"
	score_text.text = "Score: $%.2f" % score
	time_text.text = "Time: %.0fs" % time
	new_pb_text.visible = beat_pb
	transition_player.play("in")


func _on_play_button_pressed() -> void:
	transition_player.play("out")
	await transition_player.animation_finished
	get_tree().change_scene_to_file("res://main.tscn")


func _on_main_menu_button_pressed() -> void:
	transition_player.play("out")
	await transition_player.animation_finished
	get_tree().change_scene_to_file("res://main_menu.tscn")

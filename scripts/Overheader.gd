extends Node

var highest_score: float = 0
var highest_time: float = 0

var current_score: float
var current_time: float

var beat_game: bool = false
var beat_pb: bool = false
var times_played: int = 0

func update_score(score: float, time: float, won: bool) -> void:
	current_score = score
	current_time = time
	beat_pb = false
	beat_game = won
	times_played += 1
	if score > highest_score:
		highest_score = score
		highest_time = time
		beat_pb = true
	elif score == highest_score and time < highest_time:
		highest_score = score
		highest_time = time
		beat_pb = true

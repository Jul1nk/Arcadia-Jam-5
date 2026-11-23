extends Node


var time: float = 0.0
var deaths: int = 0
var secrets: int = 0

var timer_running: bool = false

func start_game() -> void:
	timer_running = true
	time = 0
	deaths = 0
	secrets = 0

func stop_game() -> void:
	timer_running = false

func _process(delta: float) -> void:
	if timer_running:
		time += delta

class_name World
extends Node2D


@onready var player: Player = $Player
@onready var camera: Camera2D = $Camera2D
@onready var checkpoints: Node2D = $Checkpoints
var last_cp: Area2D = null
@onready var end_area: Area2D = $End

func _ready() -> void:
	GameInfo.start_game()
	player.world = self
	ConsoleManager.world = self
	for checkpoint in checkpoints.get_children():
		checkpoint.body_entered.connect(checkpoint_entered.bind(checkpoint))
	last_cp = checkpoints.get_child(0)
	
	end_area.body_entered.connect(_end)
	
	MusicManager.play("Game")


func get_last_valid_ground() -> Vector2:
	return last_cp.global_position


func checkpoint_entered(body, cp) -> void:
	if not body is Player:
		return
	last_cp = cp


func tp_to_cp(cp: int = 0) -> void:
	if checkpoints.get_child_count() < cp:
		return
	last_cp = checkpoints.get_child(cp)
	player.kill()


func kill_player() -> void:
	GameInfo.deaths += 1
	get_tree().paused = true
	camera.process_mode = Node.PROCESS_MODE_ALWAYS
	await UI.transition_and_call(func():
		player.global_position = get_last_valid_ground()
		camera.global_position = player.global_position
		player.velocity = Vector2.ZERO
		player.state = player.STATE.IDLE
		player.remove_chain()
	)
	camera.process_mode = Node.PROCESS_MODE_INHERIT
	get_tree().paused = false


func _end(body) -> void:
	if body is Player:
		player.end()
	MusicManager.fade_out(3.0)
	await get_tree().create_timer(3.0).timeout
	GameInfo.stop_game()
	UI.change_scene("res://sandbox/end.tscn")

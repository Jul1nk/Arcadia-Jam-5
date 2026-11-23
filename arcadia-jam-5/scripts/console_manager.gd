extends Node

var world: World


func _ready() -> void:
	LimboConsole.register_command(set_param, "set")
	LimboConsole.add_argument_autocomplete_source("set", 0, func():
		return [
		"SPEED",
		"CLIMB_SPEED",
		"JUMP_VELOCITY",
		"DASH_VELOCITY",
		"JUMP_GRAVITY",
		"FALL_GRAVITY",
		"SLOWFALL_GRAVITY",
		"FASTFALL_GRAVITY",
		"CLIMB_GRAVITY",
		"WALLFALL_GRAVITY",
		])
	LimboConsole.register_command(print_params, "print_params")
	LimboConsole.register_command(print_tilemap, "print_tilemap")
	LimboConsole.register_command(tp_to_cp, "tp_to_cp")


func set_param(param: String, value: Variant) -> void:
	if param == "SPEED":
		Player.SPEED = value
	if param == "CLIMB_SPEED":
		Player.CLIMB_SPEED = value
	if param == "JUMP_VELOCITY":
		Player.JUMP_VELOCITY = value
	if param == "DASH_VELOCITY":
		Player.DASH_VELOCITY = value
	if param == "JUMP_GRAVITY":
		Player.JUMP_GRAVITY = value
	if param == "FALL_GRAVITY":
		Player.FALL_GRAVITY = value
	if param == "SLOWFALL_GRAVITY":
		Player.SLOWFALL_GRAVITY = value
	if param == "FASTFALL_GRAVITY":
		Player.FASTFALL_GRAVITY = value
	if param == "CLIMB_GRAVITY":
		Player.CLIMB_GRAVITY = value
	if param == "WALLFALL_GRAVITY":
		Player.WALLFALL_GRAVITY = value


func print_params() -> void:
	print("SPEED: ", Player.SPEED)
	print("CLIMB_SPEED: ", Player.CLIMB_SPEED)
	print("JUMP_VELOCITY: ", Player.JUMP_VELOCITY)
	print("DASH_VELOCITY: ", Player.DASH_VELOCITY)
	print("JUMP_GRAVITY: ", Player.JUMP_GRAVITY)
	print("FALL_GRAVITY: ", Player.FALL_GRAVITY)
	print("SLOWFALL_GRAVITY: ", Player.SLOWFALL_GRAVITY)
	print("FASTFALL_GRAVITY: ", Player.FASTFALL_GRAVITY)
	print("CLIMB_GRAVITY: ", Player.CLIMB_GRAVITY)
	print("WALLFALL_GRAVITY: ", Player.WALLFALL_GRAVITY)


func print_tilemap() -> void:
	world.print_tilemap()


func tp_to_cp(cp: int = 0) -> void:
	world.tp_to_cp(cp)

extends Node2D

@onready var label_infos: Label = $Control/MarginContainer/VBoxContainer/LabelInfos

var can_quit: bool = false

func _ready() -> void:
	label_infos.text = """Congratulations!
	
	Time: {0}
	Deaths: {1}
	Secrets found: {2}/5
	
	Press any button""".format([Time.get_time_string_from_unix_time(GameInfo.time), GameInfo.deaths, GameInfo.secrets])
	await get_tree().create_timer(0.5).timeout
	can_quit = true


func _input(event: InputEvent) -> void:
	if (event is InputEventJoypadButton or event is InputEventKey) and can_quit:
		UI.change_scene("res://sandbox/title.tscn")

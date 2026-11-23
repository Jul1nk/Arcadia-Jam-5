extends Node2D

@onready var bg: Sprite2D = $Sprite2D
@onready var title: Sprite2D = $Title

@onready var start_button: Button = $Control/MarginContainer/VBoxContainer/StartButton
@onready var hardmode_button: Button = $Control/MarginContainer/VBoxContainer/HardmodeButton
@onready var quit_button: Button = $Control/MarginContainer/VBoxContainer/QuitButton
@onready var all_buttons: Array[Button] = [start_button, hardmode_button, quit_button]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UI.fade_out()
	MusicManager.play("Title")
	for b in all_buttons:
		b.focus_entered.connect(_focus.bind(b))
	start_button.grab_focus()
	
	start_button.pressed.connect(UI.change_scene.bind("res://sandbox/world.tscn"))
	quit_button.pressed.connect(func(): get_tree().quit())
	
	var tween := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC).set_parallel()
	tween.tween_property(bg, "position:y", 0, 10.0)
	tween.tween_property(title, "position:y", 32, 10.0)


func _focus(button: Button) -> void:
	for b in all_buttons:
		if b != button:
			var tween := create_tween()
			tween.tween_property(b, "offset_transform_scale", Vector2.ONE, 0.1)
	#button.grab_focus()
	var tween := create_tween()
	tween.tween_property(button, "offset_transform_scale", Vector2.ONE*1.1, 0.1)

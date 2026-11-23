extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var pause: Control = $Control/Pause
@onready var resume_button: Button = $Control/Pause/MarginContainer/VBoxContainer/ResumeButton
@onready var quit_button: Button = $Control/Pause/MarginContainer/VBoxContainer/QuitButton
@onready var all_buttons: Array[Button] = [resume_button, quit_button]

func _ready() -> void:
	resume_button.pressed.connect(_unpause)
	quit_button.pressed.connect(func():_unpause();UI.change_scene("res://sandbox/title.tscn"))

func _pause() -> void:
	get_tree().paused = true
	pause.show()
	resume_button.grab_focus()

func _unpause() -> void:
	get_tree().paused = false
	pause.hide()

func _pause_or_unpause():
	if get_tree().paused:
		_unpause()
	else:
		_pause()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		_pause_or_unpause()


func _focus(button: Button) -> void:
	for b in all_buttons:
		if b != button:
			var tween := create_tween()
			tween.tween_property(b, "offset_transform_scale", Vector2.ONE, 0.1)
	#button.grab_focus()
	var tween := create_tween()
	tween.tween_property(button, "offset_transform_scale", Vector2.ONE*1.1, 0.1)



func transition_and_call(callable: Callable = Callable(), args: Array = []) -> void:
	await fade_in()
	if not callable.is_null():
		await callable.callv(args)
	await fade_out()

func fade_in() -> void:
	animation_player.play("fade_in")
	await animation_player.animation_finished

func fade_out() -> void:
	animation_player.play("fade_out")
	await animation_player.animation_finished


func change_scene(scene: String) -> void:
	await transition_and_call(func(): get_tree().change_scene_to_file(scene))

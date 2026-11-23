extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	body_entered.connect(_body_entered)
	animation_player.play("idle")


func _body_entered(body) -> void:
	if not body is Player:
		return
	if animation_player.current_animation == "eat":
		return
	GameInfo.secrets += 1
	animation_player.play("eat")
	await animation_player.animation_finished
	queue_free()

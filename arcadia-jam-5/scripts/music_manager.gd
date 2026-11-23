extends Node


@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	audio_stream_player.stop()


func play(music: String = "Game") -> void:
	await fade_out()
	audio_stream_player["parameters/switch_to_clip"] = music
	audio_stream_player.play()
	await fade_in()


func fade_in(duration: float = 1.0) -> void:
	audio_stream_player.volume_db = -80
	var tween: Tween = create_tween()
	tween.tween_property(audio_stream_player, "volume_db", 0, duration)

func fade_out(duration: float = 1.0) -> void:
	#audio_stream_player.volume_db = 0
	var tween: Tween = create_tween()
	tween.tween_property(audio_stream_player, "volume_db", -80, duration)

extends Node3D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

func presence():
	print("Presence Called Dummy")
	audio_stream_player.play()

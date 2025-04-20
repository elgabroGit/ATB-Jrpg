extends Node3D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

func presence():
	audio_stream_player.play()

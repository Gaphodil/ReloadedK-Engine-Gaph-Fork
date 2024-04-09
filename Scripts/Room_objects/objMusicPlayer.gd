extends Node2D

## The ID of the song to play.
@export var song_id: AudioStream = null

## If [member loop_end] is not [code]0.0[/code], then the song will loop to
## this point (in seconds) when it reaches the end.
@export var loop_start: float = 0.0
## Loops the song to [member loop_start] when this point (in seconds)
## is reached. Does nothing if equal to [code]0.0[/code].
@export var loop_end: float = 0.0


func _ready():
	$Sprite2D.visible = false
	
	GLOBAL_MUSIC.song_id = song_id
	GLOBAL_MUSIC.loop_start = loop_start
	GLOBAL_MUSIC.loop_end = loop_end
	GLOBAL_MUSIC.music_update_and_play()

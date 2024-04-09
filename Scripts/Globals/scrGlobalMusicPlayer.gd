extends AudioStreamPlayer

## The ID of the song currently playing.
var song_playing: AudioStream = null
## The ID of the song that should be playing.
## Set by [code]objMusicPlayer[/code].
var song_id: AudioStream = null

var loop_start: float = 0.0
var loop_end: float = 0.0


# Music should keep on playing/processing even if the game is paused
func _ready():
	process_mode = PROCESS_MODE_ALWAYS


# Updates the volume level from the "Music" audio bus. Also checks if the music
# is paused or not
func _physics_process(_delta):
	
	volume_db = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	
	# For pausing or resuming the music. Check scrGlobalGame
	set_stream_paused(!GLOBAL_GAME.music_is_playing)
	
	# Set the start and end positions for the music loop
	set_loop_positions()



## Checks if [member song_playing] is the same as [member song_id]. If this is the
## case, then [member song_playing] value gets replaced and streamed. [br]
## If we warp to a different room with the same [member song_id],
## it keeps playing the same song without restarting.
func music_update_and_play() -> void:
	if song_playing != song_id:
		song_playing = song_id
		
		autoplay = true
		stream = song_playing
		play()


## If we set a loop end position from [code]objMusicPlayer[/code], we then set
## the playback position once we reach the loop end position, and loop between
## those points.
func set_loop_positions():
	if loop_end != 0.0:
		if get_playback_position() > loop_end:
			seek(loop_start)

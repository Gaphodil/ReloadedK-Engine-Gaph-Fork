extends Node

"""
Public variables, meant to be accessed and modified outside of this script
"""
## If [code]true[/code], the game is in debug mode.
var debug_mode: bool = false
# Other debug values
# Placing here as well as Player to be persistent between resets
var debug_godmode: bool = true
var debug_inf_jump: bool = false
var debug_hitbox: bool = false

signal debug_toggled(value)

## If [code]true[/code], the player has touched a warp to a different room.
## This prevents the position from loading a save being applied to the wrong room.
var is_changing_rooms: bool = false

## If [code]true[/code], the game is paused. Nodes must have their
## [member Node.process_mode] changed if they want operate during a paused game.
var game_paused: bool = false

## Currently unused.
var can_save_collectable: bool = false

## Time played. Increases when not in menus or paused.
var time: float = 0.0
## Death count. Increases when the player dies, naturally.
var deaths: int = 0

# This fixes some issues with collision detection on moving platforms
const SNAPPING_GRID: int = 16

# These determine the damage for objPlayer's attacks, like bullets
var player_bullet_damage: int = 1
# var player_sword_damage: int = 4

# Global arrays
## An array of IDs for activated triggers and multiTriggers.
## Cleared on reset or quit to main menu.
## If something depends on a trigger, it should check this array for an ID.
var triggered_events: Array = []
## An array of IDs for activated dialog events.
## Only gets cleared on exit to main menu, so dialogs
## play only once per session.
var dialog_events: Array = []

## The specific position a player will move to after warping to a different room.
## Normally set by a warp object.
var warp_to_point: Vector2 = Vector2.ZERO


"""
Public readonly variables, meant to be accessed but not modified outside of this script
"""
var can_reset: bool = false
var music_is_playing: bool = true
enum {KEYBOARD, CONTROLLER}
var global_input_device = KEYBOARD



"""
Private variables, meant to be handled only by this script
"""
# Window related variables. These don't really change, but can't be constants
# since they need to get their values first from a couple functions.
var INITIAL_WINDOW_WIDTH: int = DisplayServer.window_get_size().x
var INITIAL_WINDOW_HEIGHT: int = DisplayServer.window_get_size().y
var INITIAL_WINDOW_XPOSITION: int = DisplayServer.window_get_position().x
var INITIAL_WINDOW_YPOSITION: int = DisplayServer.window_get_position().y

var current_scene_name: String = ""
var cur_pause_menu: Node = null



func _ready():
	
	# Sets pause mode to not affect this world script
	process_mode = PROCESS_MODE_ALWAYS
	
	# Hides the mouse. A visual preference, so feel free to delete this if you
	# want
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


# The global functions we want to handle each frame. They're self contained
# and should only fire once or be toggled on and off
func _physics_process(delta):
	
	if Input.is_action_just_pressed("button_debug"):
		toggle_debug_mode()
	
	if Input.is_action_just_pressed("button_music"):
		pause_music()
	
	if Input.is_action_just_pressed("button_pause"):
		pause_game()
	
	if Input.is_action_just_pressed("button_fullscreen"):
		toggle_fullscreen()
	
	if Input.is_action_just_pressed("button_fullgame_restart"):
		full_game_restart()
	
	if Input.is_action_just_pressed("button_quitgame"):
		game_quit()
	
	# Resetting is more complex, as it needs to make a few checks before
	# the reset key is even pressed
	handle_resetting()
	
	# Global time counter
	time_counter(delta)

	# Adds the time and deaths to the titlebar
	handle_titlebar()


# We use this to check what type of input device we're using, which in turn
# affects the way things like settings are shown
func _input(event):
	if event is InputEventKey and event.is_pressed():
		if global_input_device != KEYBOARD:
			global_input_device = KEYBOARD
	
	if event is InputEventJoypadButton and event.is_pressed():
		if global_input_device != CONTROLLER:
			global_input_device = CONTROLLER



## A global pause which adds a pause menu instance.
## Unpausing is handled by the menu itself.
func pause_game() -> void:
	
	# As long as we're not on menu rooms
	if is_valid_room():
		
		# Gets all "Pause" nodes (the pause menus we need). Loads and
		# instantiates them afterwards
		if get_tree().get_nodes_in_group("Pause").size() < 1:
			var pause_menu := preload("res://Objects/UI/objPauseMenuMain.tscn")
			cur_pause_menu = pause_menu.instantiate()
			add_child(cur_pause_menu)
			GLOBAL_SOUNDS.play_sound(GLOBAL_SOUNDS.sndPause)


## Toggles fullscreen on/off. When toggled from fullscreen to windowed, it
## reapplies the window scaling to the initial window size.
func toggle_fullscreen() -> void:
	GLOBAL_SETTINGS.flip_setting("fullscreen")
	GLOBAL_SETTINGS.set_window_mode()


## Performs the necessary cleanup and returns to the main menu.
func full_game_restart() -> void:
	if is_valid_room():
		
		# If the scene we're on is not the initial project's scene, we change
		# our current scene to it, essentially working as a game reset.
		# We get the main scene from our project settings. To compare the name,
		# we get the setting, then the file name and then we trim the ".tscn" suffix
		if (get_tree().get_current_scene().name != ProjectSettings.get_setting("application/run/main_scene").get_file().trim_suffix(".tscn")):
			get_tree().change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
		
		# This is to restart everything even if the game is currently paused.
		# I like it that way, but maybe a cleaner way is to not allow a full
		# game restart when paused. Still, feel free to press F2 after pausing
		# and it will work the way it should
		if (game_paused):
			
			# Frees every "Pause" node (pause menus), unsets the global pause
			# and sets it to false for this autoload as well
			var pause_nodes = get_tree().get_nodes_in_group("Pause")
			for pause_menus in pause_nodes:
				pause_menus.queue_free()
			get_tree().set_pause(false)
			game_paused = false
		
		# Clear/reset our global arrays
		triggered_events.clear()
		dialog_events.clear()
		
		# Clear itemsGameData. We don't save collectables when making a full
		# game restart
		GLOBAL_SAVELOAD.itemsGameData.clear()


## Toggles debug mode on/off. [br]
## Debug mode affects [code]objPlayer[/code], making it invincible and able to get teleported
## to the mouse with a special key. Also affects [code]objHUD[/code], which will draw some
## debug data and show a sprite on the mouse position, indicating that the player
## can get teleported. Refer to [method scrPlayer.debug_mouse_teleport]
func toggle_debug_mode() -> void:
	debug_mode = !debug_mode
	debug_toggled.emit(debug_mode)


## Pauses music using a keyboard shortcut
func pause_music() -> void:
	music_is_playing = !music_is_playing


## The "R" key. Checks if the player can reset, and calls [method reset] if so.
func handle_resetting() -> void:
	
	# We check what room we're in, to not reset inside of menus
	if is_valid_room():
		
		# We then check if the game isn't in a paused state
		if !game_paused:
			
			# If all conditions are met, we can reset. If they're not, we
			# make sure we can't reset by setting the variable to false
			can_reset = true
		else:
			can_reset = false
	else:
		can_reset = false
	
	# To avoid R spamming, we check for a single-frame press. As long as we're
	# allowed to reset and we press the proper button, we will reset
	if Input.is_action_just_pressed("button_reset") and (can_reset):
		reset()


## Conditionless reset. Call this to reset directly, without any kind of
## previous requirement (other than a savefile to read from).
func reset():
	
	# A reset is essentially taking the main tree scene and then changing
	# it to the one that's saved inside of our saveload dictionary (check
	# scrGlobalSaveload)
	get_tree().change_scene_to_file(GLOBAL_SAVELOAD.variableGameData.room_name)
	
	# Clear/reset our global trigger array
	triggered_events.clear()
	
	# Saves time and deaths
	GLOBAL_SAVELOAD.save_game(false)
	
	# Resets objHUD's notifications, needed due to it being an autoload
	reset_HUD()
	
	# Clears the item dictionary, avoiding the use of a reset to safely save
	# an item
	GLOBAL_SAVELOAD.itemsGameData.clear()


## Fully quits the game (alt + F4).
func game_quit() -> void:
	get_tree().quit()


## Checks the current scene/room's name. We use this to make sure we're not
## doing things like restarting or pausing on menu related scenes.
func is_valid_room():
	
	# We also need to check if our scene tree is not null. Only then it gets
	# its name (needed for godot v4.2 onwards)
	if get_tree().get_current_scene() != null:
		current_scene_name = get_tree().get_current_scene().name
		
		match current_scene_name:
			"rTitle":
				return false
			"rMenuMain":
				return false
			"rMenuFiles":
				return false
			"rMenuSettings":
				return false
			"rMenuControls":
				return false
			_:
				return true


## Returns a string of text, according to our input device.
## If we use a keyboard, we remove " (Physical)".
## If we use a controller, we just change the entire thing because it looks
## ugly as hell either way. Rebindable controls be damned.
func get_input_name(button_id, input_device):
	
	# Keyboard
	if input_device == KEYBOARD:
		return str(InputMap.action_get_events(button_id)[input_device].as_text().trim_suffix(" (Physical)"))
	
	# Controller
	if input_device == CONTROLLER:
		return str(InputMap.action_get_events(button_id)[input_device].as_text().trim_prefix("Joypad ").left(9).trim_suffix(" "))


## Stops the HUD from showing the item/collectable.
func reset_HUD() -> void:
	if is_instance_valid(objHUD):
		objHUD.container_timer.stop()
		objHUD.item_container.set_visible(false)


## Increments the global time counter.
func time_counter(delta):
	if !game_paused and is_valid_room():
			time += delta
	


## Takes a time parameter and returns it as a formatted string.
func format_time(time_to_format):
	
	var hours   = floor((time_to_format / 60) / 60);
	var minutes = floor(fmod(time_to_format / 60.0, 60));
	var seconds = floor(fmod(time_to_format, 60.0));
	
	return ("%02d" % hours) + ":" + ("%02d" % minutes) + ":"+("%02d" % seconds).right(2)

## Adds death/time to the title.
func handle_titlebar():
	if not is_valid_room():
		get_window().title = ProjectSettings.get_setting("application/config/name")
		return
	var setting: GLOBAL_SETTINGS.TitlebarStats = GLOBAL_SETTINGS.get_setting("titlebar_stats")
	if setting == GLOBAL_SETTINGS.TitlebarStats.OFF:
		return
	var title = ProjectSettings.get_setting("application/config/name") + " -"
	var time_str = " Time: " + format_time(time)
	if setting == GLOBAL_SETTINGS.TitlebarStats.TIME or setting == GLOBAL_SETTINGS.TitlebarStats.ALL:
		title += time_str
	var deaths_str = " Deaths: " + str(deaths)
	if setting == GLOBAL_SETTINGS.TitlebarStats.DEATHS or setting == GLOBAL_SETTINGS.TitlebarStats.ALL:
		title += deaths_str
	get_window().title = title

# Brief helper function for converting frame timing to delta timing.
# Could fit in a dedicated global for helper functions, but placed here for now.
## Given some x per frame and a delta, returns x based on time instead of frames.
func frame_to_delta(per_frame: Variant, delta: float):
	# Mathematically:
	#   physics = expected frames per second (fps)
	#   delta = actual seconds per frame (spf)
	#   dist = speed per frame * expected fps * actual spf
	return per_frame * Engine.get_physics_ticks_per_second() * delta

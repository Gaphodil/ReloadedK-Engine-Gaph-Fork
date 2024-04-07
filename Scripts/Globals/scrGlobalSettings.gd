extends Node

const DATA_PATH := "user://Data/Settings.cfg"
#const SAVE_PASSWORD_STRING := "Change me!"

## The dictionary of settings, structured similarly to
## the config file. Keys are section names, values are
## sub-dictionaries of setting names, and their type and value.
## The setting value is duplicated to represent both default and actual values.
var dict: Dictionary = {
	"volume" : {
		"music_volume" : [TYPE_FLOAT, 1.0],
		"sound_volume" : [TYPE_FLOAT, 1.0],
	},
	"settings" : {
		"fullscreen" : [TYPE_BOOL, false],
		"zoom_scaling" : [TYPE_FLOAT, 1.0],
		"hud_scaling" : [TYPE_FLOAT, 1.0],
		"window_scaling" : [TYPE_FLOAT, 1.0],
		"vsync" : [TYPE_BOOL, true],
		"autoreset" : [TYPE_BOOL, false],
		"fps_display" : [TYPE_INT, FpsDisplay.OFF],
		"titlebar_stats" : [TYPE_INT, TitlebarStats.ALL],
		"extra_keys" : [TYPE_BOOL, false],
	},
}

# Window related variables, for handling window modes
var INITIAL_WINDOW_WIDTH: int = DisplayServer.window_get_size().x
var INITIAL_WINDOW_HEIGHT: int = DisplayServer.window_get_size().y

# Enum for FPS display values
enum FpsDisplay {
	OFF,
	LAG_ONLY,
	ALWAYS_ON	
}

# Enum for titlebar stats
enum TitlebarStats {
	OFF,
	TIME,
	DEATHS,
	ALL
}

func _ready():
	var dir = DirAccess.open("user://")
	
	# If, for any reason, the Data directory doesn't exist, it creates it
	if not dir.dir_exists("user://Data"):
		dir.make_dir("Data")

	# For every value in the settings dict, duplicate the default value
	for section in dict.keys():
		for setting in dict[section].keys():
			dict[section][setting].append(dict[section][setting][1])
	
	# If the settings file doesn't exist, it creates it. If it does exist, it
	# loads it
	if not dir.file_exists(DATA_PATH):
		save_settings()
	else:
		load_settings()

func get_setting(setting: String):
	# Note that this won't function if a setting name is shared between sections
	for section in dict.keys():
		if dict[section].has(setting):
			return dict[section][setting][1]
	print_debug("Setting " + setting + " not found")

## Sets a value. Throws an error if the value is of the wrong type.
func set_setting(setting: String, value):
	for section in dict.keys():
		if dict[section].has(setting):
			assert(
				typeof(value) == dict[section][setting][0],
				"Setting " + setting + " must be of type " + str(dict[section][setting][0])
			)
			dict[section][setting][1] = value
			return
	print_debug("Setting " + setting + " not found")

## Inverts a boolean setting. Throws an error if the setting is not a boolean.
func flip_setting(setting: String):
	for section in dict.keys():
		if dict[section].has(setting):
			assert(
				typeof(dict[section][setting][1]) == TYPE_BOOL,
				"Setting " + setting + " must be of type bool"
			)
			dict[section][setting][1] = !dict[section][setting][1]
			return
	print_debug("Setting " + setting + " not found")

# Saves settings
func save_settings() -> void:
	var configFile := ConfigFile.new()

	for section in dict.keys():
		for setting in dict[section].keys():
			configFile.set_value(section, setting, dict[section][setting][1])
	
	for action in InputMap.get_actions():
		configFile.set_value("controls", action, InputMap.action_get_events(action))
	
	configFile.save(DATA_PATH)


# Load and set settings
func load_settings() -> void:
	var configFile: = ConfigFile.new()
	configFile.load(DATA_PATH)
	
	for section in dict.keys():
		for setting in dict[section].keys():
			dict[section][setting][1] = configFile.get_value(
				section, setting, dict[section][setting][1]
			)
	
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Sounds"),
		linear_to_db(get_setting("sound_volume"))
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(get_setting("music_volume"))
	)
	
	# Applies window and vsync mode
	set_window_mode()
	set_vsync_mode()
	
	# Controls
	for action in configFile.get_section_keys("controls"):
		InputMap.action_erase_events(action)
		for event in configFile.get_value("controls", action):
			InputMap.action_add_event(action, event)


# Resets and sets settings to their default values
func default_settings() -> void:
	for section in dict.keys():
		for setting in dict[section].keys():
			dict[section][setting][1] = dict[section][setting][2]

	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Sounds"),
		linear_to_db(get_setting("sound_volume"))
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(get_setting("music_volume"))
	)

	# Calls the window and vsync mode functions after setting them to their
	# default states
	set_window_mode()
	set_vsync_mode()

	# Sets HUD scaling by calling objHUDs method once
	if is_instance_valid(objHUD):
		objHUD.set_HUD_scaling()

# Sets the game's window mode by checking the FULLSCREEN boolean
func set_window_mode():
	if get_setting("fullscreen") == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		# DisplayServer.window_set_size(Vector2(INITIAL_WINDOW_WIDTH, INITIAL_WINDOW_HEIGHT))
		set_window_scale()


# Sets the game's vsync mode by checking the VSYNC boolean
func set_vsync_mode():
	if get_setting("vsync") == true:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

# Sets the window scaling
func set_window_scale():
	var scale = get_setting("window_scaling")
	var newSize = Vector2(INITIAL_WINDOW_WIDTH * scale, INITIAL_WINDOW_HEIGHT * scale)
	var oldSize = Vector2(DisplayServer.window_get_size())
	# Check to avoid recentering when not changing scale
	if oldSize != newSize:
		DisplayServer.window_set_size(newSize)
		get_window().move_to_center()

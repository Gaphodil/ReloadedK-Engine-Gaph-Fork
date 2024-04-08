extends Node

const DATA_PATH := "user://Data/Settings.cfg"
#const SAVE_PASSWORD_STRING := "Change me!"

## A class that represents a single setting.
class Setting:
	var type: Variant.Type
	var default: Variant
	var value: Variant:
		set = set_value
	# Below values are ignored if type is bool.
	var min_val: Variant
	var max_val: Variant
	var step: Variant

	func _init(
		_type: Variant.Type,
		_default: Variant,
		_min_val: Variant = 0.0,
		_max_val: Variant = 1.0,
		_step: Variant = 0.5
	):
		type = _type
		default = _default
		min_val = _min_val
		max_val = _max_val
		if _type == TYPE_INT or _type == TYPE_FLOAT:
			assert(
				_default >= _min_val and _default <= _max_val,
				"Default value must be between min and max values."
			)
		step = _step
		value = _default
	
	## Sets the value. Errors if the type does not match.
	## If the type is int or float, it also clamps it.
	func set_value(new_val: Variant):
		assert(typeof(new_val) == type, "Value must be of type " + type_string(type))
		if type == TYPE_INT:
			value = clampi(new_val, min_val, max_val)
		elif type == TYPE_FLOAT:
			value = clampf(new_val, min_val, max_val)
		else:
			value = new_val
	
	## Returns the value to default.
	func reset_value():
		value = default
	
	## Increments the value. Errors if not int or float.
	func inc_value():
		if type == TYPE_INT or type == TYPE_FLOAT:
			value += step
		assert(false, "Unimplemented for type" + type_string(type))

	## Decrements the value. Errors if not int or float.
	func dec_value():
		if type == TYPE_INT or type == TYPE_FLOAT:
			value -= step
		assert(false, "Unimplemented for type" + type_string(type))

## The dictionary of settings, structured similarly to
## the config file. Keys are section names, values are
## sub-dictionaries of setting names, and their type and value.
## The setting value is duplicated to represent both default and actual values.
var dict: Dictionary = {
	"volume": {
		"music_volume": Setting.new(TYPE_FLOAT, 1.0, 0.0, 1.0, 0.1),
		"sound_volume": Setting.new(TYPE_FLOAT, 1.0, 0.0, 1.0, 0.1),
	},
	"settings": {
		"fullscreen": Setting.new(TYPE_BOOL, false),
		"zoom_scaling": Setting.new(TYPE_FLOAT, 1.0, 1.0, 2.0, 1.0),
		"hud_scaling": Setting.new(TYPE_FLOAT, 1.0, 1.0, 1.5, 0.5),
		"window_scaling": Setting.new(TYPE_FLOAT, 1.0, 1.0, 2.0, 0.5),
		"vsync": Setting.new(TYPE_BOOL, true),
		"autoreset": Setting.new(TYPE_BOOL, false),
		"fps_display": Setting.new(TYPE_INT, FpsDisplay.OFF, 0, 2, 1),
		"titlebar_stats": Setting.new(TYPE_INT, TitlebarStats.ALL, 0, 3, 1),
		"extra_keys": Setting.new(TYPE_BOOL, false),
		# Add more settings here! Format below, last three for int or float
		# "name": Setting.new(type, default, [minimum, maximum, step])
	},
}

## Formatted strings for each setting.
var formatted: Dictionary = {
	"music_volume": "Music Volume",
	"sound_volume": "Sound Volume",
	"fullscreen": "Fullscreen",
	"zoom_scaling": "Zoom Scale",
	"hud_scaling": "HUD Scale",
	"window_scaling": "Window Scale",
	"vsync": "Vsync",
	"autoreset": "Reset on Death",
	"fps_display": "FPS Display",
	"titlebar_stats": "Titlebar Stats",
	"extra_keys": "Extra Keys",
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
			return dict[section][setting].value
	print_debug("Setting " + setting + " not found")

## Sets a value. Throws an error if the value is of the wrong type.
func set_setting(setting: String, value):
	for section in dict.keys():
		if dict[section].has(setting):
			assert(
				typeof(value) == dict[section][setting].type,
				"Setting " + setting + " must be of type " + type_string(dict[section][setting].type)
			)
			dict[section][setting].set_value(value)
			apply_side_effects(setting)
			return
	print_debug("Setting " + setting + " not found")

## Inverts a boolean setting. Throws an error if the setting is not a boolean.
func flip_setting(setting: String):
	for section in dict.keys():
		if dict[section].has(setting):
			assert(
				typeof(dict[section][setting].value) == TYPE_BOOL,
				"Setting " + setting + " must be of type bool"
			)
			dict[section][setting].set_value(not dict[section][setting].value)
			apply_side_effects(setting)
			return
	print_debug("Setting " + setting + " not found")

# Saves settings
func save_settings() -> void:
	var configFile := ConfigFile.new()

	for section in dict.keys():
		for setting in dict[section].keys():
			configFile.set_value(section, setting, dict[section][setting].value)
	
	for action in InputMap.get_actions():
		configFile.set_value("controls", action, InputMap.action_get_events(action))
	
	configFile.save(DATA_PATH)

## Applies side effects, such as updating window or audio.
## If the setting is "all", every side effect is reapplied.
func apply_side_effects(setting: String):
	if setting == "music_volume" or setting == "all":
		var music_bus: int = AudioServer.get_bus_index("Music")
		AudioServer.set_bus_volume_db(
			music_bus,
			linear_to_db(dict["volume"]["music_volume"].value)
		)
	if setting == "sound_volume" or setting == "all":
		var sounds_bus: int = AudioServer.get_bus_index("Sounds")
		AudioServer.set_bus_volume_db(
			sounds_bus,
			linear_to_db(dict["volume"]["sound_volume"].value)
		)
	if setting == "fullscreen" or setting == "window_scaling" or setting == "all":
		GLOBAL_SETTINGS.set_window_mode()
	if setting == "vsync" or setting == "all":
		GLOBAL_SETTINGS.set_vsync_mode()

## Load and set settings.
func load_settings() -> void:
	var configFile: = ConfigFile.new()
	configFile.load(DATA_PATH)
	
	for section in dict.keys():
		for setting in dict[section].keys():
			dict[section][setting].set_value(
				configFile.get_value(
					section, setting, dict[section][setting].value
				)
			)
	
	apply_side_effects("all")
	
	# Controls
	for action in configFile.get_section_keys("controls"):
		InputMap.action_erase_events(action)
		for event in configFile.get_value("controls", action):
			InputMap.action_add_event(action, event)


## Resets and sets settings to their default values.
func default_settings() -> void:
	for section in dict.keys():
		for setting in dict[section].keys():
			dict[section][setting].reset_value()

	apply_side_effects("all")

	# Sets HUD scaling by calling objHUDs method once
	if is_instance_valid(objHUD):
		objHUD.set_HUD_scaling()

## Sets the game's window mode by checking the fullscreen setting.
func set_window_mode():
	if get_setting("fullscreen") == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		# DisplayServer.window_set_size(Vector2(INITIAL_WINDOW_WIDTH, INITIAL_WINDOW_HEIGHT))
		set_window_scale()


## Sets the game's vsync mode by checking the vsync setting.
func set_vsync_mode():
	if get_setting("vsync") == true:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

## Sets the window scaling.
func set_window_scale():
	var scale = get_setting("window_scaling")
	var newSize = Vector2(INITIAL_WINDOW_WIDTH * scale, INITIAL_WINDOW_HEIGHT * scale)
	var oldSize = Vector2(DisplayServer.window_get_size())
	# Check to avoid recentering when not changing scale
	if oldSize != newSize:
		DisplayServer.window_set_size(newSize)
		get_window().move_to_center()

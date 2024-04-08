extends Control

@export_file("*.tscn") var main_menu: String
@export_file("*.tscn") var controls_menu: String

## The dictionary from GLOBAL_SETTINGS, by reference.
@onready var dict: Dictionary = GLOBAL_SETTINGS.dict

## An array of setting names to exclude from this menu.
var excluded_settings: Array = []

# Camera handling
@onready var camera_anchor_node: Node = $Environment/cameraAnchor

signal changed_setting(setting)

func _ready():
	# Attach listener to GLOBAL_SETTINGS
	if not changed_setting.is_connected(GLOBAL_SETTINGS.apply_side_effects):
		changed_setting.connect(GLOBAL_SETTINGS.apply_side_effects)

	# Creates each button and adds it to the settings container
	init_menu_buttons()

	# Resize the background and tiles to fit the settings container.
	# The settings container does not automatically resize itself
	# outside of the editor, so we have to do calculate it.
	var height: int = max(
		608,
		64 * $SettingsContainer.get_child_count()
	)
	size.y = height
	$SettingsContainer.position.y = 32
	camera_anchor_node.get_child(0).limit_bottom = height
	$Environment/objBackgroundMenus/ColorRect.size.y = height
	$Environment/objBackgroundMenus/TextureRect.size.y = height
	# Not sure about this one, there may be a better way
	$Environment/til16x16.scale.y = height / 608.0

	# Sets focus to the first option
	$SettingsContainer.get_child(0).grab_focus()
	
	# Global data settings loading at startup
	load_from_global_settings()
	
	# Sets and updates the text from each one of the button's labels
	set_labels_text()
	
	# Set the anchor positions for each button in focus
	set_camera_anchor_positions()


# Key press checking (settings, quit)
func _physics_process(_delta):
	
	# Sets and updates the text from each one of the button's labels
	set_labels_text()
	
	# Goes back to the main menu if the "settings" key is pressed. Also plays 
	# a sound to indicate we changed rooms
	if Input.is_action_just_pressed("ui_select"):
		if main_menu != null:
			save_on_exit()
			get_tree().change_scene_to_file(main_menu)
			GLOBAL_SOUNDS.play_sound(GLOBAL_SOUNDS.sndPause)

# Updates anchor positions for the camera when an input is detected
func _input(event):
	if (event is InputEventKey) or (event is InputEventJoypadButton):
		set_camera_anchor_positions()

##################################################################################################################

## Inititalizes every [code]objMenuButton[/code] besides the last three.
## Order is based on insertion order in [code]GLOBAL_SETTINGS[/code].
func init_menu_buttons():
	const button := preload("res://Objects/UI/objMenuButton.tscn")
	var cur_button: MenuItemButton

	# Iterate through the global settings dict
	for setting in dict.keys():
		# Skip if the setting is in the excluded list
		if excluded_settings.has(setting):
			continue

		# Create a button. Button text is assigned later in _ready.
		cur_button = button.instantiate()
		# The name will be used to reference the specific button later.
		cur_button.name = GLOBAL_SETTINGS.formatted[setting]

		# Assign the callback based on setting type
		if GLOBAL_SETTINGS.get_setting_type(setting) == TYPE_BOOL:
			cur_button.pressed.connect(get_callback(setting))
		else:
			cur_button.gui_input.connect(get_callback(setting))

		# Add to the scene tree. Since the last 3 buttons already exist,
		# we slide it in right before
		$SettingsContainer.add_child(cur_button)
		$SettingsContainer.move_child(cur_button, -4)

		# Set the button's neighbours, as well as the previous
		cur_button.focus_neighbor_left = "."
		cur_button.focus_neighbor_right = "."
		if $SettingsContainer.get_child_count() <= 4:
			cur_button.focus_neighbor_top = $SettingsContainer/Back.get_path()
			$SettingsContainer/Back.focus_neighbor_bottom = cur_button.get_path()
		else:
			var prev_button: MenuItemButton = $SettingsContainer.get_child(-5)
			cur_button.focus_neighbor_top = prev_button.get_path()
			prev_button.focus_neighbor_bottom = cur_button.get_path()

	# Assign the missing parts of the loop
	cur_button.focus_neighbor_bottom = $SettingsContainer/Reset.get_path()
	$SettingsContainer/Reset.focus_neighbor_top = cur_button.get_path()

## Generates an appropriate lambda for the callback.
## Depends on the setting's specified type.
func get_callback(setting: String) -> Callable:
	var setting_type: Variant.Type = GLOBAL_SETTINGS.get_setting_type(setting)

	# This can apply to regular enums too!
	if setting_type == TYPE_FLOAT or setting_type == TYPE_INT:
		# This callback is for the `gui_event` signal
		return func(_event):
			if Input.is_action_just_pressed("ui_right"):
				GLOBAL_SETTINGS.inc_setting(setting)
			if Input.is_action_just_pressed("ui_left"):
				GLOBAL_SETTINGS.dec_setting(setting)
			changed_setting.emit(setting)

	if setting_type == TYPE_BOOL:
		# This callback is for the `pressed` signal
		return func():
			GLOBAL_SETTINGS.flip_setting(setting)
			changed_setting.emit(setting)

	# If you have settings of other types, you can add them here
	return func(_event):
		print_debug("Not implemented")


##################################################################################################################

# Reset the setting's values back to their default ones. Also plays a
# confirmation sound effect
func _on_defaults_pressed():
	reset_settings_to_default()
	GLOBAL_SOUNDS.play_sound(GLOBAL_SOUNDS.sndPause)


# Go to the controls room
func _on_controls_pressed():
	if controls_menu != null:
		save_on_exit()
		get_tree().change_scene_to_file(controls_menu)
		GLOBAL_SOUNDS.play_sound(GLOBAL_SOUNDS.sndPause)


# Return to the main menu
func _on_back_pressed():
	if main_menu != null:
		save_on_exit()
		get_tree().change_scene_to_file(main_menu)
		GLOBAL_SOUNDS.play_sound(GLOBAL_SOUNDS.sndPause)

##########################################################################################################

# Loads data from the global settings file
func load_from_global_settings():
	
	# Loads the settings data, then updates the labels on each button
	GLOBAL_SETTINGS.load_settings()


# Sets and updates the text from each one of the button's labels
func set_labels_text():
	for setting in dict.keys():
		if not excluded_settings.has(setting):
			set_label_text(setting)
	$SettingsContainer/Reset.set_text("Reset to Defaults")
	$SettingsContainer/Controls.set_text("Controls")
	$SettingsContainer/Back.set_text("Back")

## Sets and updates the text on a button based on its
## setting name and type in the dict.
func set_label_text(setting: String):
	for key in dict.keys():
		if setting == key:
			var append: String = ": "
			if dict[setting].section == "volume":
				append += str(round(dict[setting].value * 100)) + "%"
			elif dict[setting].type == TYPE_BOOL:
				append += str(bool_to_on_off(dict[setting].value))
			elif dict[setting].type == TYPE_FLOAT:
				append += str(dict[setting].value) + "x"
			# Add enum handling here
			# If you add a generic TYPE_INT setting,
			# add it *after* the enums
			elif setting == "fps_display":
				match dict[setting].value:
					GLOBAL_SETTINGS.FpsDisplay.OFF:
						append += "Off"
					GLOBAL_SETTINGS.FpsDisplay.LAG_ONLY:
						append += "Lag Only"
					GLOBAL_SETTINGS.FpsDisplay.ALWAYS_ON:
						append += "Always On"
			elif setting == "titlebar_stats":
				match dict[setting].value:
					GLOBAL_SETTINGS.TitlebarStats.OFF:
						append += "Off"
					GLOBAL_SETTINGS.TitlebarStats.TIME:
						append += "Time"
					GLOBAL_SETTINGS.TitlebarStats.DEATHS:
						append += "Deaths"
					GLOBAL_SETTINGS.TitlebarStats.ALL:
						append += "All"

			var formatted_name = GLOBAL_SETTINGS.formatted[setting]
			$SettingsContainer.get_node(formatted_name).set_text(
				formatted_name + append
			)
			return
	print_debug("Setting " + setting + " not found")

## When leaving the settings menu, saves values to the global settings file.
func save_on_exit():
	# Since this menu updates the settings object directly,
	# with all side effects taking place there,
	# we don't need to do anything but save the file.
	GLOBAL_SETTINGS.save_settings()


# Sets the values back to their default ones (menu settings first, then global
# settings)
func reset_settings_to_default():
	if excluded_settings.size() == 0:
		GLOBAL_SETTINGS.default_settings()
	else:
		# Iterate through all non-excluded settings
		for setting in dict.keys():
			if not setting in excluded_settings:
				GLOBAL_SETTINGS.reset_setting(setting)


# Replaces "true/false" for "on/off". Easier to read and understand
func bool_to_on_off(bool_value):
	if bool_value == true:
		return "On"
	else:
		return "Off"


# Set the anchor positions for each button in focus
func set_camera_anchor_positions():
	
	for settings_container_nodes in $SettingsContainer.get_children():
		if settings_container_nodes.has_focus():
			camera_anchor_node.position.y = settings_container_nodes.position.y

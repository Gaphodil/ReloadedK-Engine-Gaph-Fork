extends Control

var item_sprite: CompressedTexture2D
var item_text: String = ""
@onready var item_container: Node = $Display/MarginContainer2
@onready var container_timer: Node = $Display/MarginContainer2/Timer
@onready var fps_container: Node = $Display/MarginContainer3
var fps_fadeout_amt: float = -1.0
var manual_frame_counter: Array = []
var last_four_fps: Array[int] = [120, 120, 120, 120]
var manual_fps: int = 480

var show_extra_debug: bool = false:
	set(val):
		show_extra_debug = val
		update_extra_label_vis()
@onready var extra_debug_labels: Dictionary = {
	"[G]odmode": $Display/MarginContainer/VBoxContainer/textDebug6,
	"[I]nf Jump": $Display/MarginContainer/VBoxContainer/textDebug7,
	"[H]itbox": $Display/MarginContainer/VBoxContainer/textDebug8,
	"Sa[v]e": $Display/MarginContainer/VBoxContainer/textDebug9
}

## If this is true, FPS will be calculated every frame
## instead of using the Engine value every second.
var avg_fps: bool = false

## The number of decimals the X and Y position round to.
var pos_round_decimals: int = 4

func _ready():
	$Display/MarginContainer2.set_visible(false)
	fps_container.set_visible(false)
	set_HUD_scaling()
	handle_debug_mode()
	# Initiate manual frame counter with 120 copies of current time
	for _i in range(120):
		manual_frame_counter.append(Time.get_ticks_msec())
	handle_fps_indic(0)

func _process(_delta):
	if avg_fps:
		# Add current time
		manual_frame_counter.append(Time.get_ticks_msec())
		# Remove any that are older than 0.25 seconds
		while manual_frame_counter.size() > 0 and manual_frame_counter[0] < Time.get_ticks_msec() - 250:
			manual_frame_counter.pop_front()

func _physics_process(delta):
	if avg_fps:
		# Pop the last four fps and replace it with the current sum
		last_four_fps.pop_front()
		last_four_fps.append(manual_frame_counter.size())
		manual_fps = 0
		for val in last_four_fps:
			manual_fps += val

	handle_debug_mode()
	handle_fps_indic(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_BACKSLASH:
			show_extra_debug = not show_extra_debug

func update_extra_label_vis():
	$Display/MarginContainer/VBoxContainer/textDebug5.text = (
		"[\\]: Show " + ("Less" if show_extra_debug else "More")
	)
	for label in extra_debug_labels.values():
		label.set_visible(show_extra_debug)

func set_HUD_scaling():
	var hud_scale: float = GLOBAL_SETTINGS.get_setting("hud_scaling")
	$Display/MarginContainer.scale = Vector2(hud_scale, hud_scale)
	item_container.scale = Vector2(hud_scale, hud_scale)
	fps_container.scale = Vector2(hud_scale, hud_scale)

# The debug HUD should only get shown as long as objPlayer exists in the scene,
# regardless of debug_mode being true or false
func handle_debug_mode() -> void:
	if is_instance_valid(GLOBAL_INSTANCES.objPlayerID):
		if (GLOBAL_GAME.debug_mode == false):
			$Display/MarginContainer.set_visible(false)
			$Sprite2D.set_visible(false)
		else:
			# Change pivot offset so container stays right aligned
			# Will jitter if Player text is longer than Room text
			$Display/MarginContainer.pivot_offset.x = $Display/MarginContainer.size.x
			$Display/MarginContainer.set_visible(true)
			# per tutorials/scripting/gdscript/gdscript_format_string.html#dynamic-padding
			var x_pos_str: String = "%.*f" % [pos_round_decimals, GLOBAL_INSTANCES.objPlayerID.position.x]
			var y_pos_str: String = "%.*f" % [pos_round_decimals, GLOBAL_INSTANCES.objPlayerID.position.y]
			$Display/MarginContainer/VBoxContainer/textDebug1.text = str(" Player X: ", x_pos_str, " ")
			$Display/MarginContainer/VBoxContainer/textDebug2.text = str(" Player Y: ", y_pos_str, " ")
			var fps: int = manual_fps if avg_fps else int(Engine.get_frames_per_second())
			$Display/MarginContainer/VBoxContainer/textDebug3.text = str(" FPS: %d" % fps, " ")
			
			# Extra check added for v4.2 compatibility
			if get_tree().get_current_scene() != null:
				$Display/MarginContainer/VBoxContainer/textDebug4.text = str(" Room: ", get_tree().get_current_scene().name, " ")
			
			# Debug "cursor indicator"
			$Sprite2D.set_visible(not Input.is_action_pressed("button_debug_teleport"))
			$Sprite2D.position = get_global_mouse_position()
			$Sprite2D.flip_h = !GLOBAL_INSTANCES.objPlayerID.xscale

			if show_extra_debug:
				var keys := extra_debug_labels.keys()
				extra_debug_labels[keys[0]].text = keys[0] + ": " + str(GLOBAL_INSTANCES.objPlayerID.debug_godmode)
				extra_debug_labels[keys[1]].text = keys[1] + ": " + str(GLOBAL_INSTANCES.objPlayerID.debug_inf_jump)
				extra_debug_labels[keys[2]].text = keys[2] + ": " + str(GLOBAL_INSTANCES.objPlayerID.debug_hitbox)
	else:
		$Display/MarginContainer.set_visible(false)
		$Sprite2D.set_visible(false)

# Sets the item container
func handle_item_notification():
	
	# Shows the item container
	item_container.set_visible(true)
	
	# Sets sprite and texture from collectables
	$Display/MarginContainer2/Panel/Sprite2D.texture = item_sprite
	$Display/MarginContainer2/Panel/Label.text = str(item_text + " found!")
	
	# Starts the timer countdown
	container_timer.start()

# Hides the item container
func _on_timer_timeout():
	item_container.set_visible(false)

# Shows the FPS in the HUD.
func handle_fps_indic(delta):
	fps_container.set_visible(false)
	var fps_setting: GLOBAL_SETTINGS.FpsDisplay = (
		GLOBAL_SETTINGS.get_setting("fps_display")
	)
	if not fps_setting == GLOBAL_SETTINGS.FpsDisplay.OFF:
		var fps: int = manual_fps if avg_fps else int(Engine.get_frames_per_second())
		var label = fps_container.get_child(0)
		label.text = str(fps)
		if (
			fps_setting == GLOBAL_SETTINGS.FpsDisplay.ALWAYS_ON
			or fps < 50
		):
			# Reset visibility
			fps_container.set_visible(true)
			fps_fadeout_amt = 0.0
			fps_container.modulate.a = 1.0
			# Change label colour by amount of lag
			# yellow < 50 and red < 30
			var col: Color
			if fps < 30:
				col = Color(1, 0, 0)
			elif fps < 50:
				col = Color(1, 1, 0)
			else:
				col = Color(1, 1, 1)
			label.add_theme_color_override("font_color", col)
		elif (
			fps_setting == GLOBAL_SETTINGS.FpsDisplay.LAG_ONLY
			and fps_fadeout_amt >= 0.0
		):
			fps_container.set_visible(true)
			label.add_theme_color_override("font_color", Color(1, 1, 1))
			# Fadeout the text if no longer lagging
			fps_fadeout_amt += delta
			fps_container.modulate.a = 1.0 - lerpf(0.0, 1.0, fps_fadeout_amt)
			if fps_fadeout_amt >= 1.0:
				fps_fadeout_amt = -1.0
	else:
		fps_fadeout_amt = -1.0

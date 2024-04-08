extends Control

var item_sprite: CompressedTexture2D
var item_text: String = ""
@onready var item_container: Node = $Display/MarginContainer2
@onready var container_timer: Node = $Display/MarginContainer2/Timer
@onready var fps_container: Node = $Display/MarginContainer3
var fps_fadeout_amt: float = -1.0

func _ready():
	$Display/MarginContainer2.set_visible(false)
	fps_container.set_visible(false)
	set_HUD_scaling()
	handle_debug_mode()
	handle_fps_indic(0)

func _physics_process(delta):
	handle_debug_mode()
	handle_fps_indic(delta)

func set_HUD_scaling():
	var hud_scale: float = GLOBAL_SETTINGS.get_setting("hud_scaling")
	$Display/MarginContainer.scale = Vector2(hud_scale, hud_scale)
	item_container.scale = Vector2(hud_scale, hud_scale)

# The debug HUD should only get shown as long as objPlayer exists in the scene,
# regardless of debug_mode being true or false
func handle_debug_mode() -> void:
	if is_instance_valid(GLOBAL_INSTANCES.objPlayerID):
		if (GLOBAL_GAME.debug_mode == false):
			$Display/MarginContainer.set_visible(false)
			$Sprite2D.set_visible(false)
		else:
			$Display/MarginContainer.set_visible(true)
			$Display/MarginContainer/VBoxContainer/textDebug1.text = str(" Player X: ", round(GLOBAL_INSTANCES.objPlayerID.position.x), " ")
			$Display/MarginContainer/VBoxContainer/textDebug2.text = str(" Player Y: ", round(GLOBAL_INSTANCES.objPlayerID.position.y), " ")
			$Display/MarginContainer/VBoxContainer/textDebug3.text = str(" FPS: %d" % Engine.get_frames_per_second(), " ")
			
			# Extra check added for v4.2 compatibility
			if get_tree().get_current_scene() != null:
				$Display/MarginContainer/VBoxContainer/textDebug4.text = str(" Room: ", get_tree().get_current_scene().name, " ")
			
			$Sprite2D.set_visible(true)
			$Sprite2D.position = get_global_mouse_position()
			$Sprite2D.flip_h = !GLOBAL_INSTANCES.objPlayerID.xscale
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
		var fps = Engine.get_frames_per_second()
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


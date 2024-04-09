extends Camera2D

## The node tracked by the camera.
@export var target_node: Node = null
@export var scrolling_speed: int = 10

# Zoom related variables. You can ignore the global zoom from the settings and
# add the zoom amount manually
@export_category("Zoom")
@export var ignore_global_zoom: bool = false
@export var manual_zoom_amount: Vector2 = Vector2.ONE

var camera_width: float = 800
var camera_height: float = 608



# Sets the zoom scaling and position smoothing speed once
func _ready():
	
	# Sets the camera for each reset
	if is_instance_valid(target_node):
		set_camera_target()
	else:
		target_node = self
	
	# Sets initial zoom and scrolling speed
	if !ignore_global_zoom:
		var zoom_scale: float = GLOBAL_SETTINGS.get_setting("zoom_scaling")
		zoom = Vector2(zoom_scale, zoom_scale)
	else:
		zoom = manual_zoom_amount
	position_smoothing_speed = scrolling_speed
	
	# Hides the sprite
	$Sprite2D.visible = false


# Updates the camera target and enables position smoothing if disabled
func _physics_process(_delta):
	if is_instance_valid(target_node):
		set_camera_target()
	
	if !is_position_smoothing_enabled():
		position_smoothing_enabled = true



# Sets the camera target. If it's valid, it then sets the position to the
# center of the screen relative to the target's position
func set_camera_target():
	var zoom_scale: float = GLOBAL_SETTINGS.get_setting("zoom_scaling")
	var camera_width_zoom: float = camera_width / zoom_scale
	var camera_height_zoom: float = camera_height / zoom_scale
	
	position.x = floor(target_node.position.x / camera_width_zoom) * camera_width_zoom + (camera_width_zoom / 2)
	position.y = floor(target_node.position.y / camera_height_zoom) * camera_height_zoom + (camera_height_zoom / 2)

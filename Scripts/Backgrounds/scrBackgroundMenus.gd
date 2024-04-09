extends ParallaxBackground

## The horzontal scroll-speed, multiplied by delta.
@export var scrolling_speed: int = -80

func _physics_process(delta):
	scroll_offset.x += scrolling_speed * delta
	pass

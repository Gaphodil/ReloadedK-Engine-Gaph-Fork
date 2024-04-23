extends Area2D
# Duplicating code from `scrMovingPlatform` but there's probably a method
# that uses a Resource or something

# Note that if you place both platform types next to each other with the same speed,
# this one will be ahead by a frame. For some reason.

## The distance moved per frame.
@export var move_speed: Vector2 = Vector2.ZERO

## Whether the platform gives the player a grounded jump or a double jump.
@export var grounded_jump: bool = true

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if (move_speed != Vector2.ZERO):
		# Change local position directly
		position += GLOBAL_GAME.frame_to_delta(move_speed, delta)
	
func _on_body_entered(_body):
	# Collision will only be with the `collision_mask`, so just reverse direction
	move_speed = -move_speed

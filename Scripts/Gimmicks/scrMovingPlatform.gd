extends AnimatableBody2D

## The distance moved per frame.
@export var move_speed: Vector2 = Vector2.ZERO

## Whether the platform gives the player a grounded jump or a double jump.
@export var grounded_jump: bool = true

## Whether the player will snap to the platform when jumping through it.
@export var snap_to_platform: bool = true

## How high above the platform the player can be to determine if the player should snap.
@export var snap_height: float = 32.0

func _ready():
	# Connect to the player's platform exit signal
	GLOBAL_INSTANCES.objPlayerID.player_exited_platform.connect(try_snap)

func _physics_process(delta):
	if (move_speed != Vector2.ZERO):
		
		# Godot will complain about physics bodies using move_and_collide() 
		# while sync_to_physics is enabled. A hacky but somehow accurate 
		# solution to this is disabling sync_to_physics, using 
		# move_and_collide(), re-enabling sync_to_physics and using the values 
		# it returned later on.
		set_sync_to_physics(false);
		var collision_check = move_and_collide(
			GLOBAL_GAME.frame_to_delta(move_speed, delta) / 2, true
		);
		
		# Re-enable sync_to_physics
		set_sync_to_physics(true);
		
		# If a collision with a platform block was detected, the movement speed
		# gets reversed
		if collision_check:
			move_speed = -move_speed
		
		# Change local position directly
		position += GLOBAL_GAME.frame_to_delta(move_speed, delta)
		
## Checks if the player has upward velocity and has their shoes within the `snap_height`.
func can_snap(player: Player) -> bool:
	# Checking for shoes could also happen here instead, hardcoded based on player height
	if player.velocity.y < 0:
		# Physics aren't playing nice so we'll do it the stupid way.
		# This is a very infrequent check so it being performant doesn't matter much
		var player_rect: Rect2 = player.get_node("extraCollisions/Platforms/CollisionShape2D").shape.get_rect()
		var platform_rect: Rect2 = get_node("CollisionShape2D").shape.get_rect()

		# The rects are in the local coordinates and not multiplied by any scaling
		# so we're making a LOT of assumptions about what is and isn't scaled
		player_rect.position *= player.scale
		player_rect.size *= player.scale

		platform_rect.position *= scale
		platform_rect.size *= scale

		# Add the node positions as offsets to get the rects' in-world positions
		player_rect.position += player.position
		platform_rect.position += position

		# Squish the player rect down to 1 pixel to represent the shoes
		player_rect.position.y += player_rect.size.y - 1
		player_rect.size.y = 1

		# Only check if it intersects the area above, not the platform itself
		platform_rect.position.y -= snap_height
		platform_rect.size.y = snap_height

		# Then check if they intersect
		if platform_rect.intersects(player_rect):
			return true
		# BUT apparently an issue with this specific way of doing it
		# is sometimes the check is performed BEFORE the rect moves by player velocity
		# So simulate a frame of movement and check again
		print_debug(platform_rect, player_rect)
		player_rect.position += player.velocity / Engine.get_physics_ticks_per_second()
		if not platform_rect.intersects(player_rect):
			print_debug(platform_rect, player_rect)
		return platform_rect.intersects(player_rect)
	return false

## Tries to snap the player.
func try_snap(id: int) -> void:
	if not snap_to_platform or id != get_instance_id():
		return
	var player: Player = GLOBAL_INSTANCES.objPlayerID
	if can_snap(player):
		player.apply_floor_snap()
		player.velocity.y = 0


extends AnimatableBody2D

## The distance moved per frame.
@export var move_speed: Vector2 = Vector2.ZERO


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
		

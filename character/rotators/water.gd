class_name WaterRotator
extends Rotator


@export var water_physics: WaterPhysics
@export var rot_speed: float = 10

@export var rot_amount: float = 0.075
@export var skew_amount: float = 0.075


func update_rotation(delta: float) -> float:
	var target_rot: float = clamp(
		(character.velocity.y / water_physics.max_speed),
		-1,
		1
	) * PI * rot_amount
	target_rot *= character.facing_dir
	
	## framerate independance
	var alpha: float = 1.0 - exp(-rot_speed * delta)
	return lerp_angle(animator.rotation, target_rot, alpha)


func update_skew(delta: float) -> float:
	var target_skew: float = (character.velocity.x / water_physics.max_speed) * skew_amount
	var y_factor: float = clamp(
		(character.velocity.y / water_physics.max_speed),
		-1,
		1
	)
	target_skew *= 1 - abs(y_factor)
	
	## framerate independance
	var alpha: float = 1.0 - exp(-rot_speed * delta)
	return lerp_angle(animator.skew, target_skew, alpha)

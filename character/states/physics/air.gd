class_name AirPhysics
extends PhysicsState


@export_group("Movement")
@export var accel: float
@export var max_speed: float

@export_group("Gravity")
@export var max_fall: float
@export var is_buoyant: bool
@export var float_factor: float = 1
@export var water_check: Area2D

@export_group("Misc")
@export var bounce_factor: float = 0
var did_bounce: bool

var last_velocity: Vector2


func do_movement(delta: float, move_dir: int) -> void:
	var working_accel: float = 0.0
	
	if move_dir != 0:
		working_accel += accel * move_dir * delta
		if set_facing: character.facing_dir = move_dir
	
	var projected_speed: float = character.velocity.x + working_accel
	if abs(projected_speed) > max_speed:
		if abs(character.velocity.x) < max_speed:
			working_accel = (max_speed * move_dir) - character.velocity.x
		else:
			working_accel = 0
	
	character.velocity.x += working_accel


@export_group("Misc")
@export var ground_name: String
@export var set_facing: bool = true


## runs this check every frame while inactive and 
## in the character's current pool of states
func _startup_check() -> bool:
	return not character.on_ground


## runs this check every frame while active
## the string returned is the name of the state to change to
## return self.name for no change!
func _transition_check() -> String:
	if character.on_ground:
		return ground_name
	return name


## runs every frame while active
func _update(delta: float) -> void:
	## Gravity
	var factor: float = 1
	var target_velocity: float = max_fall
	if is_buoyant and not water_check.get_overlapping_bodies().is_empty():
		target_velocity = -target_velocity
		factor = float_factor
	
	var total_gravity: float = character.get_gravity_sum()
	character.velocity.y = move_toward(
		character.velocity.y, 
		target_velocity, 
		total_gravity * factor * delta
	)
	
	var move_dir: int = 0
	if character.input["left"][0]: move_dir -= 1 
	if character.input["right"][0]: move_dir += 1
	do_movement(delta, move_dir)
	
	## bounce off walls
	if character.is_on_wall():
		if not did_bounce:
			character.velocity.x = -last_velocity.x * bounce_factor
		did_bounce = true
	else:
		did_bounce = false
	
	## run base function
	super(delta)
	
	last_velocity = character.velocity

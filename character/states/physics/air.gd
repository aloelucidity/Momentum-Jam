class_name AirPhysics
extends PhysicsState


@export_group("Movement")
@export var accel: float
@export var max_speed: float


func do_movement(delta: float, move_dir: int) -> void:
	var working_accel: float = 0.0
	
	if move_dir != 0:
		working_accel += accel * move_dir * delta
		if set_facing: character.facing_dir = move_dir
	
	var projected_speed: float = character.velocity.x + working_accel
	if abs(projected_speed) > max_speed:
		working_accel = (max_speed * move_dir) - character.velocity.x
		if sign(working_accel) != sign(move_dir): working_accel = 0
	
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
	var total_gravity: float = character.get_gravity_sum()
	character.velocity.y += total_gravity * delta
	
	var move_dir: int = 0
	if character.input["left"][0]: move_dir -= 1 
	if character.input["right"][0]: move_dir += 1
	do_movement(delta, move_dir)
	
	## run base function
	super(delta)

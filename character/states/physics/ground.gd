class_name GroundPhysics
extends PhysicsState


@export_group("Movement")
@export var accel: float
@export var max_speed: float
@export var friction_linear: float
@export var friction_decay: float = 1


@export_group("Misc")
@export var air_name: String
@export var set_facing: bool = true


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


func do_friction(delta: float) -> void:
	character.velocity.x = move_toward(character.velocity.x, 0, friction_linear * delta)
	
	## framerate independance
	var decay_factor: float = pow(friction_decay, delta)
	character.velocity.x *= decay_factor


## runs this check every frame while inactive and 
## in the character's current pool of states
func _startup_check() -> bool:
	return character.on_ground


## runs this check every frame while active
## the string returned is the name of the state to change to
## return self.name for no change!
func _transition_check() -> String:
	if not character.on_ground:
		return air_name
	return name


## runs every frame while active
func _update(delta: float) -> void:
	character.velocity.y = min(0, character.velocity.y)
	
	var move_dir: int = 0
	if character.input["left"][0]: move_dir -= 1 
	if character.input["right"][0]: move_dir += 1
	
	if move_dir == 0:
		do_friction(delta)
	else:
		do_movement(delta, move_dir)
	
	## run base function
	super(delta)

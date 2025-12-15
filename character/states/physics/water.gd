class_name WaterPhysics
extends PhysicsState


@export_group("Movement")
@export var accel: float
@export var max_speed: float
@export var friction_linear: float
@export var friction_decay: float = 1

@export_group("Misc")
@export var water_check: Area2D
@export var enter_factor: float = 1
@export var exit_factor: float = 1

@export_group("Misc")
@export var air_name: String
@export var set_facing: bool = true

var can_move: bool = true


## runs this check every frame while inactive and 
## in the character's current pool of states
func _startup_check() -> bool:
	return not water_check.get_overlapping_bodies().is_empty()


## runs this check every frame while active
## the string returned is the name of the state to change to
## return self.name for no change!
func _transition_check() -> String:
	if water_check.get_overlapping_bodies().is_empty():
		return air_name
	return name


## runs once when this state begins being active
func _on_enter() -> void:
	character.velocity.y *= enter_factor


## runs once when this state stops being active
func _on_exit() -> void:
	character.velocity.y *= exit_factor


## runs every frame while active
func _update(delta: float) -> void:
	var move_dir := Vector2.ZERO
	
	if can_move:
		if character.input["left"][0]: move_dir.x -= 1
		if character.input["right"][0]: move_dir.x += 1
		if character.input["up"][0]: move_dir.y -= 1
		if character.input["down"][0]: move_dir.y += 1
	
	if move_dir.x != 0:
		character.facing_dir = int(move_dir.x)
		character.velocity.x = move_toward(
			character.velocity.x, max_speed * move_dir.x , accel * delta)
	else:
		character.velocity.x = move_toward(character.velocity.x, 0, friction_linear * delta)
		## framerate independance
		var decay_factor: float = pow(friction_decay, delta)
		character.velocity.x *= decay_factor
	
	if move_dir.y != 0:
		character.velocity.y = move_toward(
			character.velocity.y, max_speed * move_dir.y, accel * delta)
	else:
		character.velocity.y = move_toward(character.velocity.y, 0, friction_linear * delta)
		## framerate independance
		var decay_factor: float = pow(friction_decay, delta)
		character.velocity.y *= decay_factor
	
	## run base function
	super(delta)

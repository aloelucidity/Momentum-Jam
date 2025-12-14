class_name RunPhysics
extends GroundPhysics


@export var ground_name: String
@export var stop_buffer: float
var start_direction: int
var stop_timer: float

@export_group("Gravity")
@export var max_fall: float


## runs this check every frame while active
## the string returned is the name of the state to change to
## return self.name for no change!
func _transition_check() -> String:
	var input_dir: int = 0
	if character.input["left"][0]: input_dir -= 1 
	if character.input["right"][0]: input_dir += 1
	
	if input_dir != start_direction:
		return ground_name
	
	if stop_timer > 0:
		return name
	
	return ground_check()


func ground_check() -> String:
	if not character.on_ground:
		return air_name
	return name


## runs once when this state begins being active
func _on_enter() -> void:
	stop_timer = stop_buffer


func _update(delta: float) -> void:
	## Gravity (required because the player can be in this state and not grounded)
	if not character.on_ground:
		var total_gravity: float = character.get_gravity_sum()
		character.velocity.y = move_toward(
			character.velocity.y, 
			max_fall, 
			total_gravity * delta
		)
	else:
		character.velocity.y = min(0, character.velocity.y)
	
	if ground_check() != name:
		stop_timer -= delta
	else:
		stop_timer = stop_buffer
	
	var move_dir: int = 0
	if character.input["left"][0]: move_dir -= 1 
	if character.input["right"][0]: move_dir += 1
	
	if move_dir == 0:
		do_friction(delta)
	else:
		do_movement(delta, move_dir)

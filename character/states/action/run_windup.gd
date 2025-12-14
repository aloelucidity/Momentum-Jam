class_name RunWindupAction
extends ActionState


@export var start_speed: float
@export var run_physics: PhysicsState
@export var windup_duration: float
@export var max_release_time: float

var windup_timer: float
var held_timer: float
var run_direction: int

var last_dir: int
var do_startup: bool


## runs this check every frame while inactive and 
## in the character's current pool of states
func _startup_check() -> bool:
	return do_startup


## runs this check every frame while active
## the string returned is the name of the state to change to
## return self.name for no change!
func _transition_check() -> String:
	if windup_timer <= 0:
		return ""
	return name


## runs once when this state begins being active
func _on_enter() -> void:
	do_startup = false
	run_physics.start_direction = sign(run_direction)
	
	held_timer = 0
	windup_timer = windup_duration


## runs every frame while active
func _update(delta: float) -> void:
	windup_timer -= delta

	var input_dir: int = 0
	if character.input["left"][0]: input_dir -= 1 
	if character.input["right"][0]: input_dir += 1
	
	if input_dir == run_direction:
		if character.velocity.x * run_direction < start_speed:
			character.velocity.x = start_speed * run_direction
		character.set_state("physics", run_physics)
		windup_timer = 0


## always runs no matter what, before any of the other functions
func _general_update(delta: float) -> void:
	var input_dir: int = 0
	if character.input["left"][0]: input_dir -= 1 
	if character.input["right"][0]: input_dir += 1
	
	if input_dir != last_dir:
		if input_dir == 0 and held_timer < max_release_time:
			run_direction = last_dir
			do_startup = true
		held_timer = 0
	
	elif input_dir != 0:
		do_startup = false
		held_timer += delta
	
	last_dir = input_dir

class_name RunWindupAction
extends ActionState


@export var run_physics: PhysicsState
@export var windup_duration: float
@export var input_grace_duration: float

var windup_timer: float
var reset_timer: float
var run_direction: int


## runs this check every frame while inactive and 
## in the character's current pool of states
func _startup_check() -> bool:
	var left: bool = character.input["left"][0]
	var right: bool = character.input["right"][0]
	
	if run_direction == 0:
		if right:
			reset_timer = input_grace_duration
			run_direction = 1
			
		if left:
			reset_timer = input_grace_duration
			run_direction = -1
	
	else:
		var inputting_run: bool = (run_direction < 0 and left) or (run_direction > 0 and right)
		
		if not inputting_run:
			run_direction *= 2
		
		if inputting_run and abs(run_direction) > 1:
			return true
	
	return false


## runs this check every frame while active
## the string returned is the name of the state to change to
## return self.name for no change!
func _transition_check() -> String:
	if windup_timer <= 0:
		return ""
	return name


## runs once when this state begins being active
func _on_enter() -> void:
	run_physics.start_direction = sign(run_direction)
	
	reset_timer = 0
	run_direction = 0
	windup_timer = windup_duration


## runs every frame while active
func _update(delta: float) -> void:
	windup_timer -= delta


## always runs no matter what, before any of the other functions
func _general_update(delta: float) -> void:
	reset_timer -= delta
	if reset_timer <= 0:
		reset_timer = 0
		run_direction = 0

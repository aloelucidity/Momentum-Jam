class_name RideBallAction
extends ActionState


@export var ball_physics: PhysicsState
@export var press_buffer: float
var press_timer: float


## runs this check every frame while inactive and 
## in the character's current pool of states
func _startup_check() -> bool:
	return press_timer > 0


## runs this check every frame while active
## the string returned is the name of the state to change to
## return self.name for no change!
func _transition_check() -> String:
	return ""


## runs once when this state begins being active
func _on_enter() -> void:
	press_timer = 0
	character.set_state("physics", ball_physics)


## always runs no matter what, before any of the other functions
func _general_update(delta: float) -> void:
	var ball_just_pressed: bool = character.input["ball"][1]
	if ball_just_pressed:
		press_timer = press_buffer
	else:
		press_timer -= delta

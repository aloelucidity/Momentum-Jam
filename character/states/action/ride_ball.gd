class_name RideBallAction
extends ActionState


@export var ball_physics: PhysicsState


## runs this check every frame while inactive and 
## in the character's current pool of states
func _startup_check() -> bool:
	return character.input["ball"][1]


## runs this check every frame while active
## the string returned is the name of the state to change to
## return self.name for no change!
func _transition_check() -> String:
	return ""


## runs once when this state begins being active
func _on_enter() -> void:
	character.set_state("physics", ball_physics)

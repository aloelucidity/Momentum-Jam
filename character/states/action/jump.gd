class_name JumpAction
extends ActionState


@export var jump_power: float
@export var fall_threshold: float
@export var air_physics: PhysicsState

@export var variable_jump_factor: float = 1
var jump_released: bool

@export var snap_buffer: float
@export var press_buffer: float
var snap_timer: float
var press_timer: float


## runs this check every frame while inactive and 
## in the character's current pool of states
func _startup_check() -> bool:
	return character.input["jump"][0] and press_timer > 0


## runs this check every frame while active
## the string returned is the name of the state to change to
## return self.name for no change!
func _transition_check() -> String:
	if character.velocity.y > fall_threshold or character.physics is GroundPhysics:
		return ""
	return name


## runs once when this state begins being active
func _on_enter() -> void:
	character.on_ground = false
	enable_snap = false
	jump_released = false
	
	snap_timer = snap_buffer
	press_timer = 0
	
	character.set_state("physics", air_physics)
	character.override_time = 0
	character.container_override = null
	character.velocity.y = min(-jump_power, character.velocity.y)


## runs every frame while active
func _update(delta: float) -> void:
	if snap_timer > 0:
		snap_timer -= delta
	else:
		enable_snap = true
	
	if not jump_released and not character.input["jump"][0]:
		jump_released = true
		character.velocity.y *= variable_jump_factor


## always runs no matter what, before any of the other functions
func _general_update(delta: float) -> void:
	var jump_just_pressed: bool = character.input["jump"][1]
	if jump_just_pressed:
		press_timer = press_buffer
	else:
		press_timer -= delta

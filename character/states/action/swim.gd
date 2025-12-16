class_name SwimAction
extends ActionState


@export var swim_power: float
@export var perfect_swim_power: float
@export var swim_speed: float
@export var perfect_swim_speed: float

@export var swim_delay: float
@export var swim_time: float
@export var control_regain_window: float

@export var perfect_swim_interval: float
@export var perfect_swim_window: float
@export var press_buffer: float

var do_perfect_swim: bool
var perfect_swimming: bool
var delay_timer: float
var swim_timer: float
var buffer_timer: float
var swim_dir: Vector2


## runs this check every frame while inactive and 
## in the character's current pool of states
func _startup_check() -> bool:
	return buffer_timer > 0


## runs this check every frame while active
## the string returned is the name of the state to change to
## return self.name for no change!
func _transition_check() -> String:
	if swim_timer <= 0 or character.physics != parent_physics:
		return ""
	return name


## runs once when this state begins being active
func _on_enter() -> void:
	perfect_swimming = do_perfect_swim
	do_perfect_swim = false
	
	buffer_timer = 0
	parent_physics.can_move = false
	
	swim_dir = Vector2.ZERO
	delay_timer = swim_delay
	swim_timer = swim_time

## runs once when this state stops being active
func _on_exit() -> void:
	parent_physics.can_move = true


## runs every frame while active
func _update(delta: float) -> void:
	if delay_timer > 0:
		swim_timer = swim_time
		delay_timer -= delta
		if delay_timer <= 0:
			swim_dir = Vector2.ZERO
			if character.input["left"][0]: swim_dir.x -= 1
			if character.input["right"][0]: swim_dir.x += 1
			if character.input["up"][0]: swim_dir.y -= 1
			if character.input["down"][0]: swim_dir.y += 1
			character.velocity += (perfect_swim_power if perfect_swimming else swim_power) * swim_dir
		return
	
	var speed: float = perfect_swim_speed if perfect_swimming else swim_speed
	character.velocity += swim_dir * speed * delta * (swim_timer / swim_time)


## always runs no matter what, before any of the other functions
func _general_update(delta: float) -> void:
	swim_timer -= delta
	if not parent_physics.can_move and swim_timer < control_regain_window:
		parent_physics.can_move = true
	
	buffer_timer -= delta
	
	if character.input["jump"][1]:
		if buffer_timer <= 0 and abs(swim_timer + perfect_swim_interval) < perfect_swim_window:
			do_perfect_swim = true
		buffer_timer = press_buffer

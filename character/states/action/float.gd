class_name FloatAction
extends ActionState


@export var jump_power: float
@export var gravity_subtract: float
@export var float_time: float
@export var gravity_decel: float
@export var subsequent_damp: float = 1
var float_timer: float
var floats_counter: int

@export var variable_jump_factor: float = 1
var jump_released: bool

@export var sprite: AnimatedSprite2D
@export var light: RainbowGlow
@export var wind_sound: AudioStreamPlayer2D


## runs this check every frame while inactive and 
## in the character's current pool of states
func _startup_check() -> bool:
	return character.input["jump"][1]


## runs this check every frame while active
## the string returned is the name of the state to change to
## return self.name for no change!
func _transition_check() -> String:
	if (float_timer <= 0 and not character.input["jump"][0]) or character.physics is GroundPhysics:
		return ""
	return name


## runs once when this state begins being active
func _on_enter() -> void:
	sprite.glow()
	sprite.can_unglow = false
	light.strength_factor = 0.5
	wind_sound.start_sound(0.2, 0.35)
	
	float_timer = float_time
	
	character.on_ground = false
	jump_released = false
	
	var damp_amount: float = 1 + (floats_counter / subsequent_damp)
	if damp_amount == 1:
		character.velocity.y = min(character.velocity.y, -jump_power)
	elif character.velocity.y > 0:
		character.velocity.y -= jump_power * 2 / damp_amount
	gravity_factor = 1 - gravity_subtract / damp_amount
	
	floats_counter += 1


## runs once when this state stops being active
func _on_exit() -> void:
	sprite.can_unglow = true
	light.strength_factor = 0.0
	wind_sound.stop_sound(0.5)


## runs every frame while active
func _update(delta: float) -> void:
	float_timer -= delta
	gravity_factor = move_toward(gravity_factor, 1, gravity_decel * delta)
	
	if not jump_released and not character.input["jump"][0]:
		jump_released = true
		character.velocity.y *= variable_jump_factor


## always runs no matter what, before any of the other functions
func _general_update(_delta: float) -> void:
	if character.on_ground:
		floats_counter = 0

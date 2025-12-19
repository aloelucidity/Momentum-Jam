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
@export var coyote_time: float

@export var anim_target_speed: float
@export var footstep_sound: AudioStreamPlayer2D
@export var footstep_interval: float
@export var sprite: AnimatedSprite2D


var footstep_timer: float


func do_movement(delta: float, move_dir: int) -> void:
	var working_accel: float = 0.0
	
	if move_dir != 0:
		working_accel += accel * move_dir * delta
		if set_facing: character.facing_dir = move_dir
	
	var projected_speed: float = character.velocity.x + working_accel
	if abs(projected_speed) > max_speed:
		working_accel = clamp(
			(max_speed * move_dir) - character.velocity.x,
			-accel * delta, accel * delta
		)
	
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
		character.container_override = self
		character.override_time = coyote_time
		return air_name
	return name


## runs once when this state begins being active
func _on_enter() -> void:
	footstep_timer = 0.0


## runs every frame while active
func _update(delta: float) -> void:
	var move_dir: int = 0
	if character.input["left"][0]: move_dir -= 1 
	if character.input["right"][0]: move_dir += 1
	
	if move_dir == 0:
		do_friction(delta)
	else:
		do_movement(delta, move_dir)
	
	animation = "idle"
	if abs(character.velocity.x) > 50:
		sprite.speed_scale = abs(character.velocity.x) / anim_target_speed
		animation = "walk"
	
	footstep_timer -= delta
	if abs(character.velocity.x) > 5 and is_instance_valid(footstep_sound) and footstep_timer <= 0:
		footstep_sound.play()
		footstep_timer = footstep_interval / (abs(character.velocity.x) / anim_target_speed)
		footstep_timer = min(footstep_timer, 0.5)
	
	## run base function
	super(delta)

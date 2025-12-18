class_name BallPhysics
extends AirPhysics


@onready var initial_launch_vol: float = launch_sound.volume_db
@export var aim_sound: AudioStreamPlayer2D
@export var bounce_sound: AudioStreamPlayer2D
@export var launch_sound: AudioStreamPlayer2D
@export var voice: AudioStreamPlayer2D
@export var voice_threshold: float

@export var min_bounce_vel: float
@export var bounce_damp: float = 1
var ball_direction := Vector2.ZERO

@export var base_launch_speed: float
@export var launch_damp: float = 1
var launch_speed: float
var can_launch: bool

@export var max_shrink: float
@export var scale_speed: float = 1

@export var pop: Node2D
@export var pop_speed_target: float
@export var blur_strength: float
@export var light: RainbowGlow

@export var direction_buffer: float
@export var rot_speed: float = 1
@export var sprite: AnimatedSprite2D
@export var scaler: Node2D
var buffer_vector: Vector2

var landed: bool


## runs this check every frame while inactive and 
## in the character's current pool of states
func _startup_check() -> bool:
	return false


## runs this check every frame while active
## the string returned is the name of the state to change to
## return self.name for no change!
func _transition_check() -> String:
	if not character.input["ball"][0]:
		if can_launch:
			if launch_speed > voice_threshold:
				voice.play()
			
			if not water_check.get_overlapping_bodies().is_empty():
				launch_speed *= 1.5
			
			var strength_factor: float = (launch_speed - base_launch_speed/2) / pop_speed_target
			sprite.blur(blur_strength * strength_factor)
			pop.strength_factor = strength_factor
			pop.pop(character.animator.global_position)
			
			launch_sound.volume_db = initial_launch_vol + strength_factor * 4
			launch_sound.play()
			light.strength_factor = 0.0
			
			character.velocity = ball_direction * launch_speed
			launch_speed = base_launch_speed
			can_launch = false
		return ""
	
	if landed:
		return ""
	
	return name


## runs once when this state begins being active
func _on_enter() -> void:
	if can_launch:
		var strength_factor: float = (launch_speed - base_launch_speed/2) / pop_speed_target
		light.strength_factor = strength_factor
	
	aim_sound.play()
	
	landed = false
	scaler.scale = Vector2.ONE
	
	calc_inputs()
	sprite_rot = character.rotation
	sprite_rot += PI/2 * character.facing_dir
	
	await get_tree().process_frame
	sprite.flip_v = wrapf(sprite_rot, -PI, PI) > 0


## runs once when this state stops being active
func _on_exit() -> void:
	light.strength_factor = 0.0
	scaler.scale = Vector2.ONE
	character.animator.rotation -= PI/2 * 1.0 if sprite.flip_v else -1.0


func calc_inputs() -> Vector2:
	var input_direction := Vector2.ZERO
	if character.input["left"][0]: input_direction.x -= 1
	if character.input["right"][0]: input_direction.x += 1
	if character.input["up"][0]: input_direction.y -= 1
	if character.input["down"][0]: input_direction.y += 1
	
	var working_buffer: float = direction_buffer
	if input_direction != Vector2.ZERO:
		if input_direction.x != 0:
			## check if using joystick
			var left_strength: float = Input.get_action_strength("left")
			var right_strength: float = Input.get_action_strength("right")
			if left_strength != round(left_strength) or right_strength != round(right_strength):
				direction_buffer = 0.001
			
			buffer_vector.x = input_direction.x * working_buffer
		if input_direction.y != 0:
			## check if using joystick
			var up_strength: float = Input.get_action_strength("up")
			var down_strength: float = Input.get_action_strength("down")
			if up_strength != round(up_strength) or down_strength != round(down_strength):
				direction_buffer = 0.001
			
			buffer_vector.y = input_direction.y * working_buffer
		ball_direction = buffer_vector.sign()
	
	return input_direction


## runs every frame while active
func _update(delta: float) -> void:
	var input_direction: Vector2 = calc_inputs()
	if input_direction.x == 0:
		buffer_vector.x = move_toward(buffer_vector.x, 0, delta)
	if input_direction.y == 0:
		buffer_vector.y = move_toward(buffer_vector.y, 0, delta)
	
	## framerate independance
	var rot_alpha: float = 1.0 - exp(-rot_speed * delta)
	sprite_rot = lerp_angle(sprite_rot, ball_direction.angle() + PI/2, rot_alpha)
	sprite.flip_v = wrapf(sprite_rot, -PI, PI) > 0
	
	for index: int in character.get_slide_collision_count():
		var collision: KinematicCollision2D = character.get_slide_collision(index)
		var bounce_velocity: Vector2 = last_velocity.normalized() * (last_velocity.length() / bounce_damp)
		
		var normal: Vector2 = collision.get_normal()
		var ball_hit: bool = normal.round().x * ball_direction.x == 1 or normal.round().y * ball_direction.y == 1
		var one_way_check: bool = last_velocity.dot(normal) < -0.1
		if one_way_check and ball_hit:
			bounce_sound.play()
			
			character.velocity = bounce_velocity.bounce(normal)
			launch_speed = base_launch_speed + last_velocity.length() / launch_damp
			
			can_launch = true
			character.on_ground = false
			
			var total_shrink: float = max_shrink * (character.velocity.length() / max_fall)
			scaler.scale = Vector2.ONE - abs(normal) * total_shrink
			
			if abs(character.velocity.x) < min_bounce_vel and ball_direction.x != 0:
				character.velocity.x = min_bounce_vel * ball_direction.x
			if abs(character.velocity.y) < min_bounce_vel and ball_direction.y != 0:
				character.velocity.y = min_bounce_vel * ball_direction.y
			
			var strength_factor: float = (launch_speed - base_launch_speed/2) / pop_speed_target
			light.strength_factor = strength_factor
			
			break

	## framerate independance
	var scale_alpha: float = 1.0 - exp(-scale_speed * delta)
	scaler.scale = lerp(scaler.scale, Vector2.ONE, scale_alpha)

	## run base function
	super(delta)
	
	landed = character.on_ground

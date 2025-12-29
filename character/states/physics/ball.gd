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
@export var bounce_sensor: ShapeCast2D
@export var bounce_sensor_predict: float = 1
@export var sensor_buffer_time: float
var ball_direction := Vector2.ZERO
var buffered_direction := Vector2.ZERO
var sensor_buffer_normal := Vector2.ZERO
var sensor_buffer_timer: float

@export var base_launch_speed: float
@export var launch_damp: float = 1
var launch_speed: float
var can_launch: bool

@export var max_shrink: float
@export var scale_speed: float = 1

@export var predictor: Predictor
@export var pop: Node2D
@export var pop_speed_target: float
@export var blur_strength: float
@export var light: RainbowGlow

@export var direction_charge_time: float
var direction_charge_timer: float
var last_input_dir: Vector2

@export var rot_speed: float = 1
@export var sprite: AnimatedSprite2D
@export var scaler: Node2D

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
			if buffered_direction != Vector2.ZERO:
				ball_direction = buffered_direction
			else:
				ball_direction = get_input_intent()
			
			if sign(ball_direction.x) != 0:
				character.facing_dir = sign(ball_direction.x)
			
			if launch_speed > voice_threshold:
				voice.play()
			
			if not water_check.get_overlapping_areas().is_empty():
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
	
	direction_charge_time = 0.0
	aim_sound.play()
	
	landed = false
	scaler.scale = Vector2.ONE
	ball_direction = get_input_intent()
	
	sprite_rot = character.rotation
	sprite_rot += PI/2 * character.facing_dir
	
	await get_tree().process_frame
	sprite.flip_v = wrapf(sprite_rot, -PI, PI) > 0


## runs once when this state stops being active
func _on_exit() -> void:
	light.strength_factor = 0.0
	scaler.scale = Vector2.ONE
	character.animator.rotation -= PI/2 * 1.0 if sprite.flip_v else -1.0
	
	if predictor.visible:
		predictor.create_ghost()


func get_input_intent() -> Vector2:
	var base_y: int = 0
	if character.input["up"][0]: base_y -= 1
	if character.input["down"][0]: base_y += 1
	
	var base_x: int = 0
	if character.input["left"][0]: base_x -= 1
	if character.input["right"][0]: base_x += 1
	
	if base_x == 0 and base_y == 0:
		base_x = sign(character.velocity.x)
		base_y = -1
	
	var input_dir := Vector2.UP
	input_dir.x = base_x
	input_dir.y = base_y
	
	return input_dir


## runs every frame while active
func _update(delta: float) -> void:
	var input_dir: Vector2 = get_input_intent()
	ball_direction = input_dir
	
	if input_dir != last_input_dir:
		direction_charge_timer = 0
	
	direction_charge_timer += delta
	if buffered_direction != input_dir and direction_charge_timer > direction_charge_time:
		buffered_direction = input_dir
		direction_charge_timer = 0
	
	bounce_sensor.target_position = last_velocity * delta * bounce_sensor_predict
	bounce_sensor.force_shapecast_update()
	
	if bounce_sensor.is_colliding() or sensor_buffer_timer > 0:
		var bounce_normal: Vector2 = sensor_buffer_normal
		if bounce_sensor.is_colliding():
			bounce_normal = bounce_sensor.get_collision_normal(0)
			sensor_buffer_normal = bounce_normal
			sensor_buffer_timer = sensor_buffer_time
		else:
			sensor_buffer_timer -= delta
		
		var bounce_dir: Vector2 = bounce_normal.round().sign()
		
		var real_x: int = 0
		if character.input["left"][0]: real_x -= 1
		if character.input["right"][0]: real_x += 1
		 
		var is_horizontal_surface: bool = abs(bounce_normal.y) > 0.5
		var pushing_into_wall: bool = real_x != 0 and sign(real_x) != sign(bounce_dir.x)
		
		if (is_horizontal_surface or pushing_into_wall) or abs(character.velocity.x) < 100:
			ball_direction.x = input_dir.x
		else:
			ball_direction.x = bounce_dir.x
		
		if input_dir.y != 1 and bounce_dir.y == -1:
			var will_collide: bool = bounce_normal.round().y * input_dir.y == 1
			if will_collide:
				ball_direction.y = input_dir.y
			else:
				ball_direction.y = bounce_dir.y
	
	
	## framerate independance
	var rot_alpha: float = 1.0 - exp(-rot_speed * delta)
	sprite_rot = lerp_angle(sprite_rot, ball_direction.angle() + PI/2, rot_alpha)
	sprite.flip_v = wrapf(sprite_rot, -PI, PI) > 0
	
	landed = character.on_ground
	for index: int in character.get_slide_collision_count():
		var collision: KinematicCollision2D = character.get_slide_collision(index)
		var bounce_velocity: Vector2 = last_velocity.normalized() * (last_velocity.length() / bounce_damp)
		
		var normal: Vector2 = collision.get_normal()
		var ball_hit: bool = not (normal.round().x == -ball_direction.x and ball_direction.x != 0)\
			and not (normal.round().y == -ball_direction.y and ball_direction.y != 0)
		
		if ball_hit:
			bounce_sound.play()
			
			if abs(normal.y) > 0.5:
				normal.x /= 2
				normal = normal.normalized() ## ah yes
			
			character.velocity = bounce_velocity.bounce(normal)
			launch_speed = base_launch_speed + last_velocity.length() / launch_damp
			
			can_launch = true
			character.on_ground = false
			landed = false
			
			var total_shrink: float = max_shrink * (character.velocity.length() / max_fall)
			scaler.scale = Vector2.ONE - abs(normal) * total_shrink
			
			if abs(character.velocity.x) < min_bounce_vel and ball_direction.x != 0:
				character.velocity.x = min_bounce_vel * ball_direction.x
			if abs(character.velocity.y) < min_bounce_vel and ball_direction.y != 0:
				character.velocity.y = min_bounce_vel * ball_direction.y
			
			var strength_factor: float = (launch_speed - base_launch_speed/2) / pop_speed_target
			light.strength_factor = strength_factor
			
			break
		elif not water_check.get_overlapping_areas().is_empty():
			landed = true

	## framerate independance
	var scale_alpha: float = 1.0 - exp(-scale_speed * delta)
	scaler.scale = lerp(scaler.scale, Vector2.ONE, scale_alpha)

	## run base function
	super(delta)
	
	last_input_dir = input_dir

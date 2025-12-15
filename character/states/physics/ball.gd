class_name BallPhysics
extends AirPhysics


@export var min_bounce_vel: float
@export var bounce_damp: float = 1
var ball_direction := Vector2.ZERO

@export var base_launch_speed: float
@export var launch_damp: float = 1
var launch_speed: float
var can_launch: bool

@export var direction_buffer: float
@export var rot_speed: float = 1
@export var sprite: AnimatedSprite2D
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
			character.velocity = ball_direction * launch_speed
			launch_speed = base_launch_speed
			can_launch = false
		return ""
	
	if landed:
		return ""
	
	return name


## runs once when this state begins being active
func _on_enter() -> void:
	landed = false
	
	calc_inputs()
	sprite_rot = ball_direction.angle() + PI/2
	await get_tree().process_frame
	sprite.flip_v = wrapf(sprite_rot, -PI, PI) > 0


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
	
	## alpha is done this way to preserve framerate independence
	var alpha: float = 1.0 - exp(-rot_speed * delta)
	sprite_rot = lerp_angle(sprite_rot, ball_direction.angle() + PI/2, alpha)
	sprite.flip_v = wrapf(sprite_rot, -PI, PI) > 0
	
	for index: int in character.get_slide_collision_count():
		var collision: KinematicCollision2D = character.get_slide_collision(index)
		var bounce_velocity: Vector2 = last_velocity.normalized() * (last_velocity.length() / bounce_damp)
		
		var normal: Vector2 = collision.get_normal()
		if normal.round().x * ball_direction.x == 1 or normal.round().y * ball_direction.y == 1:
			character.velocity = bounce_velocity.bounce(normal)
			launch_speed = base_launch_speed + last_velocity.length() / launch_damp
			
			can_launch = true
			character.on_ground = false
			
			if abs(character.velocity.x) < min_bounce_vel and ball_direction.x != 0:
				character.velocity.x = min_bounce_vel * ball_direction.x
			if abs(character.velocity.y) < min_bounce_vel and ball_direction.y != 0:
				character.velocity.y = min_bounce_vel * ball_direction.y
			
			break

	## run base function
	super(delta)
	
	landed = character.on_ground

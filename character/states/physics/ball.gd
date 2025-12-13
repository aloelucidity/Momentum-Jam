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
var buffer_vector: Vector2

var landed: bool


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


## runs every frame while active
func _update(delta: float) -> void:
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
	
	if input_direction.x == 0:
		buffer_vector.x = move_toward(buffer_vector.x, 0, delta)
	if input_direction.y == 0:
		buffer_vector.y = move_toward(buffer_vector.y, 0, delta)
	
	var prefix: String = "ball" if ball_direction.x == 0 else "ball_side"
	var suffix: String = ""
	
	if ball_direction.y != 0:
		suffix = "_top" if ball_direction.y == 1 else "_bottom"
	
	if prefix + suffix != "ball":
		animation = prefix + suffix
	
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

class_name BallPhysics
extends AirPhysics


## runs this check every frame while active
## the string returned is the name of the state to change to
## return self.name for no change!
func _transition_check() -> String:
	if not character.input["ball"][0]:
		return ""
	return name


## runs every frame while active
func _update(delta: float) -> void:
	for index: int in character.get_slide_collision_count():
		var collision: KinematicCollision2D = character.get_slide_collision(index)
		var bounce_velocity: Vector2 = last_velocity.normalized() * last_velocity.length()
		character.velocity = bounce_velocity.bounce(collision.get_normal())
		break

	## run base function
	super(delta)

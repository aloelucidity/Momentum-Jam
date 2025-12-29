class_name Predictor
extends Line2D


@export var fps = 30
@export var predict_time: float = 1.0
@export var air_physics: AirPhysics
@export var ball_physics: BallPhysics
@export var shape: CollisionShape2D
@export var ghost_fade_time: float = 0.25

@onready var predict_steps: int = predict_time * fps
@onready var delta_predict: float = 1.0/fps
@onready var character: Character = owner

@export var lerp_speed: float = 12
var display_velocity: Vector2


func get_projected_velocity() -> Vector2:
	return ball_physics.get_input_intent() * ball_physics.launch_speed


func _process(delta: float) -> void:
	visible = false
	if not is_instance_valid(character): return
	visible = ball_physics.can_launch and character.physics == ball_physics
	if not is_visible_in_tree(): 
		display_velocity = get_projected_velocity()
		return
	
	## framerate independance
	var alpha: float = 1.0 - exp(-lerp_speed * delta)
	display_velocity = lerp(display_velocity, get_projected_velocity(), alpha)
	
	points = return_trajectory(display_velocity)


func return_trajectory(initial_velocity: Vector2) -> PackedVector2Array:
	var calc_points: PackedVector2Array
	
	var pos := global_position
	var velocity: Vector2 = initial_velocity
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	
	calc_points.append(Vector2.ZERO)
	for i in range(predict_steps):
		var predicted_point: Array[Vector2] = predict_point(pos, velocity, space_state)
		calc_points.append(predicted_point[0] - global_position)
		pos = predicted_point[0]
		velocity = predicted_point[1]
		if predicted_point[2] == Vector2.INF:
			break
	
	return calc_points


func predict_point(pos: Vector2, velocity: Vector2, space_state: PhysicsDirectSpaceState2D) -> Array[Vector2]:
	var next_pos: Vector2 = pos + velocity * delta_predict
	
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape.shape
	params.transform = Transform2D(0, pos)
	params.motion = velocity * delta_predict
	params.collision_mask = 1
	
	var results: PackedFloat32Array = space_state.cast_motion(params)
	var hit_point: float = results[0]
	
	if hit_point < 1.0:
		params.transform.origin += (velocity * delta_predict) * hit_point
		var rest_info: Dictionary = space_state.get_rest_info(params)
		if rest_info.size() > 0:
			var hit_body: CollisionObject2D = instance_from_id(rest_info.collider_id)
			var shape_index: int = rest_info.shape
			var owner_id: int = hit_body.shape_find_owner(shape_index)
			var hit_shape: Node2D = hit_body.shape_owner_get_owner(owner_id)
			
			if hit_shape.one_way_collision and params.motion.normalized().dot(-hit_shape.global_transform.y) > 0:
				pos = next_pos
			else:
				pos += (velocity * delta_predict) * hit_point
				return [pos, velocity, Vector2.INF]
		else:
			pos += (velocity * delta_predict) * hit_point
			return [pos, velocity, Vector2.INF]
	else:
		pos = next_pos
	
	velocity.y = move_toward(
		velocity.y, 
		air_physics.max_fall, 
		character.get_gravity_sum() * delta_predict
	)
	return [pos, velocity, Vector2.ZERO]


func create_ghost() -> void:
	var clone: Predictor = duplicate()
	clone.process_mode = Node.PROCESS_MODE_DISABLED
	clone.modulate.a = 0.5
	clone.global_position = global_position
	character.get_parent().add_child.call_deferred(clone)
	
	var tween: Tween = create_tween()
	tween.tween_property(clone, "modulate", Color.TRANSPARENT, ghost_fade_time)
	tween.tween_callback(clone.queue_free)

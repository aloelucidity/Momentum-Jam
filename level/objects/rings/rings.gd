extends Path2D


@onready var globals_id: String = get_path().get_concatenated_names()
@onready var path_follow_2d: PathFollow2D = $PathFollow2D
@onready var ring: Area2D = $Ring
@onready var timer: Timer = $Timer
@onready var particles: CPUParticles2D = $PathFollow2D/CPUParticles2D

@export var clover: Clover
@export var particle_time: float

var character: Character
var tween: Tween
var last_char_pos: Vector2
var point_index: int


func _ready() -> void:
	if globals_id in Globals.completed_rings: 
		queue_free()
		return
	
	if is_instance_valid(clover):
		clover.deactivate()


func collected() -> void:
	timer.start()
	point_index += 1
	if point_index >= curve.point_count:
		Globals.completed_rings.append(globals_id)
		clover.activate()
		queue_free()
	else:
		var new_progress: float = curve.get_closest_offset(
			curve.get_point_position(point_index)
		)
		var tween_time: float = (
			(new_progress - path_follow_2d.progress) /
			(curve.get_baked_length() / curve.point_count)
		) * particle_time
		
		if is_instance_valid(tween):
			tween.kill()
		
		tween = create_tween()
		tween.tween_property(
			path_follow_2d, "progress", new_progress, 
			tween_time
		)
		tween.tween_callback(particles.set_emitting.bind(false))
		particles.emitting = true
		
		ring.position = curve.get_point_position(point_index)
		ring.reset_physics_interpolation()


func timeout() -> void:
	point_index = 0
	path_follow_2d.progress = 0
	particles.emitting = false
	
	ring.position = curve.get_point_position(0)
	ring.reset_physics_interpolation()


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(character): return
	
	## went through ring
	if (sign(character.global_position.x - ring.global_position.x) != 
		sign(last_char_pos.x - ring.global_position.x)):
		collected()
	
	last_char_pos = character.global_position


func ring_entered(body: Node2D) -> void:
	if not body is Character: return
	character = body


func ring_exited(body: Node2D) -> void:
	if body == character:
		character = null

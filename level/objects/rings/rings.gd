extends Path2D


@onready var globals_id: String = get_owner().scene_file_path + get_owner().scene_file_path + get_path().get_concatenated_names()
@onready var path_follow_2d: PathFollow2D = $PathFollow2D
@onready var ring: Area2D = $Ring
@onready var ring_last: Node2D = $RingLast
@onready var animation_player: AnimationPlayer = $RingLast/AnimationPlayer
@onready var timer: Timer = $Timer
@onready var particles: CPUParticles2D = $PathFollow2D/CPUParticles2D

@export var clover: Clover
@export var particle_time: float
@export var hover_time: float

@onready var tick_sound: AudioStreamPlayer2D = $Ring/TickSound
@onready var sound: AudioStreamPlayer2D = $RingLast/Sound
@onready var sound_last: AudioStreamPlayer2D = $RingLast/SoundLast

@export var min_tick_delay: float
@export var max_tick_delay: float
@export var speedup_threshold: float

var character: Character
var tween: Tween
var glow_tween: Tween
var last_char_pos: Vector2
var point_index: int
var next_tick_counter: float

var modulate_mult := Color.WHITE
var completed: bool


func _ready() -> void:
	if globals_id in Globals.completed_rings: 
		queue_free()
		return
	
	if is_instance_valid(clover):
		clover.deactivate()


func collected() -> void:
	if completed: return
	
	ring_last.position = ring.position
	ring_last.reset_physics_interpolation()
	
	animation_player.stop()
	animation_player.play("fade")
	
	timer.start()
	point_index += 1
	if point_index >= curve.point_count:
		completed = true
		Globals.completed_rings.append(globals_id)
		
		
		clover.activate()
		sound_last.play()
		timer.stop()
		ring.hide()
		
		if is_instance_valid(tween):
			tween.kill()
		tween = create_tween()
		tween.tween_callback(queue_free).set_delay(5.0)
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
		
		sound.play()


func timeout() -> void:
	point_index = 0
	path_follow_2d.progress = 0
	particles.emitting = false
	
	ring.position = curve.get_point_position(0)
	ring.reset_physics_interpolation()


func _process(delta: float) -> void:
	ring.modulate = modulate_mult
	if timer.is_stopped(): return
	
	var remaining_scale: float = timer.time_left / speedup_threshold
	
	next_tick_counter -= delta
	if next_tick_counter <= 0:
		tick_sound.play()
		next_tick_counter = max_tick_delay
		if timer.time_left < speedup_threshold:
			next_tick_counter = remaining_scale * max_tick_delay
			next_tick_counter = max(next_tick_counter, min_tick_delay)
	
	if timer.time_left < speedup_threshold:
		ring.modulate.a = min(remaining_scale * 2, 1.0)
		ring.modulate.r = ring.modulate.a * max(1.0, ring.modulate.b)
		ring.modulate.g = ring.modulate.a * max(1.0, ring.modulate.b)


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(character): return
	
	## went through ring
	if last_char_pos != Vector2.INF and (sign(character.global_position.x - ring.global_position.x) != 
		sign(last_char_pos.x - ring.global_position.x)):
		collected()
	
	last_char_pos = character.global_position


func ring_entered(body: Node2D) -> void:
	if not body is Character: return
	character = body
	if is_instance_valid(glow_tween):
		glow_tween.kill()
	glow_tween = create_tween()
	glow_tween.tween_property(self, "modulate_mult", Color.WHITE * 1.5, hover_time)


func ring_exited(body: Node2D) -> void:
	if body == character:
		character = null
	
	last_char_pos = Vector2.INF
	if is_instance_valid(glow_tween):
		glow_tween.kill()
	glow_tween = create_tween()
	glow_tween.tween_property(self, "modulate_mult", Color.WHITE, hover_time)

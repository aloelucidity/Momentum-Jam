@tool
extends Area2D


@onready var visiblity_enabler: VisibleOnScreenEnabler2D = $VisibleOnScreenEnabler2D
@onready var collision: CollisionPolygon2D = $Collision
@onready var inner: Polygon2D = $Inner
@onready var overlay: Polygon2D = $Overlay
@onready var edge: Line2D = $Edge

@export_group("Splash")
@export var resolution: int
@export_range(0, 10) var smoothness: int = 2
@export var tension: float
@export var wave_damp: float
@export var wave_spread: float
@export var velocity_divide: float

@export_group("Idle")
@export var idle_amplitude: float
@export var idle_period_1: float
@export var idle_period_2: float
@export var idle_speed: float

var springs: Array
var surface_indices: Array[int]


class Spring:
	var target_height: float
	var height: float
	var velocity: float

	func update(delta: float, tension: float, damp: float) -> void:
		var x: float = height - target_height
		var loss: float = -damp * velocity
		var force: float = -tension * x + loss
		velocity += force * delta
		height += velocity * delta


func get_polygon_rect(polygon: PackedVector2Array) -> Rect2:
	if polygon.is_empty():
		return Rect2()
		
	var min_v: Vector2 = polygon[0]
	var max_v: Vector2 = polygon[0]

	for index: int in range(1, polygon.size()):
		min_v.x = min(min_v.x, polygon[index].x)
		min_v.y = min(min_v.y, polygon[index].y)
		max_v.x = max(max_v.x, polygon[index].x)
		max_v.y = max(max_v.y, polygon[index].y)
	
	return Rect2(min_v, max_v - min_v)


func _ready() -> void:
	subdivide_surface()
	initialize_springs()
	await get_tree().physics_frame
	visiblity_enabler.rect = get_polygon_rect(collision.polygon)


func subdivide_surface() -> void:
	var old_poly: PackedVector2Array = collision.polygon
	var new_poly: PackedVector2Array = []
	
	for i in range(old_poly.size()):
		var p1 = old_poly[i]
		var p2 = old_poly[(i + 1) % old_poly.size()]
		new_poly.append(p1)
		
		var normal: Vector2 = get_segment_normal(p1, p2)
		if normal.y < -0.7:
			var dist = p1.distance_to(p2)
			if dist > resolution:
				var segments = int(dist / resolution)
				for j in range(1, segments):
					new_poly.append(p1.lerp(p2, float(j) / segments))
	
	collision.polygon = new_poly
	decorate_water(new_poly)


func initialize_springs() -> void:
	springs.clear()
	surface_indices.clear()

	for i in range(collision.polygon.size()):
		var spring = Spring.new()
		spring.target_height = collision.polygon[i].y
		spring.height = spring.target_height
		spring.velocity = 0
		springs.append(spring)

		if is_vertex_on_surface(i, collision.polygon):
			surface_indices.append(i)


func is_vertex_on_surface(index: int, polygon: PackedVector2Array) -> bool:
	var p = polygon[index]
	var prev = polygon[index - 1 if index > 0 else polygon.size() - 1]
	var next = polygon[(index + 1) % polygon.size()]

	var n1 = get_segment_normal(prev, p)
	var n2 = get_segment_normal(p, next)

	return n1.y < -0.5 or n2.y < -0.5


func get_segment_normal(p1: Vector2, p2: Vector2) -> Vector2:
	var segment: Vector2 = p2 - p1
	return Vector2(-segment.y, segment.x).normalized()


func update_visuals() -> void:
	var raw_points: PackedVector2Array = collision.polygon
	
	for i: int in range(springs.size()):
		var sine_wave: float = sin(
			float(i) * idle_period_1 + 
			Time.get_unix_time_from_system() * idle_speed
		) * idle_amplitude
		var sine_wave_2: float = sin(
			float(i) * idle_period_2 + 
			Time.get_unix_time_from_system() * idle_speed
		) * idle_amplitude
		raw_points[i].y = springs[i].height + sine_wave * sine_wave_2
	
	var smooth_points = raw_points
	for _pass: int in range(smoothness):
		var temporary_points = smooth_points
		for i: int in range(surface_indices.size()):
			var current_idx = surface_indices[i]
			
			var prev_idx = surface_indices[i - 1] if i > 0 else current_idx
			var next_idx = surface_indices[i + 1] if i < surface_indices.size() - 1 else current_idx
			
			temporary_points[current_idx].y = (
				smooth_points[prev_idx].y + 
				smooth_points[current_idx].y + 
				smooth_points[next_idx].y
			) / 3.0
		smooth_points = temporary_points
	
	decorate_water(smooth_points)


func decorate_water(polygon: PackedVector2Array = collision.polygon) -> void:
	inner.polygon = polygon
	overlay.polygon = polygon
	edge.points = polygon


func splash(index: int, speed: float) -> void:
	if index > 0 and index < springs.size():
		springs[index].velocity = speed


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	for i: int in surface_indices:
		springs[i].update(delta, tension, wave_damp)
	
	var velocity_changes: Array[float]
	velocity_changes.resize(springs.size())
	velocity_changes.fill(0.0)
	
	for i: int in range(surface_indices.size()):
		var current_index = surface_indices[i]
		if i > 0:
			var prev_index: int = surface_indices[i-1]
			var diff: float = wave_spread * (
				springs[current_index].height - 
				springs[prev_index].height
			)
			velocity_changes[prev_index] += diff * delta
		if i < surface_indices.size() - 1:
			var next_index: int = surface_indices[i+1]
			var diff: float = wave_spread * (
				springs[current_index].height - 
				springs[next_index].height
			)
			velocity_changes[next_index] += diff * delta
	
	for i: int in surface_indices:
		springs[i].velocity += velocity_changes[i]
	
	update_visuals()


func handle_body(body: Node2D, splash_factor: float = 1.0) -> void:
	if not "velocity" in body: return
	
	var local_pos: Vector2 = to_local(body.global_position)
	var closest_index: int = -1
	var min_dist: float = INF
	
	for i in surface_indices:
		var dist = abs(collision.polygon[i].x - local_pos.x)
		if dist < min_dist:
			min_dist = dist
			closest_index = i
			
	if closest_index != -1:
		var vertical_dist = abs(local_pos.y - springs[closest_index].height)
		if vertical_dist < 250:
			splash(closest_index, body.velocity.y * splash_factor / velocity_divide)

@tool
extends CollisionPolygon2D


@onready var inner: Polygon2D = $Inner
@onready var details: MultiMeshInstance2D = $Details
@onready var overlay: Polygon2D = $Overlay

@onready var edges: Node2D = $Edges
@onready var top: Node2D = $Top

@export var detail_amount: int:
	set(new_value):
		detail_amount = new_value
		decorate_terrain()

@export var detail_seed: int:
	set(new_value):
		detail_seed = new_value
		decorate_terrain()

@export var detail_margin: int:
	set(new_value):
		detail_margin = new_value
		decorate_terrain()

@export var top_offset: int:
	set(new_value):
		top_offset = new_value
		decorate_terrain()

@export var edge_offset: int:
	set(new_value):
		edge_offset = new_value
		decorate_terrain()

@export var top_texture: Texture2D
@export var edge_texture: Texture2D


func _ready() -> void:
	details.multimesh = details.multimesh.duplicate()


func _set(property: StringName, _value):
	if not Engine.is_editor_hint(): return
	if property == "polygon":
		decorate_terrain()


func get_random_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	if polygon.size() < 3 or detail_amount <= 0:
		return points
	
	var margin_poly: PackedVector2Array = Geometry2D.offset_polygon(polygon, -detail_margin, Geometry2D.JOIN_MITER)[0]
	
	var rng := RandomNumberGenerator.new()
	rng.seed = detail_seed
	
	var indices := Geometry2D.triangulate_polygon(margin_poly)
	if indices.is_empty():
		return points

	var triangle_areas: PackedFloat32Array = []
	var total_area: float = 0.0
	
	for i in range(0, indices.size(), 3):
		var a = margin_poly[indices[i]]
		var b = margin_poly[indices[i+1]]
		var c = margin_poly[indices[i+2]]
		
		var area = 0.5 * abs(a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y))
		triangle_areas.append(area)
		total_area += area

	for n in range(detail_amount):
		var pick: float = rng.randf() * total_area
		var current_sum: float = 0.0
		var tri_index: float = 0
		
		for i in range(triangle_areas.size()):
			current_sum += triangle_areas[i]
			if pick <= current_sum:
				tri_index = i * 3
				break

		var A: Vector2 = margin_poly[indices[tri_index]]
		var B: Vector2 = margin_poly[indices[tri_index + 1]]
		var C: Vector2 = margin_poly[indices[tri_index + 2]]
		
		var r1: float = sqrt(rng.randf())
		var r2: float = rng.randf()
		var random_point: Vector2 = (1 - r1) * A + (r1 * (1 - r2)) * B + (r1 * r2) * C
		points.append(random_point)
	
	return points


func place_edge(points: PackedVector2Array, tex: Texture2D, container: Node2D) -> void:
	## shrink the edges so we can place some manually
	var offset = edge_offset if tex == edge_texture else top_offset
	var end_index: int = points.size() - 1
	
	var start_distance: float = points[0].distance_to(points[1])
	var start_weight: float = clamp(offset / start_distance, 0.0, 1.0)
	points[0] = points[0].lerp(points[1], start_weight)

	var end_distance: float = points[end_index].distance_to(points[end_index - 1])
	var end_weight: float = clamp(offset / end_distance, 0.0, 1.0)
	points[end_index] = points[end_index].lerp(points[end_index - 1], end_weight)

	var line_2d := Line2D.new()
	line_2d.points = points
	
	var texture: Texture2D = tex
	line_2d.texture = texture
	line_2d.width = texture.get_height()
	
	line_2d.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line_2d.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	line_2d.texture_mode = Line2D.LINE_TEXTURE_TILE
	line_2d.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	line_2d.set_meta("_edit_lock_", true)
	
	container.add_child(line_2d)
	line_2d.owner = owner


func decorate_terrain():
	if not is_instance_valid(top): return
	
	for child in details.get_children():
		child.queue_free()
	for child in edges.get_children():
		child.queue_free()
	for child in top.get_children():
		child.queue_free()
	
	inner.polygon = polygon
	overlay.polygon = polygon
	
	var last_point: Vector2 = polygon[polygon.size() - 1]
	var last_type: int = -1
	var point_cache: PackedVector2Array
	
	var index: int = 0
	for point in polygon:
		var edge: Vector2 = last_point - point
		var normal := Vector2(-edge.y, edge.x).normalized()
		if Geometry2D.is_polygon_clockwise(polygon): 
			normal = -normal
		
		var type: int = -1
		if normal.y < -0.7:
			type = 0
		
		if type != last_type or index == polygon.size() - 1:
			point_cache.append(last_point)
			if index == polygon.size() - 1:
				point_cache.append(point)
			
			place_edge(
				point_cache, 
				edge_texture if last_type < 0 else top_texture,
				edges if last_type < 0 else top
			)
			
			point_cache.clear()
		point_cache.append(last_point)
		
		index += 1
		last_type = type
		last_point = point
	
	index = 0
	
	var detail_quad := QuadMesh.new()
	detail_quad.size = details.texture.get_size()
	details.multimesh.mesh = detail_quad
	details.multimesh.instance_count = detail_amount
	
	for point: Vector2 in get_random_points():
		var point_trans := Transform2D(PI, point)
		details.multimesh.set_instance_transform_2d(index, point_trans)
		index += 1

extends CollisionPolygon2D


const TEXTURE: Texture2D = preload("res://level/terrain/platform/wood.png")
const Y_OFFSET: int = -3


func _ready() -> void:
	if polygon.is_empty():return
	
	build_mode = CollisionPolygon2D.BUILD_SOLIDS
	
	var min_pos: Vector2i = polygon[0]
	var max_pos: Vector2i = polygon[0]

	for point: Vector2i in polygon:
		min_pos.x = min(min_pos.x, point.x)
		min_pos.y = min(min_pos.y, point.y)
		max_pos.x = max(max_pos.x, point.x)
		max_pos.y = max(max_pos.y, point.y)

	var rect_width: int = max_pos.x - min_pos.x

	var nine_patch := NinePatchRect.new()
	nine_patch.texture = TEXTURE
	nine_patch.region_rect = Rect2(0, 0, 48, 17)
	nine_patch.patch_margin_left = 8
	nine_patch.patch_margin_right = 8
	nine_patch.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE
	
	nine_patch.position = min_pos + Vector2i(0, Y_OFFSET)
	nine_patch.size = Vector2(rect_width, 17)
	nine_patch.z_index = -1
	add_child(nine_patch)

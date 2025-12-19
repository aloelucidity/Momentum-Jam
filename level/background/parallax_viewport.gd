extends SubViewport


func _ready() -> void:
	get_window().size_changed.connect(resized)
	resized()


func resized():
	var base_res := Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)
	
	var canvas_size: Vector2 = get_tree().root.get_visible_rect().size
	size = Vector2i(canvas_size)
	
	var aspect: float = canvas_size.x / canvas_size.y
	if aspect >= (base_res.x / base_res.y):
		size_2d_override = Vector2(base_res.y * aspect, base_res.y)
	else:
		size_2d_override = Vector2(base_res.x, base_res.x / aspect)
		
	size_2d_override_stretch = true

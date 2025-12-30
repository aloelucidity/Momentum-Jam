extends CanvasLayer


@onready var shadow_mask: SubViewport = $ShadowMask


func _ready() -> void:
	var root_viewport: Viewport = get_tree().root.get_viewport()
	shadow_mask.world_2d = root_viewport.world_2d
	set_process_internal(true)


func _process(_delta: float) -> void:
	var root_window: Window = get_tree().root.get_window()
	var root_viewport: Viewport = get_tree().root.get_viewport()
	
	shadow_mask.canvas_transform = root_viewport.canvas_transform
	
	## well time to emulate the engine's built in c++ code for expand stretch mode :P
	var desired_res: Vector2 = root_window.content_scale_size
	var window_size := Vector2(root_viewport.size)
	var viewport_size: Vector2

	var viewport_aspect: float = desired_res.aspect()
	var window_size_aspect: float = window_size.aspect()

	## same aspect
	if is_equal_approx(viewport_aspect, window_size_aspect):
		viewport_size = desired_res
	## expand width
	elif viewport_aspect < window_size_aspect:
		viewport_size.x = desired_res.y * window_size_aspect
		viewport_size.y = desired_res.y
	## expand height
	else:
		viewport_size.x = desired_res.x
		viewport_size.y = desired_res.x / window_size_aspect
	
	shadow_mask.size = window_size / 4
	shadow_mask.size_2d_override = viewport_size.floor()
	shadow_mask.size_2d_override_stretch = true

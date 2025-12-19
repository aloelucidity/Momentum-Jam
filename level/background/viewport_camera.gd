extends Camera2D


@export var main_camera: Camera2D


func _ready() -> void:
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS


func _physics_process(_delta: float) -> void:
	global_position = main_camera.get_screen_center_position()
	zoom = main_camera.zoom

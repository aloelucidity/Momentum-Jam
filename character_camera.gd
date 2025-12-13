class_name CharacterCamera
extends Camera2D


@export var camera_follow: Node2D
@export var camera_speed: float = 3

@export var air_offset: float = 0
@export var ground_offset: float = 200
@export var offset_speed: float = 4

var camera_offset: Vector2
var camera_velocity: Vector2


func _ready() -> void:
	global_position = camera_follow.global_position
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS


func _physics_process(delta: float) -> void:
	var center_distance: Vector2 = global_position - camera_follow.global_position
	var target_offset: Vector2
	
	if camera_follow is Character:
		var character: Character = camera_follow
		if not character.on_ground:
			target_offset.y = -air_offset
		else:
			target_offset.y = -ground_offset
	
	## alpha is done this way to preserve framerate independence
	var alpha: float = 1.0 - exp(-offset_speed * delta)
	camera_offset = lerp(camera_offset, target_offset, alpha)
	
	camera_velocity = (-center_distance + camera_offset) * camera_speed
	position += camera_velocity * delta

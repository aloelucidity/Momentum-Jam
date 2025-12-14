class_name CharacterCamera
extends Camera2D


@export var camera_follow: Node2D
@export var camera_speed: float = 3

@export var max_zoom: float = 1
@export var min_zoom: float = 0.5
@export var zoom_out_threshold: float = 400
@export var zoom_out_damp: float = 1000
@export var zoom_out_speed: float = 2

@export var velocity_offset_damp: float = 2
@export var max_velocity_offset: Vector2

@export var air_offset: float = 0
@export var ground_offset: float = 100
@export var offset_speed: float = 2

var camera_offset: Vector2
var camera_velocity: Vector2


func _ready() -> void:
	global_position = camera_follow.global_position
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS


func _physics_process(delta: float) -> void:
	var center_distance: Vector2 = global_position - camera_follow.global_position
	var target_offset := Vector2.ZERO
	
	if camera_follow is Character:
		var character: Character = camera_follow
		if not character.on_ground:
			target_offset.y = -air_offset
		else:
			target_offset.y = -ground_offset
		
		target_offset += character.velocity / velocity_offset_damp
		
		var zoom_subtract: float = max(0, abs(character.velocity.x) - zoom_out_threshold) / zoom_out_damp
		var final_zoom: float = clamp(1 - zoom_subtract, min_zoom, max_zoom)
		
		var zoom_alpha: float = 1.0 - exp(-zoom_out_speed * delta)
		zoom = lerp(zoom, Vector2(final_zoom, final_zoom), zoom_alpha)
	
	target_offset = target_offset.clamp(-max_velocity_offset / zoom, max_velocity_offset / zoom)
	
	## alpha is done this way to preserve framerate independence
	var alpha: float = 1.0 - exp(-offset_speed * delta)
	camera_offset = lerp(camera_offset, target_offset, alpha)
	
	camera_velocity = (-center_distance + camera_offset) * camera_speed
	position += camera_velocity * delta

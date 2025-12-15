extends Node2D


@onready var camera: CharacterCamera = get_parent()

@export_file_path var left_scene: String
@export_file_path var right_scene: String


func _physics_process(_delta: float) -> void:
	if camera.character.global_position.x < camera.limit_left - Transitions.TRANSITION_MARGIN:
		get_tree().paused = true
		camera.process_mode = Node.PROCESS_MODE_ALWAYS
		Transitions.change_scene(left_scene, camera.character, -1)
		
	if camera.character.global_position.x > camera.limit_right + Transitions.TRANSITION_MARGIN:
		get_tree().paused = true
		camera.process_mode = Node.PROCESS_MODE_ALWAYS
		Transitions.change_scene(right_scene, camera.character, 1)

class_name PlayerSpawner
extends AnimatedSprite2D


@export_file_path var character_scene: String
@export var camera: CharacterCamera


func _init() -> void:
	hide()


func _ready() -> void:
	if Transitions.is_screen_change:
		queue_free()
		return
	
	camera.global_position = global_position
	
	var character: Character = load(character_scene).instantiate()
	character.global_position = global_position
	get_parent().call_deferred("add_child", character)
	
	camera.character = character

extends Node2D


@onready var camera: CharacterCamera = get_parent()

@export_file_path var left_scene: String
@export_file_path var right_scene: String


func _ready() -> void:
	var gradient_tex := GradientTexture2D.new()
	gradient_tex.gradient = Gradient.new()
	gradient_tex.gradient.colors = [Color(1, 1, 1, 0.3), Color(1, 1, 1, 0.1), Color.TRANSPARENT]
	gradient_tex.gradient.offsets = [0.0, 0.5, 1.0]
	
	var transition_left := TextureRect.new()
	transition_left.size = Vector2(64, 200000)
	transition_left.position = Vector2(camera.limit_left, -100000)
	transition_left.texture = gradient_tex
	transition_left.material = CanvasItemMaterial.new()
	transition_left.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	transition_left.z_index = -1
	
	var transition_right: TextureRect = transition_left.duplicate()
	transition_right.position.x = camera.limit_right - 64
	transition_right.flip_h = true
	
	camera.owner.add_child.call_deferred(transition_left)
	camera.owner.add_child.call_deferred(transition_right)


func _physics_process(_delta: float) -> void:
	if camera.character.global_position.x < camera.limit_left - Transitions.TRANSITION_MARGIN:
		get_tree().paused = true
		camera.process_mode = Node.PROCESS_MODE_ALWAYS
		Transitions.change_scene(left_scene, camera.character, -1)
		
	if camera.character.global_position.x > camera.limit_right + Transitions.TRANSITION_MARGIN:
		get_tree().paused = true
		camera.process_mode = Node.PROCESS_MODE_ALWAYS
		Transitions.change_scene(right_scene, camera.character, 1)

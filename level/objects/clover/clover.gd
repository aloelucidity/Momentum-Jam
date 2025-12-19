class_name Clover
extends Area2D


@onready var globals_id: String = get_path().get_concatenated_names()
@onready var spin: AnimationPlayer = $Spin
@onready var glow: Sprite2D = $Viewport/Glow
@onready var sprite: Sprite2D = $SubViewport/Sprite
@export var rainbow_material: ShaderMaterial

var activated: bool = true


func _ready() -> void:
	if globals_id in Globals.collected_clovers:
		queue_free()
		return
	
	sprite.material = sprite.material.duplicate()
	spin.play("spin")


func _process(_delta: float) -> void:
	if not is_instance_valid(sprite.material): return
	sprite.material.set_shader_parameter("global_pos", 
		get_global_transform_with_canvas().origin / get_viewport_rect().size)


func body_entered(body: Node2D) -> void:
	if not activated: return
	if not body is Character: return
	
	Globals.collected_clovers.append(globals_id)
	var character: Character = body
	var collect_physics: CollectPhysics = character.get_node("%Collect")
	collect_physics.target_x = global_position.x
	character.set_state("physics", collect_physics)
	queue_free()


func deactivate() -> void:
	activated = false
	sprite.material = null
	sprite.modulate.a = 0.75
	spin.play("RESET")
	glow.hide()


func activate() -> void:
	sprite.material = rainbow_material
	sprite.modulate.a = 1.0
	activated = true
	spin.play("spin")
	glow.show()

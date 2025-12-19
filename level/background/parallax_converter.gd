extends Parallax2D


const VIEWPORT_SCRIPT: Script = preload("res://level/background/parallax_viewport.gd")
const CAMERA_SCRIPT: Script = preload("res://level/background/viewport_camera.gd")
const BLUR_SHADER: Shader = preload("res://shaders/blur_mask.gdshader")
const HSV_SHADER: Shader = preload("res://shaders/hsv.gdshader")

@onready var parent: Node2D = get_parent()
@onready var main_camera: Camera2D = owner.character_camera

@export var layer_index: int = -64
@export var blur_amount: float = 1.0
@export var saturation: float = 1.0

var canvas_layer: CanvasLayer
var viewport_rect: TextureRect
var blur_rect: TextureRect
var viewport_node: SubViewport
var camera: Camera2D


func _ready() -> void:
	viewport_node = SubViewport.new()
	viewport_node.transparent_bg = true
	viewport_node.set_script(VIEWPORT_SCRIPT)
	parent.add_child.call_deferred(viewport_node)
	parent.remove_child.call_deferred(self)
	viewport_node.add_child.call_deferred(self)
	
	camera = Camera2D.new()
	camera.set_script(CAMERA_SCRIPT)
	camera.main_camera = main_camera
	viewport_node.add_child.call_deferred(camera)
	
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = layer_index
	owner.add_child.call_deferred(canvas_layer)
	
	viewport_rect = TextureRect.new()
	viewport_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport_rect.texture = viewport_node.get_texture()
	canvas_layer.add_child.call_deferred(viewport_rect)
	
	blur_rect = viewport_rect.duplicate()
	canvas_layer.add_child.call_deferred(blur_rect)
	
	viewport_rect.material = ShaderMaterial.new()
	viewport_rect.material.shader = HSV_SHADER
	viewport_rect.material.set_shader_parameter("s", saturation)
	
	blur_rect.material = ShaderMaterial.new()
	blur_rect.material.shader = BLUR_SHADER
	blur_rect.material.set_shader_parameter("blur_amount", blur_amount)

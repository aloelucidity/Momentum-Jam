extends Collectible


@onready var sprite: Sprite2D = $SubViewport/Sprite


func _ready() -> void:
	super()
	sprite.material = sprite.material.duplicate()


func _process(_delta: float) -> void:
	if not is_instance_valid(sprite.material): return
	sprite.material.set_shader_parameter("global_pos", 
		get_global_transform_with_canvas().origin / get_viewport_rect().size * 10)

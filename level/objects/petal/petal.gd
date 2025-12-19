extends Collectible


@onready var spin: AnimationPlayer = $Spin
@onready var sprite: Sprite2D = $SubViewport/Sprite


func _ready() -> void:
	sprite.material = sprite.material.duplicate()
	spin.play("spin")


func _process(_delta: float) -> void:
	if not is_instance_valid(sprite.material): return
	sprite.material.set_shader_parameter("global_pos", 
		get_global_transform_with_canvas().origin / get_viewport_rect().size * 10)

extends Sprite2D


@onready var glow: Sprite2D = $BackBufferCopy/Glow


func _process(_delta: float) -> void:
	if not is_visible_in_tree(): return
	flip_h = global_scale.y < 0
	glow.flip_h = flip_h

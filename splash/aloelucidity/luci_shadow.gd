extends Sprite2D


@export var luci: Sprite2D
@onready var front: Sprite2D = $Front


func _process(delta: float) -> void:
	region_rect = luci.region_rect
	front.region_rect = region_rect

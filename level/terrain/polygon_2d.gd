extends Polygon2D


@onready var collision_polygon = get_parent()


func _ready() -> void:
	polygon = collision_polygon.polygon

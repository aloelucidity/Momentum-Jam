extends Polygon2D


@export var collision_polygon: CollisionPolygon2D


func _ready() -> void:
	polygon = collision_polygon.polygon

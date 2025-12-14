extends Line2D


@export var collision_polygon: CollisionPolygon2D


func _ready() -> void:
	var polygon: PackedVector2Array = collision_polygon.polygon
	
	polygon.remove_at(polygon.size() - 1)
	polygon.remove_at(polygon.size() - 1)
	
	points = polygon

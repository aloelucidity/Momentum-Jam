@tool
extends CollisionPolygon2D


signal polygon_changed


func _set(property: StringName, _value):
	if not Engine.is_editor_hint(): return
	if property == "polygon":
		polygon_changed.emit()

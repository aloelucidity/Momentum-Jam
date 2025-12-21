extends CanvasLayer


func _process(_delta: float) -> void:
	visible = owner.is_visible_in_tree()

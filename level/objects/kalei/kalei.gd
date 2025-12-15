extends Area2D


func body_entered(body: Node2D) -> void:
	if body is Character:
		var character: Character = body
		var collect_physics: CollectPhysics = character.get_node("%Collect")
		collect_physics.target_x = global_position.x
		character.set_state("physics", collect_physics)
	
	queue_free()

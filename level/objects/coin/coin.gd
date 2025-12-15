extends Area2D


var character: Character

@export var magnet_speed: float
var collected: bool


func body_entered(body: Node2D) -> void:
	if body is Character and not collected:
		character = body


func body_exited(body: Node2D) -> void:
	if body == character:
		character = null


func _physics_process(delta: float) -> void:
	if not is_instance_valid(character): return
	
	## framerate independance
	var alpha: float = 1.0 - exp(-magnet_speed * delta)
	global_position = global_position.lerp(character.global_position, alpha)


func collect_body_entered(body: Node2D) -> void:
	if body is Character:
		queue_free()
		collected = true
		character = null

@tool
extends Area2D


@onready var collision: CollisionPolygon2D = $Collision
@onready var inner: Polygon2D = $Inner
@onready var overlay: Polygon2D = $Overlay
@onready var edge: Line2D = $Edge

@export var resolution: int = 20
@export var target_height: float = 0.0
@export var tension: float = 0.015
@export var wave_damp: float = 0.05
@export var wave_spread: float = 0.2

@export var springs: Array


class Spring:
	var target_height: float
	var height: float
	var velocity: float

	func update(tension: float, damp: float) -> void:
		var x: float = height - target_height
		var loss: float = -damp * velocity
		var force: float = -tension * x + loss
		velocity += force
		height += velocity


func decorate_water() -> void:
	inner.polygon = collision.polygon
	overlay.polygon = collision.polygon
	edge.points = collision.polygon


#func splash(index: int, speed: float) -> void:
	#if index > 0 and index < springs.size():
		#springs[index].velocity = speed


#func _physics_process(_delta: float) -> void:
	#if Engine.is_editor_hint(): return
	#for spring: Spring in springs:
		#spring.update(tension, wave_damp)


#func body_entered(body: Node2D) -> void:
	#var relative_x: float = body.global_position.x - global_position.x
	#var index := int(relative_x / resolution)
	#splash(index, body.velocity.y / 10)

class_name Rotator
extends Node2D


@onready var character: Character = get_owner()
@onready var animator: CharacterAnimator = %Animator


func on_enter() -> void:
	pass


func update_rotation(_delta: float) -> float:
	return animator.rotation


func update_skew(_delta: float) -> float:
	return animator.skew

class_name CharacterAnimator
extends Node2D


@onready var character: Character = get_owner()
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var cur_anim: String
var last_rotator: Rotator


func _update() -> void:
	var new_anim: String
	
	var sprite_offset: Vector2i
	var sprite_rot: float
	var sprite_skew: float
	var sprite_scale := Vector2.ONE
	var animator: Animator
	var rotator: Rotator
	
	if is_instance_valid(character.action):
		new_anim = character.action.animation
		sprite_offset = character.action.sprite_offset
		sprite_rot = character.action.sprite_rot
		sprite_skew = character.action.sprite_skew
		sprite_scale = character.action.sprite_scale
		animator = character.action.animator
		rotator = character.action.rotator
	
	if is_instance_valid(character.physics):
		if new_anim == "":
			new_anim = character.physics.animation
			sprite_offset = character.physics.sprite_offset
		
		sprite_rot += character.physics.sprite_rot
		sprite_skew += character.physics.sprite_skew
		sprite_scale *= character.physics.sprite_scale
		if not is_instance_valid(character.action):
			animator = character.physics.animator
			rotator = character.physics.rotator
	
	position = sprite_offset
	rotation = sprite_rot * character.facing_dir
	skew = sprite_skew
	scale = sprite_scale * Vector2(character.facing_dir, 1)
	
	if is_instance_valid(rotator):
		if rotator != last_rotator:
			rotator.on_enter()
		rotation_degrees = rotator.update_rotation()
	
	if new_anim == "":
		if animation_player.is_playing(): 
			animation_player.play("RESET")
	elif cur_anim != new_anim:
		cur_anim = new_anim
		animation_player.play("RESET")
		animation_player.advance(0)
		animation_player.play(new_anim)
		animation_player.advance(0)
	
	if is_instance_valid(animator):
		animator._update()
	else:
		animation_player.speed_scale = 1
	
	last_rotator = rotator

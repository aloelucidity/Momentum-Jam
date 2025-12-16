class_name CharacterAnimator
extends Node2D


@onready var character: Character = get_owner()
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var cur_anim: String
var last_rotator: Rotator
var last_dir: int


func _update(delta: float) -> void:
	var new_anim: String
	
	var sprite_offset: Vector2i
	var sprite_rot: float
	var sprite_skew: float
	var sprite_scale := Vector2.ONE
	var do_flip_scale: bool = true
	var animator: Animator
	var rotator: Rotator
	
	if is_instance_valid(character.action):
		new_anim = character.action.animation
		sprite_offset = character.action.sprite_offset
		sprite_rot = character.action.sprite_rot
		sprite_skew = character.action.sprite_skew
		sprite_scale = character.action.sprite_scale
		do_flip_scale = character.action.do_flip_scale
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
			do_flip_scale = character.physics.do_flip_scale
		if not is_instance_valid(animator):
			animator = character.physics.animator
		if not is_instance_valid(rotator):
			rotator = character.physics.rotator
	
	var flip_factor: float = character.facing_dir if do_flip_scale else 1
	position = sprite_offset
	scale = sprite_scale * Vector2(flip_factor, 1)
	
	if is_instance_valid(rotator):
		if rotator != last_rotator:
			rotator.on_enter()
		rotation = rotator.update_rotation(delta)
		skew = rotator.update_skew(delta)
	else:
		rotation = sprite_rot * flip_factor
		skew = sprite_skew
	
	if new_anim == "":
		if animation_player.is_playing(): 
			animation_player.play("RESET")
			
			reset_physics_interpolation()
			for child in get_children():
				child.reset_physics_interpolation()
	elif cur_anim != new_anim:
		cur_anim = new_anim
		animation_player.play("RESET")
		animation_player.advance(0)
		animation_player.play(new_anim)
		animation_player.advance(0)
		
		reset_physics_interpolation()
		for child in get_children():
			child.reset_physics_interpolation()
		
	
	if is_instance_valid(animator):
		animator._update()
	else:
		animation_player.speed_scale = 1
	
	last_rotator = rotator
	last_dir = character.facing_dir

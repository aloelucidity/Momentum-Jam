extends AnimatedSprite2D


enum SpriteEffect {
	None,
	Blur,
	Glow
}

@onready var character: Character = get_owner()
@onready var animator: CharacterAnimator = get_parent()
@onready var trail: AnimatedSprite2D = $Trail

@export var sprite_effect: SpriteEffect
@export var materials: Array[Material]

@export var unblur_speed: float
@export var trail_divider: float = 1

@export var unglow_speed: float
@export var glow_width: float

var blur_strength: float
var can_unglow: bool = true


func blur(strength: float):
	blur_strength = strength
	sprite_effect = SpriteEffect.Blur
	materials[SpriteEffect.Blur].set_shader_parameter("blur_radius", strength)


func glow():
	sprite_effect = SpriteEffect.Glow
	materials[SpriteEffect.Glow].set_shader_parameter("width", glow_width)


func _process(delta: float) -> void:
	material = materials[sprite_effect]
	
	trail.visible = false
	match sprite_effect:
		SpriteEffect.Blur:
			var cur_radius: float = material.get_shader_parameter("blur_radius")
			## framerate independance
			var alpha: float = 1.0 - exp(-unblur_speed * delta)
			cur_radius = lerp(cur_radius, 0.0, alpha)
			if is_zero_approx(cur_radius):
				sprite_effect = SpriteEffect.None
				material = null
			else:
				material.set_shader_parameter("blur_radius", cur_radius)
			
			modulate.a = 1.0 - cur_radius / blur_strength / 2
			trail.position = -Vector2(
				abs(character.velocity.x),  
				character.velocity.y
			) * delta * (cur_radius / blur_strength) * blur_strength / trail_divider
			trail.position = trail.position.rotated(-animator.rotation)
			offset = -trail.position * 2
			trail.visible = true
		
		SpriteEffect.Glow:
			if can_unglow:
				var cur_width: float = material.get_shader_parameter("width")
				## framerate independance
				var alpha: float = 1.0 - exp(-unglow_speed * delta)
				cur_width = lerp(cur_width, 0.0, alpha)
				if is_zero_approx(cur_width):
					sprite_effect = SpriteEffect.None
					material = null
				else:
					material.set_shader_parameter("width", cur_width)

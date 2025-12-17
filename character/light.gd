extends RainbowGlow


@export var strength_factor: float
@export var lerp_speed: float = 1


func _process(delta: float) -> void:
	scale = Vector2.ONE * max(strength_factor, 1.0)
	
	## framerate independancy
	var alpha: float = 1.0 - exp(-lerp_speed * delta)
	
	var cur_strength: float = (texture.gradient.offsets[1] - 0.2) / 0.8
	var new_strength: float = lerp(cur_strength, min(strength_factor, 1.0), alpha)
	texture.gradient.offsets[1] = 0.2 + 0.8 * new_strength
	
	super(delta)

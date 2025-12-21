extends TextureRect


@export var speed: float = 10


func _process(delta: float) -> void:
	var noise_texture: NoiseTexture2D = texture
	noise_texture.noise.offset += Vector3(delta, delta, 0) * speed

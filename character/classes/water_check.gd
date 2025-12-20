extends Area2D


@export var splash_sound: AudioStreamPlayer2D


func _physics_process(_delta: float) -> void:
	var is_underwater: bool = not get_overlapping_areas().is_empty()
	if is_underwater != Music.is_underwater:
		Music.set_underwater(is_underwater)
		splash_sound.play()

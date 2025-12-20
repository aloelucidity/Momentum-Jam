extends AudioStreamPlayer2D


@onready var start_volume: float = volume_linear
@onready var start_pitch: float = pitch_scale
var tween: Tween


func _ready() -> void:
	volume_linear = 0.0


func start_sound(fade: float, pitch: float) -> void:
	if is_instance_valid(tween):
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel()
	
	tween.tween_property(self, "volume_linear", start_volume, fade)
	tween.tween_property(self, "pitch_scale", pitch, fade)
	play()


func stop_sound(fade: float) -> void:
	if is_instance_valid(tween):
		tween.kill()
	
	tween = create_tween()
	tween.set_parallel()
	
	tween.tween_property(self, "volume_linear", 0.0, fade)
	tween.tween_property(self, "pitch_scale", start_pitch, fade)
	tween.tween_callback(stop).set_delay(fade)

extends AudioStreamPlayer2D


@onready var start_volume: float = volume_linear
var tween: Tween


func _ready() -> void:
	volume_linear = 0.0


func start_sound(fade: float) -> void:
	if is_instance_valid(tween):
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(self, "volume_linear", start_volume, fade)
	play()


func stop_sound(fade: float) -> void:
	if is_instance_valid(tween):
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(self, "volume_linear", 0.0, fade)
	tween.tween_callback(stop)

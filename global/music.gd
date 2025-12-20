extends Node


const BGM_RESTORE_TIME: float = 5
const UNDERWATER_CUTOFF: float = 1500
const UNDERWATER_WET: float = 0.05

@onready var main_bus_idx: int = AudioServer.get_bus_index("Main")

@onready var bgm: AudioStreamPlayer = $BGM
@onready var bgm_start_vol: float = bgm.volume_linear

@onready var victory: AudioStreamPlayer = $Victory
@onready var victory_start_vol: float = victory.volume_linear

var fade_tween: Tween
var victory_tween: Tween
var water_tween: Tween
var is_underwater: bool


func fade_bgm() -> void:
	if is_instance_valid(fade_tween):
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.tween_property(bgm, "volume_linear", 0.0, 0.75)
	fade_tween.tween_callback(bgm.set_stream_paused.bind(true)).set_delay(0.75)


func play_victory_theme() -> void:
	if is_instance_valid(victory_tween):
		victory_tween.kill()
	
	victory_tween = create_tween()
	victory_tween.set_parallel()

	victory_tween.tween_callback(restore_bgm).set_delay(BGM_RESTORE_TIME)

	victory_tween.tween_property(victory, "volume_linear", victory_start_vol, 0.25)
	victory_tween.tween_callback(victory.play).set_delay(0.25)


func restore_bgm() -> void:
	if is_instance_valid(victory_tween):
		victory_tween.kill()
	
	victory_tween = create_tween()
	victory_tween.set_parallel()
	
	bgm.stream_paused = false
	victory_tween.tween_property(bgm, "volume_linear", bgm_start_vol, 0.75)
	victory_tween.tween_property(victory, "volume_linear", 0.0, 0.75)


func set_underwater(new_underwater: bool) -> void:
	if is_instance_valid(water_tween):
		water_tween.kill()
	
	is_underwater = new_underwater
	var lp_filter: AudioEffectFilter = AudioServer.get_bus_effect(main_bus_idx, 0)
	var reverb_filter: AudioEffectReverb = AudioServer.get_bus_effect(main_bus_idx, 1)
	
	if is_underwater:
		water_tween = create_tween()
		water_tween.set_parallel()
		water_tween.tween_property(lp_filter, "cutoff_hz", UNDERWATER_CUTOFF, 0.4)
		water_tween.tween_property(reverb_filter, "wet", UNDERWATER_WET, 0.4)
		AudioServer.set_bus_effect_enabled(main_bus_idx, 0, true)
		AudioServer.set_bus_effect_enabled(main_bus_idx, 1, true)
	else:
		water_tween = create_tween()
		water_tween.tween_property(lp_filter, "cutoff_hz", 20000, 0.4)
		water_tween.tween_property(reverb_filter, "wet", 0, 0.4)
		water_tween.finished.connect(disable_effects, CONNECT_ONE_SHOT)


func disable_effects() -> void:
	AudioServer.set_bus_effect_enabled(main_bus_idx, 0, false)
	AudioServer.set_bus_effect_enabled(main_bus_idx, 1, false)

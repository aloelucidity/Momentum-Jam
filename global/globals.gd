extends Node


var collected_clovers: Array[String]
var collected_coins: Dictionary[String, PackedByteArray]

var completed_petals: Array[String]
var completed_rings: Array[String]

var money: int = 0:
	set(new_value):
		money = new_value
		coin_collected.emit(new_value)
var levels: Array[Level] = [
	preload("res://level/level_resources/tutorial.tres")
]
var level_index: int = 0
var time: float = 0

var is_splash: bool = true
var cached_mission: String

signal coin_collected(new_value: int)
signal clover_collected(mission_name: String)


func new_level(level_resource: Level) -> void:
	levels.append(level_resource)
	level_index += 1


func _process(delta: float) -> void:
	if get_tree().paused or is_splash: return
	time += delta


func collect_clover(mission_name: String, clover_id: String) -> void:
	if not clover_id in collected_clovers:
		levels[level_index].current_clovers += 1
		collected_clovers.append(clover_id)
	cached_mission = mission_name


func display_victory() -> void:
	clover_collected.emit(cached_mission)


func seconds_to_hms(total_seconds: float) -> String:
	@warning_ignore("integer_division")
	var hours: int = int(total_seconds) / 3600
	@warning_ignore("integer_division")
	var minutes: int = (int(total_seconds) % 3600) / 60
	var seconds: int = int(total_seconds) % 60
	@warning_ignore("narrowing_conversion")
	var milliseconds: int = fmod(total_seconds, 1.0) * 100
	
	if hours > 0:
		return "%02d:%02d:%02d.%02d" % [hours, minutes, seconds, milliseconds]
	return "%02d:%02d.%02d" % [minutes, seconds, milliseconds]

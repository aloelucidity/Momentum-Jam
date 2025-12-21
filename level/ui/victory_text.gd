extends Control


const HIDE_TIME: float = 4.0

@onready var awesome_holder: Control = %AwesomeHolder
@onready var awesome: TextureRect = %Awesome
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var mission_outline: Label = %MissionOutline
@onready var mission_label: Label = %MissionLabel

@onready var counter_label: Label = %CounterLabel
@onready var counter_outline: Label = %CounterOutline


func _ready() -> void:
	Globals.connect("clover_collected", display_victory)


func update_holders() -> void:
	awesome_holder.custom_minimum_size.y = awesome.size.y


func display_victory(mission_name: String) -> void:
	mission_label.text = mission_name
	mission_outline.text = mission_label.text
	
	var cur_level: Level = Globals.levels[Globals.level_index]
	counter_label.text = "(%s/%s)" % [cur_level.current_clovers, cur_level.total_clovers]
	counter_outline.text = counter_label.text
	
	animation_player.play("transition")
	
	await get_tree().create_timer(HIDE_TIME).timeout
	
	animation_player.play_backwards("transition")

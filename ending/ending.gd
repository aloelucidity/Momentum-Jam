extends Control


@onready var your_time: Label = %YourTime


func _ready() -> void:
	your_time.text = "Your time: " + Globals.seconds_to_hms(Globals.time)

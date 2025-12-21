extends MarginContainer


@onready var outline: Label = $Outline
@onready var label: Label = $Label


func _process(_delta: float) -> void:
	label.text = Globals.seconds_to_hms(Globals.time)
	outline.text = label.text

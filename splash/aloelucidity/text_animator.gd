@tool
extends Control


@export var labels: Array[RichTextLabel]
@export var effect: FlyRichTextEffect
@export var visible_characters: int = -1: 
	set(new_value):
		for label: RichTextLabel in labels:
			label.visible_characters = new_value
		effect.visible_characters = new_value - 1
		visible_characters = new_value


func _process(delta: float) -> void:
	effect.delta = delta

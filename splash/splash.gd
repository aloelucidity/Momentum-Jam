extends Control


@onready var wild_jam: Control = $WildJam
@onready var luci: Control = $Luci
@onready var kinetiball: Control = $KinetiBall

@onready var wild_player: AnimationPlayer = wild_jam.get_node("AnimationPlayer")
@onready var luci_player: AnimationPlayer = luci.get_node("AnimationPlayer")
@onready var kinetiplayer: AnimationPlayer = kinetiball.get_node("AnimationPlayer")

func _ready() -> void:
	await get_tree().process_frame
	
	#wild_jam.show()
	#wild_player.play("splash")
	#
	#await wild_player.animation_finished
	#wild_jam.hide()
	
	luci.show()
	luci_player.play("splash")
	await luci_player.animation_finished
	luci.hide()
	
	kinetiball.show()
	kinetiplayer.play("splash")
	await kinetiplayer.animation_finished
	
	Globals.is_splash = false
	Transitions.change_scene("res://level/level_scenes/tutorial.tscn", null, 0)

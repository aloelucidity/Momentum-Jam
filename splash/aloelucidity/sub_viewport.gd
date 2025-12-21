extends SubViewport


func _ready() -> void:
	#printerr("Please delete the temporary SubViewport you used for getting the logo before release.")
	#
	#queue_free()
	
	for i in range(300):
		await get_tree().process_frame
	
	var image: Image = get_texture().get_image()
	image.save_png("user://logo.png")

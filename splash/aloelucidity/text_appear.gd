@tool
class_name FlyRichTextEffect
extends RichTextEffect


var bbcode = "fly"
var data = {}
var delta:float = 0.0
var visible_characters:int = -1:
	set(new_value):
		visible_characters = new_value
		# Clean up the data if we are showing less characters than before
		if visible_characters < 0:
			data.clear()
		else:
			for data_range in data.keys():
				if data_range.x > visible_characters:
					data.erase(data_range)


func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	if visible_characters < 0:
		return true

	var starting_x = float(char_fx.env.get('start', -10))
	var speed = float(char_fx.env.get('speed', 30))

	var char_range = char_fx.range

	# get the char data, set the default data if not available
	var char_data = data.get(char_range, {
		"offset_x": starting_x,
		"end": char_fx.transform,
		"finished": false
	})

	var finished = char_data.get("finished", false)

	# if not finished then update the offset_x until it reaches 0
	# update the char_fx values with that
	if not finished:
		var offset_x = char_data.get('offset_x', starting_x)
		offset_x = move_toward(offset_x, 0, delta * speed)
		if offset_x >= 0:
			offset_x = 0
			char_data['finished'] = true
		
		var progress: float = ease(remap(offset_x, starting_x, 0, 0.0, 1.0), 0.75)
		char_fx.offset.x = floor(offset_x)
		char_fx.offset.y = floor(offset_x * 4)
		char_fx.transform = char_fx.transform.scaled_local(Vector2(progress, progress)).rotated_local(1 - progress)
		char_fx.color = Color(progress, progress, 1, progress)

		char_data['offset_x'] = offset_x

	# update the data dictionary
	data[char_range] = char_data

	return true

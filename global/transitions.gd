extends CanvasLayer


const TRANSITION_MARGIN: float = 32
const UNPAUSE_WAIT: float = 0.2

@onready var screenshot: TextureRect = $Fade/Screenshot
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var transitioning: bool


func change_scene(scene_path: String, character: Character, transition_dir: int) -> void:
	if transitioning: return
	transitioning = true
	
	character.get_parent().remove_child(character)
	
	await RenderingServer.frame_post_draw
	## getting the image so that the texture doesnt
	## continue to update after the screen is grabbed
	screenshot.texture = ImageTexture.create_from_image(
		get_viewport().get_texture().get_image())

	get_tree().call_deferred("change_scene_to_file", scene_path)
	animation_player.call_deferred("play", "left" if transition_dir < 0 else "right")
	
	await get_tree().scene_changed
	
	var level: LevelScene = get_tree().get_current_scene()
	level.call_deferred("add_child", character)
	character.position.x = (
		level.character_camera.limit_right + TRANSITION_MARGIN if transition_dir < 0 
		else level.character_camera.limit_left - TRANSITION_MARGIN)
	
	get_tree().paused = false
	
	var cam_offset := Vector2(0, -level.character_camera.air_offset)
	if character.on_ground:
		cam_offset.y = -level.character_camera.ground_offset
	
	level.character_camera.character = character
	level.character_camera.camera_offset = cam_offset
	level.character_camera.global_position = character.position + cam_offset
	
	get_tree().set_deferred("paused", true)
	
	await get_tree().create_timer(UNPAUSE_WAIT).timeout
	
	get_tree().paused = false
	
	await animation_player.animation_finished
	
	transitioning = false

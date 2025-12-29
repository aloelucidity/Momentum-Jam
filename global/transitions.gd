extends CanvasLayer


const TRANSITION_MARGIN: float = 32
const UNPAUSE_WAIT: float = 0.2

@onready var fade: TextureRect = $Fade
@onready var screenshot: TextureRect = $Fade/Screenshot
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var cover: ColorRect = $Fade/Cover
@export var HORIZONTAL_TEXTURE: GradientTexture2D = preload("res://global/horizontal_tex.tres")
@export var CIRCLE_TEXTURE: GradientTexture2D = preload("res://global/circle_tex.tres")

var transitioning: bool
var is_screen_change: bool


func change_scene(scene_path: String, character: Character, transition_dir: int) -> void:
	if transitioning: return
	transitioning = true
	is_screen_change = transition_dir == -1 or transition_dir == 1
	fade.texture = HORIZONTAL_TEXTURE if is_screen_change else CIRCLE_TEXTURE
	cover.hide()
	
	if is_screen_change:
		character.get_parent().remove_child(character)
	
	await RenderingServer.frame_post_draw
	## getting the image so that the texture doesnt
	## continue to update after the screen is grabbed
	screenshot.texture = ImageTexture.create_from_image(
		get_viewport().get_texture().get_image())
	
	animation_player.play("prepare")
	
	get_tree().call_deferred("change_scene_to_file", scene_path)
	await get_tree().scene_changed
	
	if is_screen_change:
		var level: LevelScene = get_tree().get_current_scene()
		level.call_deferred("add_child", character)
		character.position.x = (
			level.character_camera.limit_right + TRANSITION_MARGIN if transition_dir < 0 
			else level.character_camera.limit_left - TRANSITION_MARGIN)
	
	get_tree().paused = false
	
	var animation: String = "left" if transition_dir == -1 else "right"
	if not is_screen_change:
		animation = "center"
	
	animation_player.play.call_deferred(animation)
	cover.show.call_deferred()
	
	if is_screen_change:
		var level: LevelScene = get_tree().get_current_scene()
		var cam_offset := Vector2(0, -level.character_camera.air_offset / 2)
		if character.on_ground:
			cam_offset.y = -level.character_camera.ground_offset /  2
		
		level.character_camera.character = character
		level.character_camera.camera_offset = cam_offset
		level.character_camera.global_position = character.position + cam_offset
	
	get_tree().set_deferred("paused", true)
	
	await get_tree().create_timer(UNPAUSE_WAIT).timeout
	
	get_tree().paused = false
	
	await animation_player.animation_finished
	
	screenshot.texture = null
	transitioning = false

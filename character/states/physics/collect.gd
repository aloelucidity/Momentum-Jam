class_name CollectPhysics
extends PhysicsState


@export var ground_name: String
@export var animate_time: float
@export var x_correct_speed: float = 1
var stop_timer: float
var target_x: float

@export_group("Gravity")
@export var max_fall: float


## runs this check every frame while active
## the string returned is the name of the state to change to
## return self.name for no change!
func _transition_check() -> String:
	if stop_timer <= 0:
		var cur_level: Level = Globals.levels[Globals.level_index]
		if cur_level.current_clovers >= cur_level.total_clovers:
			cur_level.completion_time = Globals.time
			
			var target_scene: String
			if is_instance_valid(cur_level.next_stage):
				target_scene = cur_level.next_stage.start_scene
			else:
				target_scene = "res://ending/ending.tscn"
			
			Globals.new_level(cur_level.next_stage)
			Transitions.change_scene(target_scene, character, 0)
		else:
			return ground_name
	return name


## runs once when this state begins being active
func _on_enter() -> void:
	Music.fade_bgm()
	character.set_state("action", null)
	character.velocity.x = 0
	character.velocity.y = min(character.velocity.y, 0)
	stop_timer = animate_time


func _update(delta: float) -> void:
	## Gravity (required because the player can be in this state and not grounded)
	if not character.on_ground:
		var total_gravity: float = character.get_gravity_sum()
		character.velocity.y = move_toward(
			character.velocity.y, 
			max_fall, 
			total_gravity * delta
		)
		character.velocity.x = (target_x - character.position.x) * x_correct_speed * delta
		animation = "fall"
	else:
		## if just landed
		if stop_timer == animate_time:
			var cur_level: Level = Globals.levels[Globals.level_index]
			if not is_instance_valid(cur_level.next_stage):
				Music.stop_restore = true
			
			character.emit_signal("start_collect_cutscene")
			Music.play_victory_theme()
			Globals.display_victory()
		
		character.velocity.x = move_toward(character.velocity.x, 0, x_correct_speed * delta)
		stop_timer -= delta
		animation = "collect"
	
	super(delta)

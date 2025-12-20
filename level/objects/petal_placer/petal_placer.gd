extends CollectiblePlacer


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var spawner: Area2D = $Spawner
@onready var timer: Timer = $Timer

@onready var glow: TextureRect = $Spawner/Glow
@onready var clock: Sprite2D = $Spawner/Clock

@onready var tick_sound: AudioStreamPlayer2D = $TickSound
@onready var sound: AudioStreamPlayer2D = $Sound
@onready var sound_last: AudioStreamPlayer2D = $SoundLast

@export var sin_speed: float
@export var sin_amplitude: float

@export var min_tick_delay: float
@export var max_tick_delay: float
@export var speedup_threshold: float

@export var clover: Clover

var character: Character
var collected_petals: Array[bool]
var next_tick_counter: float


func _ready() -> void:
	if globals_id in Globals.completed_petals: 
		queue_free()
		return
	
	if is_instance_valid(clover):
		clover.deactivate()
	collected_petals.resize(collectible_count)


func spawner_entered(body: Node2D) -> void:
	if not body is Character: return
	character = body
	place()
	collectibles.modulate.a = 1
	spawner.set_deferred("monitoring", false)
	timer.start()
	animation_player.play("start")


func collected(index: int, collect_pos: Vector2) -> void:
	collected_petals[index] = true
	if collected_petals.count(false) <= 0:
		timer.stop()
		clover.activate()
		Globals.completed_petals.append(globals_id)
		sound_last.global_position = collect_pos
		sound_last.play()
		character = null
	else:
		sound.global_position = collect_pos
		sound.play()


func _process(delta: float) -> void:
	if timer.is_stopped(): 
		clock.offset.y = sin(Time.get_unix_time_from_system() * sin_speed) * sin_amplitude
		glow.position.y = clock.offset.y - (glow.size.y/2)
		return
	
	next_tick_counter -= delta
	if next_tick_counter <= 0:
		tick_sound.play()
		next_tick_counter = max_tick_delay
		if timer.time_left < speedup_threshold:
			var remaining_scale: float = timer.time_left / speedup_threshold
			next_tick_counter = remaining_scale * max_tick_delay
			next_tick_counter = max(next_tick_counter, min_tick_delay)
			
			collectibles.modulate.a = min(remaining_scale * 2, 1.0) 
	
	tick_sound.global_position = character.global_position.clamp(
		collectibles_rect.position + global_position, 
		collectibles_rect.end + global_position
	)


func timeout() -> void:
	collected_petals.fill(false)
	for child in collectibles.get_children():
		child.queue_free()

	spawner.set_deferred("monitoring", true)
	animation_player.play("respawn")
	
	character = null

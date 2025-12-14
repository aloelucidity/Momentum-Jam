class_name Character
extends CharacterBody2D


### Basics
@onready var initial_snap: float = floor_snap_length
var input: Dictionary
var gravity: float
var facing_dir: int = 1 : 
	set(new_value):
		if facing_dir != new_value:
			emit_signal("direction_changed", new_value)
		facing_dir = new_value
var on_ground: bool

### Nodes
@onready var physics_states: Node = %PhysicsStates
@onready var animator: CharacterAnimator = %Animator

### States
var physics: PhysicsState
var action: ActionState


@export var default_collision: CollisionShape2D
var collision_override: CollisionShape2D

# the below is used for coyote time; when the ground state transitions 
# to the air state, it'll set an override for a few frames so you
# can still do ground actions even if you're slightly late
var container_override: PhysicsState
var override_time: float


### Signals
signal direction_changed(new_direction: int)


func set_state(type: String, state: CharacterState) -> void:
	var old_state: CharacterState = self[type]
	if is_instance_valid(old_state):
		old_state._on_exit()
	
	self[type] = state
	
	if is_instance_valid(state):
		state._on_enter()


func check_startups(cur_state: CharacterState, container: Node) -> CharacterState:
	var cur_priority: int = int(-INF)
	if is_instance_valid(cur_state): cur_priority = cur_state.priority
	for check_state: Node in container.get_children():
		var char_state: CharacterState
		if check_state is CharacterState:
			char_state = check_state
		elif check_state is StateLink:
			var link: StateLink = check_state
			char_state = link.link_to
		
		if (
			char_state.priority > cur_priority
		) or (
			char_state.priority >= cur_priority and 
			cur_state.allow_priority_override
		):
			if char_state._startup_check():
				return char_state
	return null


func handle_general_updates(delta: float) -> void:
	if is_instance_valid(physics_states):
		for phys: PhysicsState in physics_states.get_children():
			phys._general_update(delta)
			
			for act: Node in phys.get_children():
				var action_state: ActionState
				if act is ActionState:
					action_state = act
				elif act is StateLink:
					var link: StateLink = act
					action_state = link.link_to
				action_state._general_update(delta)


func update_states(delta: float, type: String, container: Node) -> void:
	## handle updates, transitions
	var cur_state: CharacterState = self[type]
	if is_instance_valid(cur_state):
		var transition_to: String = cur_state._transition_check()
		if transition_to == cur_state.name:
			cur_state._update(delta)
		elif is_instance_valid(container) and container.has_node(transition_to):
			var found_node: Node = container.get_node(transition_to)
			var new_state: CharacterState
			if found_node is CharacterState:
				new_state = found_node
			elif found_node is StateLink:
				var link: StateLink = found_node
				new_state = link.link_to
			
			set_state(type, new_state)
		else:
			set_state(type, null)
	
	## handle startups
	if is_instance_valid(container):
		var startup_state: CharacterState = check_startups(self[type], container)
		if is_instance_valid(startup_state):
			set_state(type, startup_state)


### Logic
func _enter_tree() -> void:
	gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta: float) -> void:
	input = get_input()
	
	handle_general_updates(delta)
	update_states(delta, "physics", physics_states)
	
	var container: PhysicsState = physics
	if override_time > 0:
		override_time -= delta
		container = container_override
		if override_time <= 0: container_override = null
	
	update_states(delta, "action", container)
	
	var last_override = collision_override
	collision_override = null
	
	var enable_snap: bool = true
	if is_instance_valid(physics):
		enable_snap = enable_snap and physics.enable_snap
		collision_override = physics.shape_override
	if is_instance_valid(action):
		enable_snap = enable_snap and action.enable_snap
		collision_override = physics.shape_override
	if is_instance_valid(last_override) and last_override != collision_override:
		last_override.disabled = true
	
	default_collision.disabled = false
	if is_instance_valid(collision_override):
		default_collision.disabled = true
		collision_override.disabled = false
	
	floor_snap_length = initial_snap if enable_snap else 0.0
	
	move_and_slide()
	on_ground = is_on_floor()
	animator._update()


### Physics
func get_gravity_sum() -> float:
	var total_factor: float = gravity
	if is_instance_valid(physics):
		total_factor *= physics.gravity_factor
	if is_instance_valid(action):
		total_factor *= action.gravity_factor
	return total_factor


### Input
var inputs_list: Array = [
	"up",
	"down",
	"left",
	"right",
	"jump",
	"ball"
]
func get_input() -> Dictionary[String, Array]:
	var new_input: Dictionary[String, Array] = {}
	
	for action_name: String in inputs_list:
		var pressed: bool = Input.is_action_pressed(action_name)
		var just_pressed: bool = Input.is_action_just_pressed(action_name)
		new_input[action_name] = [pressed, just_pressed]
	
	return new_input

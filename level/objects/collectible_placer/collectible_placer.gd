extends Path2D


@onready var path_follow_2d: PathFollow2D = $PathFollow2D

@export var collectible_scene: PackedScene
@export var collectible_count: int


func _ready() -> void:
	for i: float in range(collectible_count):
		path_follow_2d.progress_ratio = (i + 1) / collectible_count
		
		var collectible: Node2D = collectible_scene.instantiate()
		collectible.global_position = path_follow_2d.global_position
		add_child(collectible)

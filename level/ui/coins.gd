extends Control


@onready var coin_label: Label = %CoinLabel
@onready var coin_label_outline: Label = %CoinLabelOutline
@onready var coin_anim_player: AnimationPlayer = %CoinAnimPlayer

var debounce: bool = true


func _ready() -> void:
	Globals.connect("coin_collected", coin_collected)
	coin_collected(Globals.money)


func coin_collected(new_coins: int) -> void:
	coin_label.text = str(new_coins) + " :-"
	coin_label_outline.text = coin_label.text
	if debounce:
		debounce = false
		coin_anim_player.stop()
		coin_anim_player.play("collect")

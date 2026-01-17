extends Control
## How to Play instructions screen

@onready var btn_back: Button = $BtnBack


func _ready() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	
	# Setup button animation
	btn_back.mouse_entered.connect(_on_button_hover.bind(btn_back))
	btn_back.mouse_exited.connect(_on_button_unhover.bind(btn_back))


func _on_button_hover(btn: Button) -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.3)


func _on_button_unhover(btn: Button) -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.3)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

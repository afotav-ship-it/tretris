extends Control
## Main menu screen with bubbly buttons and navigation

@onready var btn_play: Button = $VBox/BtnPlay
@onready var btn_game_modes: Button = $VBox/BtnGameModes
@onready var btn_how_to_play: Button = $VBox/BtnHowToPlay
@onready var title: Label = $VBox/Title

var title_scale := 1.0
var title_pulse_time := 0.0


func _ready() -> void:
	btn_play.pressed.connect(_on_play_pressed)
	btn_game_modes.pressed.connect(_on_game_modes_pressed)
	btn_how_to_play.pressed.connect(_on_how_to_play_pressed)
	
	# Add bubbly animation to buttons
	_setup_button_animations()


func _setup_button_animations() -> void:
	var buttons := [btn_play, btn_game_modes, btn_how_to_play]
	
	for btn in buttons:
		# Create dynamic button style with animation
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
		btn.mouse_exited.connect(_on_button_unhover.bind(btn))


func _on_button_hover(btn: Button) -> void:
	# Create a bounce animation when hovering
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.3)


func _on_button_unhover(btn: Button) -> void:
	# Return to normal size
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.3)


func _process(delta: float) -> void:
	# Animate title with subtle pulse
	title_pulse_time += delta * 2.0
	title_scale = 1.0 + sin(title_pulse_time) * 0.05
	title.scale = Vector2(title_scale, title_scale)


func _on_play_pressed() -> void:
	# Navigate to game scene
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_game_modes_pressed() -> void:
	# Navigate to game modes screen
	get_tree().change_scene_to_file("res://scenes/game_modes.tscn")


func _on_how_to_play_pressed() -> void:
	# Navigate to how to play screen
	get_tree().change_scene_to_file("res://scenes/how_to_play.tscn")

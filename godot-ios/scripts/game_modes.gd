extends Control
## Game modes selection screen

@onready var btn_normal: Button = $VBox/NormalMode/BtnNormal
@onready var btn_advanced: Button = $VBox/AdvancedMode/BtnAdvanced
@onready var btn_boulder: Button = $VBox/BoulderMode/BtnBoulder
@onready var btn_north: Button = $VBox/DirectionsSection/DirectionGrid/BtnNorth
@onready var btn_south: Button = $VBox/DirectionsSection/DirectionGrid/BtnSouth
@onready var btn_west: Button = $VBox/DirectionsSection/DirectionGrid/BtnWest
@onready var btn_east: Button = $VBox/DirectionsSection/DirectionGrid/BtnEast
@onready var btn_back: Button = $VBox/BtnBack

# Store selected mode and directions
var selected_mode: int = Constants.PlayLevel.NORMAL
var active_directions: Dictionary = {
	Constants.Direction.UP: true,
	Constants.Direction.DOWN: true,
	Constants.Direction.LEFT: true,
	Constants.Direction.RIGHT: true
}


func _ready() -> void:
	# Connect mode buttons
	btn_normal.pressed.connect(_on_mode_selected.bind(Constants.PlayLevel.NORMAL))
	btn_advanced.pressed.connect(_on_mode_selected.bind(Constants.PlayLevel.ADVANCED))
	btn_boulder.pressed.connect(_on_mode_selected.bind(Constants.PlayLevel.BOULDER))
	
	# Connect direction buttons
	btn_north.pressed.connect(_on_direction_toggled.bind(Constants.Direction.UP))
	btn_south.pressed.connect(_on_direction_toggled.bind(Constants.Direction.DOWN))
	btn_west.pressed.connect(_on_direction_toggled.bind(Constants.Direction.LEFT))
	btn_east.pressed.connect(_on_direction_toggled.bind(Constants.Direction.RIGHT))
	
	btn_back.pressed.connect(_on_back_pressed)
	
	# Setup button animations
	_setup_button_animations()
	_update_ui()


func _setup_button_animations() -> void:
	var buttons := [btn_normal, btn_advanced, btn_boulder, btn_north, btn_south, btn_west, btn_east, btn_back]
	
	for btn in buttons:
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
		btn.mouse_exited.connect(_on_button_unhover.bind(btn))


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


func _on_mode_selected(mode: int) -> void:
	selected_mode = mode
	_update_ui()
	
	# Save to game settings and start game
	GameSettings.play_level = mode
	GameSettings.enabled_directions = _get_enabled_directions_array()
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_direction_toggled(direction: int) -> void:
	# Count active directions
	var active_count := 0
	for d in active_directions:
		if active_directions[d]:
			active_count += 1
	
	# Don't allow disabling if only one is left
	if active_directions[direction] and active_count <= 1:
		return
	
	active_directions[direction] = not active_directions[direction]
	_update_ui()


func _update_ui() -> void:
	# Update mode button colors
	var mode_colors := {
		Constants.PlayLevel.NORMAL: Color(0.4, 1, 0.4),
		Constants.PlayLevel.ADVANCED: Color(1, 1, 0.4),
		Constants.PlayLevel.BOULDER: Color(1, 0.4, 0.4)
	}
	
	btn_normal.modulate = mode_colors[Constants.PlayLevel.NORMAL] if selected_mode == Constants.PlayLevel.NORMAL else Color(0.6, 0.6, 0.6)
	btn_advanced.modulate = mode_colors[Constants.PlayLevel.ADVANCED] if selected_mode == Constants.PlayLevel.ADVANCED else Color(0.6, 0.6, 0.6)
	btn_boulder.modulate = mode_colors[Constants.PlayLevel.BOULDER] if selected_mode == Constants.PlayLevel.BOULDER else Color(0.6, 0.6, 0.6)
	
	# Update direction button colors
	var active_color := Color(0.2, 0.8, 0.3)
	var inactive_color := Color(0.4, 0.4, 0.4)
	
	btn_north.modulate = active_color if active_directions[Constants.Direction.UP] else inactive_color
	btn_south.modulate = active_color if active_directions[Constants.Direction.DOWN] else inactive_color
	btn_west.modulate = active_color if active_directions[Constants.Direction.LEFT] else inactive_color
	btn_east.modulate = active_color if active_directions[Constants.Direction.RIGHT] else inactive_color


func _get_enabled_directions_array() -> Array[int]:
	var enabled_dirs: Array[int] = []
	for dir in active_directions:
		if active_directions[dir]:
			enabled_dirs.append(dir)
	return enabled_dirs


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

extends Control
## UI controller for game interface with control panel and menu

signal direction_toggled(direction: int, enabled: bool)
signal mode_changed(mode: int)
signal music_toggled(enabled: bool)
signal fx_toggled(enabled: bool)
signal exit_pressed
signal menu_side_changed(is_right: bool)

@onready var game: Node2D = $"../Game"
@onready var menu_panel: Panel = $MenuPanel
@onready var control_panel: Panel = $ControlPanel
@onready var score_label: Label = $MenuPanel/VBox/ScoreLabel
@onready var lines_label: Label = $MenuPanel/VBox/LinesLabel
@onready var level_label: Label = $MenuPanel/VBox/LevelLabel
@onready var next_block_panel: Panel = $MenuPanel/VBox/NextBlockPanel

# Direction buttons
@onready var btn_north: Button = $MenuPanel/VBox/DirectionGrid/BtnNorth
@onready var btn_south: Button = $MenuPanel/VBox/DirectionGrid/BtnSouth
@onready var btn_west: Button = $MenuPanel/VBox/DirectionGrid/BtnWest
@onready var btn_east: Button = $MenuPanel/VBox/DirectionGrid/BtnEast

# Mode buttons
@onready var btn_normal: Button = $MenuPanel/VBox/ModeBox/BtnNormal
@onready var btn_advanced: Button = $MenuPanel/VBox/ModeBox/BtnAdvanced
@onready var btn_boulder: Button = $MenuPanel/VBox/ModeBox/BtnBoulder

# Control buttons
@onready var btn_music: Button = $MenuPanel/VBox/ControlBox/BtnMusic
@onready var btn_fx: Button = $MenuPanel/VBox/ControlBox/BtnFX
@onready var btn_drop: Button = $MenuPanel/VBox/BtnDrop
@onready var btn_switch: Button = $MenuPanel/VBox/BtnSwitch
@onready var btn_exit: Button = $MenuPanel/VBox/BtnExit

# Control panel buttons (d-pad, drop, rotate)
@onready var btn_move_up: Button = $ControlPanel/VBox/BtnMoveUp
@onready var btn_move_down: Button = $ControlPanel/VBox/BtnMoveDown
@onready var btn_move_left: Button = $ControlPanel/VBox/MoveRow/BtnMoveLeft
@onready var btn_move_right: Button = $ControlPanel/VBox/MoveRow/BtnMoveRight
@ontml:parameter name="btn_drop_ctrl: Button = $ControlPanel/VBox/BtnDropCtrl
@onready var btn_rotate_left: Button = $ControlPanel/VBox/RotateRow/BtnRotateLeft
@onready var btn_rotate_right: Button = $ControlPanel/VBox/RotateRow/BtnRotateRight

# Game over overlay
@onready var game_over_overlay: ColorRect = $"../GameOverOverlay"
@onready var btn_play_again: Button = $"../GameOverOverlay/VBox/BtnPlayAgain"
@onready var btn_exit_game: Button = $"../GameOverOverlay/VBox/BtnExitGame"

var menu_on_right: bool = true
# Active directions: maps Direction enum to enabled state
# N=UP(0), S=DOWN(1), W=LEFT(2), E=RIGHT(3)
var active_directions: Dictionary = {
	Constants.Direction.UP: true,
	Constants.Direction.DOWN: true,
	Constants.Direction.LEFT: true,
	Constants.Direction.RIGHT: true
}

const MENU_WIDTH: float = 280.0
const CONTROL_PANEL_WIDTH: float = 280.0  # Wider control panel
const GAME_AREA_SIZE: float = 720.0  # Square game area

# Icon textures for buttons
var icon_up: ImageTexture
var icon_down: ImageTexture
var icon_left: ImageTexture
var icon_right: ImageTexture
var icon_drop: ImageTexture
var icon_rotate_left: ImageTexture
var icon_rotate_right: ImageTexture


func _ready() -> void:
	_create_icon_textures()
	_setup_buttons()
	_apply_button_icons()
	_update_menu_position()
	
	if game:
		game.score_changed.connect(_on_score_changed)
		_on_score_changed(0, 0, 1)
	
	_update_direction_buttons()
	_update_mode_buttons()
	_update_control_buttons()
	
	# Check if running on web - hide exit button
	if OS.has_feature("web"):
		btn_exit.text = "RESTART"


func _create_icon_textures() -> void:
	# Create arrow and control icons programmatically
	icon_up = _create_arrow_icon(Vector2(0, -1))
	icon_down = _create_arrow_icon(Vector2(0, 1))
	icon_left = _create_arrow_icon(Vector2(-1, 0))
	icon_right = _create_arrow_icon(Vector2(1, 0))
	icon_drop = _create_drop_icon()
	icon_rotate_left = _create_rotate_icon(false)
	icon_rotate_right = _create_rotate_icon(true)


func _create_arrow_icon(direction: Vector2) -> ImageTexture:
	var size := 32
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Transparent background
	
	var center := Vector2(size / 2, size / 2)
	var arrow_color := Color(1, 1, 1, 1)  # White
	
	# Draw arrow pointing in direction
	var tip: Vector2
	var base1: Vector2
	var base2: Vector2
	var shaft_start: Vector2
	var shaft_end: Vector2
	
	if direction.y < 0:  # Up
		tip = center + Vector2(0, -12)
		base1 = center + Vector2(-10, 2)
		base2 = center + Vector2(10, 2)
		shaft_start = center + Vector2(0, 2)
		shaft_end = center + Vector2(0, 12)
	elif direction.y > 0:  # Down
		tip = center + Vector2(0, 12)
		base1 = center + Vector2(-10, -2)
		base2 = center + Vector2(10, -2)
		shaft_start = center + Vector2(0, -2)
		shaft_end = center + Vector2(0, -12)
	elif direction.x < 0:  # Left
		tip = center + Vector2(-12, 0)
		base1 = center + Vector2(2, -10)
		base2 = center + Vector2(2, 10)
		shaft_start = center + Vector2(2, 0)
		shaft_end = center + Vector2(12, 0)
	else:  # Right
		tip = center + Vector2(12, 0)
		base1 = center + Vector2(-2, -10)
		base2 = center + Vector2(-2, 10)
		shaft_start = center + Vector2(-2, 0)
		shaft_end = center + Vector2(-12, 0)
	
	# Draw filled triangle for arrow head
	_draw_triangle_on_image(img, tip, base1, base2, arrow_color)
	# Draw shaft
	_draw_thick_line_on_image(img, shaft_start, shaft_end, arrow_color, 4)
	
	var tex := ImageTexture.create_from_image(img)
	return tex


func _create_drop_icon() -> ImageTexture:
	var size := 32
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var center := Vector2(size / 2, size / 2)
	var color := Color(1, 0.9, 0.2, 1)  # Yellow
	
	# Draw double down arrow for drop
	var tip1 := center + Vector2(0, 4)
	_draw_triangle_on_image(img, tip1, tip1 + Vector2(-8, -8), tip1 + Vector2(8, -8), color)
	var tip2 := center + Vector2(0, 12)
	_draw_triangle_on_image(img, tip2, tip2 + Vector2(-8, -8), tip2 + Vector2(8, -8), color)
	
	var tex := ImageTexture.create_from_image(img)
	return tex


func _create_rotate_icon(clockwise: bool) -> ImageTexture:
	var size := 32
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var center := Vector2(size / 2, size / 2)
	var color := Color(0.5, 0.9, 1, 1)  # Light blue
	
	# Draw circular arrow
	var radius := 10.0
	var start_angle: float
	var end_angle: float
	
	if clockwise:
		start_angle = -PI * 0.7
		end_angle = PI * 0.5
	else:
		start_angle = PI * 0.5
		end_angle = PI * 1.7
	
	# Draw arc
	var steps := 16
	for i in range(steps):
		var t1: float = start_angle + (end_angle - start_angle) * float(i) / float(steps)
		var t2: float = start_angle + (end_angle - start_angle) * float(i + 1) / float(steps)
		var p1 := center + Vector2(cos(t1), sin(t1)) * radius
		var p2 := center + Vector2(cos(t2), sin(t2)) * radius
		_draw_thick_line_on_image(img, p1, p2, color, 3)
	
	# Draw arrow head at end
	var end_pos := center + Vector2(cos(end_angle), sin(end_angle)) * radius
	var arrow_dir: Vector2
	if clockwise:
		arrow_dir = Vector2(cos(end_angle + PI/2), sin(end_angle + PI/2))
	else:
		arrow_dir = Vector2(cos(end_angle - PI/2), sin(end_angle - PI/2))
	
	var tip := end_pos + arrow_dir * 6
	var base1 := end_pos + arrow_dir.rotated(PI * 0.7) * 5
	var base2 := end_pos + arrow_dir.rotated(-PI * 0.7) * 5
	_draw_triangle_on_image(img, tip, base1, base2, color)
	
	var tex := ImageTexture.create_from_image(img)
	return tex


func _draw_triangle_on_image(img: Image, p1: Vector2, p2: Vector2, p3: Vector2, color: Color) -> void:
	# Simple triangle fill using scanline
	var min_y := int(min(p1.y, min(p2.y, p3.y)))
	var max_y := int(max(p1.y, max(p2.y, p3.y)))
	
	for y in range(max(0, min_y), min(img.get_height(), max_y + 1)):
		var intersections: Array[float] = []
		var edges := [[p1, p2], [p2, p3], [p3, p1]]
		for edge in edges:
			var e1: Vector2 = edge[0]
			var e2: Vector2 = edge[1]
			if (e1.y <= y and e2.y > y) or (e2.y <= y and e1.y > y):
				var t: float = (float(y) - e1.y) / (e2.y - e1.y)
				intersections.append(e1.x + t * (e2.x - e1.x))
		
		if intersections.size() >= 2:
			intersections.sort()
			for x in range(max(0, int(intersections[0])), min(img.get_width(), int(intersections[1]) + 1)):
				img.set_pixel(x, y, color)


func _draw_thick_line_on_image(img: Image, from: Vector2, to: Vector2, color: Color, thickness: int) -> void:
	var dir := (to - from).normalized()
	var length := from.distance_to(to)
	
	for i in range(int(length) + 1):
		var p := from + dir * float(i)
		for dx in range(-thickness/2, thickness/2 + 1):
			for dy in range(-thickness/2, thickness/2 + 1):
				var px := int(p.x) + dx
				var py := int(p.y) + dy
				if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
					img.set_pixel(px, py, color)


func _apply_button_icons() -> void:
	# Apply icons to control panel buttons with centered alignment
	var buttons := [btn_move_up, btn_move_down, btn_move_left, btn_move_right, 
					btn_drop_ctrl, btn_rotate_left, btn_rotate_right]
	var icons := [icon_up, icon_down, icon_left, icon_right, 
				  icon_drop, icon_rotate_left, icon_rotate_right]
	
	for i in range(buttons.size()):
		var btn: Button = buttons[i]
		btn.icon = icons[i]
		btn.text = ""
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.expand_icon = true


func _setup_buttons() -> void:
	# Direction buttons
	btn_north.pressed.connect(_on_north_pressed)
	btn_south.pressed.connect(_on_south_pressed)
	btn_west.pressed.connect(_on_west_pressed)
	btn_east.pressed.connect(_on_east_pressed)
	
	# Mode buttons
	btn_normal.pressed.connect(_on_normal_pressed)
	btn_advanced.pressed.connect(_on_advanced_pressed)
	btn_boulder.pressed.connect(_on_boulder_pressed)
	
	# Control buttons
	btn_music.pressed.connect(_on_music_pressed)
	btn_fx.pressed.connect(_on_fx_pressed)
	btn_drop.pressed.connect(_on_drop_pressed)
	btn_switch.pressed.connect(_on_switch_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)
	
	# Play again button
	btn_play_again.pressed.connect(_on_play_again_pressed)
	btn_exit_game.pressed.connect(_on_exit_pressed)
	
	# Control panel buttons (d-pad)
	btn_move_up.pressed.connect(_on_move_up_pressed)
	btn_move_down.pressed.connect(_on_move_down_pressed)
	btn_move_left.pressed.connect(_on_move_left_pressed)
	btn_move_right.pressed.connect(_on_move_right_pressed)
	btn_drop_ctrl.pressed.connect(_on_drop_pressed)
	btn_rotate_left.pressed.connect(_on_rotate_left_pressed)
	btn_rotate_right.pressed.connect(_on_rotate_right_pressed)


func _update_menu_position() -> void:
	# Fixed layout: control panel on left, menu on right
	control_panel.position = Vector2(0, 0)
	menu_panel.position = Vector2(1280 - MENU_WIDTH, 0)
	
	# Game is centered between control panel and menu
	if game:
		var game_x := CONTROL_PANEL_WIDTH + (1280 - CONTROL_PANEL_WIDTH - MENU_WIDTH - GAME_AREA_SIZE) / 2
		game.position = Vector2(game_x, 0)


func _on_score_changed(new_score: int, lines: int, level: int) -> void:
	score_label.text = "Score: %d" % new_score
	lines_label.text = "Lines: %d" % lines
	level_label.text = "Level: %d" % level


func _on_north_pressed() -> void:
	_toggle_direction(Constants.Direction.UP)


func _on_south_pressed() -> void:
	_toggle_direction(Constants.Direction.DOWN)


func _on_west_pressed() -> void:
	_toggle_direction(Constants.Direction.LEFT)


func _on_east_pressed() -> void:
	_toggle_direction(Constants.Direction.RIGHT)


func _toggle_direction(dir: int) -> void:
	# Count active directions
	var active_count := 0
	for d in active_directions:
		if active_directions[d]:
			active_count += 1
	
	# Don't allow disabling if only one is left
	if active_directions[dir] and active_count <= 1:
		return
	
	active_directions[dir] = not active_directions[dir]
	_update_direction_buttons()
	_apply_directions_to_game()
	emit_signal("direction_toggled", dir, active_directions[dir])


func _apply_directions_to_game() -> void:
	if not game:
		return
	
	# Pass the enabled directions array to the game
	var enabled_dirs: Array[int] = []
	for dir in active_directions:
		if active_directions[dir]:
			enabled_dirs.append(dir)
	
	game.enabled_directions = enabled_dirs
	game.reset_game()


func _update_direction_buttons() -> void:
	var active_color := Color(0.2, 0.8, 0.3)
	var inactive_color := Color(0.4, 0.4, 0.4)
	
	btn_north.modulate = active_color if active_directions[Constants.Direction.UP] else inactive_color
	btn_south.modulate = active_color if active_directions[Constants.Direction.DOWN] else inactive_color
	btn_west.modulate = active_color if active_directions[Constants.Direction.LEFT] else inactive_color
	btn_east.modulate = active_color if active_directions[Constants.Direction.RIGHT] else inactive_color
	
	btn_north.text = "N ^" if active_directions[Constants.Direction.UP] else "N"
	btn_south.text = "S v" if active_directions[Constants.Direction.DOWN] else "S"
	btn_west.text = "< W" if active_directions[Constants.Direction.LEFT] else "W"
	btn_east.text = "E >" if active_directions[Constants.Direction.RIGHT] else "E"


func _on_normal_pressed() -> void:
	_set_mode(Constants.PlayLevel.NORMAL)


func _on_advanced_pressed() -> void:
	_set_mode(Constants.PlayLevel.ADVANCED)


func _on_boulder_pressed() -> void:
	_set_mode(Constants.PlayLevel.BOULDER)


func _set_mode(mode: int) -> void:
	if game:
		game.play_level = mode
		game.reset_game()
	_update_mode_buttons()
	emit_signal("mode_changed", mode)


func _update_mode_buttons() -> void:
	var current_mode := Constants.PlayLevel.NORMAL
	if game:
		current_mode = game.play_level
	
	btn_normal.modulate = Constants.PLAY_LEVEL_COLORS[Constants.PlayLevel.NORMAL] if current_mode == Constants.PlayLevel.NORMAL else Color(0.5, 0.5, 0.5)
	btn_advanced.modulate = Constants.PLAY_LEVEL_COLORS[Constants.PlayLevel.ADVANCED] if current_mode == Constants.PlayLevel.ADVANCED else Color(0.5, 0.5, 0.5)
	btn_boulder.modulate = Constants.PLAY_LEVEL_COLORS[Constants.PlayLevel.BOULDER] if current_mode == Constants.PlayLevel.BOULDER else Color(0.5, 0.5, 0.5)


func _on_music_pressed() -> void:
	if game:
		game.toggle_music()
	_update_control_buttons()
	emit_signal("music_toggled", game.music_enabled if game else false)


func _on_fx_pressed() -> void:
	if game:
		game.toggle_effects()
	_update_control_buttons()
	emit_signal("fx_toggled", game.effects_enabled if game else false)


func _update_control_buttons() -> void:
	if game:
		btn_music.text = "Music ON" if game.music_enabled else "Music OFF"
		btn_music.modulate = Color(0.3, 0.7, 1.0) if game.music_enabled else Color(0.5, 0.5, 0.5)
		btn_fx.text = "FX ON" if game.effects_enabled else "FX OFF"
		btn_fx.modulate = Color(1.0, 0.7, 0.3) if game.effects_enabled else Color(0.5, 0.5, 0.5)


func _on_switch_pressed() -> void:
	menu_on_right = not menu_on_right
	_update_menu_position()
	emit_signal("menu_side_changed", menu_on_right)


func _on_drop_pressed() -> void:
	if game and not game.is_game_over:
		game.hard_drop()


# Control panel d-pad handlers - rotate when pressing opposite to block direction
func _on_move_up_pressed() -> void:
	if game and not game.is_game_over and game.current_block:
		if game.current_block.direction == Constants.Direction.DOWN:
			game.rotate_block(true)  # Rotate when pressing opposite direction
		else:
			game.move_block(0, -1)


func _on_move_down_pressed() -> void:
	if game and not game.is_game_over and game.current_block:
		if game.current_block.direction == Constants.Direction.UP:
			game.rotate_block(true)  # Rotate when pressing opposite direction
		else:
			game.move_block(0, 1)


func _on_move_left_pressed() -> void:
	if game and not game.is_game_over and game.current_block:
		if game.current_block.direction == Constants.Direction.RIGHT:
			game.rotate_block(true)  # Rotate when pressing opposite direction
		else:
			game.move_block(-1, 0)


func _on_move_right_pressed() -> void:
	if game and not game.is_game_over and game.current_block:
		if game.current_block.direction == Constants.Direction.LEFT:
			game.rotate_block(true)  # Rotate when pressing opposite direction
		else:
			game.move_block(1, 0)


func _on_rotate_left_pressed() -> void:
	if game and not game.is_game_over:
		game.rotate_block(false)


func _on_rotate_right_pressed() -> void:
	if game and not game.is_game_over:
		game.rotate_block(true)


func _on_exit_pressed() -> void:
	# Navigate back to main menu
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	emit_signal("exit_pressed")


func _on_game_over() -> void:
	# Show game over overlay
	game_over_overlay.visible = true


func _on_play_again_pressed() -> void:
	# Hide overlay and restart game
	game_over_overlay.visible = false
	if game:
		game.reset_game()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# Draw next block preview in the panel - centered and matching game style
	if not game or game.next_block == null:
		return
	
	var preview_scale := 0.6  # Slightly larger scale for visibility
	var cell_size: float = Constants.CELL_SIZE * preview_scale
	
	# Calculate block dimensions
	var block_pixel_width: float = game.next_block.width() * cell_size
	var block_pixel_height: float = game.next_block.height() * cell_size
	
	# Center the block in the panel
	var panel_pos := menu_panel.position + next_block_panel.position
	var panel_size := next_block_panel.size
	var preview_pos := panel_pos + Vector2(
		(panel_size.x - block_pixel_width) / 2,
		(panel_size.y - block_pixel_height) / 2
	)
	
	for row_idx in range(game.next_block.height()):
		for col_idx in range(game.next_block.width()):
			if game.next_block.shape[row_idx][col_idx] != 0:
				var x: float = preview_pos.x + col_idx * cell_size
				var y: float = preview_pos.y + row_idx * cell_size
				_draw_preview_cell_3d(x, y, cell_size, game.next_block.color)
	
	# Draw direction arrow for next block
	var arrow_pos := menu_panel.position + next_block_panel.position + Vector2(next_block_panel.size.x + 20, 30)
	var dir: int = game.next_block.direction
	var arrow_text: String = "?"
	match dir:
		Constants.Direction.DOWN:
			arrow_text = "v"
		Constants.Direction.UP:
			arrow_text = "^"
		Constants.Direction.LEFT:
			arrow_text = "<"
		Constants.Direction.RIGHT:
			arrow_text = ">"
	
	# Draw arrow background circle
	draw_circle(arrow_pos + Vector2(15, 15), 25, Color(0.15, 0.15, 0.2))
	# Draw arrow using a simple line indicator
	var arrow_color := Color(1.0, 0.9, 0.2)  # Warm yellow
	var center := arrow_pos + Vector2(15, 15)
	match dir:
		Constants.Direction.DOWN:
			draw_line(center + Vector2(0, -12), center + Vector2(0, 12), arrow_color, 4)
			draw_line(center + Vector2(0, 12), center + Vector2(-8, 4), arrow_color, 4)
			draw_line(center + Vector2(0, 12), center + Vector2(8, 4), arrow_color, 4)
		Constants.Direction.UP:
			draw_line(center + Vector2(0, 12), center + Vector2(0, -12), arrow_color, 4)
			draw_line(center + Vector2(0, -12), center + Vector2(-8, -4), arrow_color, 4)
			draw_line(center + Vector2(0, -12), center + Vector2(8, -4), arrow_color, 4)
		Constants.Direction.LEFT:
			draw_line(center + Vector2(12, 0), center + Vector2(-12, 0), arrow_color, 4)
			draw_line(center + Vector2(-12, 0), center + Vector2(-4, -8), arrow_color, 4)
			draw_line(center + Vector2(-12, 0), center + Vector2(-4, 8), arrow_color, 4)
		Constants.Direction.RIGHT:
			draw_line(center + Vector2(-12, 0), center + Vector2(12, 0), arrow_color, 4)
			draw_line(center + Vector2(12, 0), center + Vector2(4, -8), arrow_color, 4)
			draw_line(center + Vector2(12, 0), center + Vector2(4, 8), arrow_color, 4)


func _draw_preview_cell_3d(px: float, py: float, size: float, color: Color) -> void:
	# Full 3D-style cell for preview matching the game blocks exactly
	var margin := 1.0
	var x := px + margin
	var y := py + margin
	var s := size - margin * 2
	var corner := 3.0  # Slightly smaller corner for preview
	
	# Use exact same brightness as active play blocks (is_active=true)
	var base_color := color.lightened(0.1)
	# Add inner glow like active blocks
	var has_glow := true
	
	# Draw rounded rectangle (approximated with overlapping rects)
	draw_rect(Rect2(x + corner, y, s - corner * 2, s), base_color)
	draw_rect(Rect2(x, y + corner, s, s - corner * 2), base_color)
	# Corners (circles)
	draw_circle(Vector2(x + corner, y + corner), corner, base_color)
	draw_circle(Vector2(x + s - corner, y + corner), corner, base_color)
	draw_circle(Vector2(x + corner, y + s - corner), corner, base_color)
	draw_circle(Vector2(x + s - corner, y + s - corner), corner, base_color)
	
	# Top highlight (3D bevel effect) - match game blocks
	var highlight := color.lightened(0.35)
	var bevel := 2.5
	draw_line(Vector2(x + corner, y + bevel/2), Vector2(x + s - corner, y + bevel/2), 
			  highlight, bevel, true)
	draw_line(Vector2(x + bevel/2, y + corner), Vector2(x + bevel/2, y + s - corner), 
			  highlight, bevel, true)
	
	# Bottom shadow (3D bevel effect)  
	var shadow := color.darkened(0.35)
	draw_line(Vector2(x + corner, y + s - bevel/2), Vector2(x + s - corner, y + s - bevel/2), 
			  shadow, bevel, true)
	draw_line(Vector2(x + s - bevel/2, y + corner), Vector2(x + s - bevel/2, y + s - corner), 
			  shadow, bevel, true)
	
	# Inner glow
	var glow := color.lightened(0.5)
	glow.a = 0.3
	draw_rect(Rect2(x + 3, y + 3, s - 6, s - 6), glow)
	
	# Specular highlight (small bright spot)
	var spec := Color(1, 1, 1, 0.5)
	draw_circle(Vector2(x + 6, y + 6), 2, spec)

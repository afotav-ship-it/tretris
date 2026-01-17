extends Node2D
## Main game controller

const BlockClass = preload("res://scripts/block.gd")

signal game_over_signal
signal score_changed(score: int, lines: int, level: int)
signal block_locked
signal lines_cleared(count: int)

# Grid state: null = empty, Color = occupied
var grid: Array[Array] = []

# Game state
var score: int = 0
var lines_cleared_count: int = 0
var level: int = 1
var is_game_over: bool = false
var is_paused: bool = false

# Settings
var music_enabled: bool = true
var effects_enabled: bool = true
var play_level: int = Constants.PlayLevel.NORMAL
var num_directions: int = 4  # Deprecated, kept for compatibility
var enabled_directions: Array[int] = [0, 1, 2, 3]  # UP, DOWN, LEFT, RIGHT

# Block parameters (set by play level)
var min_cells: int = 2
var max_cells: int = 4
var min_size = null
var max_size = null

# Current blocks
var current_block = null  # Block instance
var next_block = null     # Block instance

# Timing
var fall_time: float = 0.0
var base_fall_speed: float = 0.5  # seconds
var fall_speed: float = 0.5

# Line clearing animation
var clearing_lines: Array = []  # Array of {"type": "row"/"col", "index": int}
var clear_animation_time: float = 0.0
var clear_animation_duration: float = 0.2

# Audio
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer

# Web audio requires user interaction first
var audio_initialized: bool = false
# Pregenerated sounds
var landing_sound: AudioStreamWAV
var blopper_sound: AudioStreamWAV
var explosion_sounds: Dictionary = {}
var current_music: AudioStreamWAV = null

# Touch tracking for better swipe detection
var touch_start_pos: Vector2 = Vector2.ZERO
var touch_start_time: float = 0.0
var is_touching: bool = false


func _ready() -> void:
	# Configure audio players for mobile - use higher volume
	music_player.bus = "Master"
	sfx_player.bus = "Master"
	music_player.volume_db = 0
	sfx_player.volume_db = 0
	
	_pregenerate_sounds()
	reset_game()
	queue_redraw()


func _try_init_audio() -> void:
	# iOS/Web browsers require user interaction before audio can play
	if audio_initialized:
		return
	
	audio_initialized = true
	print("Audio: Attempting to initialize on user interaction")
	
	# For web exports, use a more aggressive iOS unlock strategy
	if OS.has_feature("web"):
		_unlock_web_audio_ios()
	else:
		# Native platforms - just start music
		if music_enabled:
			call_deferred("_start_music_deferred")


func _unlock_web_audio_ios() -> void:
	# Use the AudioContext that was already unlocked by the HTML tap-to-start overlay
	if OS.has_feature("web"):
		var js_code := """
		(function() {
			console.log('Godot: Checking audio unlock status...');
			console.log('window.audioUnlocked:', window.audioUnlocked);
			
			// Use the AudioContext created by the tap-to-start overlay
			if (window.gameAudioContext) {
				console.log('Using existing gameAudioContext, state:', window.gameAudioContext.state);
				if (window.gameAudioContext.state === 'suspended') {
					window.gameAudioContext.resume().then(function() {
						console.log('gameAudioContext resumed to:', window.gameAudioContext.state);
					});
				}
			}
			
			// Also try to resume Godot's audio context
			if (typeof GodotRuntime !== 'undefined' && GodotRuntime.getAudioContext) {
				var ctx = GodotRuntime.getAudioContext();
				if (ctx) {
					console.log('GodotRuntime AudioContext state:', ctx.state);
					if (ctx.state === 'suspended') {
						ctx.resume().then(function() {
							console.log('GodotRuntime context resumed');
						});
					}
				}
			}
			
			// Try Godot 4's audio interface
			if (typeof Godot !== 'undefined' && Godot.audio && Godot.audio.ctx) {
				console.log('Godot.audio.ctx state:', Godot.audio.ctx.state);
				if (Godot.audio.ctx.state === 'suspended') {
					Godot.audio.ctx.resume().then(function() {
						console.log('Godot.audio.ctx resumed');
					});
				}
			}
			
			console.log('Godot audio check complete');
		})();
		"""
		JavaScriptBridge.eval(js_code)
		print("Audio: iOS unlock check executed")
	
	# Play a sound through Godot to establish the audio pipeline
	var unlock_sound := AudioStreamWAV.new()
	unlock_sound.format = AudioStreamWAV.FORMAT_16_BITS
	unlock_sound.stereo = true
	unlock_sound.mix_rate = 22050
	# Create a short click/blip sound
	var click_data := PackedByteArray()
	for i in range(2000):  # ~90ms at 22050Hz
		var t := float(i) / 22050.0
		var wave := sin(TAU * 440.0 * t) * exp(-t * 30.0)  # 440Hz A note, quick decay
		var value := int(wave * 8000)
		value = clampi(value, -32000, 32000)
		# Stereo (L and R)
		click_data.append(value & 0xFF)
		click_data.append((value >> 8) & 0xFF)
		click_data.append(value & 0xFF)
		click_data.append((value >> 8) & 0xFF)
	unlock_sound.data = click_data
	
	sfx_player.stream = unlock_sound
	sfx_player.volume_db = -20
	sfx_player.play()
	print("Audio: Unlock sound played through Godot")
	
	# Start music after ensuring audio is ready
	if music_enabled:
		call_deferred("_start_music_deferred")


func _start_music_deferred() -> void:
	# Wait for audio context to be ready on mobile browsers
	await get_tree().create_timer(0.3).timeout
	
	if music_enabled and audio_initialized:
		sfx_player.volume_db = 0  # Restore volume
		
		# On iOS, do another resume attempt right before playing
		if OS.has_feature("web"):
			JavaScriptBridge.eval("""
			(function() {
				// Resume all audio contexts before playing music
				if (window.gameAudioCtx && window.gameAudioCtx.state === 'suspended') {
					window.gameAudioCtx.resume();
				}
				if (typeof GodotRuntime !== 'undefined' && GodotRuntime.getAudioContext) {
					var ctx = GodotRuntime.getAudioContext();
					if (ctx && ctx.state === 'suspended') ctx.resume();
				}
				if (typeof Godot !== 'undefined' && Godot.audio && Godot.audio.ctx) {
					if (Godot.audio.ctx.state === 'suspended') Godot.audio.ctx.resume();
				}
			})();
			""")
		
		print("Audio: Starting music...")
		start_music()
		
		# On web, retry if music isn't playing
		if OS.has_feature("web"):
			await get_tree().create_timer(0.5).timeout
			if not music_player.playing:
				print("Audio: Music not playing, retrying with context resume...")
				JavaScriptBridge.eval("""
				(function() {
					if (window.gameAudioCtx) window.gameAudioCtx.resume();
					if (typeof Godot !== 'undefined' && Godot.audio && Godot.audio.ctx) {
						Godot.audio.ctx.resume();
					}
				})();
				""")
				await get_tree().create_timer(0.2).timeout
				start_music()


func _pregenerate_sounds() -> void:
	landing_sound = AudioGenerator.generate_landing_sound()
	blopper_sound = AudioGenerator.generate_blopper_sound()
	
	for i in range(1, 6):
		explosion_sounds[i] = AudioGenerator.generate_explosion_sound(i)


func reset_game() -> void:
	# Initialize grid
	grid.clear()
	for _y in range(Constants.GRID_HEIGHT):
		var row: Array = []
		for _x in range(Constants.GRID_WIDTH):
			row.append(null)
		grid.append(row)
	
	score = 0
	lines_cleared_count = 0
	level = 1
	is_game_over = false
	is_paused = false
	
	# Set block parameters based on play level
	var params: Dictionary = Constants.LEVEL_PARAMS[play_level]
	min_cells = params["min_cells"]
	max_cells = params["max_cells"]
	min_size = params["min_size"]
	max_size = params["max_size"]
	
	fall_speed = base_fall_speed
	fall_time = 0.0
	clearing_lines.clear()
	
	# Generate first blocks using enabled directions
	next_block = BlockClass.create_with_directions([], Color.WHITE, -1, enabled_directions, min_cells, max_cells, min_size, max_size)
	spawn_new_block()
	
	# Start music only if audio is already initialized (user has interacted)
	if audio_initialized and music_enabled:
		start_music()
	
	emit_signal("score_changed", score, lines_cleared_count, level)


func start_music() -> void:
	stop_music()
	current_music = AudioGenerator.generate_folk_music(-1, level)
	music_player.stream = current_music
	music_player.volume_db = -10
	music_player.play()


func stop_music() -> void:
	music_player.stop()


func toggle_music() -> void:
	# Ensure audio is unlocked when user toggles music
	_try_init_audio()
	
	music_enabled = not music_enabled
	if music_enabled:
		start_music()
	else:
		stop_music()


func toggle_effects() -> void:
	# Ensure audio is unlocked
	_try_init_audio()
	effects_enabled = not effects_enabled


func toggle_pause() -> void:
	is_paused = not is_paused


func cycle_play_level() -> void:
	play_level = (play_level + 1) % 3
	reset_game()


func _process(delta: float) -> void:
	if is_game_over or is_paused:
		return
	
	# Handle line clear animation
	if not clearing_lines.is_empty():
		clear_animation_time -= delta
		if clear_animation_time <= 0:
			finish_clear_lines()
		return
	
	# Auto-move based on direction
	fall_time += delta
	if fall_time >= fall_speed:
		fall_time = 0.0
		auto_move()
	
	queue_redraw()


func _input(event: InputEvent) -> void:
	# Initialize audio on first user interaction (required for web)
	_try_init_audio()
	
	if event is InputEventKey and event.pressed:
		var key: int = event.keycode
		
		# Global controls
		match key:
			KEY_Q, KEY_ESCAPE:
				get_tree().quit()
			KEY_M:
				toggle_music()
			KEY_N:
				toggle_effects()
			KEY_P:
				toggle_pause()
			KEY_R:
				reset_game()
			KEY_L:
				cycle_play_level()
			KEY_1:
				enabled_directions = [Constants.Direction.DOWN]
				reset_game()
			KEY_2:
				enabled_directions = [Constants.Direction.DOWN, Constants.Direction.UP]
				reset_game()
			KEY_3:
				enabled_directions = [Constants.Direction.DOWN, Constants.Direction.UP, Constants.Direction.LEFT]
				reset_game()
			KEY_4:
				enabled_directions = [Constants.Direction.DOWN, Constants.Direction.UP, Constants.Direction.LEFT, Constants.Direction.RIGHT]
				reset_game()
		
		if is_game_over or is_paused:
			return
		
		# Game controls
		var direction: int = current_block.direction
		
		match key:
			KEY_LEFT:
				if direction == Constants.Direction.RIGHT:
					rotate_block(true)
				else:
					move_block(-1, 0)
			KEY_RIGHT:
				if direction == Constants.Direction.LEFT:
					rotate_block(true)
				else:
					move_block(1, 0)
			KEY_UP:
				if direction == Constants.Direction.DOWN:
					rotate_block(true)
				else:
					move_block(0, -1)
			KEY_DOWN:
				if direction == Constants.Direction.UP:
					rotate_block(true)
				else:
					move_block(0, 1)
			KEY_Z:
				rotate_block(false)
			KEY_X:
				rotate_block(true)
			KEY_SPACE:
				hard_drop()


func get_spawn_position(block) -> Vector2i:
	var direction: int = block.direction
	var x: int = 0
	var y: int = 0
	
	match direction:
		Constants.Direction.DOWN:
			x = Constants.GRID_WIDTH / 2 - block.width() / 2
			y = 0
		Constants.Direction.UP:
			x = Constants.GRID_WIDTH / 2 - block.width() / 2
			y = Constants.GRID_HEIGHT - block.height()
		Constants.Direction.RIGHT:
			x = 0
			y = Constants.GRID_HEIGHT / 2 - block.height() / 2
		Constants.Direction.LEFT:
			x = Constants.GRID_WIDTH - block.width()
			y = Constants.GRID_HEIGHT / 2 - block.height() / 2
	
	return Vector2i(x, y)


func can_spawn_block(block, x: int, y: int) -> bool:
	for row_idx in range(block.height()):
		for col_idx in range(block.width()):
			if block.shape[row_idx][col_idx] != 0:
				var check_x: int = x + col_idx
				var check_y: int = y + row_idx
				
				if check_x < 0 or check_x >= Constants.GRID_WIDTH:
					return false
				if check_y < 0 or check_y >= Constants.GRID_HEIGHT:
					return false
				if grid[check_y][check_x] != null:
					return false
	return true


func find_valid_spawn_position(block) -> Dictionary:
	var base_pos: Vector2i = get_spawn_position(block)
	
	if can_spawn_block(block, base_pos.x, base_pos.y):
		return {"x": base_pos.x, "y": base_pos.y, "valid": true}
	
	var direction: int = block.direction
	
	# Search for valid position based on direction
	match direction:
		Constants.Direction.DOWN:
			for y in range(Constants.GRID_HEIGHT - block.height() + 1):
				for x_offset in range(maxi(Constants.GRID_WIDTH / 2, block.width())):
					for x in [base_pos.x - x_offset, base_pos.x + x_offset]:
						if x >= 0 and x <= Constants.GRID_WIDTH - block.width():
							if can_spawn_block(block, x, y):
								return {"x": x, "y": y, "valid": true}
		
		Constants.Direction.UP:
			for y in range(Constants.GRID_HEIGHT - block.height(), -1, -1):
				for x_offset in range(maxi(Constants.GRID_WIDTH / 2, block.width())):
					for x in [base_pos.x - x_offset, base_pos.x + x_offset]:
						if x >= 0 and x <= Constants.GRID_WIDTH - block.width():
							if can_spawn_block(block, x, y):
								return {"x": x, "y": y, "valid": true}
		
		Constants.Direction.RIGHT:
			for x in range(Constants.GRID_WIDTH - block.width() + 1):
				for y_offset in range(maxi(Constants.GRID_HEIGHT / 2, block.height())):
					for y in [base_pos.y - y_offset, base_pos.y + y_offset]:
						if y >= 0 and y <= Constants.GRID_HEIGHT - block.height():
							if can_spawn_block(block, x, y):
								return {"x": x, "y": y, "valid": true}
		
		Constants.Direction.LEFT:
			for x in range(Constants.GRID_WIDTH - block.width(), -1, -1):
				for y_offset in range(maxi(Constants.GRID_HEIGHT / 2, block.height())):
					for y in [base_pos.y - y_offset, base_pos.y + y_offset]:
						if y >= 0 and y <= Constants.GRID_HEIGHT - block.height():
							if can_spawn_block(block, x, y):
								return {"x": x, "y": y, "valid": true}
	
	return {"x": base_pos.x, "y": base_pos.y, "valid": false}


func spawn_new_block() -> void:
	current_block = next_block
	next_block = BlockClass.create_with_directions([], Color.WHITE, -1, enabled_directions, min_cells, max_cells, min_size, max_size)
	
	var spawn_result: Dictionary = find_valid_spawn_position(current_block)
	current_block.x = spawn_result["x"]
	current_block.y = spawn_result["y"]
	
	if not spawn_result["valid"]:
		is_game_over = true
		emit_signal("game_over_signal")


func is_valid_position(block, offset_x: int = 0, offset_y: int = 0) -> bool:
	for row_idx in range(block.height()):
		for col_idx in range(block.width()):
			if block.shape[row_idx][col_idx] != 0:
				var new_x: int = block.x + col_idx + offset_x
				var new_y: int = block.y + row_idx + offset_y
				
				if new_x < 0 or new_x >= Constants.GRID_WIDTH:
					return false
				if new_y < 0 or new_y >= Constants.GRID_HEIGHT:
					return false
				if grid[new_y][new_x] != null:
					return false
	return true


func lock_block() -> void:
	var mono_color: Color = Constants.to_grayscale(current_block.color)
	
	for row_idx in range(current_block.height()):
		for col_idx in range(current_block.width()):
			if current_block.shape[row_idx][col_idx] != 0:
				var x: int = current_block.x + col_idx
				var y: int = current_block.y + row_idx
				if x >= 0 and x < Constants.GRID_WIDTH and y >= 0 and y < Constants.GRID_HEIGHT:
					grid[y][x] = mono_color
	
	# Play sound
	if effects_enabled:
		if is_solid_landing():
			sfx_player.stream = landing_sound
		else:
			sfx_player.stream = blopper_sound
		sfx_player.play()
	
	emit_signal("block_locked")
	check_and_start_clear_animation()
	
	if clearing_lines.is_empty():
		spawn_new_block()


func is_solid_landing() -> bool:
	var direction: int = current_block.direction
	
	match direction:
		Constants.Direction.DOWN:
			for col_idx in range(current_block.width()):
				var lowest_row: int = -1
				for row_idx in range(current_block.height()):
					if current_block.shape[row_idx][col_idx] != 0:
						lowest_row = row_idx
				if lowest_row >= 0:
					var x: int = current_block.x + col_idx
					var y: int = current_block.y + lowest_row
					if y < Constants.GRID_HEIGHT - 1 and grid[y + 1][x] == null:
						return false
		
		Constants.Direction.UP:
			for col_idx in range(current_block.width()):
				var highest_row: int = -1
				for row_idx in range(current_block.height()):
					if current_block.shape[row_idx][col_idx] != 0:
						highest_row = row_idx
						break
				if highest_row >= 0:
					var x: int = current_block.x + col_idx
					var y: int = current_block.y + highest_row
					if y > 0 and grid[y - 1][x] == null:
						return false
		
		Constants.Direction.RIGHT:
			for row_idx in range(current_block.height()):
				var rightmost_col: int = -1
				for col_idx in range(current_block.width()):
					if current_block.shape[row_idx][col_idx] != 0:
						rightmost_col = col_idx
				if rightmost_col >= 0:
					var x: int = current_block.x + rightmost_col
					var y: int = current_block.y + row_idx
					if x < Constants.GRID_WIDTH - 1 and grid[y][x + 1] == null:
						return false
		
		Constants.Direction.LEFT:
			for row_idx in range(current_block.height()):
				var leftmost_col: int = -1
				for col_idx in range(current_block.width()):
					if current_block.shape[row_idx][col_idx] != 0:
						leftmost_col = col_idx
						break
				if leftmost_col >= 0:
					var x: int = current_block.x + leftmost_col
					var y: int = current_block.y + row_idx
					if x > 0 and grid[y][x - 1] == null:
						return false
	
	return true


func check_and_start_clear_animation() -> void:
	clearing_lines.clear()
	
	# Check rows
	for y in range(Constants.GRID_HEIGHT):
		var complete := true
		for x in range(Constants.GRID_WIDTH):
			if grid[y][x] == null:
				complete = false
				break
		if complete:
			clearing_lines.append({"type": "row", "index": y})
	
	# Check columns
	for x in range(Constants.GRID_WIDTH):
		var complete := true
		for y in range(Constants.GRID_HEIGHT):
			if grid[y][x] == null:
				complete = false
				break
		if complete:
			clearing_lines.append({"type": "col", "index": x})
	
	if not clearing_lines.is_empty():
		clear_animation_time = clear_animation_duration
		brighten_clearing_lines()


func brighten_clearing_lines() -> void:
	for line in clearing_lines:
		if line["type"] == "row":
			for x in range(Constants.GRID_WIDTH):
				if grid[line["index"]][x] != null:
					grid[line["index"]][x] = Constants.brighten_color(grid[line["index"]][x], 2.0)
		elif line["type"] == "col":
			for y in range(Constants.GRID_HEIGHT):
				if grid[y][line["index"]] != null:
					grid[y][line["index"]] = Constants.brighten_color(grid[y][line["index"]], 2.0)


func finish_clear_lines() -> void:
	if clearing_lines.is_empty():
		return
	
	var total_lines: int = clearing_lines.size()
	
	# Clear the lines
	for line in clearing_lines:
		if line["type"] == "row":
			for x in range(Constants.GRID_WIDTH):
				grid[line["index"]][x] = null
		elif line["type"] == "col":
			for y in range(Constants.GRID_HEIGHT):
				grid[y][line["index"]] = null
	
	collapse_all_directions()
	
	if total_lines > 0:
		lines_cleared_count += total_lines
		
		# Play explosion sound
		if effects_enabled:
			var intensity: int = mini(5, total_lines)
			sfx_player.stream = explosion_sounds[intensity]
			sfx_player.play()
		
		# Exponential scoring
		var points: int = 0
		for i in range(total_lines):
			points += 100 * int(pow(2, i))
		score += points
		
		# Level up every 5 lines
		var new_level: int = (lines_cleared_count / 5) + 1
		if new_level > level:
			level = new_level
			fall_speed = base_fall_speed * pow(0.9, level - 1)
			if music_enabled:
				start_music()
		
		emit_signal("lines_cleared", total_lines)
		emit_signal("score_changed", score, lines_cleared_count, level)
	
	clearing_lines.clear()
	spawn_new_block()


func collapse_all_directions() -> void:
	for _pass in range(maxi(Constants.GRID_WIDTH, Constants.GRID_HEIGHT)):
		if Constants.Direction.DOWN in enabled_directions:
			collapse_down()
		if Constants.Direction.UP in enabled_directions:
			collapse_up()
		if Constants.Direction.LEFT in enabled_directions:
			collapse_left()
		if Constants.Direction.RIGHT in enabled_directions:
			collapse_right()


func collapse_down() -> void:
	var mid_y: int = Constants.GRID_HEIGHT / 2
	for x in range(Constants.GRID_WIDTH):
		var cells: Array = []
		for y in range(mid_y, Constants.GRID_HEIGHT):
			if grid[y][x] != null:
				cells.append(grid[y][x])
				grid[y][x] = null
		cells.reverse()
		for i in range(cells.size()):
			grid[Constants.GRID_HEIGHT - 1 - i][x] = cells[i]


func collapse_up() -> void:
	var mid_y: int = Constants.GRID_HEIGHT / 2
	for x in range(Constants.GRID_WIDTH):
		var cells: Array = []
		for y in range(mid_y):
			if grid[y][x] != null:
				cells.append(grid[y][x])
				grid[y][x] = null
		for i in range(cells.size()):
			grid[i][x] = cells[i]


func collapse_right() -> void:
	var mid_x: int = Constants.GRID_WIDTH / 2
	for y in range(Constants.GRID_HEIGHT):
		var cells: Array = []
		for x in range(mid_x, Constants.GRID_WIDTH):
			if grid[y][x] != null:
				cells.append(grid[y][x])
				grid[y][x] = null
		cells.reverse()
		for i in range(cells.size()):
			grid[y][Constants.GRID_WIDTH - 1 - i] = cells[i]


func collapse_left() -> void:
	var mid_x: int = Constants.GRID_WIDTH / 2
	for y in range(Constants.GRID_HEIGHT):
		var cells: Array = []
		for x in range(mid_x):
			if grid[y][x] != null:
				cells.append(grid[y][x])
				grid[y][x] = null
		for i in range(cells.size()):
			grid[y][i] = cells[i]


func move_block(dx: int, dy: int) -> bool:
	if is_valid_position(current_block, dx, dy):
		current_block.x += dx
		current_block.y += dy
		return true
	return false


func auto_move() -> void:
	var dx: int = 0
	var dy: int = 0
	
	match current_block.direction:
		Constants.Direction.DOWN:
			dy = 1
		Constants.Direction.UP:
			dy = -1
		Constants.Direction.RIGHT:
			dx = 1
		Constants.Direction.LEFT:
			dx = -1
	
	if not move_block(dx, dy):
		lock_block()


func rotate_block(clockwise: bool = true) -> void:
	var original_shape: Array = current_block.shape.duplicate(true)
	current_block.rotate(clockwise)
	
	if not is_valid_position(current_block):
		# Wall kick attempts
		var offsets := [[1, 0], [-1, 0], [0, 1], [0, -1], [2, 0], [-2, 0]]
		var found := false
		
		for offset in offsets:
			if is_valid_position(current_block, offset[0], offset[1]):
				current_block.x += offset[0]
				current_block.y += offset[1]
				found = true
				break
		
		if not found:
			current_block.shape = original_shape


func hard_drop() -> void:
	var dx: int = 0
	var dy: int = 0
	
	match current_block.direction:
		Constants.Direction.DOWN:
			dy = 1
		Constants.Direction.UP:
			dy = -1
		Constants.Direction.RIGHT:
			dx = 1
		Constants.Direction.LEFT:
			dx = -1
	
	while move_block(dx, dy):
		score += 1
	
	lock_block()


func _draw() -> void:
	# Draw gradient background
	var grid_w: float = Constants.GRID_WIDTH * Constants.CELL_SIZE
	var grid_h: float = Constants.GRID_HEIGHT * Constants.CELL_SIZE
	
	# Dark gradient background
	for i in range(20):
		var t: float = float(i) / 20.0
		var shade: float = lerp(0.03, 0.08, t)
		var y: float = grid_h * t
		var h: float = grid_h / 20.0 + 1
		draw_rect(Rect2(0, y, grid_w, h), Color(shade, shade, shade * 1.2))
	
	# Draw subtle grid lines
	for x in range(Constants.GRID_WIDTH + 1):
		var alpha := 0.15 if x % 3 == 0 else 0.08
		draw_line(Vector2(x * Constants.CELL_SIZE, 0), 
				  Vector2(x * Constants.CELL_SIZE, grid_h),
				  Color(0.3, 0.35, 0.4, alpha), 1.0)
	for y in range(Constants.GRID_HEIGHT + 1):
		var alpha := 0.15 if y % 3 == 0 else 0.08
		draw_line(Vector2(0, y * Constants.CELL_SIZE),
				  Vector2(grid_w, y * Constants.CELL_SIZE),
				  Color(0.3, 0.35, 0.4, alpha), 1.0)
	
	# Draw placed blocks with 3D effect
	for y in range(Constants.GRID_HEIGHT):
		for x in range(Constants.GRID_WIDTH):
			if grid[y][x] != null:
				_draw_3d_cell(x * Constants.CELL_SIZE, y * Constants.CELL_SIZE, 
							  Constants.CELL_SIZE, grid[y][x], false)
	
	# Draw ghost and current block
	if not is_game_over and clearing_lines.is_empty() and current_block != null:
		draw_ghost()
		draw_block(current_block)


func _draw_3d_cell(px: float, py: float, size: float, color: Color, is_active: bool) -> void:
	var margin := 1.0
	var x := px + margin
	var y := py + margin
	var s := size - margin * 2
	var corner := 4.0  # Corner radius
	
	# Main block body with slight gradient
	var base_color := color
	if is_active:
		base_color = color.lightened(0.1)
	
	# Draw rounded rectangle (approximated with overlapping rects)
	# Main body
	draw_rect(Rect2(x + corner, y, s - corner * 2, s), base_color)
	draw_rect(Rect2(x, y + corner, s, s - corner * 2), base_color)
	# Corners (circles)
	draw_circle(Vector2(x + corner, y + corner), corner, base_color)
	draw_circle(Vector2(x + s - corner, y + corner), corner, base_color)
	draw_circle(Vector2(x + corner, y + s - corner), corner, base_color)
	draw_circle(Vector2(x + s - corner, y + s - corner), corner, base_color)
	
	# Top highlight (3D bevel effect)
	var highlight := color.lightened(0.35)
	var bevel := 3.0
	draw_line(Vector2(x + corner, y + bevel/2), Vector2(x + s - corner, y + bevel/2), 
			  highlight, bevel, true)
	draw_line(Vector2(x + bevel/2, y + corner), Vector2(x + bevel/2, y + s - corner), 
			  highlight, bevel, true)
	
	# Bottom shadow (3D bevel effect)  
	var shadow := color.darkened(0.4)
	draw_line(Vector2(x + corner, y + s - bevel/2), Vector2(x + s - corner, y + s - bevel/2), 
			  shadow, bevel, true)
	draw_line(Vector2(x + s - bevel/2, y + corner), Vector2(x + s - bevel/2, y + s - corner), 
			  shadow, bevel, true)
	
	# Inner glow for active block
	if is_active:
		var glow := color.lightened(0.5)
		glow.a = 0.3
		draw_rect(Rect2(x + 4, y + 4, s - 8, s - 8), glow)
	
	# Specular highlight (small bright spot)
	var spec := Color(1, 1, 1, 0.4)
	draw_circle(Vector2(x + 8, y + 8), 3, spec)


func draw_block(block, offset_x: float = 0, offset_y: float = 0, scale_factor: float = 1.0) -> void:
	for row_idx in range(block.height()):
		for col_idx in range(block.width()):
			if block.shape[row_idx][col_idx] != 0:
				var px: float = (block.x + col_idx) * Constants.CELL_SIZE * scale_factor + offset_x
				var py: float = (block.y + row_idx) * Constants.CELL_SIZE * scale_factor + offset_y
				_draw_3d_cell(px, py, Constants.CELL_SIZE * scale_factor, block.color, true)


func draw_ghost() -> void:
	var ghost = current_block.duplicate_block()
	
	var dx: int = 0
	var dy: int = 0
	
	match ghost.direction:
		Constants.Direction.DOWN:
			dy = 1
		Constants.Direction.UP:
			dy = -1
		Constants.Direction.RIGHT:
			dx = 1
		Constants.Direction.LEFT:
			dx = -1
	
	while is_valid_position(ghost, dx, dy):
		ghost.x += dx
		ghost.y += dy
	
	# Draw ghost with dashed outline
	var ghost_color := Color(ghost.color.r * 0.4, ghost.color.g * 0.4, ghost.color.b * 0.4, 0.6)
	
	for row_idx in range(ghost.height()):
		for col_idx in range(ghost.width()):
			if ghost.shape[row_idx][col_idx] != 0:
				var x: float = (ghost.x + col_idx) * Constants.CELL_SIZE
				var y: float = (ghost.y + row_idx) * Constants.CELL_SIZE
				var s: float = Constants.CELL_SIZE
				var m: float = 2.0
				
				# Draw dotted outline
				for i in range(0, int(s - m * 2), 6):
					draw_line(Vector2(x + m + i, y + m), Vector2(x + m + i + 3, y + m), ghost_color, 2)
					draw_line(Vector2(x + m + i, y + s - m), Vector2(x + m + i + 3, y + s - m), ghost_color, 2)
					draw_line(Vector2(x + m, y + m + i), Vector2(x + m, y + m + i + 3), ghost_color, 2)
					draw_line(Vector2(x + s - m, y + m + i), Vector2(x + s - m, y + m + i + 3), ghost_color, 2)

func _unhandled_input(event: InputEvent) -> void:
	# Initialize audio on first user interaction (required for web)
	_try_init_audio()
	
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	# Game area is between control panel (280px) and menu (280px)
	var game_area_start: float = 280.0
	var game_area_end: float = screen_size.x - 280.0
	var game_area_bottom: float = screen_size.y
	
	# Track touch start for swipe detection
	if event is InputEventScreenTouch:
		var touch_event = event as InputEventScreenTouch
		var touch_pos: Vector2 = touch_event.position
		
		# Only process touches in the game area (between control panel and menu)
		if touch_pos.x < game_area_start or touch_pos.x >= game_area_end:
			return
		
		if touch_event.pressed:
			# Touch started
			touch_start_pos = touch_pos
			touch_start_time = Time.get_ticks_msec() / 1000.0
			is_touching = true
		else:
			# Touch ended - check for swipe or tap gesture
			if is_touching:
				var touch_duration: float = (Time.get_ticks_msec() / 1000.0) - touch_start_time
				var delta: Vector2 = touch_pos - touch_start_pos
				var distance: float = delta.length()
				
				# Swipe detection: minimum distance and reasonable time
				if distance > 40 and touch_duration < 0.5:
					_handle_swipe(delta)
				elif distance < 20 and touch_duration < 0.3:
					# Tap detection: small movement, quick tap - rotate the block
					rotate_block(true)
				
				is_touching = false
	
	# Track drag for continuous lateral movement
	if event is InputEventScreenDrag and is_touching:
		var drag_event = event as InputEventScreenDrag
		var current_pos: Vector2 = drag_event.position
		
		# Only process drags in the game area
		if current_pos.x < game_area_start or current_pos.x >= game_area_end:
			return


func _handle_swipe(delta: Vector2) -> void:
	if is_game_over or is_paused or not current_block:
		return
	
	var dir: int = current_block.direction
	var abs_x: float = abs(delta.x)
	var abs_y: float = abs(delta.y)
	
	# Determine swipe direction based on dominant axis
	if abs_x > abs_y:
		# Horizontal swipe
		if delta.x > 0:
			# Swipe right
			if dir == Constants.Direction.DOWN or dir == Constants.Direction.UP:
				move_block(1, 0)  # Move right for vertical falling blocks
			elif dir == Constants.Direction.RIGHT:
				hard_drop()  # Drop for right-facing blocks
			elif dir == Constants.Direction.LEFT:
				rotate_block(true)  # Rotate when swiping opposite to block direction
		else:
			# Swipe left
			if dir == Constants.Direction.DOWN or dir == Constants.Direction.UP:
				move_block(-1, 0)  # Move left for vertical falling blocks
			elif dir == Constants.Direction.LEFT:
				hard_drop()  # Drop for left-facing blocks
			elif dir == Constants.Direction.RIGHT:
				rotate_block(true)  # Rotate when swiping opposite to block direction
	else:
		# Vertical swipe
		if delta.y > 0:
			# Swipe down
			if dir == Constants.Direction.DOWN:
				hard_drop()  # Drop for downward falling blocks
			elif dir == Constants.Direction.LEFT or dir == Constants.Direction.RIGHT:
				move_block(0, 1)  # Move down for horizontal falling blocks
			elif dir == Constants.Direction.UP:
				rotate_block(true)  # Rotate when swiping opposite to block direction
		else:
			# Swipe up
			if dir == Constants.Direction.UP:
				hard_drop()  # Drop for upward falling blocks
			elif dir == Constants.Direction.LEFT or dir == Constants.Direction.RIGHT:
				move_block(0, -1)  # Move up for horizontal falling blocks
			elif dir == Constants.Direction.DOWN:
				rotate_block(true)  # Rotate when swiping opposite to block direction
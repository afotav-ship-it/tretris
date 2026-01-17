class_name Block
extends RefCounted
## Represents a falling tetris block

var shape: Array[Array]  # 2D array of 0s and 1s
var color: Color
var direction: int  # Constants.Direction enum
var x: int = 0
var y: int = 0


static func create(
	custom_shape: Array = [],
	custom_color: Color = Color.WHITE,
	custom_direction: int = -1,
	num_directions: int = 4,
	min_cells: int = 2,
	max_cells: int = 4,
	min_size = null,
	max_size = null
):
	var BlockScript = load("res://scripts/block.gd")
	var block = BlockScript.new()
	
	if custom_shape.size() > 0:
		block.shape = custom_shape.duplicate(true)
	else:
		block.shape = generate_random_shape(min_cells, max_cells, min_size, max_size)
	
	if custom_color != Color.WHITE:
		block.color = custom_color
	else:
		var colors = Constants.BLOCK_COLORS
		block.color = colors[randi() % colors.size()]
	
	if custom_direction >= 0:
		block.direction = custom_direction
	else:
		var available_directions := range(num_directions)
		# Directions: 0=UP, 1=DOWN, 2=LEFT, 3=RIGHT -> we want DOWN, UP, LEFT, RIGHT order
		var direction_map := [1, 0, 2, 3]  # Remap to DOWN first
		var valid_dirs := []
		for i in available_directions:
			valid_dirs.append(direction_map[i])
		block.direction = valid_dirs[randi() % valid_dirs.size()]
	
	return block


static func create_with_directions(
	custom_shape: Array = [],
	custom_color: Color = Color.WHITE,
	custom_direction: int = -1,
	enabled_directions: Array = [0, 1, 2, 3],  # Array of Direction enum values
	min_cells: int = 2,
	max_cells: int = 4,
	min_size = null,
	max_size = null
):
	var BlockScript = load("res://scripts/block.gd")
	var block = BlockScript.new()
	
	if custom_shape.size() > 0:
		block.shape = custom_shape.duplicate(true)
	else:
		block.shape = generate_random_shape(min_cells, max_cells, min_size, max_size)
	
	if custom_color != Color.WHITE:
		block.color = custom_color
	else:
		var colors = Constants.BLOCK_COLORS
		block.color = colors[randi() % colors.size()]
	
	if custom_direction >= 0:
		block.direction = custom_direction
	else:
		# Use the enabled directions directly
		if enabled_directions.size() > 0:
			block.direction = enabled_directions[randi() % enabled_directions.size()]
		else:
			block.direction = Constants.Direction.DOWN  # Fallback
	
	return block


func width() -> int:
	if shape.size() == 0:
		return 0
	return shape[0].size()


func height() -> int:
	return shape.size()


func rotate(clockwise: bool = true) -> void:
	var old_shape := shape.duplicate(true)
	var h := height()
	var w := width()
	
	var new_shape: Array[Array] = []
	
	if clockwise:
		for col in range(w):
			var new_row: Array = []
			for row in range(h - 1, -1, -1):
				new_row.append(old_shape[row][col])
			new_shape.append(new_row)
	else:
		for col in range(w - 1, -1, -1):
			var new_row: Array = []
			for row in range(h):
				new_row.append(old_shape[row][col])
			new_shape.append(new_row)
	
	shape = new_shape


func duplicate_block():
	var new_block = get_script().new()
	new_block.shape = shape.duplicate(true)
	new_block.color = color
	new_block.direction = direction
	new_block.x = x
	new_block.y = y
	return new_block


static func generate_random_shape(
	min_cells: int = 2,
	max_cells: int = 4,
	min_size = null,  # Variant for nullable
	max_size = null   # Variant for nullable
) -> Array[Array]:
	# Determine grid size based on constraints
	var grid_size: int
	if max_size != null:
		grid_size = max_size
	else:
		grid_size = maxi(2, int(ceil(sqrt(max_cells))) + 1)
	
	if min_size != null:
		grid_size = maxi(grid_size, min_size)
	
	# Try multiple times to generate a valid shape
	for _attempt in range(20):
		var temp_shape: Array[Array] = []
		for _i in range(grid_size):
			var row: Array = []
			for _j in range(grid_size):
				row.append(0)
			temp_shape.append(row)
		
		# Start with one cell in the center and grow randomly
		var start_x := grid_size / 2
		var start_y := grid_size / 2
		var filled: Dictionary = { Vector2i(start_x, start_y): true }
		temp_shape[start_y][start_x] = 1
		
		# Pick target cell count
		var target_cells := randi_range(min_cells, max_cells)
		
		# Grow the shape by adding adjacent cells
		var max_tries := grid_size * grid_size * 10
		for _growth in range(max_tries):
			if filled.size() >= target_cells:
				break
			
			# Pick a random filled cell and try to grow from it
			var filled_cells := filled.keys()
			var cell: Vector2i = filled_cells[randi() % filled_cells.size()]
			var directions := [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]
			directions.shuffle()
			
			for dir in directions:
				var new_pos: Vector2i = cell + dir
				if new_pos.x >= 0 and new_pos.x < grid_size and \
				   new_pos.y >= 0 and new_pos.y < grid_size and \
				   not filled.has(new_pos):
					temp_shape[new_pos.y][new_pos.x] = 1
					filled[new_pos] = true
					break
		
		# Handle min_size constraint
		if min_size != null:
			var min_x := grid_size
			var max_x := 0
			var min_y := grid_size
			var max_y := 0
			
			for pos in filled.keys():
				min_x = mini(min_x, pos.x)
				max_x = maxi(max_x, pos.x)
				min_y = mini(min_y, pos.y)
				max_y = maxi(max_y, pos.y)
			
			var current_width := max_x - min_x + 1
			var current_height := max_y - min_y + 1
			
			while current_width < min_size or current_height < min_size:
				var edge_cells: Array[Vector2i] = []
				for pos in filled.keys():
					for dir in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
						var new_pos: Vector2i = pos + dir
						if new_pos.x >= 0 and new_pos.x < grid_size and \
						   new_pos.y >= 0 and new_pos.y < grid_size and \
						   not filled.has(new_pos):
							edge_cells.append(new_pos)
				
				if edge_cells.is_empty():
					break
				
				var new_pos := edge_cells[randi() % edge_cells.size()]
				temp_shape[new_pos.y][new_pos.x] = 1
				filled[new_pos] = true
				
				min_x = grid_size
				max_x = 0
				min_y = grid_size
				max_y = 0
				for pos in filled.keys():
					min_x = mini(min_x, pos.x)
					max_x = maxi(max_x, pos.x)
					min_y = mini(min_y, pos.y)
					max_y = maxi(max_y, pos.y)
				current_width = max_x - min_x + 1
				current_height = max_y - min_y + 1
		
		# Trim empty rows and columns
		var result := trim_shape(temp_shape)
		
		if result.is_empty():
			continue
		
		# Verify constraints
		var cell_count := 0
		for row in result:
			for cell in row:
				cell_count += cell
		
		var result_height := result.size()
		var result_width: int = result[0].size() if result.size() > 0 else 0
		
		if cell_count < min_cells or cell_count > max_cells:
			continue
		
		if min_size != null and (result_width < min_size or result_height < min_size):
			continue
		if max_size != null and (result_width > max_size or result_height > max_size):
			continue
		
		return result
	
	# Fallback: create a simple line
	var fallback: Array[Array] = []
	var row: Array = []
	for _i in range(min_cells):
		row.append(1)
	fallback.append(row)
	return fallback


static func trim_shape(shape_array: Array[Array]) -> Array[Array]:
	var result := shape_array.duplicate(true)
	
	# Remove empty top rows
	while result.size() > 0:
		var all_empty := true
		for cell in result[0]:
			if cell != 0:
				all_empty = false
				break
		if all_empty:
			result.pop_front()
		else:
			break
	
	# Remove empty bottom rows
	while result.size() > 0:
		var all_empty := true
		for cell in result[result.size() - 1]:
			if cell != 0:
				all_empty = false
				break
		if all_empty:
			result.pop_back()
		else:
			break
	
	if result.is_empty():
		return []
	
	# Remove empty left columns
	while result[0].size() > 0:
		var all_empty := true
		for row in result:
			if row[0] != 0:
				all_empty = false
				break
		if all_empty:
			for row in result:
				row.pop_front()
		else:
			break
	
	# Remove empty right columns
	while result.size() > 0 and result[0].size() > 0:
		var all_empty := true
		for row in result:
			if row[row.size() - 1] != 0:
				all_empty = false
				break
		if all_empty:
			for row in result:
				row.pop_back()
		else:
			break
	
	return result

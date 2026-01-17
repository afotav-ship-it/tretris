extends Node
## Game constants and configuration - Autoload singleton

# Grid settings - landscape: 720px height / 40px = 18 cells, width fits in ~1080px area
var CELL_SIZE: int = 40
var GRID_WIDTH: int = 18
var GRID_HEIGHT: int = 18

# Colors
var BLACK: Color = Color(0, 0, 0)
var WHITE: Color = Color(1, 1, 1)
var GRAY: Color = Color(0.3, 0.3, 0.35)
var DARK_GRAY: Color = Color(0.08, 0.08, 0.12)
var GRID_BG: Color = Color(0.05, 0.05, 0.08)
var GRID_LINE: Color = Color(0.15, 0.15, 0.2, 0.5)

# Block colors - more vibrant and saturated
var BLOCK_COLORS: Array[Color] = [
	Color(0.95, 0.25, 0.25),   # Red
	Color(0.25, 0.9, 0.35),    # Green
	Color(0.3, 0.5, 0.95),     # Blue
	Color(0.95, 0.85, 0.2),    # Yellow
	Color(0.9, 0.3, 0.85),     # Magenta
	Color(0.2, 0.85, 0.9),     # Cyan
	Color(0.95, 0.55, 0.15),   # Orange
	Color(0.6, 0.3, 0.95),     # Purple
	Color(0.95, 0.45, 0.55),   # Pink
	Color(0.45, 0.9, 0.5),     # Light Green
]

# Directions
enum Direction { UP = 0, DOWN = 1, LEFT = 2, RIGHT = 3 }

var DIRECTION_NAMES: Dictionary = {
	Direction.UP: "UP",
	Direction.DOWN: "DOWN", 
	Direction.LEFT: "LEFT",
	Direction.RIGHT: "RIGHT"
}

var DIRECTION_ARROWS: Dictionary = {
	Direction.UP: "↑",
	Direction.DOWN: "↓",
	Direction.LEFT: "←",
	Direction.RIGHT: "→"
}

# Play levels
enum PlayLevel { NORMAL = 0, ADVANCED = 1, BOULDER = 2 }

var PLAY_LEVEL_NAMES: Dictionary = {
	PlayLevel.NORMAL: "NORMAL",
	PlayLevel.ADVANCED: "ADVANCED",
	PlayLevel.BOULDER: "BOULDER"
}

var PLAY_LEVEL_COLORS: Dictionary = {
	PlayLevel.NORMAL: Color(0.4, 1, 0.4),
	PlayLevel.ADVANCED: Color(1, 1, 0.4),
	PlayLevel.BOULDER: Color(1, 0.4, 0.4)
}

# Level-specific block parameters
var LEVEL_PARAMS: Dictionary = {
	PlayLevel.NORMAL: { "min_cells": 3, "max_cells": 4, "min_size": null, "max_size": null },
	PlayLevel.ADVANCED: { "min_cells": 3, "max_cells": 6, "min_size": null, "max_size": 4 },
	PlayLevel.BOULDER: { "min_cells": 4, "max_cells": 9, "min_size": 2, "max_size": 3 }
}

func to_grayscale(color: Color) -> Color:
	var gray: float = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b
	var light_gray: float = clampf(gray * 0.5 + 0.55, 0.55, 1.0)
	return Color(light_gray, light_gray, light_gray)

func brighten_color(color: Color, factor: float = 1.5) -> Color:
	return Color(
		clampf(color.r * factor, 0, 1),
		clampf(color.g * factor, 0, 1),
		clampf(color.b * factor, 0, 1)
	)

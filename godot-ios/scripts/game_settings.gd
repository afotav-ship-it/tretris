extends Node
## Global game settings autoload

var play_level: int = Constants.PlayLevel.NORMAL
var enabled_directions: Array[int] = [
	Constants.Direction.UP,
	Constants.Direction.DOWN,
	Constants.Direction.LEFT,
	Constants.Direction.RIGHT
]
var music_enabled: bool = true
var effects_enabled: bool = true


func reset_to_defaults() -> void:
	play_level = Constants.PlayLevel.NORMAL
	enabled_directions = [
		Constants.Direction.UP,
		Constants.Direction.DOWN,
		Constants.Direction.LEFT,
		Constants.Direction.RIGHT
	]
	music_enabled = true
	effects_enabled = true

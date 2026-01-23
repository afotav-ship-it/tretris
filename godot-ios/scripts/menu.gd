extends Control

signal start_pressed
signal mode_selected(mode: int)
signal exit_pressed

const Constants = preload("res://scripts/constants.gd")

@onready var btn_play = $VBox/BtnMenuPlay
@onready var btn_exit = $VBox/BtnMenuExit
@onready var btn_normal = $VBox/ModeBox/BtnMenuNormal
@onready var btn_advanced = $VBox/ModeBox/BtnMenuAdvanced
@onready var btn_boulder = $VBox/ModeBox/BtnMenuBoulder

func _ready() -> void:
    btn_play.pressed.connect(_on_play_pressed)
    btn_exit.pressed.connect(_on_exit_pressed)
    btn_normal.pressed.connect(_on_normal_pressed)
    btn_advanced.pressed.connect(_on_advanced_pressed)
    btn_boulder.pressed.connect(_on_boulder_pressed)

func _on_play_pressed() -> void:
    emit_signal("start_pressed")

func _on_exit_pressed() -> void:
    emit_signal("exit_pressed")

func _on_normal_pressed() -> void:
    emit_signal("mode_selected", Constants.PlayLevel.NORMAL)

func _on_advanced_pressed() -> void:
    emit_signal("mode_selected", Constants.PlayLevel.ADVANCED)

func _on_boulder_pressed() -> void:
    emit_signal("mode_selected", Constants.PlayLevel.BOULDER)

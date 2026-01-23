extends Control

signal start_pressed
signal mode_selected(mode: int)
signal exit_pressed

const Constants = preload("res://scripts/constants.gd")

var btn_play: Button
var btn_exit: Button
var btn_normal: Button
var btn_advanced: Button
var btn_boulder: Button

func _ready() -> void:
    # Safely find child nodes; some instancing contexts may delay child creation.
    btn_play = get_node_or_null("VBox/BtnMenuPlay")
    btn_exit = get_node_or_null("VBox/BtnMenuExit")
    btn_normal = get_node_or_null("VBox/ModeBox/BtnMenuNormal")
    btn_advanced = get_node_or_null("VBox/ModeBox/BtnMenuAdvanced")
    btn_boulder = get_node_or_null("VBox/ModeBox/BtnMenuBoulder")

    if not btn_play or not btn_exit or not btn_normal:
        # Defer setup once the scene is fully ready
        call_deferred("_deferred_setup")
        return

    _connect_buttons()

func _deferred_setup() -> void:
    btn_play = get_node_or_null("VBox/BtnMenuPlay")
    btn_exit = get_node_or_null("VBox/BtnMenuExit")
    btn_normal = get_node_or_null("VBox/ModeBox/BtnMenuNormal")
    btn_advanced = get_node_or_null("VBox/ModeBox/BtnMenuAdvanced")
    btn_boulder = get_node_or_null("VBox/ModeBox/BtnMenuBoulder")
    _connect_buttons()

func _connect_buttons() -> void:
    if btn_play:
        btn_play.pressed.connect(_on_play_pressed)
    if btn_exit:
        btn_exit.pressed.connect(_on_exit_pressed)
    if btn_normal:
        btn_normal.pressed.connect(_on_normal_pressed)
    if btn_advanced:
        btn_advanced.pressed.connect(_on_advanced_pressed)
    if btn_boulder:
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

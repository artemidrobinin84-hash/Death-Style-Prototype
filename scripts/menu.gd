extends Node2D

func _ready() -> void:
	_Exit()
	_Settings()
	_SettingsExit()
# Called when the node enters the scene tree for the first time.
func _Settings() -> void:
	$menu/MenuUi/Settings.pressed.connect(_on_settings_pressed)


func _SettingsExit() -> void:
	$menu/MenuUi/Control/SettingsUi/Button.pressed.connect(_on_exit_settings_pressed)


func _Exit() -> void:
	$menu/MenuUi/Exit.pressed.connect(_on_exit_pressed)


func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	print("nasal")
	$menu/MenuUi/Control.mouse_filter = Control.MOUSE_FILTER_STOP
	$menu/MenuUi/Control/SettingsUi.show()

func _on_exit_settings_pressed() -> void:
	print("lol")
	$menu/MenuUi/Control/SettingsUi.visible = false
	$menu/MenuUi/Control.mouse_filter = Control.MOUSE_FILTER_IGNORE

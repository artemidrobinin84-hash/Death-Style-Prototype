extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CanvasLayer/Sprite2D/Exit.pressed.connect(_on_exit_pressed)


func _on_exit_pressed() -> void:
	
	get_tree().quit()

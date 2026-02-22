extends Area2D
@export var next_level_scene: PackedScene
func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		Engine.set_meta("kill_count", body.kill_count)
		Engine.set_meta("attack_damage", body.attack_damage)
		Engine.set_meta("player_scale", body.get_node("AnimatedSprite2D").scale)
		if next_level_scene:
			get_tree().change_scene_to_packed(next_level_scene)
		else:
			get_tree().reload_current_scene()

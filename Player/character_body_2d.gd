extends CharacterBody2D
var player_data = null
var kill_count : int = 0
@export var damage_increase_per_kill : int = 2 
@export var size_increase_per_kill : float = 0.05 
var base_attack_damage : int
var base_scale : Vector2
signal health_changed(current_health)
signal player_died
@export var max_health : int = 100
var current_health : int
@export var attack_damage : int = 25
var is_attacking = false
@export var attack_offset := 15
@export var speed := 150.0
@export var kill_counter: Label

func _ready():
	current_health = max_health
	add_to_group("player")
	emit_signal("health_changed", current_health)
	
	$AnimatedSprite2D/Area2D.monitoring = false
	$AnimatedSprite2D/Area2D.monitorable = false
	base_attack_damage = attack_damage
	base_scale = $AnimatedSprite2D.scale
	
	# ЗАГРУЗКА
	if Engine.has_meta("kill_count"):
		kill_count = Engine.get_meta("kill_count")
		attack_damage = Engine.get_meta("attack_damage")
		$AnimatedSprite2D.scale = Engine.get_meta("player_scale")
		if kill_counter:
			kill_counter.text = "Kill: " + str(kill_count)

func _physics_process(_delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed
	move_and_slide()
	$Sprite2D.look_at(get_global_mouse_position())
	var look_direction = Vector2.RIGHT.rotated($Sprite2D.rotation)
	$AnimatedSprite2D.global_position = $Sprite2D.global_position + look_direction * attack_offset
	$AnimatedSprite2D.rotation = $Sprite2D.rotation

func _input(event):
	if event.is_action_pressed("left_mouse") and not is_attacking:
		start_attack()

func start_attack():
	is_attacking = true
	$AnimatedSprite2D/Area2D.monitoring = true
	$AnimatedSprite2D/Area2D.monitorable = true
	$AnimatedSprite2D.look_at(get_global_mouse_position())
	$AnimatedSprite2D.show()
	$AnimatedSprite2D.play("Attack")
	await get_tree().create_timer(0.1).timeout
	await get_tree().create_timer(0.15).timeout
	$AnimatedSprite2D/Area2D.monitoring = false
	$AnimatedSprite2D/Area2D.monitorable = false
	$AnimatedSprite2D.hide()
	$AnimatedSprite2D.stop()
	is_attacking = false

func take_damage(damage_amount : int, _source = null):
	if current_health <= 0:
		return
	current_health -= damage_amount
	emit_signal("health_changed", current_health)
	modulate = Color.RED
	await get_tree().create_timer(0.2).timeout
	modulate = Color.WHITE
	if current_health <= 0:
		die()

func die():
	emit_signal("player_died")
	set_process(false)
	set_physics_process(false)
	var white_screen = ColorRect.new()
	white_screen.color = Color.WHITE
	white_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	white_screen.z_index = 1000
	white_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().root.add_child(white_screen)
	var tween = create_tween()
	tween.tween_property(white_screen, "modulate:a", 0.0, 0.3).from(1.0)
	await tween.finished
	for child in get_tree().root.get_children():
		if child is ColorRect and child.color == Color.WHITE:
			child.queue_free()
	get_tree().reload_current_scene()

func get_attack_damage() -> int:
	return attack_damage

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not is_attacking:
		return
	if body == self:
		return
	if not body.has_method("take_damage"):
		return
	if body.is_in_group("enemy"):
		body.take_damage(attack_damage, "player")
		return
	body.take_damage(attack_damage, "player")

func add_kill():
	kill_count += 1
	if kill_counter:
		kill_counter.text = "Kill: " + str(kill_count)
	attack_damage = base_attack_damage + (kill_count * damage_increase_per_kill)
	var scale_factor = 1.0 + (kill_count * size_increase_per_kill)
	$AnimatedSprite2D.scale = base_scale * scale_factor
	Engine.set_meta("kill_count", kill_count)
	Engine.set_meta("attack_damage", attack_damage)
	Engine.set_meta("player_scale", $AnimatedSprite2D.scale)

func get_save_data() -> Dictionary:
	return {
		"kill_count": kill_count,
		"attack_damage": attack_damage,
		"scale": $AnimatedSprite2D.scale
	}

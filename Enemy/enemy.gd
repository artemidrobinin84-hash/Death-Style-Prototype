extends CharacterBody2D
var stuck_counter = 0
var last_position = Vector2.ZERO
@export var stop_range : float = 20.0
@export var bullet_scene: PackedScene 
enum EnemyType { MELEE, RANGED }
@export var enemy_type: EnemyType = EnemyType.MELEE
signal health_changed(current_health)
signal enemy_died
@export var max_health : int = 50
var current_health : int
@export var attack_damage : int = 30
@export var attack_cooldown : float = 1.5
var can_attack = true
var is_attacking = false
@export var speed : float = 30.0
@export var detection_range : float = 150.0
@export var attack_range : float = 30.0
var player = null
@export var attack_offset := 20.0

func _ready():
	current_health = max_health
	add_to_group("enemy") 
	emit_signal("health_changed", current_health)

func shoot():
	if bullet_scene == null:
		return
	var bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	if has_node("ShootPosition"):
		bullet.global_position = $ShootPosition.global_position
	else:
		bullet.global_position = global_position
	var dir = (player.global_position - global_position).normalized()
	bullet.start(dir, 300, attack_damage)

func _physics_process(_delta):
	if player == null:
		find_player()
	if player:
		var distance_to_player = global_position.distance_to(player.global_position)
		$Sprite2D.look_at(player.global_position)
		if distance_to_player < detection_range:
			var direction = (player.global_position - global_position).normalized()
			match enemy_type:
				EnemyType.MELEE:
					if distance_to_player > stop_range:
						velocity = direction * speed
					else:
						velocity = Vector2.ZERO
				EnemyType.RANGED:
					if distance_to_player > stop_range:
						velocity = direction * speed
					else:
						velocity = Vector2.ZERO
			move_and_slide()
			var can_attack_now = distance_to_player < attack_range
			if can_attack_now and can_attack and not is_attacking:
				start_attack()
			if global_position.distance_to(last_position) < 1.0 and distance_to_player > stop_range * 0.8:
				stuck_counter += 1
			else:
				stuck_counter = 0
				
			if stuck_counter > 15 and not is_attacking:
				var avoid_direction = Vector2.RIGHT if randf() > 0.5 else Vector2.LEFT
				velocity = avoid_direction * speed * 3
				move_and_slide()
				stuck_counter = 0
			last_position = global_position
		else:
			velocity = Vector2.ZERO
			move_and_slide()
	else:
		velocity = Vector2.ZERO
		move_and_slide()
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider() == player:
			var push_dir = (global_position - player.global_position).normalized()
			velocity = push_dir * speed * 2
			move_and_slide()
			break

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func start_attack():
	is_attacking = true
	can_attack = false
	match enemy_type:
		EnemyType.MELEE:
			await melee_attack()
		EnemyType.RANGED:
			await ranged_attack()
	is_attacking = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func melee_attack():
	var attack_direction = Vector2.RIGHT
	if player:
		attack_direction = (player.global_position - global_position).normalized()
	if $AnimatedSprite2D:
		$AnimatedSprite2D.global_position = global_position + attack_direction * attack_offset
		if attack_direction.x > 0:
			$AnimatedSprite2D.scale.x = abs($AnimatedSprite2D.scale.x)
		else:
			$AnimatedSprite2D.scale.x = -abs($AnimatedSprite2D.scale.x)
		$AnimatedSprite2D.visible = true
		$AnimatedSprite2D.play("attack")
	await get_tree().create_timer(0.15).timeout
	if player and is_instance_valid(player) and global_position.distance_to(player.global_position) < attack_range * 1.5:
		if player.has_method("take_damage"):
			player.take_damage(attack_damage, "enemy")
	await get_tree().create_timer(0.05).timeout
	if $AnimatedSprite2D:
		$AnimatedSprite2D.visible = false
		$AnimatedSprite2D.stop()

func ranged_attack():
	if $AnimatedSprite2D:
		$AnimatedSprite2D.play("attack")
	await get_tree().create_timer(0.3).timeout
	shoot() 
	await get_tree().create_timer(0.2).timeout
	if $AnimatedSprite2D:
		$AnimatedSprite2D.stop()

func take_damage(damage_amount : int, _source = null):
	if current_health <= 0:
		return
	current_health -= damage_amount
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	if current_health <= 0:
		die()

func die():
	print("Враг умер!")
	emit_signal("enemy_died")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		if player.has_method("add_kill"):
			player.add_kill()
	if $AnimatedSprite2D and $AnimatedSprite2D.sprite_frames.has_animation("death"):
		$AnimatedSprite2D.play("death")
		await $AnimatedSprite2D.animation_finished
	queue_free()

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player = body

func _on_detection_area_body_exited(body):
	if body == player:
		player = null

func _on_area_2d_body_entered(body):
	if body.is_in_group("player") and body.has_method("get_attack_damage"):
		if body.has_method("is_attacking") and body.is_attacking:
			var damage = body.get_attack_damage()
			take_damage(damage, "player")

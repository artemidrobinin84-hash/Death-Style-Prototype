extends Area2D

var speed = 300
var direction = Vector2.RIGHT
var damage = 10 

func _ready():
	$LifeTimer.wait_time = 3.0
	$LifeTimer.start()

func _physics_process(delta):
	position += direction * speed * delta

func start(dir, bullet_speed, bullet_damage):
	direction = dir
	speed = bullet_speed
	damage = bullet_damage
	rotation = direction.angle()

func _on_body_entered(body):
	if body.has_method("take_damage") and body.is_in_group("player"):
		body.take_damage(damage, "enemy")
		queue_free()
	elif not body.is_in_group("enemy"):
		queue_free()

func _on_life_timer_timeout():
	queue_free()

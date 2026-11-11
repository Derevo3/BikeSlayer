extends CharacterBody2D
class_name BaseEnemy

## Базовый класс врагов для BikeSlayer

@export var max_health: float = 20.0
@export var coins_reward: int = 3
@export var souls_reward: int = 1
@export var enemy_name: String = "BaseEnemy"
@export var base_speed: float = 60.0
@export var gravity: float = 980.0
@export var flying: bool = false

var current_health: float = 20.0
var is_dead: bool = false
var damage_num_scene = preload("res://scenes/ui/damage_number.tscn")

@onready var visuals: Node2D = $Visuals
@onready var hurtbox: Area2D = $Hurtbox

func _ready() -> void:
	current_health = max_health

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not flying and not is_on_floor():
		velocity.y += gravity * delta

	# Враги медленно двигаются навстречу байку
	velocity.x = -base_speed
	move_and_slide()

	# Очистка, если игрок уехал далеко вперед
	var player = get_tree().get_first_node_in_group("player")
	if player and global_position.x < player.global_position.x - 900.0:
		queue_free()

func take_damage(amount: float, hit_pos: Vector2) -> void:
	if is_dead:
		return

	current_health -= amount
	_spawn_damage_number(amount, hit_pos)
	_play_hit_flash()

	# Импульс отскока при ударе велосипедом
	velocity.x = 220.0
	velocity.y = -140.0

	if current_health <= 0.0:
		die()

func _spawn_damage_number(amount: float, pos: Vector2) -> void:
	var dmg_node = damage_num_scene.instantiate()
	get_parent().add_child(dmg_node)
	dmg_node.global_position = pos + Vector2(randf_range(-10, 10), -20)
	dmg_node.setup(amount, GameManager.is_boosting)

func _play_hit_flash() -> void:
	if not visuals:
		return
	var tween = create_tween()
	visuals.modulate = Color(3.0, 3.0, 3.0, 1.0) # Вспышка белым/пересветом
	tween.tween_property(visuals, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)

func die() -> void:
	is_dead = true
	# Отключаем коллизии
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
	set_collision_layer_value(1, false)
	set_collision_layer_value(2, false)

	EventBus.enemy_killed.emit(enemy_name, coins_reward, souls_reward, global_position)

	# Если враг уничтожен на ускорении (Нитро), из него дополнительно выбиваются сверкающие монеты
	if GameManager.is_boosting:
		var bonus_level = UpgradeManager.get_upgrade("boost_bounty")
		var extra_coins = 1 + (bonus_level.level if bonus_level else 0)
		var coin_scene = preload("res://scenes/world/coin.tscn")
		for i in range(extra_coins):
			var coin = coin_scene.instantiate()
			get_parent().add_child(coin)
			coin.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-25, -5))

	# Анимация сокрушения/разлета
	var tween = create_tween()
	tween.tween_property(visuals, "scale", Vector2(1.6, 0.3), 0.1)
	tween.parallel().tween_property(visuals, "modulate:a", 0.0, 0.18)
	tween.tween_callback(queue_free)

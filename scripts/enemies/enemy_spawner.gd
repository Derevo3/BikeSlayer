extends Node2D
class_name EnemySpawner

## Спавнер врагов впереди велосипеда игрока с поддержкой биомов/локаций

@export var player: Node2D
@export var spawn_distance_ahead: float = 950.0
@export var min_interval: float = 1.6
@export var max_interval: float = 3.2
@export var enemies_between_bosses: int = 7

var slime_scene = preload("res://scenes/enemies/slime_enemy.tscn")
var bat_scene = preload("res://scenes/enemies/bat_enemy.tscn")
var mini_boss_scene = preload("res://scenes/enemies/mini_boss_enemy.tscn")

var treant_scene = preload("res://scenes/enemies/treant_enemy.tscn")
var wasp_scene = preload("res://scenes/enemies/wasp_enemy.tscn")
var forest_boss_scene = preload("res://scenes/enemies/forest_boss_enemy.tscn")

var timer: float = 0.0
var next_spawn_time: float = 2.0
var regular_enemies_spawned: int = 0
var active_boss: Node = null

func _ready() -> void:
	EventBus.dimension_changed.connect(_on_dimension_changed)
	_schedule_next_spawn()

func _on_dimension_changed(_dim_id: String) -> void:
	clear_all_enemies()

## Уничтожает всех существующих противников на карте при смене локации
func clear_all_enemies() -> void:
	# 1. Удаляем всех детей внутри спавнера
	for child in get_children():
		if is_instance_valid(child):
			child.queue_free()
	
	# 2. Удаляем всех врагов в глобальных группах "enemy" и "boss"
	var enemies = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	
	var bosses = get_tree().get_nodes_in_group("boss")
	for b in bosses:
		if is_instance_valid(b):
			b.queue_free()
	
	# 3. Сбрасываем босса и счетчики
	active_boss = null
	regular_enemies_spawned = 0
	_schedule_next_spawn()

func _schedule_next_spawn() -> void:
	timer = 0.0
	next_spawn_time = randf_range(min_interval, max_interval)

func _process(delta: float) -> void:
	if not player:
		return
	
	# Не спавним новых врагов, пока активен босс или пока игрок остановлен
	if is_instance_valid(active_boss) and not active_boss.is_dead:
		return
	if "velocity" in player and abs(player.velocity.x) < 1.0:
		return
	
	timer += delta
	if timer >= next_spawn_time:
		_spawn_enemy()
		_schedule_next_spawn()

func _spawn_enemy() -> void:
	var spawn_x = player.global_position.x + spawn_distance_ahead
	var hp_mult = GameManager.get_dimension_enemy_mult()
	var rew_mult = GameManager.get_dimension_reward_mult()
	var dim = GameManager.current_dimension
	
	# Проверяем спавн мини-босса (каждые enemies_between_bosses врагов)
	if not is_instance_valid(active_boss) and regular_enemies_spawned >= enemies_between_bosses:
		_spawn_mini_boss(spawn_x, hp_mult, rew_mult, dim)
		regular_enemies_spawned = 0
		return
	
	regular_enemies_spawned += 1
	
	if dim == "forest":
		# Враги локации "Древний лес": Древень и Лесной Шершень
		if randf() < 0.65:
			var treant = treant_scene.instantiate()
			treant.position = Vector2(spawn_x, 0.0)
			treant.max_health *= hp_mult
			treant.current_health = treant.max_health
			treant.coins_reward = int(round(treant.coins_reward * rew_mult))
			treant.souls_reward = int(round(treant.souls_reward * rew_mult))
			add_child(treant)
		else:
			var wasp = wasp_scene.instantiate()
			wasp.position = Vector2(spawn_x, randf_range(-75.0, -115.0))
			wasp.max_health *= hp_mult
			wasp.current_health = wasp.max_health
			wasp.coins_reward = int(round(wasp.coins_reward * rew_mult))
			wasp.souls_reward = int(round(wasp.souls_reward * rew_mult))
			add_child(wasp)
	else:
		# 65% наземные слизни, 35% летающие мыши
		if randf() < 0.65:
			var slime = slime_scene.instantiate()
			if slime.has_method("apply_upgrades"):
				slime.apply_upgrades()
			slime.position = Vector2(spawn_x, -16.0)
			slime.max_health *= hp_mult
			slime.current_health = slime.max_health
			slime.coins_reward = int(round(slime.coins_reward * rew_mult))
			slime.souls_reward = int(round(slime.souls_reward * rew_mult))
			add_child(slime)
		else:
			var bat = bat_scene.instantiate()
			bat.position = Vector2(spawn_x, randf_range(-75.0, -115.0))
			bat.max_health *= hp_mult
			bat.current_health = bat.max_health
			bat.coins_reward = int(round(bat.coins_reward * rew_mult))
			bat.souls_reward = int(round(bat.souls_reward * rew_mult))
			add_child(bat)

func _spawn_mini_boss(spawn_x: float, hp_mult: float, rew_mult: float, dim: String) -> void:
	var boss: Node2D
	var boss_title: String
	
	if dim == "forest":
		boss = forest_boss_scene.instantiate()
		boss_title = "Древний Леший"
	else:
		boss = mini_boss_scene.instantiate()
		boss_title = "Голиаф"
		
	boss.position = Vector2(spawn_x, 0.0)
	boss.max_health *= hp_mult
	boss.current_health = boss.max_health
	boss.coins_reward = int(round(boss.coins_reward * rew_mult))
	boss.souls_reward = int(round(boss.souls_reward * rew_mult))
	active_boss = boss
	add_child(boss)
	EventBus.boss_spawned.emit(boss_title)

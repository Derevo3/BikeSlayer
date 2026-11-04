extends CharacterBody2D
class_name PlayerBike

## Контроллер игрока на велосипеде для Idle-раннера
## Двигается автоматически вперед, прыгает по нажатию, таранит врагов передним колесом

@export var base_gravity: float = 1200.0
@export var jump_force: float = -520.0
@export var boost_speed_mult: float = 1.7
@export var ram_damage: float = 20.0

@onready var attack_area: Area2D = $AttackArea
@onready var coin_collector: Area2D = $CoinCollector
@onready var coin_collision_shape: CollisionShape2D = $CoinCollector/CollisionShape2D
@onready var bike_visuals: Node2D = $Visuals
@onready var front_wheel: Node2D = $Visuals/FrontWheel
@onready var back_wheel: Node2D = $Visuals/BackWheel
@onready var pedals: Node2D = $Visuals/Pedals
@onready var ram_impact_spawner: Marker2D = $Visuals/RamPoint
@onready var dust_particles: CPUParticles2D = $DustParticles
@onready var boost_trail: CPUParticles2D = $BoostParticles

var current_speed: float = 300.0
var attack_timer: float = 0.0
var is_ramming: bool = false
var ram_anim_time: float = 0.0
var original_visual_pos: Vector2 = Vector2.ZERO
var current_boss_target: Node = null

var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
const JUMP_BUFFER_TIME: float = 0.16
const COYOTE_TIME: float = 0.12

func _ready() -> void:
	original_visual_pos = bike_visuals.position
	EventBus.boost_activated.connect(_on_boost_started)
	EventBus.boost_ended.connect(_on_boost_ended)
	UpgradeManager.upgrades_updated.connect(_update_stats_from_upgrades)
	if coin_collector:
		coin_collector.area_entered.connect(_on_coin_collector_area_entered)
	_update_stats_from_upgrades()

func _update_stats_from_upgrades() -> void:
	current_speed = UpgradeManager.get_value("bike_speed", 300.0)
	# Обновляем радиус магнита для монет
	if coin_collision_shape and coin_collision_shape.shape is CircleShape2D:
		var radius = UpgradeManager.get_value("coin_magnet", 60.0)
		coin_collision_shape.shape.radius = radius
	if coin_collector:
		for area in coin_collector.get_overlapping_areas():
			_on_coin_collector_area_entered(area)

func _on_coin_collector_area_entered(area: Area2D) -> void:
	if area.has_method("magnetize_to"):
		area.magnetize_to(self)
	elif area is CoinPickup:
		area.target_player = self

func _on_boost_started(_duration: float) -> void:
	if boost_trail:
		boost_trail.emitting = true

func _on_boost_ended() -> void:
	if boost_trail:
		boost_trail.emitting = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		try_jump()
	elif event.is_action_pressed("boost"):
		GameManager.activate_boost()

func try_jump() -> void:
	jump_buffer_timer = JUMP_BUFFER_TIME
	_check_jump()

func _check_jump() -> void:
	if (is_on_floor() or coyote_timer > 0.0) and jump_buffer_timer > 0.0:
		velocity.y = jump_force
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		if dust_particles:
			dust_particles.restart()

func _physics_process(delta: float) -> void:
	# 1. Гравитация и таймеры прыжка
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = max(0.0, coyote_timer - delta)
		velocity.y += base_gravity * delta
	
	if jump_buffer_timer > 0.0:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)
		_check_jump()
	
	# Проверка статуса противостояния с боссом
	var is_fighting_boss: bool = false
	if is_instance_valid(current_boss_target):
		if current_boss_target.is_dead:
			current_boss_target = null
		else:
			is_fighting_boss = true
	
	# Если цель еще не зафиксирована, проверяем наличие живого босса в зоне атаки
	if not is_fighting_boss and attack_area:
		for area in attack_area.get_overlapping_areas():
			if area.is_in_group("enemy_hitbox"):
				var enemy = area.get_parent()
				if enemy and enemy.is_in_group("boss") and not enemy.is_dead:
					current_boss_target = enemy
					is_fighting_boss = true
					if enemy.has_method("set_engaged"):
						enemy.set_engaged(true)
					break
	
	# 2. Горизонтальное движение (автоматическое или удержание перед боссом)
	var target_speed = current_speed
	if GameManager.is_boosting:
		target_speed *= boost_speed_mult
	
	if is_fighting_boss:
		var stop_dist: float = 78.0
		var desired_x: float = current_boss_target.global_position.x - stop_dist
		if global_position.x < desired_x:
			velocity.x = min(target_speed, (desired_x - global_position.x) / max(delta, 0.001))
		else:
			velocity.x = 0.0
			global_position.x = desired_x
	else:
		velocity.x = target_speed
	
	# Обновляем пройденную дистанцию только при поступательном движении вперед
	if velocity.x > 0.0:
		GameManager.distance_traveled += (velocity.x * delta) / 100.0 # метры
	
	move_and_slide()
	
	# 3. Анимация колес и педалей
	var wheel_rotation_speed = (velocity.x / 24.0) * delta
	if is_fighting_boss:
		# При остановке перед боссом заднее колесо пробуксовывает
		if back_wheel:
			back_wheel.rotation += (target_speed / 28.0) * delta
		if pedals:
			pedals.rotation += (target_speed / 36.0) * delta
	else:
		if front_wheel:
			front_wheel.rotation += wheel_rotation_speed
		if back_wheel:
			back_wheel.rotation += wheel_rotation_speed
		if pedals:
			pedals.rotation += wheel_rotation_speed * 0.75
	
	# Частицы пыли при контакте с землей (включая пробуксовку перед боссом)
	if dust_particles:
		dust_particles.emitting = is_on_floor() and (velocity.x > 50.0 or is_fighting_boss)

	# 4. Логика авто-атаки велосипедом
	_process_auto_attack(delta)
	
	# 5. Анимация тарана (выпад передним колесом)
	if is_ramming:
		ram_anim_time += delta * 12.0
		if ram_anim_time < PI:
			# Выпад вперед и подъем на вилли (удар передним колесом)
			bike_visuals.position.x = original_visual_pos.x + sin(ram_anim_time) * 18.0
			bike_visuals.rotation = -sin(ram_anim_time) * 0.22
		else:
			is_ramming = false
			bike_visuals.position = original_visual_pos
			bike_visuals.rotation = 0.0

func _process_auto_attack(delta: float) -> void:
	var attack_rate = UpgradeManager.get_value("attack_rate", 1.0)
	var cooldown = 1.0 / max(0.2, attack_rate)
	
	attack_timer += delta
	
	# Если заблокированы перед боссом — непрерывно тараним его по откату
	if is_instance_valid(current_boss_target):
		if current_boss_target.is_dead:
			current_boss_target = null
		else:
			if attack_timer >= cooldown:
				_perform_bike_ram(current_boss_target)
				attack_timer = 0.0
				if current_boss_target.is_dead:
					current_boss_target = null
			return
	
	if attack_timer >= cooldown:
		var targets = attack_area.get_overlapping_areas()
		for area in targets:
			if area.is_in_group("enemy_hitbox"):
				var enemy = area.get_parent()
				if enemy and enemy.has_method("take_damage") and not enemy.is_dead:
					_perform_bike_ram(enemy)
					attack_timer = 0.0
					
					# Если это босс и он пережил удар — останавливаемся перед ним!
					if enemy.is_in_group("boss") and not enemy.is_dead:
						current_boss_target = enemy
						if enemy.has_method("set_engaged"):
							enemy.set_engaged(true)
					break

func _perform_bike_ram(enemy: Node) -> void:
	is_ramming = true
	ram_anim_time = 0.0
	
	var total_dmg = ram_damage * (2.0 if GameManager.is_boosting else 1.0)
	
	var hit_pos = ram_impact_spawner.global_position if ram_impact_spawner else global_position + Vector2(40, 0)
	enemy.take_damage(total_dmg, hit_pos)
	
	# Сплеш-урон по остальным мелким врагам в зоне контакта
	for area in attack_area.get_overlapping_areas():
		if area.is_in_group("enemy_hitbox"):
			var other = area.get_parent()
			if other and other != enemy and other.has_method("take_damage") and not other.is_dead:
				other.take_damage(total_dmg, hit_pos)
	
	EventBus.player_attacked.emit(hit_pos)
	_spawn_ram_impact_fx(hit_pos)

func _spawn_ram_impact_fx(pos: Vector2) -> void:
	var fx_scene = preload("res://scenes/player/ram_impact_effect.tscn")
	var fx = fx_scene.instantiate()
	fx.global_position = pos
	get_parent().add_child(fx)

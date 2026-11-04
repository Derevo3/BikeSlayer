extends Node

## Главный контроллер игры: ресурсы, состояние, статистика

signal stats_changed

var coins: int = 0:
	set(val):
		coins = max(0, val)
		stats_changed.emit()

var souls: int = 0:
	set(val):
		souls = max(0, val)
		stats_changed.emit()

var total_enemies_slain: int = 0
var distance_traveled: float = 0.0:
	set(val):
		distance_traveled = val
		EventBus.distance_updated.emit(distance_traveled)

# Состояние способности ускорения (Boost / Нитро)
var is_boosting: bool = false
var boost_duration: float = 4.0
var boost_cooldown: float = 12.0
var boost_cooldown_remaining: float = 0.0

# Буфер пассивного дохода монет
var passive_coins_buffer: float = 0.0

# Текущий биом/измерение
var current_dimension: String = "suburb"
const AVAILABLE_DIMENSIONS: Array[String] = ["suburb", "wasteland", "cyber"]

func change_dimension(dim_id: String) -> void:
	if dim_id in AVAILABLE_DIMENSIONS and current_dimension != dim_id:
		current_dimension = dim_id
		EventBus.dimension_changed.emit(current_dimension)
		stats_changed.emit()

func cycle_dimension() -> void:
	var idx = AVAILABLE_DIMENSIONS.find(current_dimension)
	var next_idx = (idx + 1) % AVAILABLE_DIMENSIONS.size()
	change_dimension(AVAILABLE_DIMENSIONS[next_idx])

func get_dimension_enemy_mult() -> float:
	match current_dimension:
		"suburb": return 1.0
		"wasteland": return 2.2
		"cyber": return 4.5
		_: return 1.0

func get_dimension_reward_mult() -> float:
	match current_dimension:
		"suburb": return 1.0
		"wasteland": return 2.5
		"cyber": return 5.0
		_: return 1.0

func get_passive_income_rate() -> float:
	var base_rate = UpgradeManager.get_value("bike_upgrade", 0.0)
	return base_rate * get_dimension_reward_mult()

func _ready() -> void:
	EventBus.coin_collected.connect(_on_coin_collected)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	UpgradeManager.upgrades_updated.connect(_on_upgrades_updated)

func _on_upgrades_updated() -> void:
	stats_changed.emit()

func _process(delta: float) -> void:
	if boost_cooldown_remaining > 0.0:
		boost_cooldown_remaining = max(0.0, boost_cooldown_remaining - delta)
	_process_passive_income(delta)

func _process_passive_income(delta: float) -> void:
	var rate = get_passive_income_rate()
	if rate > 0.0:
		passive_coins_buffer += rate * delta
		if passive_coins_buffer >= 1.0:
			var coins_to_add: int = int(passive_coins_buffer)
			passive_coins_buffer -= coins_to_add
			coins += coins_to_add

func get_boost_reward_multiplier() -> float:
	if not is_boosting:
		return 1.0
	return UpgradeManager.get_value("boost_bounty", 1.0)

func _on_coin_collected(amount: int) -> void:
	var multiplier: float = UpgradeManager.get_value("coin_greed", 1.0)
	var boost_mult: float = get_boost_reward_multiplier()
	coins += int(round(amount * multiplier * boost_mult))

func _on_enemy_killed(_type: String, reward_coins: int, reward_souls: int, _pos: Vector2) -> void:
	total_enemies_slain += 1
	var coin_mult: float = UpgradeManager.get_value("coin_greed", 1.0)
	var soul_mult: float = UpgradeManager.get_value("soul_reaper", 1.0)
	var boost_mult: float = get_boost_reward_multiplier()
	coins += int(round(reward_coins * coin_mult * boost_mult))
	souls += int(round(reward_souls * soul_mult * boost_mult))

func can_activate_boost() -> bool:
	return not is_boosting and boost_cooldown_remaining <= 0.0

func activate_boost() -> bool:
	if not can_activate_boost():
		return false
	
	is_boosting = true
	EventBus.boost_activated.emit(boost_duration)
	
	get_tree().create_timer(boost_duration).timeout.connect(func():
		is_boosting = false
		boost_cooldown_remaining = boost_cooldown
		EventBus.boost_ended.emit()
	)
	return true

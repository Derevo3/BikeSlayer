extends Node

## Менеджер прокачки и апгрейдов в стиле Idle Slayer

signal upgrades_updated

class Upgrade:
	var id: String
	var name: String
	var description: String
	var level: int = 0
	var max_level: int = -1 # -1 для бесконечных
	var base_cost: int = 10
	var cost_multiplier: float = 1.3
	var currency: String = "coins" # "coins" или "souls"
	var base_value: float = 1.0
	var value_step: float = 0.5
	
	func _init(p_id: String, p_name: String, p_desc: String, p_base_cost: int, p_mult: float, p_base_val: float, p_step: float, p_curr: String = "coins", p_max: int = -1) -> void:
		id = p_id
		name = p_name
		description = p_desc
		base_cost = p_base_cost
		cost_multiplier = p_mult
		base_value = p_base_val
		value_step = p_step
		currency = p_curr
		max_level = p_max

	func get_cost() -> int:
		if max_level > 0 and level >= max_level:
			return -1
		return int(round(base_cost * pow(cost_multiplier, level)))

	func get_value() -> float:
		return base_value + (level * value_step)

var upgrades: Dictionary = {}

func _ready() -> void:
	_init_upgrades()

func _init_upgrades() -> void:
	_register(Upgrade.new(
		"ram_damage",
		"Удар рамой и колесом",
		"Увеличивает урон от тарана велосипедом",
		10, 1.25, 10.0, 5.0, "coins"
	))
	
	_register(Upgrade.new(
		"bike_speed",
		"Турбо-педали",
		"Повышает скорость движения велосипеда",
		15, 1.3, 280.0, 25.0, "coins"
	))
	
	_register(Upgrade.new(
		"attack_rate",
		"Частота тарана",
		"Снижает паузу между силовыми ударами колесом",
		25, 1.35, 1.0, 0.15, "coins", 20
	))
	
	_register(Upgrade.new(
		"coin_magnet",
		"Магнит для монет",
		"Увеличивает радиус сбора золота",
		30, 1.4, 60.0, 20.0, "coins", 15
	))
	
	_register(Upgrade.new(
		"coin_greed",
		"Золотые спицы",
		"Увеличивает ценность каждой собранной монеты",
		40, 1.45, 1.0, 0.5, "coins"
	))

	_register(Upgrade.new(
		"soul_reaper",
		"Ловец душ",
		"Увеличивает получаемые очки душ за уничтожение монстров",
		5, 1.5, 1.0, 0.5, "souls"
	))

func _register(upgrade: Upgrade) -> void:
	upgrades[upgrade.id] = upgrade

func get_upgrade(id: String) -> Upgrade:
	return upgrades.get(id, null)

func can_afford(id: String) -> bool:
	var up = get_upgrade(id)
	if not up:
		return false
	var cost = up.get_cost()
	if cost < 0:
		return false
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return false
	if up.currency == "coins":
		return gm.coins >= cost
	elif up.currency == "souls":
		return gm.souls >= cost
	return false

func purchase(id: String) -> bool:
	var up = get_upgrade(id)
	if not up:
		return false
	var cost = up.get_cost()
	if cost < 0:
		return false
	
	var gm = get_node_or_null("/root/GameManager")
	if not gm:
		return false
		
	if up.currency == "coins" and gm.coins >= cost:
		gm.coins -= cost
		up.level += 1
		var bus = get_node_or_null("/root/EventBus")
		if bus:
			bus.upgrade_purchased.emit(id, up.level)
		upgrades_updated.emit()
		return true
	elif up.currency == "souls" and gm.souls >= cost:
		gm.souls -= cost
		up.level += 1
		var bus = get_node_or_null("/root/EventBus")
		if bus:
			bus.upgrade_purchased.emit(id, up.level)
		upgrades_updated.emit()
		return true
	
	return false

func get_value(id: String, default_value: float = 0.0) -> float:
	var up = get_upgrade(id)
	if up:
		return up.get_value()
	return default_value

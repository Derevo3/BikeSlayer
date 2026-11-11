extends PanelContainer
class_name UpgradeCard

## Карточка отдельного улучшения в магазине прокачки

@onready var title_label: Label = $Margin/VBox/Header/TitleLabel
@onready var level_label: Label = $Margin/VBox/Header/LevelLabel
@onready var desc_label: Label = $Margin/VBox/DescLabel
@onready var value_label: Label = $Margin/VBox/ValueLabel
@onready var buy_button: Button = $Margin/VBox/BuyButton

var upgrade_id: String = ""

func setup(up_id: String) -> void:
	upgrade_id = up_id
	update_view()
	buy_button.pressed.connect(_on_buy_pressed)

func update_view() -> void:
	var up = UpgradeManager.get_upgrade(upgrade_id)
	if not up:
		return
	
	title_label.text = up.name
	level_label.text = "Ур. " + str(up.level) if up.max_level < 0 else "Ур. %d/%d" % [up.level, up.max_level]
	desc_label.text = up.description
	if upgrade_id == "bike_upgrade":
		value_label.text = "Пассивный доход: +%.1f/с" % (up.level * up.value_step)
	elif upgrade_id == "soul_damage":
		value_label.text = "Бонус к урону: +%.0f ед." % (up.level * up.value_step)
	elif upgrade_id == "slime_upgrade":
		if up.level == 0:
			value_label.text = "Вид: Обычные зеленые"
		else:
			value_label.text = "Вид: Красные (Тир %d)" % up.level
	elif upgrade_id == "boost_bounty":
		value_label.text = "Бонус добычи на нитро: +%.0f%%" % (up.level * up.value_step * 100.0)
	elif upgrade_id == "portal_unlock":
		if up.level == 0:
			value_label.text = "Статус: Закрыт (купите для разблокировки)"
		else:
			value_label.text = "Статус: АКТИВИРОВАН (кнопка в левом верхнем углу)"
	else:
		value_label.text = "Текущий бонус: +%.1f" % (up.level * up.value_step)
	
	var cost = up.get_cost()
	if cost < 0:
		buy_button.text = "ОТКРЫТО" if upgrade_id == "portal_unlock" else "МАКС."
		buy_button.disabled = true
	else:
		var curr_name = "Зол." if up.currency == "coins" else "Душ"
		buy_button.text = "%d %s" % [cost, curr_name]
		buy_button.disabled = not UpgradeManager.can_afford(upgrade_id)

func _on_buy_pressed() -> void:
	if UpgradeManager.purchase(upgrade_id):
		update_view()

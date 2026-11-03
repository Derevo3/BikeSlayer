extends Control
class_name UpgradeShop

## Панель магазина улучшений (Upgrades)

@onready var cards_container: VBoxContainer = $Panel/Margin/VBox/Scroll/CardsContainer
@onready var close_button: Button = $Panel/Margin/VBox/Header/CloseButton

var card_scene = preload("res://scenes/ui/upgrade_card.tscn")
var card_instances: Array[PanelContainer] = []

func _ready() -> void:
	close_button.pressed.connect(toggle_visibility)
	_populate_upgrades()
	
	GameManager.stats_changed.connect(_refresh_cards)
	UpgradeManager.upgrades_updated.connect(_refresh_cards)

func _populate_upgrades() -> void:
	for child in cards_container.get_children():
		child.queue_free()
	card_instances.clear()
	
	for up_id in UpgradeManager.upgrades.keys():
		var card = card_scene.instantiate()
		cards_container.add_child(card)
		card.setup(up_id)
		card_instances.append(card)

func _refresh_cards() -> void:
	for card in card_instances:
		if is_instance_valid(card):
			card.update_view()

func toggle_visibility() -> void:
	visible = not visible
	if visible:
		_refresh_cards()

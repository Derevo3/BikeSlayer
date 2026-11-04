extends CanvasLayer
class_name GameHUD

## HUD игры: ресурсы, дистанция, способности и вызов магазина

@onready var coins_label: Label = $RootUI/TopBar/Margin/HBox/Currencies/CoinsBox/CoinsLabel
@onready var souls_label: Label = $RootUI/TopBar/Margin/HBox/Currencies/SoulsBox/SoulsLabel
@onready var distance_label: Label = $RootUI/TopBar/Margin/HBox/DistanceBox/DistanceLabel
@onready var dimension_label: Label = $RootUI/TopBar/Margin/HBox/DistanceBox/DimensionLabel
@onready var shop_button: Button = $RootUI/TopBar/Margin/HBox/ShopButton
@onready var portal_button: Button = $RootUI/TopBar/Margin/HBox/PortalButton
@onready var boost_button: Button = $RootUI/BottomControls/HBox/BoostButton
@onready var boost_label: Label = $RootUI/BottomControls/HBox/BoostButton/Label
@onready var jump_button: Button = $RootUI/BottomControls/HBox/JumpButton
@onready var upgrade_shop: Control = $RootUI/UpgradeShop
@onready var warp_flash: ColorRect = $RootUI/WarpFlash

var player: Node = null

func _ready() -> void:
	var gm = get_node_or_null("/root/GameManager")
	var bus = get_node_or_null("/root/EventBus")
	
	if gm:
		gm.stats_changed.connect(_update_stats_display)
	if bus:
		bus.distance_updated.connect(_update_distance_display)
		bus.dimension_changed.connect(_on_dimension_changed)
		bus.boss_spawned.connect(_on_boss_spawned)
	
	shop_button.pressed.connect(_on_shop_pressed)
	portal_button.pressed.connect(_on_portal_pressed)
	boost_button.pressed.connect(_on_boost_pressed)
	jump_button.pressed.connect(_on_jump_pressed)
	
	_update_stats_display()
	if gm:
		_update_distance_display(gm.distance_traveled)

func _process(_delta: float) -> void:
	_update_boost_ui()

func _update_stats_display() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm and coins_label and souls_label:
		var passive_rate: float = gm.get_passive_income_rate()
		if passive_rate > 0.0:
			coins_label.text = "%s (+%.1f/с)" % [_format_number(gm.coins), passive_rate]
		else:
			coins_label.text = _format_number(gm.coins)
		souls_label.text = _format_number(gm.souls)

func _update_distance_display(meters: float) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if distance_label:
		distance_label.text = "%d м" % int(meters)
	if dimension_label and gm:
		dimension_label.text = "Локация: " + _get_dimension_title(gm.current_dimension)

func _on_dimension_changed(_dim_id: String) -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		_update_distance_display(gm.distance_traveled)
		_update_stats_display()

func _get_dimension_title(dim_id: String) -> String:
	match dim_id:
		"suburb": return "Пригород"
		"wasteland": return "Пустошь"
		"cyber": return "Неоновый мегаполис"
		_: return "Дорога"

func _update_boost_ui() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if not gm or not boost_button or not boost_label:
		return
		
	if gm.is_boosting:
		boost_label.text = "АКТИВНО!"
		boost_button.disabled = true
		boost_button.modulate = Color(0.3, 1.0, 0.5)
	elif gm.boost_cooldown_remaining > 0.0:
		boost_label.text = "%.1f с" % gm.boost_cooldown_remaining
		boost_button.disabled = true
		boost_button.modulate = Color(0.6, 0.6, 0.6)
	else:
		boost_label.text = "НИТРО (Shift)"
		boost_button.disabled = false
		boost_button.modulate = Color(0.2, 0.8, 1.0)

func _on_shop_pressed() -> void:
	if upgrade_shop:
		upgrade_shop.toggle_visibility()

func _on_portal_pressed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.cycle_dimension()
		_play_dimension_warp_fx()

func _play_dimension_warp_fx() -> void:
	if not warp_flash:
		return
	warp_flash.modulate.a = 0.8
	var tween = create_tween()
	tween.tween_property(warp_flash, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_boost_pressed() -> void:
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.activate_boost()

func _on_jump_pressed() -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("try_jump"):
		player.try_jump()

func _format_number(num: int) -> String:
	if num >= 1_000_000_000:
		return "%.2f B" % (float(num) / 1_000_000_000.0)
	elif num >= 1_000_000:
		return "%.2f M" % (float(num) / 1_000_000.0)
	elif num >= 1_000:
		return "%.1f K" % (float(num) / 1_000.0)
	return str(num)

func _on_boss_spawned(boss_name: String) -> void:
	_show_boss_alert(boss_name)

func _show_boss_alert(boss_name: String) -> void:
	var alert = Label.new()
	alert.text = "⚠️ ВНИМАНИЕ: МИНИ-БОСС %s! ⚠️" % boss_name.to_upper()
	alert.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alert.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	alert.add_theme_font_size_override("font_size", 22)
	alert.add_theme_color_override("font_color", Color(1.0, 0.28, 0.2))
	alert.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.1, 0.95))
	alert.add_theme_constant_override("outline_size", 4)
	
	alert.anchors_preset = Control.PRESET_CENTER_TOP
	alert.position = Vector2(0, 75)
	alert.size = Vector2(1280, 40)
	$RootUI.add_child(alert)
	
	alert.modulate.a = 0.0
	alert.scale = Vector2(0.85, 0.85)
	alert.pivot_offset = Vector2(640, 20)
	
	var tw = create_tween()
	tw.tween_property(alert, "modulate:a", 1.0, 0.22)
	tw.parallel().tween_property(alert, "scale", Vector2(1.1, 1.1), 0.22).set_trans(Tween.TRANS_BACK)
	tw.tween_property(alert, "scale", Vector2(1.0, 1.0), 0.15)
	tw.tween_interval(1.8)
	tw.tween_property(alert, "modulate:a", 0.0, 0.35)
	tw.tween_callback(alert.queue_free)

extends Control
class_name PortalDialog

## Окно межпространственного портала для выбора и перемещения между локациями

signal location_selected(dimension_id: String)

@onready var close_button: Button = $CenterContainer/Panel/Margin/VBox/Header/CloseButton
@onready var locations_container: VBoxContainer = $CenterContainer/Panel/Margin/VBox/Scroll/LocationsContainer

const DIMENSIONS_INFO = [
	{
		"id": "suburb",
		"name": "Пригород",
		"badge": "🏡",
		"desc": "Спокойный ночной пригород. Ровный асфальт, фонари и умеренные противники.",
		"enemies": "Враги: Зеленые слизни, летучие мыши и Голиаф",
		"mult": "1.0x"
	},
	{
		"id": "forest",
		"name": "Древний лес",
		"badge": "🌲",
		"desc": "Заколдованная чаща с лесными тропами, светлячками и древней магией.",
		"enemies": "Враги: Древни, Лесные шершни и Древний Леший",
		"mult": "1.8x"
	},
	{
		"id": "wasteland",
		"name": "Пустошь",
		"badge": "🏜️",
		"desc": "Выжженная каменистая земля под багровым солнцем. Опасные мутанты.",
		"enemies": "Враги: Закаленные пустошью монстры и мутанты",
		"mult": "2.5x"
	},
	{
		"id": "cyber",
		"name": "Неоновый мегаполис",
		"badge": "🏙️",
		"desc": "Сверхтехнологичный киберпанк с неоновыми магистралями и высокими наградами.",
		"enemies": "Враги: Высокотехнологичные кибер-угрозы",
		"mult": "5.0x"
	}
]

func _ready() -> void:
	close_button.pressed.connect(toggle_visibility)
	GameManager.stats_changed.connect(refresh_locations)
	refresh_locations()

func toggle_visibility() -> void:
	visible = not visible
	if visible:
		refresh_locations()

func refresh_locations() -> void:
	if not locations_container:
		return
		
	for child in locations_container.get_children():
		child.queue_free()

	var current = GameManager.current_dimension

	for info in DIMENSIONS_INFO:
		var panel = PanelContainer.new()
		var p_style = StyleBoxFlat.new()
		p_style.bg_color = Color(0.12, 0.14, 0.18, 0.95)
		p_style.corner_radius_bottom_left = 6
		p_style.corner_radius_bottom_right = 6
		p_style.corner_radius_top_left = 6
		p_style.corner_radius_top_right = 6
		
		var is_cur = (info["id"] == current)
		if is_cur:
			p_style.border_color = Color(0.35, 0.95, 0.55)
			p_style.border_width_left = 3
			p_style.border_width_right = 3
			p_style.border_width_top = 3
			p_style.border_width_bottom = 3
		else:
			p_style.border_color = Color(0.24, 0.28, 0.36)
			p_style.border_width_left = 1
			p_style.border_width_right = 1
			p_style.border_width_top = 1
			p_style.border_width_bottom = 1
			
		panel.add_theme_stylebox_override("panel", p_style)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 10)
		panel.add_child(margin)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		margin.add_child(hbox)
		
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 4)
		hbox.add_child(vbox)
		
		# Заголовок локации
		var title_label = Label.new()
		title_label.text = "%s %s  (Награды: %s)" % [info["badge"], info["name"], info["mult"]]
		title_label.add_theme_font_size_override("font_size", 16)
		title_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0) if not is_cur else Color(0.4, 1.0, 0.6))
		vbox.add_child(title_label)
		
		# Описание
		var desc_label = Label.new()
		desc_label.text = info["desc"]
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.72, 0.78))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc_label)

		# Враги
		var enemy_label = Label.new()
		enemy_label.text = info["enemies"]
		enemy_label.add_theme_font_size_override("font_size", 11)
		enemy_label.add_theme_color_override("font_color", Color(0.95, 0.7, 0.4) if info["id"] == "forest" else Color(0.8, 0.65, 0.85))
		vbox.add_child(enemy_label)
		
		# Кнопка перехода
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(130, 42)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		if is_cur:
			btn.text = "ТЕКУЩАЯ"
			btn.disabled = true
		else:
			btn.text = "ВОЙТИ В ПОРТАЛ"
			btn.add_theme_color_override("font_color", Color(0.65, 1.0, 0.85))
			var dim_id = info["id"]
			btn.pressed.connect(func():
				_on_teleport_clicked(dim_id)
			)
		hbox.add_child(btn)
		
		locations_container.add_child(panel)

func _on_teleport_clicked(dim_id: String) -> void:
	location_selected.emit(dim_id)
	visible = false

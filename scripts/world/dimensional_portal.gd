extends Area2D
class_name DimensionalPortal

## Физический объект портала на дороге, в который игрок въезжает на велосипеде

@export var target_dimension: String = "forest"

var anim_phase: float = 0.0
var is_entered: bool = false

var main_color: Color = Color(0.2, 0.95, 0.45)
var core_color: Color = Color(0.85, 1.0, 0.6)
var accent_color: Color = Color(0.1, 0.4, 0.2)
var location_name: String = "Древний лес"

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visuals: Node2D = $Visuals
@onready var title_label: Label = $TitleLabel

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	if visuals:
		visuals.draw.connect(_draw_portal)
	
	# Анимация эффектного материализации портала из разлома
	scale = Vector2(0.05, 0.05)
	modulate.a = 0.0
	var spawn_tw = create_tween()
	spawn_tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	spawn_tw.parallel().tween_property(self, "modulate:a", 1.0, 0.25)

func setup(p_target_dim: String) -> void:
	target_dimension = p_target_dim
	match target_dimension:
		"forest":
			main_color = Color(0.25, 0.95, 0.45)
			core_color = Color(0.8, 1.0, 0.6)
			accent_color = Color(0.1, 0.35, 0.18)
			location_name = "ДРЕВНИЙ ЛЕС"
		"wasteland":
			main_color = Color(1.0, 0.45, 0.15)
			core_color = Color(1.0, 0.9, 0.4)
			accent_color = Color(0.4, 0.15, 0.08)
			location_name = "ПУСТОШЬ"
		"cyber":
			main_color = Color(0.0, 0.85, 1.0)
			core_color = Color(1.0, 0.25, 0.8)
			accent_color = Color(0.05, 0.2, 0.35)
			location_name = "КИБЕРПОЛИС"
		_: # suburb
			main_color = Color(0.75, 0.45, 1.0)
			core_color = Color(1.0, 0.85, 1.0)
			accent_color = Color(0.25, 0.12, 0.35)
			location_name = "ПРИГОРОД"
			
	if title_label:
		title_label.text = "🌀 ПОРТАЛ: " + location_name
		title_label.add_theme_color_override("font_color", main_color)
	
	if visuals:
		visuals.queue_redraw()

func _physics_process(delta: float) -> void:
	if is_entered:
		return

	anim_phase += delta * 5.0
	if visuals:
		visuals.queue_redraw()
	
	# Плавное покачивание вывески над порталом
	if title_label:
		title_label.position.y = -152.0 + sin(anim_phase * 0.8) * 4.0

	# Самоочистка, если игрок уехал далеко вперед и пропустил портал
	var player = get_tree().get_first_node_in_group("player")
	if player and global_position.x < player.global_position.x - 300.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if is_entered:
		return
	if body.is_in_group("player") or body is PlayerBike:
		_trigger_portal_entry(body)

func _on_area_entered(area: Area2D) -> void:
	if is_entered:
		return
	var parent = area.get_parent()
	if parent and (parent.is_in_group("player") or parent is PlayerBike):
		_trigger_portal_entry(parent)

func _trigger_portal_entry(player_node: Node) -> void:
	is_entered = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	# Эффект втягивания и мгновенного гипер-рывка
	if player_node and "velocity" in player_node:
		player_node.velocity.x += 180.0
	
	_apply_camera_shake(9.0)

	# Схлопывание портала при входе
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.5, 0.15), 0.12).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(visuals, "modulate", Color(3.0, 3.0, 3.0, 1.0), 0.1)
	tw.tween_property(self, "scale", Vector2(0.0, 0.0), 0.14)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.14)
	
	tw.tween_callback(func():
		GameManager.change_dimension(target_dimension)
		queue_free()
	)

func _apply_camera_shake(intensity: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("Camera2D"):
		var cam = player.get_node("Camera2D") as Camera2D
		if cam:
			cam.offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
			var tw = create_tween()
			tw.tween_property(cam, "offset", Vector2.ZERO, 0.2)

func _draw_portal() -> void:
	var pulse = 1.0 + sin(anim_phase) * 0.07
	var center_y = -62.0

	# 1. Свечение портала на асфальте / земле
	var ground_w = 48.0 * pulse
	visuals.draw_circle(Vector2(0, 0), ground_w, Color(main_color.r, main_color.g, main_color.b, 0.28))
	visuals.draw_circle(Vector2(0, 0), ground_w * 0.5, Color(core_color.r, core_color.g, core_color.b, 0.45))

	# 2. Внешние колонны портала (портальные кристаллы/арка)
	var pillar_w = 12.0
	var pillar_h = 115.0
	# Левая колонна
	visuals.draw_rect(Rect2(-36, -pillar_h, pillar_w, pillar_h), accent_color, true)
	visuals.draw_rect(Rect2(-36, -pillar_h, pillar_w, pillar_h), main_color, false, 1.5)
	# Правая колонна
	visuals.draw_rect(Rect2(24, -pillar_h, pillar_w, pillar_h), accent_color, true)
	visuals.draw_rect(Rect2(24, -pillar_h, pillar_w, pillar_h), main_color, false, 1.5)
	
	# Верхняя перемычка арки
	visuals.draw_rect(Rect2(-36, -pillar_h - 10, 72, 12), accent_color, true)
	visuals.draw_rect(Rect2(-36, -pillar_h - 10, 72, 12), main_color, false, 1.5)
	
	# Светящийся венчающий камень арки
	visuals.draw_circle(Vector2(0, -pillar_h - 4), 7.0, core_color)
	visuals.draw_circle(Vector2(0, -pillar_h - 4), 13.0, Color(main_color.r, main_color.g, main_color.b, 0.35))

	# 3. Вихревой овал портала (Dimensional Rift)
	var rx = 24.0 * pulse
	var ry = 52.0 * pulse
	
	# Наружное свечение воронки
	_draw_ellipse(Vector2(0, center_y), rx + 6.0, ry + 6.0, Color(main_color.r, main_color.g, main_color.b, 0.35))
	# Основное тело воронки
	_draw_ellipse(Vector2(0, center_y), rx, ry, main_color)
	# Внутреннее яркое ядро
	_draw_ellipse(Vector2(0, center_y), rx * 0.55, ry * 0.55, core_color)

	# 4. Вращающиеся энергетические спирали внутри портала
	for i in range(4):
		var angle = anim_phase * 1.8 + (i * (PI / 2.0))
		var pt_outer = Vector2(cos(angle) * (rx * 0.85), center_y + sin(angle) * (ry * 0.85))
		var pt_inner = Vector2(cos(angle + 0.8) * (rx * 0.25), center_y + sin(angle + 0.8) * (ry * 0.25))
		visuals.draw_line(pt_outer, pt_inner, Color(1.0, 1.0, 1.0, 0.75), 2.0)

	# 5. Рунические огоньки вдоль колонн
	for y_step in range(3):
		var py = -25.0 - (y_step * 35.0)
		var rune_pulse = 0.8 + sin(anim_phase * 2.0 + y_step) * 0.2
		visuals.draw_circle(Vector2(-30, py), 2.5 * rune_pulse, core_color)
		visuals.draw_circle(Vector2(30, py), 2.5 * rune_pulse, core_color)

func _draw_ellipse(pos: Vector2, rad_x: float, rad_y: float, color: Color) -> void:
	var pts: Array[Vector2] = []
	var count = 24
	for i in range(count):
		var a = (float(i) / float(count)) * TAU
		pts.append(pos + Vector2(cos(a) * rad_x, sin(a) * rad_y))
	visuals.draw_colored_polygon(PackedVector2Array(pts), color)

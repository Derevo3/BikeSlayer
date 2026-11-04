extends BaseEnemy
class_name MiniBossEnemy

## Мини-босс для BikeSlayer: огромный бронированный монстр с запасом здоровья и наградой кратно выше обычных монстров

@export var boss_color: Color = Color(0.8, 0.18, 0.22)
@export var armor_color: Color = Color(0.24, 0.26, 0.32)

var anim_phase: float = 0.0
var is_engaged: bool = false

@onready var hp_bar: Node2D = $HealthBarUI
@onready var name_label: Label = $HealthBarUI/NameLabel
@onready var hp_label: Label = $HealthBarUI/HPLabel

func _init() -> void:
	max_health = 140.0
	coins_reward = 50
	souls_reward = 15
	enemy_name = "Голиаф"
	base_speed = 30.0
	flying = false

func _ready() -> void:
	super._ready()
	add_to_group("boss")
	if visuals:
		visuals.draw.connect(_draw_boss)
	if hp_bar:
		hp_bar.draw.connect(_draw_hp_bar)
	_update_hp_display()

func set_engaged(p_engaged: bool) -> void:
	is_engaged = p_engaged
	if is_engaged:
		velocity.x = 0.0

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if is_engaged:
		velocity.x = 0.0
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
	else:
		super._physics_process(delta)

	# Тяжелая покачивающаяся походка / стойка противостояния
	anim_phase += delta * (6.0 if is_engaged else 4.5)
	var stomp = sin(anim_phase)
	if visuals:
		visuals.position.y = -abs(stomp) * (6.0 if is_engaged else 4.0)
		visuals.rotation = stomp * 0.04
		visuals.queue_redraw()

func take_damage(amount: float, hit_pos: Vector2) -> void:
	if is_dead:
		return

	current_health -= amount
	_spawn_damage_number(amount, hit_pos)
	_play_hit_flash()

	# При ударе босс вздрагивает на месте от сокрушительного напора колеса
	velocity.x = 0.0
	if visuals:
		var recoil_tw = create_tween()
		visuals.position.x = 6.0
		recoil_tw.tween_property(visuals, "position:x", 0.0, 0.1)

	_update_hp_display()
	_apply_camera_shake(3.5)

	if current_health <= 0.0:
		die()

func _update_hp_display() -> void:
	if hp_label:
		hp_label.text = "%d / %d" % [max(0, int(round(current_health))), int(round(max_health))]
	if hp_bar:
		hp_bar.queue_redraw()

func _draw_hp_bar() -> void:
	var w = 84.0
	var h = 9.0
	var x = -w / 2.0
	var y = 0.0
	
	# Подложка и рамка
	hp_bar.draw_rect(Rect2(x - 2, y - 2, w + 4, h + 4), Color(0.08, 0.09, 0.12, 0.9), true)
	hp_bar.draw_rect(Rect2(x - 2, y - 2, w + 4, h + 4), Color(0.4, 0.45, 0.55, 0.9), false, 1.5)
	
	# Заполнение здоровья
	var pct = clamp(current_health / max(1.0, max_health), 0.0, 1.0)
	var fill_w = w * pct
	if fill_w > 0.0:
		hp_bar.draw_rect(Rect2(x, y, fill_w, h), Color(0.95, 0.22, 0.25, 1.0), true)
		# Световой блик
		hp_bar.draw_rect(Rect2(x, y, fill_w, 2.5), Color(1.0, 0.65, 0.65, 0.8), true)

func _draw_boss() -> void:
	# 1. Тень под ногами
	visuals.draw_circle(Vector2(0, 0), 32.0, Color(0, 0, 0, 0.35))

	# 2. Массивные ноги / лапы
	var foot_l = PackedVector2Array([Vector2(-26, 0), Vector2(-10, 0), Vector2(-12, -18), Vector2(-24, -18)])
	var foot_r = PackedVector2Array([Vector2(10, 0), Vector2(26, 0), Vector2(24, -18), Vector2(12, -18)])
	visuals.draw_colored_polygon(foot_l, armor_color)
	visuals.draw_colored_polygon(foot_r, armor_color)

	# 3. Мощный торс
	var body_pts = PackedVector2Array([
		Vector2(-28, -62),
		Vector2(28, -62),
		Vector2(32, -40),
		Vector2(26, -16),
		Vector2(-26, -16),
		Vector2(-32, -40)
	])
	visuals.draw_colored_polygon(body_pts, boss_color)

	# 4. Наплечники
	var left_p = PackedVector2Array([Vector2(-26, -60), Vector2(-42, -52), Vector2(-36, -34), Vector2(-24, -42)])
	var right_p = PackedVector2Array([Vector2(26, -60), Vector2(42, -52), Vector2(36, -34), Vector2(24, -42)])
	visuals.draw_colored_polygon(left_p, armor_color)
	visuals.draw_colored_polygon(right_p, armor_color)

	# 5. Шипы на плечах
	visuals.draw_colored_polygon(PackedVector2Array([Vector2(-38, -52), Vector2(-50, -68), Vector2(-28, -58)]), Color(0.15, 0.15, 0.18))
	visuals.draw_colored_polygon(PackedVector2Array([Vector2(38, -52), Vector2(50, -68), Vector2(28, -58)]), Color(0.15, 0.15, 0.18))

	# 6. Рога на голове
	var horn_l = PackedVector2Array([Vector2(-22, -62), Vector2(-36, -82), Vector2(-14, -66)])
	var horn_r = PackedVector2Array([Vector2(22, -62), Vector2(36, -82), Vector2(14, -66)])
	var horn_center = PackedVector2Array([Vector2(-8, -62), Vector2(0, -84), Vector2(8, -62)])
	visuals.draw_colored_polygon(horn_l, Color(0.12, 0.12, 0.15))
	visuals.draw_colored_polygon(horn_r, Color(0.12, 0.12, 0.15))
	visuals.draw_colored_polygon(horn_center, Color(0.16, 0.16, 0.2))

	# 7. Лицевая маска / броня
	var face_p = PackedVector2Array([Vector2(-18, -62), Vector2(18, -62), Vector2(14, -38), Vector2(-14, -38)])
	visuals.draw_colored_polygon(face_p, armor_color)

	# 8. Глаза с яростным прищуром
	visuals.draw_line(Vector2(-14, -49), Vector2(-4, -47), Color(1.0, 0.9, 0.2), 3.0)
	visuals.draw_line(Vector2(4, -47), Vector2(14, -49), Color(1.0, 0.9, 0.2), 3.0)
	visuals.draw_circle(Vector2(-9, -48), 1.8, Color(1, 1, 1))
	visuals.draw_circle(Vector2(9, -48), 1.8, Color(1, 1, 1))

	# 9. Пульсирующий реактор в груди
	var pulse = 0.85 + sin(anim_phase * 6.0) * 0.15
	visuals.draw_circle(Vector2(0, -30), 7.0 * pulse, Color(1.0, 0.35, 0.1))
	visuals.draw_circle(Vector2(0, -30), 4.0 * pulse, Color(1.0, 0.95, 0.4))

	# 10. Таранные клыки/шипы спереди (обращены навстречу велосипеду)
	visuals.draw_colored_polygon(PackedVector2Array([Vector2(-32, -36), Vector2(-48, -30), Vector2(-30, -24)]), Color(0.9, 0.85, 0.8))
	visuals.draw_colored_polygon(PackedVector2Array([Vector2(-32, -26), Vector2(-44, -20), Vector2(-28, -16)]), Color(0.9, 0.85, 0.8))

func _apply_camera_shake(intensity: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("Camera2D"):
		var cam = player.get_node("Camera2D") as Camera2D
		if cam:
			cam.offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
			var tw = create_tween()
			tw.tween_property(cam, "offset", Vector2.ZERO, 0.14)

func die() -> void:
	is_dead = true
	is_engaged = false
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
	set_collision_layer_value(1, false)
	set_collision_layer_value(2, false)

	if hp_bar:
		hp_bar.visible = false

	_apply_camera_shake(7.5)

	# Фонтан из золотых монет при сокрушении босса
	var coin_scene = preload("res://scenes/world/coin.tscn")
	for i in range(10):
		var coin = coin_scene.instantiate()
		coin.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-65, -15))
		get_parent().add_child(coin)

	EventBus.enemy_killed.emit(enemy_name, coins_reward, souls_reward, global_position)

	# Сокрушительная анимация гибели босса
	var tween = create_tween()
	tween.tween_property(visuals, "scale", Vector2(1.7, 0.25), 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(visuals, "modulate", Color(3.0, 1.8, 0.8, 0.0), 0.25)
	tween.tween_callback(queue_free)

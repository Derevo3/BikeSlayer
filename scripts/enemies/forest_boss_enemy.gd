extends BaseEnemy
class_name ForestBossEnemy

## Мини-босс локации "Древний лес": Древний Леший
## Гигантский хранитель леса из векового дуба, увитый лозами и наделенный магией природы

@export var bark_color: Color = Color(0.24, 0.16, 0.10)
@export var moss_color: Color = Color(0.22, 0.55, 0.20)
@export var rune_color: Color = Color(0.3, 0.95, 0.45)

var anim_phase: float = 0.0
var is_engaged: bool = false

@onready var hp_bar: Node2D = $HealthBarUI
@onready var name_label: Label = $HealthBarUI/NameLabel
@onready var hp_label: Label = $HealthBarUI/HPLabel

func _init() -> void:
	max_health = 180.0
	coins_reward = 80
	souls_reward = 25
	enemy_name = "Древний Леший"
	base_speed = 28.0
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

	# Поступь древнего древесного титана
	anim_phase += delta * (5.5 if is_engaged else 4.0)
	var stomp = sin(anim_phase)
	if visuals:
		visuals.position.y = -abs(stomp) * (6.0 if is_engaged else 4.0)
		visuals.rotation = stomp * 0.035
		visuals.queue_redraw()

func take_damage(amount: float, hit_pos: Vector2) -> void:
	if is_dead:
		return

	current_health -= amount
	_spawn_damage_number(amount, hit_pos)
	_play_hit_flash()

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
	
	hp_bar.draw_rect(Rect2(x - 2, y - 2, w + 4, h + 4), Color(0.06, 0.1, 0.06, 0.9), true)
	hp_bar.draw_rect(Rect2(x - 2, y - 2, w + 4, h + 4), Color(0.3, 0.7, 0.4, 0.9), false, 1.5)
	
	var pct = clamp(current_health / max(1.0, max_health), 0.0, 1.0)
	var fill_w = w * pct
	if fill_w > 0.0:
		hp_bar.draw_rect(Rect2(x, y, fill_w, h), Color(0.2, 0.85, 0.35, 1.0), true)
		hp_bar.draw_rect(Rect2(x, y, fill_w, 2.5), Color(0.7, 1.0, 0.7, 0.8), true)

func _draw_boss() -> void:
	# 1. Тень
	visuals.draw_circle(Vector2(0, 0), 34.0, Color(0, 0, 0, 0.35))

	# 2. Мощные корневые лапы
	var foot_l = PackedVector2Array([Vector2(-26, 0), Vector2(-10, 0), Vector2(-12, -20), Vector2(-24, -20)])
	var foot_r = PackedVector2Array([Vector2(10, 0), Vector2(26, 0), Vector2(24, -20), Vector2(12, -20)])
	visuals.draw_colored_polygon(foot_l, bark_color.darkened(0.25))
	visuals.draw_colored_polygon(foot_r, bark_color.darkened(0.25))

	# 3. Торс из дубового ствола
	var body_pts = PackedVector2Array([
		Vector2(-30, -68),
		Vector2(30, -68),
		Vector2(34, -42),
		Vector2(26, -18),
		Vector2(-26, -18),
		Vector2(-34, -42)
	])
	visuals.draw_colored_polygon(body_pts, bark_color)

	# 4. Мховые наплечники и заросли
	visuals.draw_circle(Vector2(-32, -54), 16.0, moss_color)
	visuals.draw_circle(Vector2(32, -54), 16.0, moss_color)
	visuals.draw_circle(Vector2(-24, -30), 10.0, moss_color.darkened(0.15))
	visuals.draw_circle(Vector2(24, -30), 10.0, moss_color.darkened(0.15))

	# 5. Развесистые рога-ветви на голове Лешего
	var horn_l = PackedVector2Array([Vector2(-20, -68), Vector2(-44, -94), Vector2(-36, -82), Vector2(-14, -72)])
	var horn_sub_l = PackedVector2Array([Vector2(-36, -82), Vector2(-48, -78), Vector2(-32, -75)])
	var horn_r = PackedVector2Array([Vector2(20, -68), Vector2(44, -94), Vector2(36, -82), Vector2(14, -72)])
	var horn_sub_r = PackedVector2Array([Vector2(36, -82), Vector2(48, -78), Vector2(32, -75)])
	visuals.draw_colored_polygon(horn_l, bark_color.darkened(0.3))
	visuals.draw_colored_polygon(horn_sub_l, bark_color.darkened(0.3))
	visuals.draw_colored_polygon(horn_r, bark_color.darkened(0.3))
	visuals.draw_colored_polygon(horn_sub_r, bark_color.darkened(0.3))

	# Листья на рогах
	visuals.draw_circle(Vector2(-44, -94), 7.0, moss_color.lightened(0.1))
	visuals.draw_circle(Vector2(44, -94), 7.0, moss_color.lightened(0.1))

	# 6. Резная деревянная маска Лешего
	var mask_p = PackedVector2Array([Vector2(-18, -68), Vector2(18, -68), Vector2(14, -42), Vector2(0, -32), Vector2(-14, -42)])
	visuals.draw_colored_polygon(mask_p, bark_color.lightened(0.15))

	# 7. Светящиеся изумрудные глаза-руны
	visuals.draw_circle(Vector2(-10, -52), 4.5, rune_color)
	visuals.draw_circle(Vector2(-10, -52), 1.8, Color(1, 1, 1))
	visuals.draw_circle(Vector2(10, -52), 4.5, rune_color)
	visuals.draw_circle(Vector2(10, -52), 1.8, Color(1, 1, 1))

	# 8. Пульсирующее Сердце Леса (магический изумруд в груди)
	var pulse = 0.85 + sin(anim_phase * 5.0) * 0.15
	visuals.draw_circle(Vector2(0, -36), 9.0 * pulse, rune_color)
	visuals.draw_circle(Vector2(0, -36), 5.0 * pulse, Color(0.9, 1.0, 0.8))
	visuals.draw_circle(Vector2(0, -36), 14.0 * pulse, Color(rune_color.r, rune_color.g, rune_color.b, 0.2))

	# 9. Клыки из корней на маске
	visuals.draw_line(Vector2(-6, -38), Vector2(-6, -26), Color(0.9, 0.85, 0.7), 2.5)
	visuals.draw_line(Vector2(6, -38), Vector2(6, -26), Color(0.9, 0.85, 0.7), 2.5)

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

	# Фонтан из золота и душ
	var coin_scene = preload("res://scenes/world/coin.tscn")
	var coin_count = 12
	if GameManager.is_boosting:
		var bonus_level = UpgradeManager.get_upgrade("boost_bounty")
		coin_count += 6 * (1 + (bonus_level.level if bonus_level else 0))
	for i in range(coin_count):
		var coin = coin_scene.instantiate()
		coin.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-65, -15))
		get_parent().add_child(coin)

	EventBus.enemy_killed.emit(enemy_name, coins_reward, souls_reward, global_position)

	var tween = create_tween()
	tween.tween_property(visuals, "scale", Vector2(1.7, 0.25), 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(visuals, "modulate", Color(0.4, 2.5, 0.8, 0.0), 0.25)
	tween.tween_callback(queue_free)

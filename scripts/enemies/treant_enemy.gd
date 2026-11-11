extends BaseEnemy
class_name TreantEnemy

## Лесной противник: Древень (оживший лесной пень-голем)
## Медлительный, но крепкий обитатель древнего леса

@export var bark_color: Color = Color(0.28, 0.18, 0.12)
@export var leaves_color: Color = Color(0.2, 0.65, 0.22)
@export var glow_eye_color: Color = Color(1.0, 0.8, 0.15)

var anim_phase: float = 0.0

func _init() -> void:
	max_health = 32.0
	coins_reward = 8
	souls_reward = 3
	enemy_name = "Древень"
	base_speed = 38.0
	flying = false

func _ready() -> void:
	super._ready()
	if visuals:
		visuals.draw.connect(_draw_treant)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead:
		return
	
	# Неуклюжая переваливающаяся походка лесного пня
	anim_phase += delta * 6.5
	var step_wobble = sin(anim_phase)
	if visuals:
		visuals.rotation = step_wobble * 0.08
		visuals.position.y = -abs(sin(anim_phase * 2.0)) * 3.5
		visuals.queue_redraw()

func _draw_treant() -> void:
	# 1. Тень
	visuals.draw_circle(Vector2(0, 0), 16.0, Color(0, 0, 0, 0.3))

	# 2. Корни-ноги
	var root_offset = sin(anim_phase) * 4.0
	var root_l = PackedVector2Array([
		Vector2(-14 + root_offset, 0),
		Vector2(-4 + root_offset, 0),
		Vector2(-6, -10),
		Vector2(-12, -10)
	])
	var root_r = PackedVector2Array([
		Vector2(4 - root_offset, 0),
		Vector2(14 - root_offset, 0),
		Vector2(12, -10),
		Vector2(6, -10)
	])
	visuals.draw_colored_polygon(root_l, bark_color.darkened(0.2))
	visuals.draw_colored_polygon(root_r, bark_color.darkened(0.2))

	# 3. Массивный древесный ствол / тело
	var trunk = PackedVector2Array([
		Vector2(-15, -8),
		Vector2(15, -8),
		Vector2(17, -26),
		Vector2(12, -38),
		Vector2(-12, -38),
		Vector2(-17, -26)
	])
	visuals.draw_colored_polygon(trunk, bark_color)

	# 4. Кора, трещины и кольца древесины
	visuals.draw_line(Vector2(-10, -12), Vector2(-6, -30), bark_color.darkened(0.35), 2.0)
	visuals.draw_line(Vector2(5, -10), Vector2(7, -32), bark_color.darkened(0.35), 2.0)
	visuals.draw_line(Vector2(-3, -18), Vector2(3, -22), bark_color.darkened(0.35), 1.5)

	# 5. Ветки-рога на голове
	var branch_l = PackedVector2Array([Vector2(-10, -38), Vector2(-18, -48), Vector2(-12, -42), Vector2(-7, -38)])
	var branch_r = PackedVector2Array([Vector2(7, -38), Vector2(18, -48), Vector2(12, -42), Vector2(10, -38)])
	visuals.draw_colored_polygon(branch_l, bark_color.darkened(0.15))
	visuals.draw_colored_polygon(branch_r, bark_color.darkened(0.15))

	# 6. Пышная крона листьев и мха на плечах и голове
	visuals.draw_circle(Vector2(-11, -38), 7.0, leaves_color)
	visuals.draw_circle(Vector2(11, -38), 7.0, leaves_color)
	visuals.draw_circle(Vector2(0, -42), 8.5, leaves_color.lightened(0.1))
	visuals.draw_circle(Vector2(-16, -24), 5.5, leaves_color.darkened(0.15))
	visuals.draw_circle(Vector2(16, -24), 5.5, leaves_color.darkened(0.15))

	# 7. Светящиеся янтарные глаза в дупле дерева
	var eye_pulse = 0.9 + sin(anim_phase * 3.0) * 0.1
	visuals.draw_circle(Vector2(-6, -22), 3.2 * eye_pulse, glow_eye_color)
	visuals.draw_circle(Vector2(-6, -22), 1.4, Color(1, 1, 1))
	visuals.draw_circle(Vector2(6, -22), 3.2 * eye_pulse, glow_eye_color)
	visuals.draw_circle(Vector2(6, -22), 1.4, Color(1, 1, 1))

	# 8. Зубастая деревянная пасть-трещина
	var mouth = PackedVector2Array([
		Vector2(-7, -13),
		Vector2(-3, -16),
		Vector2(0, -13),
		Vector2(3, -16),
		Vector2(7, -13),
		Vector2(0, -11)
	])
	visuals.draw_colored_polygon(mouth, Color(0.12, 0.08, 0.05))

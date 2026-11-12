extends BaseEnemy
class_name WaspEnemy

## Лесной летающий противник: Лесной Шершень
## Стремительно парит на высоте прыжка велосипеда, угрожая ядовитым жалом

@export var wasp_yellow: Color = Color(0.95, 0.78, 0.12)
@export var wasp_dark: Color = Color(0.14, 0.12, 0.15)
@export var wing_color: Color = Color(0.7, 0.9, 1.0, 0.55)

var wing_phase: float = 0.0
var base_y: float = 0.0

func _init() -> void:
	max_health = 24.0
	coins_reward = 10
	souls_reward = 4
	enemy_name = "Шершень"
	base_speed = 0.0
	flying = true

func _ready() -> void:
	super._ready()
	base_y = position.y
	if visuals:
		visuals.draw.connect(_draw_wasp)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	var is_world_stopped = player and "velocity" in player and abs(player.velocity.x) < 1.0
	var buzz_mult = 0.35 if is_world_stopped else 1.0
	
	wing_phase += delta * 36.0 * buzz_mult
	# Волнообразное жужжащее парение в воздухе (замирает при остановке мира)
	var amp_y = 3.0 if is_world_stopped else 14.0
	var amp_x = 1.0 if is_world_stopped else 5.0
	position.y = base_y + sin(wing_phase * 0.25) * amp_y + cos(wing_phase * 0.12) * amp_x
	if visuals:
		visuals.queue_redraw()

func _draw_wasp() -> void:
	# 1. Полосатое брюшко (наклон назад)
	var abdomen_pts = PackedVector2Array([
		Vector2(2, -4),
		Vector2(18, -1),
		Vector2(26, 4),
		Vector2(14, 8),
		Vector2(2, 4)
	])
	visuals.draw_colored_polygon(abdomen_pts, wasp_yellow)

	# Полосы на брюшке
	visuals.draw_line(Vector2(8, -3), Vector2(8, 5), wasp_dark, 3.0)
	visuals.draw_line(Vector2(15, -1), Vector2(15, 6), wasp_dark, 3.0)
	visuals.draw_line(Vector2(21, 1), Vector2(21, 5), wasp_dark, 2.5)

	# Острое ядовитое жало сзади
	var stinger = PackedVector2Array([Vector2(24, 3), Vector2(33, 4), Vector2(25, 6)])
	visuals.draw_colored_polygon(stinger, Color(0.1, 0.1, 0.1))

	# 2. Массивная грудь (торакс)
	visuals.draw_circle(Vector2(-4, 0), 9.0, wasp_dark)

	# 3. Голова с фасеточными глазами и усиками
	visuals.draw_circle(Vector2(-14, 0), 7.0, wasp_dark.lightened(0.1))
	# Зловещие красные фасеточные глаза
	visuals.draw_circle(Vector2(-17, -2), 3.0, Color(0.95, 0.15, 0.2))
	visuals.draw_circle(Vector2(-17, -2), 1.2, Color(1.0, 0.8, 0.8))
	# Усики-антенны
	visuals.draw_line(Vector2(-16, -5), Vector2(-23, -13), wasp_dark, 1.8)
	visuals.draw_line(Vector2(-14, -6), Vector2(-19, -15), wasp_dark, 1.8)

	# 4. Лапки осы под брюшком
	visuals.draw_line(Vector2(-6, 7), Vector2(-9, 15), wasp_dark, 1.5)
	visuals.draw_line(Vector2(0, 7), Vector2(2, 16), wasp_dark, 1.5)
	visuals.draw_line(Vector2(8, 7), Vector2(13, 14), wasp_dark, 1.5)

	# 5. Быстро трепещущие полупрозрачные крылья
	var wing_flap = sin(wing_phase) * 16.0
	var wing_fore = PackedVector2Array([
		Vector2(-4, -6),
		Vector2(-18, -26 + wing_flap),
		Vector2(4, -20 + wing_flap * 0.8)
	])
	var wing_hind = PackedVector2Array([
		Vector2(2, -4),
		Vector2(16, -22 + wing_flap * 0.9),
		Vector2(22, -12 + wing_flap * 0.5)
	])
	visuals.draw_colored_polygon(wing_fore, wing_color)
	visuals.draw_colored_polygon(wing_hind, wing_color.darkened(0.1))

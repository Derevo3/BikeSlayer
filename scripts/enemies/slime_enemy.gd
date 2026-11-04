extends BaseEnemy

@export var slime_color: Color = Color(0.2, 0.85, 0.35)
var anim_phase: float = 0.0
var is_red_slime: bool = false

func _init() -> void:
	max_health = 15.0
	coins_reward = 2
	souls_reward = 1
	enemy_name = "Слизень"
	base_speed = 40.0
	flying = false

## Применяет улучшения противника перед спавном
func apply_upgrades() -> void:
	var up = UpgradeManager.get_upgrade("slime_upgrade")
	if up and up.level > 0:
		is_red_slime = true
		slime_color = Color(0.95, 0.16, 0.24) # Кроваво-красный
		enemy_name = "Красный Слизень"
		
		# Красный слизень имеет увеличенное здоровье:
		# Ур 1: 35 HP (было 15) + 15 HP за каждый след. уровень
		max_health = 35.0 + (up.level - 1) * 15.0
		current_health = max_health
		
		# Большая награда:
		# Ур 1: 8 золота (было 2), 3 души (было 1) + доп. награды за уровень
		coins_reward = 8 + (up.level - 1) * 4
		souls_reward = 3 + (up.level - 1) * 2

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead:
		return
	
	# Анимация сжатия и растяжения при ходьбе
	anim_phase += delta * (8.0 if is_red_slime else 7.0)
	var squash = 1.0 + sin(anim_phase) * 0.18
	var stretch = 1.0 - sin(anim_phase) * 0.15
	if visuals:
		visuals.scale = Vector2(stretch, squash)
		visuals.queue_redraw()

func _ready() -> void:
	super._ready()
	if visuals:
		visuals.draw.connect(_draw_slime)

func _draw_slime() -> void:
	# Рисуем тело слизня
	var pts: Array[Vector2] = []
	var count = 16
	var r = 21.0 if is_red_slime else 18.0 # Красный слизень чуть крупнее
	for i in range(count):
		var angle = (float(i) / float(count)) * TAU
		var wobble = 1.0 + sin(angle * 3.0 + anim_phase) * 0.08
		pts.append(Vector2(cos(angle) * r * wobble, sin(angle) * r * wobble - 6.0))
	visuals.draw_colored_polygon(PackedVector2Array(pts), slime_color)
	
	if is_red_slime:
		# Пылающее магматическое ядро внутри красного слизня
		var core_pulse = 0.9 + sin(anim_phase * 2.0) * 0.1
		visuals.draw_circle(Vector2(0, -6), 9.0 * core_pulse, Color(0.7, 0.08, 0.15, 0.75))
		visuals.draw_circle(Vector2(0, -6), 5.0 * core_pulse, Color(1.0, 0.45, 0.15, 0.85))
		
		# Злые светящиеся желтые глаза с красными зрачками
		visuals.draw_circle(Vector2(-6, -11), 4.0, Color(1.0, 0.9, 0.2))
		visuals.draw_circle(Vector2(-7, -11), 2.0, Color(0.7, 0.05, 0.1))
		visuals.draw_circle(Vector2(3, -11), 3.4, Color(1.0, 0.9, 0.2))
		visuals.draw_circle(Vector2(2, -11), 1.7, Color(0.7, 0.05, 0.1))
		
		# Демонические рожки на макушке
		var horn_l = PackedVector2Array([Vector2(-8, -20), Vector2(-13, -28), Vector2(-4, -22)])
		var horn_r = PackedVector2Array([Vector2(4, -22), Vector2(13, -28), Vector2(8, -20)])
		visuals.draw_colored_polygon(horn_l, Color(0.8, 0.1, 0.18))
		visuals.draw_colored_polygon(horn_r, Color(0.8, 0.1, 0.18))
	else:
		# Обычные глаза зеленого слизня
		visuals.draw_circle(Vector2(-6, -10), 3.5, Color(1, 1, 1))
		visuals.draw_circle(Vector2(-8, -10), 1.8, Color(0.1, 0.1, 0.2))
		visuals.draw_circle(Vector2(2, -10), 3.0, Color(1, 1, 1))
		visuals.draw_circle(Vector2(1, -10), 1.5, Color(0.1, 0.1, 0.2))

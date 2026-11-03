extends BaseEnemy

@export var slime_color: Color = Color(0.2, 0.85, 0.35)
var anim_phase: float = 0.0

func _init() -> void:
	max_health = 15.0
	coins_reward = 2
	souls_reward = 1
	enemy_name = "Slime"
	base_speed = 40.0
	flying = false

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead:
		return
	
	# Анимация сжатия и растяжения при ходьбе
	anim_phase += delta * 7.0
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
	var r = 18.0
	for i in range(count):
		var angle = (float(i) / float(count)) * TAU
		var wobble = 1.0 + sin(angle * 3.0 + anim_phase) * 0.08
		pts.append(Vector2(cos(angle) * r * wobble, sin(angle) * r * wobble - 6.0))
	visuals.draw_colored_polygon(PackedVector2Array(pts), slime_color)
	
	# Глазки
	visuals.draw_circle(Vector2(-6, -10), 3.5, Color(1, 1, 1))
	visuals.draw_circle(Vector2(-8, -10), 1.8, Color(0.1, 0.1, 0.2))
	visuals.draw_circle(Vector2(2, -10), 3.0, Color(1, 1, 1))
	visuals.draw_circle(Vector2(1, -10), 1.5, Color(0.1, 0.1, 0.2))

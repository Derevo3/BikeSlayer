extends BaseEnemy

@export var bat_color: Color = Color(0.65, 0.2, 0.8) # Фиолетовый
var wing_anim_phase: float = 0.0
var base_y: float = 0.0

func _init() -> void:
	max_health = 25.0
	coins_reward = 5
	souls_reward = 2
	enemy_name = "Bat"
	base_speed = 0.0
	flying = true

func _ready() -> void:
	super._ready()
	base_y = position.y
	if visuals:
		visuals.draw.connect(_draw_bat)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if is_dead:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	var is_world_stopped = player and "velocity" in player and abs(player.velocity.x) < 1.0
	var flap_mult = 0.4 if is_world_stopped else 1.0
	
	wing_anim_phase += delta * 14.0 * flap_mult
	# Парение вверх-вниз (затухает до легкого зависания при остановке мира)
	var amp = 4.0 if is_world_stopped else 15.0
	position.y = base_y + sin(wing_anim_phase * 0.4) * amp
	if visuals:
		visuals.queue_redraw()

func _draw_bat() -> void:
	# Тело
	visuals.draw_circle(Vector2.ZERO, 10.0, bat_color)
	
	# Глаза
	visuals.draw_circle(Vector2(-3, -2), 2.5, Color(1, 0.9, 0.2))
	visuals.draw_circle(Vector2(3, -2), 2.5, Color(1, 0.9, 0.2))
	
	# Размах крыльев
	var wing_flap = sin(wing_anim_phase) * 12.0
	var left_wing = PackedVector2Array([
		Vector2(-6, 0),
		Vector2(-24, -12 + wing_flap),
		Vector2(-14, 8)
	])
	var right_wing = PackedVector2Array([
		Vector2(6, 0),
		Vector2(24, -12 + wing_flap),
		Vector2(14, 8)
	])
	visuals.draw_colored_polygon(left_wing, bat_color.darkened(0.15))
	visuals.draw_colored_polygon(right_wing, bat_color.darkened(0.15))

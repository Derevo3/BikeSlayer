extends Node2D
class_name GroundChunk

## Чанк бесконечной дороги. Отрисовывает дорогу и окружение в зависимости от локации.

@export var chunk_width: float = 1280.0
@export var road_height: float = 160.0

var coin_scene = preload("res://scenes/world/coin.tscn")

func _ready() -> void:
	_setup_collision()
	_spawn_pickups()
	EventBus.dimension_changed.connect(_on_dimension_changed)

func _on_dimension_changed(_dim_id: String) -> void:
	queue_redraw()

func _setup_collision() -> void:
	var static_body = StaticBody2D.new()
	static_body.collision_layer = 1
	static_body.collision_mask = 0
	
	var col_shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(chunk_width, road_height)
	col_shape.shape = rect
	col_shape.position = Vector2(chunk_width / 2.0, road_height / 2.0)
	
	static_body.add_child(col_shape)
	add_child(static_body)

func _spawn_pickups() -> void:
	# 70% шанс заспавнить группу монет (по земле или аркой для прыжка)
	if randf() < 0.7:
		var pattern_type = randi() % 2
		var start_x = randf_range(150.0, chunk_width - 350.0)
		
		if pattern_type == 0:
			# Линия монет по земле
			for i in range(5):
				var coin = coin_scene.instantiate()
				coin.position = Vector2(start_x + (i * 45.0), -24.0)
				add_child(coin)
		else:
			# Арка монет для прыжка
			var count = 7
			var arc_width = 240.0
			for i in range(count):
				var t = float(i) / float(count - 1)
				var px = start_x + (t * arc_width)
				# Парабола прыжка
				var py = -20.0 - (sin(t * PI) * 110.0)
				var coin = coin_scene.instantiate()
				coin.position = Vector2(px, py)
				add_child(coin)

func _draw() -> void:
	var dim = GameManager.current_dimension
	match dim:
		"forest":
			_draw_forest_ground()
		"wasteland":
			_draw_wasteland_ground()
		"cyber":
			_draw_cyber_ground()
		_:
			_draw_suburb_ground()

func _draw_forest_ground() -> void:
	# 1. Лесная тропа / грунт с мхом
	draw_rect(Rect2(0, 0, chunk_width, road_height), Color(0.18, 0.13, 0.09))
	
	# 2. Мшистый травяной покров обочины
	draw_rect(Rect2(0, 0, chunk_width, 6.0), Color(0.22, 0.48, 0.18))
	draw_rect(Rect2(0, 6, chunk_width, 4.0), Color(0.14, 0.32, 0.12))
	
	# Травинки и кочки по верхнему краю
	var grass_x = 15.0
	while grass_x < chunk_width:
		draw_line(Vector2(grass_x, 0), Vector2(grass_x - 3, -6), Color(0.28, 0.58, 0.22), 2.0)
		draw_line(Vector2(grass_x + 6, 0), Vector2(grass_x + 9, -8), Color(0.32, 0.65, 0.24), 2.0)
		grass_x += 45.0

	# 3. Следы колеи лесной тропы
	var trail_y = 45.0
	var x = 10.0
	while x < chunk_width:
		draw_line(Vector2(x, trail_y), Vector2(min(chunk_width, x + 35.0), trail_y), Color(0.24, 0.18, 0.12, 0.6), 4.0)
		x += 60.0

	# 4. Деревянные резные фонари с волшебными светлячками
	var prop_x = 220.0
	while prop_x < chunk_width:
		_draw_forest_lantern(prop_x)
		prop_x += 460.0

func _draw_forest_lantern(px: float) -> void:
	var base = Vector2(px, 0)
	var top = Vector2(px, -90)
	var arm = top + Vector2(20, -5)
	var lamp = arm + Vector2(0, 15)
	
	# Изогнутый деревянный столб
	draw_line(base, top, Color(0.26, 0.17, 0.11), 4.0)
	draw_line(top, arm, Color(0.26, 0.17, 0.11), 3.0)
	draw_line(arm, lamp, Color(0.2, 0.2, 0.2), 1.5)
	
	# Фонарь с изумрудным/золотым магическим свечением
	draw_circle(lamp, 6.0, Color(0.65, 1.0, 0.35))
	draw_circle(lamp, 14.0, Color(0.65, 1.0, 0.35, 0.22))
	
	# Светящиеся грибочки у подножия столба
	draw_circle(base + Vector2(8, -4), 3.5, Color(0.3, 0.85, 0.9))
	draw_circle(base + Vector2(14, -3), 2.5, Color(0.9, 0.4, 0.7))

func _draw_suburb_ground() -> void:
	# 1. Асфальт (дорожное полотно)
	draw_rect(Rect2(0, 0, chunk_width, road_height), Color(0.14, 0.15, 0.18))
	
	# 2. Бордюр / верхняя кромка обочины
	draw_rect(Rect2(0, 0, chunk_width, 4.0), Color(0.85, 0.85, 0.88))
	draw_rect(Rect2(0, 4, chunk_width, 6.0), Color(0.9, 0.35, 0.2)) # Красно-белые полосы безопасности
	
	# 3. Прерывистая разделительная полоса
	var dash_length = 40.0
	var gap = 30.0
	var y_dash = 50.0
	var x = 10.0
	while x < chunk_width:
		draw_line(Vector2(x, y_dash), Vector2(min(chunk_width, x + dash_length), y_dash), Color(0.9, 0.8, 0.2, 0.85), 3.0)
		x += dash_length + gap
	
	# 4. Фонарные столбы
	var pole_x = 200.0
	while pole_x < chunk_width:
		_draw_street_light(pole_x)
		pole_x += 480.0

func _draw_street_light(px: float) -> void:
	var base = Vector2(px, 0)
	var top = Vector2(px, -110)
	var lamp = top + Vector2(25, 8)
	
	draw_line(base, top, Color(0.25, 0.28, 0.32), 3.5)
	draw_line(top, lamp, Color(0.25, 0.28, 0.32), 2.5)
	
	draw_circle(lamp, 4.5, Color(1.0, 0.95, 0.6))
	draw_circle(lamp, 9.0, Color(1.0, 0.95, 0.6, 0.2))

func _draw_wasteland_ground() -> void:
	draw_rect(Rect2(0, 0, chunk_width, road_height), Color(0.22, 0.12, 0.08))
	draw_rect(Rect2(0, 0, chunk_width, 4.0), Color(0.42, 0.22, 0.15))
	var pole_x = 200.0
	while pole_x < chunk_width:
		draw_line(Vector2(pole_x, 0), Vector2(pole_x, -70), Color(0.3, 0.18, 0.15), 3.0)
		pole_x += 450.0

func _draw_cyber_ground() -> void:
	draw_rect(Rect2(0, 0, chunk_width, road_height), Color(0.05, 0.07, 0.14))
	draw_rect(Rect2(0, 0, chunk_width, 3.0), Color(0.0, 0.9, 1.0, 0.9))
	draw_line(Vector2(0, 45), Vector2(chunk_width, 45), Color(1.0, 0.1, 0.6, 0.6), 2.0)
	var pole_x = 200.0
	while pole_x < chunk_width:
		draw_line(Vector2(pole_x, 0), Vector2(pole_x, -100), Color(0.0, 0.7, 0.9), 2.0)
		draw_circle(Vector2(pole_x, -100), 5.0, Color(1.0, 0.2, 0.7))
		pole_x += 400.0

extends Node2D
class_name GroundChunk

## Чанк бесконечной дороги. Отрисовывает асфальт, разметку, обочину и спавнит дорожные элементы.

@export var chunk_width: float = 1280.0
@export var road_height: float = 160.0

var coin_scene = preload("res://scenes/world/coin.tscn")

func _ready() -> void:
	_setup_collision()
	_spawn_pickups()

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
	
	# 4. Фонарные столбы / ориентиры на обочине
	var pole_x = 200.0
	while pole_x < chunk_width:
		_draw_street_light(pole_x)
		pole_x += 480.0

func _draw_street_light(px: float) -> void:
	var base = Vector2(px, 0)
	var top = Vector2(px, -110)
	var lamp = top + Vector2(25, 8)
	
	# Столб
	draw_line(base, top, Color(0.25, 0.28, 0.32), 3.5)
	draw_line(top, lamp, Color(0.25, 0.28, 0.32), 2.5)
	
	# Плафон и легкое свечение
	draw_circle(lamp, 4.5, Color(1.0, 0.95, 0.6))
	draw_circle(lamp, 9.0, Color(1.0, 0.95, 0.6, 0.2))

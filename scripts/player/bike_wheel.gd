extends Node2D

@export var radius: float = 18.0
@export var rim_color: Color = Color(0.2, 0.22, 0.25)
@export var spoke_color: Color = Color(0.7, 0.75, 0.8)
@export var tire_color: Color = Color(0.12, 0.12, 0.14)
@export var is_front_weapon_wheel: bool = false

func _draw() -> void:
	# Шина (внешний круг)
	draw_circle(Vector2.ZERO, radius + 3.0, tire_color)
	# Обод (rim)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, rim_color, 2.5)
	
	# Спицы (4 крестообразные пары = 8 спиц)
	for i in range(8):
		var angle = (i / 8.0) * TAU
		var end_pt = Vector2(cos(angle), sin(angle)) * radius
		draw_line(Vector2.ZERO, end_pt, spoke_color, 1.2)
	
	# Центральная втулка
	draw_circle(Vector2.ZERO, 4.0, rim_color)
	
	# Если это боевое переднее колесо (таран/лезвия)
	if is_front_weapon_wheel:
		var blade_color = Color(1.0, 0.3, 0.2, 0.8)
		for i in range(4):
			var a = (i / 4.0) * TAU + 0.2
			var p1 = Vector2(cos(a), sin(a)) * (radius + 2.0)
			var p2 = Vector2(cos(a + 0.25), sin(a + 0.25)) * (radius + 8.0)
			var p3 = Vector2(cos(a + 0.3), sin(a + 0.3)) * (radius + 1.0)
			draw_colored_polygon(PackedVector2Array([p1, p2, p3]), blade_color)

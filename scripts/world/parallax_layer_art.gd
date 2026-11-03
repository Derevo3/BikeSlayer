extends Node2D

@export_enum("sky", "mountains", "hills") var layer_type: String = "mountains"
@export var width: float = 1280.0
@export var height: float = 720.0

func _ready() -> void:
	EventBus.dimension_changed.connect(_on_dimension_changed)

func _on_dimension_changed(_dim_id: String) -> void:
	queue_redraw()

func _draw() -> void:
	var dim = GameManager.current_dimension
	match layer_type:
		"sky":
			_draw_sky(dim)
		"mountains":
			_draw_mountains(dim)
		"hills":
			_draw_hills(dim)

func _draw_sky(dim: String) -> void:
	var c_top: Color
	var c_mid: Color
	var c_bot: Color
	var sun_color: Color
	
	match dim:
		"wasteland":
			c_top = Color(0.16, 0.05, 0.06)
			c_mid = Color(0.36, 0.12, 0.10)
			c_bot = Color(0.58, 0.22, 0.12)
			sun_color = Color(1.0, 0.25, 0.2)
		"cyber":
			c_top = Color(0.04, 0.03, 0.12)
			c_mid = Color(0.12, 0.05, 0.24)
			c_bot = Color(0.05, 0.25, 0.35)
			sun_color = Color(1.0, 0.15, 0.6)
		_: # suburb
			c_top = Color(0.08, 0.08, 0.18)
			c_mid = Color(0.22, 0.14, 0.30)
			c_bot = Color(0.48, 0.22, 0.35)
			sun_color = Color(1.0, 0.55, 0.2)

	var points = PackedVector2Array([
		Vector2(0, -height),
		Vector2(width, -height),
		Vector2(width, height * 0.5),
		Vector2(0, height * 0.5)
	])
	draw_polygon(points, PackedColorArray([c_top, c_top, c_mid, c_bot]))
	
	# Светило (Солнце / Луна / Неоновое солнце)
	draw_circle(Vector2(width * 0.7, -180), 45.0, sun_color)
	draw_circle(Vector2(width * 0.7, -180), 55.0, Color(sun_color.r, sun_color.g, sun_color.b, 0.25))

func _draw_mountains(dim: String) -> void:
	var color: Color
	match dim:
		"wasteland": color = Color(0.18, 0.08, 0.08)
		"cyber": color = Color(0.08, 0.10, 0.22)
		_: color = Color(0.16, 0.12, 0.24)

	var pts: Array[Vector2] = [Vector2(0, 100)]
	var x = 0.0
	var step = 80.0
	while x <= width + step:
		var peak_h = sin(x * 0.005) * 80.0 + cos(x * 0.02) * 50.0 - 140.0
		pts.append(Vector2(x, peak_h))
		x += step
	pts.append(Vector2(width, 100))
	draw_colored_polygon(PackedVector2Array(pts), color)

func _draw_hills(dim: String) -> void:
	var color: Color
	var tree_color: Color
	match dim:
		"wasteland":
			color = Color(0.14, 0.08, 0.07)
			tree_color = Color(0.08, 0.05, 0.05)
		"cyber":
			color = Color(0.06, 0.12, 0.18)
			tree_color = Color(0.0, 0.8, 0.9, 0.6)
		_:
			color = Color(0.10, 0.10, 0.18)
			tree_color = Color(0.07, 0.08, 0.14)

	var pts: Array[Vector2] = [Vector2(0, 100)]
	var x = 0.0
	var step = 50.0
	while x <= width + step:
		var h = sin(x * 0.008) * 35.0 - 55.0
		pts.append(Vector2(x, h))
		x += step
	pts.append(Vector2(width, 100))
	draw_colored_polygon(PackedVector2Array(pts), color)

	# Элементы силуэта (деревья или кибер-вышки)
	for tree_x in range(40, int(width), 110):
		var ty = sin(tree_x * 0.008) * 35.0 - 55.0
		if dim == "cyber":
			# Антенны / неоновые вышки
			draw_line(Vector2(tree_x, ty), Vector2(tree_x, ty - 40), tree_color, 2.0)
			draw_circle(Vector2(tree_x, ty - 40), 3.0, Color(1, 0.2, 0.6))
		else:
			var p1 = Vector2(tree_x, ty - 30)
			var p2 = Vector2(tree_x - 12, ty)
			var p3 = Vector2(tree_x + 12, ty)
			draw_colored_polygon(PackedVector2Array([p1, p2, p3]), tree_color)

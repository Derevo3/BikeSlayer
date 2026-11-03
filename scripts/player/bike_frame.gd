extends Node2D

@export var frame_color: Color = Color(0.95, 0.25, 0.15) # Яркий спортивный красный
@export var rider_color: Color = Color(0.18, 0.2, 0.25) # Темный костюм райдера
@export var helmet_color: Color = Color(1.0, 0.8, 0.2) # Золотисто-желтый шлем

func _draw() -> void:
	# Координаты ключевых узлов велосипеда (относительно центра между колес):
	var back_hub = Vector2(-28, 0)
	var front_hub = Vector2(28, 0)
	var bottom_bracket = Vector2(-4, 0) # каретка с педалями
	var seat_post = Vector2(-14, -26) # подседельный узел
	var head_tube = Vector2(18, -28) # рулевой стакан
	var handlebar = Vector2(20, -36) # руль
	var saddle = Vector2(-16, -30) # седло
	
	# 1. Задний треугольник рамы (дропаут -> каретка -> седло -> дропаут)
	draw_line(back_hub, bottom_bracket, frame_color, 3.5)
	draw_line(bottom_bracket, seat_post, frame_color, 4.0)
	draw_line(seat_post, back_hub, frame_color, 3.0)
	
	# 2. Передний треугольник (каретка -> рулевой стакан -> седло)
	draw_line(bottom_bracket, head_tube, frame_color, 4.0)
	draw_line(seat_post, head_tube, frame_color, 3.5)
	
	# 3. Вилка переднего колеса
	draw_line(head_tube, front_hub, frame_color, 3.5)
	
	# 4. Вынос и руль
	draw_line(head_tube, handlebar, Color(0.2, 0.2, 0.25), 3.0)
	draw_circle(handlebar, 3.0, Color(0.1, 0.1, 0.15))
	
	# 5. Седло
	draw_line(saddle + Vector2(-6, 0), saddle + Vector2(6, 0), Color(0.1, 0.1, 0.15), 5.0)

	# 6. Силуэт райдера (гонщика)
	var pelvis = saddle + Vector2(0, -6)
	var shoulder = head_tube + Vector2(-8, -18)
	var head = shoulder + Vector2(6, -12)
	
	# Торс в динамичном наклоне
	draw_line(pelvis, shoulder, rider_color, 7.0)
	
	# Руки (плечо -> локоть -> руль)
	var elbow = shoulder + Vector2(10, 4)
	draw_line(shoulder, elbow, rider_color, 4.0)
	draw_line(elbow, handlebar, rider_color, 3.5)
	
	# Ноги (бедро -> колено -> педали)
	var knee = pelvis + Vector2(12, 10)
	draw_line(pelvis, knee, rider_color, 5.0)
	draw_line(knee, bottom_bracket, rider_color, 4.0)
	
	# Шлем / голова
	draw_circle(head, 7.0, helmet_color)
	# Визор / маска шлема
	draw_line(head + Vector2(2, 0), head + Vector2(7, 2), Color(0.1, 0.8, 1.0), 3.0)

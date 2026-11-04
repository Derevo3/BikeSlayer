extends Node2D

@export var frame_color: Color = Color(0.95, 0.25, 0.15) # Яркий спортивный красный
@export var rider_color: Color = Color(0.18, 0.2, 0.25) # Темный костюм райдера
@export var helmet_color: Color = Color(1.0, 0.8, 0.2) # Золотисто-желтый шлем

var is_tailwhip: bool = false
var whip_angle: float = 0.0

## Вычисляет 3D-проекцию вращающейся вокруг рулевого стакана точки
func get_whip_pt(rel_x: float, rel_y: float, phi: float) -> Dictionary:
	var x_rot = rel_x * cos(phi)
	# z_rot > 0: точка смещается вперед к камере (3D глубина)
	var z_rot = -rel_x * sin(phi)
	var p = 1.0 + (z_rot / 55.0) * 0.38 # Масштаб перспективы
	var y_proj = (rel_y + z_rot * 0.24) * p
	var x_proj = x_rot * p
	return {
		"pos": Vector2(18.0 + x_proj, -28.0 + y_proj),
		"z": z_rot,
		"p": p
	}

func _draw() -> void:
	if is_tailwhip:
		_draw_footjam_tailwhip()
	else:
		_draw_normal_bike()

func _draw_normal_bike() -> void:
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

func _draw_footjam_tailwhip() -> void:
	var hub_info = get_whip_pt(-46.0, 28.0, whip_angle)
	var is_in_front = hub_info.z >= 0.0
	
	# Если задняя часть рамы сзади персонажа (Z < 0), рисуем ее ПОД райдером
	if not is_in_front:
		_draw_rotating_rear_frame(whip_angle, false)
	
	# Передняя опора и райдер в трюке Footjam
	_draw_front_and_rider_footjam()
	
	# Если задняя часть рамы спереди (Z > 0, вращается в сторону камеры), рисуем ПОВЕРХ райдера
	if is_in_front:
		_draw_rotating_rear_frame(whip_angle, true)

func _draw_rotating_rear_frame(phi: float, in_front: bool) -> void:
	var head_tube = Vector2(18, -28)
	var bb = get_whip_pt(-22.0, 28.0, phi)
	var seat = get_whip_pt(-32.0, 2.0, phi)
	var saddle = get_whip_pt(-34.0, -2.0, phi)
	var hub = get_whip_pt(-46.0, 28.0, phi)
	
	# 3D глубина и освещение: ближе к камере — ярче и толще, дальше — глубже и темнее
	var col = frame_color.lightened(0.15) if in_front else frame_color.darkened(0.3)
	var saddle_col = Color(0.12, 0.12, 0.18) if in_front else Color(0.06, 0.06, 0.09)
	var p = bb.p
	
	# Трубы задней рамы в 3D
	draw_line(head_tube, seat.pos, col, 3.6 * seat.p)
	draw_line(head_tube, bb.pos, col, 4.2 * p)
	draw_line(seat.pos, bb.pos, col, 3.6 * p)
	draw_line(bb.pos, hub.pos, col, 3.8 * hub.p)
	draw_line(seat.pos, hub.pos, col, 3.2 * hub.p)
	
	# Седло
	draw_line(saddle.pos + Vector2(-6 * saddle.p, 0), saddle.pos + Vector2(6 * saddle.p, 0), saddle_col, 5.5 * saddle.p)
	
	# Педаль / каретка
	draw_circle(bb.pos, 3.8 * p, Color(0.15, 0.15, 0.2))

func _draw_front_and_rider_footjam() -> void:
	var front_hub = Vector2(28, 0)
	var head_tube = Vector2(18, -28)
	var handlebar = Vector2(20, -36)
	
	# 1. Зафиксированная передняя вилка, стакан и руль
	draw_line(head_tube, front_hub, frame_color, 3.8)
	draw_line(head_tube, handlebar, Color(0.2, 0.2, 0.25), 3.2)
	draw_circle(handlebar, 3.2, Color(0.1, 0.1, 0.15))
	
	# 2. Райдер в трюке Footjam:
	# Руки держат руль с упором
	var shoulder = Vector2(10, -42)
	var elbow = Vector2(18, -39)
	draw_line(shoulder, elbow, rider_color, 4.4)
	draw_line(elbow, handlebar, rider_color, 3.8)
	
	# Торс наклонен над рулем для баланса на переднем колесе
	var pelvis = Vector2(4, -34)
	draw_line(pelvis, shoulder, rider_color, 7.5)
	
	# Голова и шлем
	var head = Vector2(14, -54)
	draw_circle(head, 7.0, helmet_color)
	draw_line(head + Vector2(2, 0), head + Vector2(7, 2), Color(0.1, 0.8, 1.0), 3.0)
	
	# Опорная нога (Footjam): нога заклинена прямо в передней покрышке / вилке!
	var knee_jam = Vector2(17, -24)
	var foot_jam = Vector2(24, -14) # упор стопы в переднее колесо
	draw_line(pelvis, knee_jam, rider_color, 5.2)
	draw_line(knee_jam, foot_jam, rider_color, 4.4)
	draw_line(foot_jam + Vector2(-2, 0), foot_jam + Vector2(4, 1), Color(0.1, 0.1, 0.15), 4.5) # кроссовок
	
	# Вторая нога (задающая импульс трюку / в воздухе)
	var knee_whip = Vector2(0, -22)
	var foot_whip = Vector2(-6, -16)
	draw_line(pelvis, knee_whip, rider_color.darkened(0.15), 4.6)
	draw_line(knee_whip, foot_whip, rider_color.darkened(0.15), 3.8)

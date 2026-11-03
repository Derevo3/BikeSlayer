extends Area2D
class_name CoinPickup

## Подбираемая монета. При приближении плавно притягивается к велосипеду магнитом

@export var value: int = 1
var target_player: Node2D = null
var magnet_speed: float = 0.0
var spin_time: float = 0.0
var is_collected: bool = false

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body is PlayerBike or body.is_in_group("player"):
		collect()

func _on_area_entered(area: Area2D) -> void:
	if is_collected:
		return
	# Игрок вошел в радиус магнита
	if area.name == "CoinCollector":
		magnetize_to(area.get_parent())
	elif area.get_parent() is PlayerBike or area.get_parent().is_in_group("player"):
		magnetize_to(area.get_parent())

func magnetize_to(player: Node2D) -> void:
	if is_collected or target_player:
		return
	target_player = player
	var player_speed = player.velocity.x if ("velocity" in player and player.velocity.x > 0.0) else 300.0
	magnet_speed = max(450.0, player_speed + 150.0)

func _physics_process(delta: float) -> void:
	spin_time += delta * 5.0
	queue_redraw()
	
	if target_player and not is_collected:
		magnet_speed += delta * 1800.0
		var target_pos: Vector2 = target_player.global_position + Vector2(0, -18)
		if "coin_collector" in target_player and target_player.coin_collector:
			target_pos = target_player.coin_collector.global_position
		
		var dist = global_position.distance_to(target_pos)
		var step = magnet_speed * delta
		
		# Если подлетели вплотную к игроку или перелетаем цель — собираем
		if dist <= max(32.0, step):
			collect()
		else:
			global_position = global_position.move_toward(target_pos, step)

func collect() -> void:
	if is_collected:
		return
	is_collected = true
	
	set_physics_process(false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	EventBus.coin_collected.emit(value)
	
	# Небольшой эффект всплывания при подборе
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)

func _draw() -> void:
	# Эффект вращения золотой монеты (сплющивание по горизонтали)
	var sx = abs(cos(spin_time))
	var rx = max(2.0, 10.0 * sx)
	var ry = 10.0
	
	# Тень монеты
	draw_ellipse(Vector2(0, 12), 8.0 * sx, 3.0, Color(0, 0, 0, 0.25))
	
	# Внешнее золотое кольцо
	draw_ellipse(Vector2.ZERO, rx, ry, Color(0.95, 0.75, 0.15))
	# Внутреннее ребро
	draw_ellipse(Vector2.ZERO, rx * 0.75, ry * 0.75, Color(1.0, 0.88, 0.3))
	# Блик
	if sx > 0.4:
		draw_line(Vector2(-rx * 0.3, -ry * 0.4), Vector2(rx * 0.3, ry * 0.4), Color(1.0, 1.0, 1.0, 0.7), 2.0)

extends Node2D

@onready var label: Label = $Label

func setup(amount: float, is_critical: bool = false) -> void:
	if not is_node_ready():
		await ready
		
	label.text = str(int(round(amount)))
	if is_critical:
		label.text += "!"
		modulate = Color(1.0, 0.2, 0.1)
		scale = Vector2(1.4, 1.4)
	else:
		modulate = Color(1.0, 0.85, 0.2)
		scale = Vector2(1.0, 1.0)
	
	# Анимация подпрыгивания и затухания
	var tween = create_tween()
	var target_pos = position + Vector2(randf_range(-25, 25), randf_range(-55, -75))
	
	tween.tween_property(self, "position", target_pos, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", scale * 1.25, 0.15)
	tween.tween_property(self, "scale", scale * 0.7, 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

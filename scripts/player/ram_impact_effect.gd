extends Node2D

@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var flash: Node2D = $Flash

func _ready() -> void:
	if particles:
		particles.emitting = true
	
	# Анимация вспышки и кольца удара
	var tween = create_tween()
	flash.scale = Vector2(0.3, 0.3)
	flash.modulate.a = 1.0
	tween.tween_property(flash, "scale", Vector2(1.8, 1.8), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.25)
	
	await get_tree().create_timer(0.4).timeout
	queue_free()

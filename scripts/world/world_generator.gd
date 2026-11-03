extends Node2D
class_name WorldGenerator

## Управляет бесконечным спавном дорожных чанков перед игроком и удалением пройденных

@export var player: Node2D
@export var chunk_scene: PackedScene = preload("res://scenes/world/ground_chunk.tscn")
@export var chunk_width: float = 1280.0
@export var active_chunks_ahead: int = 3
@export var despawn_distance_behind: float = 1500.0

var active_chunks: Array[Node2D] = []
var next_chunk_x: float = -640.0 # Начинаем немного позади стартовой позиции игрока

func _ready() -> void:
	# Спавним начальные чанки, чтобы мир был готов сразу
	for i in range(active_chunks_ahead + 2):
		_spawn_next_chunk()

func _process(_delta: float) -> void:
	if not player:
		return

	# Проверяем, нужно ли заспавнить новый чанк вперед
	var player_x = player.global_position.x
	while next_chunk_x < player_x + (chunk_width * active_chunks_ahead):
		_spawn_next_chunk()

	# Очищаем старые чанки позади игрока
	_cleanup_old_chunks(player_x)

func _spawn_next_chunk() -> void:
	var chunk = chunk_scene.instantiate()
	chunk.position = Vector2(next_chunk_x, 0)
	add_child(chunk)
	active_chunks.append(chunk)
	next_chunk_x += chunk_width

func _cleanup_old_chunks(player_x: float) -> void:
	var threshold = player_x - despawn_distance_behind
	var remaining: Array[Node2D] = []
	
	for chunk in active_chunks:
		# Правый край чанка
		if chunk.position.x + chunk_width < threshold:
			chunk.queue_free()
		else:
			remaining.append(chunk)
			
	active_chunks = remaining

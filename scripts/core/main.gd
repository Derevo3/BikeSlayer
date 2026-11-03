extends Node2D

## Главный контроллер сцены: инициализация связей и игрового цикла

@onready var player: CharacterBody2D = $PlayerBike
@onready var world_generator: Node2D = $WorldGenerator
@onready var enemy_spawner: Node2D = $EnemySpawner
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	player.add_to_group("player")
	world_generator.player = player
	enemy_spawner.player = player
	if hud and "player" in hud:
		hud.player = player

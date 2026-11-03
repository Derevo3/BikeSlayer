extends Node

## Глобальная шина событий для связывания компонентов без жестких зависимостей

signal coin_collected(amount: int)
signal souls_collected(amount: int)
signal enemy_killed(enemy_type: String, coins: int, souls: int, global_pos: Vector2)
signal player_attacked(target_position: Vector2)
signal upgrade_purchased(upgrade_id: String, new_level: int)
signal boost_activated(duration: float)
signal boost_ended()
signal dimension_changed(dimension_id: String)
signal distance_updated(meters: float)

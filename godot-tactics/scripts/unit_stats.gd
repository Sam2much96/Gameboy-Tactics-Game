class_name UnitStats
extends Resource

## Base combat stats for a Unit — pulled out of player_unit.gd/enemy_unit.gd
## and into standalone .tres files (resources/player_stats.tres,
## resources/enemy_stats.tres) instead of being hardcoded numeric literals
## in the scripts. Editable directly in the Inspector, a text editor, or any
## other process that can touch a .tres file, without needing to open or
## edit GDScript at all.

@export var max_hp: int = 10
@export var atk: int = 5
@export var def: int = 2
@export var max_mp: int = 0

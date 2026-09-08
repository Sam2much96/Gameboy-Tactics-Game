class_name EnemyUnit
extends Unit

# Simple enemy: paths toward the player and attacks when adjacent.
# GB's `struct GameCharacter enemy;` (src/main.c) was declared but never
# actually set up or drawn — this stands it up as a real opponent.

enum Dir { DOWN, LEFT, RIGHT, UP }

const STEP_TIME := 0.2

## Base stats loaded from a standalone resource instead of hardcoded here —
## see resources/enemy_stats.tres. @export also lets a specific scene
## instance override it via the Inspector if ever needed, while still
## defaulting to the shared resource file.
@export var stats: UnitStats = preload("res://resources/enemy_stats.tres")

var facing: Dir = Dir.DOWN

func _ready() -> void:
	faction = Faction.ENEMY
	max_hp = stats.max_hp
	atk = stats.atk
	def = stats.def
	max_mp = stats.max_mp
	super._ready()
	frame = facing

func move_along(path: Array[Vector2i]) -> void:
	if path.size() < 2:
		return
	for i in range(1, path.size()):
		var step: Vector2i = path[i]
		var prev: Vector2i = path[i - 1]
		facing = _dir_from_delta(step - prev)
		frame = facing
		grid_pos = step
		var tween := create_tween()
		tween.tween_property(self, "position", grid_to_world(step), STEP_TIME)
		await tween.finished

func face_towards(target: Vector2i) -> void:
	var d := target - grid_pos
	if abs(d.x) >= abs(d.y):
		facing = Dir.RIGHT if d.x >= 0 else Dir.LEFT
	else:
		facing = Dir.DOWN if d.y >= 0 else Dir.UP
	frame = facing

func _dir_from_delta(d: Vector2i) -> Dir:
	if d.x > 0:
		return Dir.RIGHT
	if d.x < 0:
		return Dir.LEFT
	if d.y > 0:
		return Dir.DOWN
	return Dir.UP

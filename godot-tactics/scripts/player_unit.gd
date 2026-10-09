class_name PlayerUnit
extends Unit

# Mirrors src/characters/player_anim.c's direction/state machine.

enum Dir { DOWN, LEFT, RIGHT, UP }
enum AnimState { IDLE, WALK, ATTACK }

# GB's own player_anim.c currently aliases WALK/ATTACK frames back onto the
# 4 idle frames (WALK_FRAME_COUNT / ATTACK_FRAME_COUNT == 1, both pointing at
# GBTD_IDLE_*) because no extra walk/attack tiles exist yet in player.c. This
# table intentionally does the same rather than inventing frames that aren't
# in the source art — bump this once real walk/attack frames are added to
# 16x16_gameboy_animation.png (frames 4-6 are currently unused/reserved).
const DIR_FRAME := {
	Dir.DOWN: 0,
	Dir.LEFT: 1,
	Dir.RIGHT: 2,
	Dir.UP: 3,
}

const STEP_TIME := 0.2  # ~ GB's MOVE_DELAY (12 frames @ ~60fps)

## Base stats loaded from a standalone resource instead of hardcoded here —
## see resources/player_stats.tres. @export also lets a specific scene
## instance override it via the Inspector if ever needed, while still
## defaulting to the shared resource file.
@export var stats: UnitStats = preload("res://resources/player_stats.tres")

var facing: Dir = Dir.DOWN
var anim_state: AnimState = AnimState.IDLE
var is_moving: bool = false

func _ready() -> void:
	faction = Faction.PLAYER
	max_hp = stats.max_hp
	atk = stats.atk
	def = stats.def
	max_mp = stats.max_mp
	super._ready()
	_apply_frame()

func _apply_frame() -> void:
	frame = DIR_FRAME[facing]

func set_state(state: AnimState) -> void:
	anim_state = state
	_apply_frame()

## Walks one tile at a time along `path` (path[0] must be the unit's current
## cell), updating facing from each step's direction — mirrors main.c's
## move_path_step loop.
func walk_path(path: Array[Vector2i]) -> void:
	if path.size() < 2:
		return
	is_moving = true
	set_state(AnimState.WALK)
	for i in range(1, path.size()):
		var step: Vector2i = path[i]
		var prev: Vector2i = path[i - 1]
		facing = _dir_from_delta(step - prev)
		_apply_frame()
		grid_pos = step
		var tween := create_tween()
		tween.tween_property(self, "position", grid_to_world(step), STEP_TIME)
		await tween.finished
	set_state(AnimState.IDLE)
	is_moving = false

func play_attack() -> void:
	set_state(AnimState.ATTACK)
	await get_tree().create_timer(0.3).timeout
	set_state(AnimState.IDLE)

func face_towards(target: Vector2i) -> void:
	var d := target - grid_pos
	if abs(d.x) >= abs(d.y):
		facing = Dir.RIGHT if d.x >= 0 else Dir.LEFT
	else:
		facing = Dir.DOWN if d.y >= 0 else Dir.UP
	_apply_frame()

func _dir_from_delta(d: Vector2i) -> Dir:
	if d.x > 0:
		return Dir.RIGHT
	if d.x < 0:
		return Dir.LEFT
	if d.y > 0:
		return Dir.DOWN
	return Dir.UP

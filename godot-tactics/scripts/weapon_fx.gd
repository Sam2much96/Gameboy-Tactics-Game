class_name WeaponFx
extends Sprite2D
# Attack-swing effect: a shared prop (not owned by any one unit) that
# battle_manager.gd plays at an attacker's position whenever an attack
# resolves — both the player's and the enemy's.
#
# weapons.png's 8 frames rotate a sword through 45-degree steps (a full
# turn), verified visually: frame 0 = straight down, 2 = straight left,
# 4 = straight up, 6 = straight right, with a diagonal frame between each
# cardinal pair. This used to play all 8 back-to-back as one
# direction-agnostic flourish; now split into 4 non-overlapping 2-frame
# swings, one per cardinal facing — each pair starts at that direction's own
# cardinal frame and arcs into the next diagonal, so the swing actually
# points toward whichever way the attacker is facing.
#
# Dir's DOWN/LEFT/RIGHT/UP ordering (and underlying int values) matches
# PlayerUnit.Dir and EnemyUnit.Dir, so either unit's `facing` can be passed
# straight through as `direction` without translation.

enum Dir { DOWN, LEFT, RIGHT, UP }

const ATTACK_FRAMES := {
	Dir.DOWN: [0, 1],
	Dir.LEFT: [2, 3],
	Dir.UP: [4, 5],
	Dir.RIGHT: [6, 7],
}

const FRAME_TIME := 0.14  # 2 frames -> ~0.28s swing, same total length as the old 8-frame cycle

var _playing: bool = false

func _ready() -> void:
	visible = false
	frame = 0

func play_swing(at_position: Vector2, direction: int) -> void:
	if _playing:
		return
	_playing = true
	position = at_position
	visible = true
	for f in ATTACK_FRAMES[direction]:
		frame = f
		await get_tree().create_timer(FRAME_TIME).timeout
	visible = false
	_playing = false

class_name Unit
extends Sprite2D

# Shared grid-bound character state — mirrors GB's `struct GameCharacter`
# (src/characters/player_character.c) but carries real battle stats, since
# Godot's Sprite2D already renders a 16x16 sprite directly (no need to
# reassemble one from four 8x8 OAM tiles the way the GB build does).

enum Faction { PLAYER, ENEMY }

const CELL_PX := 16

var faction: Faction = Faction.PLAYER

var max_hp: int = 10
var atk: int = 5
var def: int = 2
var max_mp: int = 0

var hp: int
var mp: int

## @export (not a plain var) so each scene instance can carry its own
## starting cell in the Inspector — battle_manager.gd's _ready() runs after
## every unit's own _ready() (children ready before their parent), so by the
## time it looks at grid_pos to lay out the battlefield, each unit has
## already read back whatever was authored here rather than a shared
## hardcoded constant. This is what makes duplicating an EnemyUnit node
## (battle_manager.gd, ## 6) "just work": the duplicate keeps its own
## grid_pos, distinct from the original, instead of both units needing a
## code change to start somewhere different.
@export var grid_pos: Vector2i = Vector2i.ZERO

func _ready() -> void:
	hp = max_hp
	mp = max_mp
	position = grid_to_world(grid_pos)

func grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL_PX + CELL_PX / 2.0, cell.y * CELL_PX + CELL_PX / 2.0)

func is_alive() -> bool:
	return hp > 0

func take_damage(amount: int) -> void:
	hp = max(hp - amount, 0)

const DEFEAT_FLASH_COUNT := 5
const DEFEAT_FLASH_TIME := 0.08

## Battle-ending "you defeated this unit" feedback — flickers the sprite a
## few times, then leaves it hidden. Shared by both PlayerUnit and
## EnemyUnit via battle_manager.gd's _end_battle() (whichever side lost),
## so it lives on the base class rather than either subclass.
func play_defeat() -> void:
	for i in DEFEAT_FLASH_COUNT:
		visible = false
		await get_tree().create_timer(DEFEAT_FLASH_TIME).timeout
		visible = true
		await get_tree().create_timer(DEFEAT_FLASH_TIME).timeout
	visible = false

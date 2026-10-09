class_name BattleManager
extends Node2D

# Turn-based SRPG loop layered on the grid — this is deliberately beyond what
# GB's stub does (main.c's battle menu has a literal `/* TODO: act on
# ui_menu_idx */` and never resolves any combat). Per the user, this is
# fleshed out into a real system: move + MAGIC/ATTACK/END, HP/ATK/DEF/MP,
# a simple enemy AI, and win/lose.

enum TurnState { PLAYER_TURN, BUSY, ENEMY_TURN, GAME_OVER }

const ATTACK_RANGE := 1
const MAGIC_RANGE := 2
const MAGIC_COST := 3
const MAGIC_DAMAGE := 8

## Max tiles either side can move in one turn. A path longer than this gets
## truncated to the first N steps (a partial move toward the clicked/target
## cell) rather than the move being rejected outright — something still
## happens instead of a dead click, matching how most tactics games treat
## an out-of-range destination once you've already committed to a direction.
const PLAYER_MOVE_RANGE := 4
const ENEMY_MOVE_RANGE := 4

const PLAYER_START := Vector2i(2, 2)

@onready var grid_map: TacticsGrid = $TileMap
@onready var player: PlayerUnit = $Player
@onready var weapon_fx: WeaponFx = $Weapon
@onready var ui_panel: UIPanel = $WindowLayer/UI_Menu
@onready var dialogue: DialogueUI = $WindowLayer/Dialogue_UI


# this currently points to the wrong object
@onready var ui_message_label : Label = dialogue._announce_label#ui_panel._message_label
# stores the enemys path in the scene tree for implementing the enemy ai logic on them

## Any number of EnemyUnit siblings under the scene root — not a single
## hardcoded $Enemy — discovered in _ready() rather than @onready-bound to
## one path. This is what lets the scene just be duplicated (Enemy2,
## Enemy3, ...) instead of needing a script change per enemy added.
var enemies: Array[EnemyUnit] = []

var _fade: FadeOverlay
var state: TurnState = TurnState.PLAYER_TURN

func _ready() -> void:
	player.grid_pos = PLAYER_START
	player.position = player.grid_to_world(player.grid_pos)

	for child in get_children():
		if child is EnemyUnit:
			enemies.append(child)

	# Each EnemyUnit's own @export grid_pos (unit.gd) already places it
	# correctly via its own _ready() (children ready before this node does),
	# so normally nothing further is needed here. This only steps in for the
	# one case a scene-authored grid_pos can't cover on its own: a freshly
	# duplicated node that still shares its original's exact grid_pos (Ctrl+D
	# offsets the duplicate's pixel position slightly, but not by a whole
	# grid cell) — nudges it to the nearest free cell instead of silently
	# stacking two units on the same tile.
	var occupied: Array[Vector2i] = [player.grid_pos]
	for e in enemies:
		if not grid_map.is_within_grid(e.grid_pos) or e.grid_pos in occupied:
			e.grid_pos = _find_free_cell(e.grid_pos, occupied)
			e.position = e.grid_to_world(e.grid_pos)
		occupied.append(e.grid_pos)

	_fade = FadeOverlay.new()
	add_child(_fade)
	_fade.snap_opaque()

	grid_map.confirm_pressed.connect(_on_confirm_pressed)
	ui_panel.action_chosen.connect(_on_action_chosen)
	ui_panel.opened.connect(_on_panel_opened)
	ui_panel.closed.connect(_on_panel_closed)

	await _fade.fade_in()

## ui_panel (UIPanel, UI.gd) owns its own open/close input handling — see
## its class doc — so this only reacts to the result: suppress grid input
## for as long as it's open or animating, and refresh its stats display
## with current data right as it opens.
func _on_panel_opened() -> void:
	ui_panel.update_stats(player)
	grid_map.input_enabled = false

func _on_panel_closed() -> void:
	grid_map.input_enabled = true

# consumes the confirm pressed signal from tilemap_gd : 
func _on_confirm_pressed(cell: Vector2i) -> void:
	if state != TurnState.PLAYER_TURN or ui_panel.is_open:
		return
	var path: Array[Vector2i] = grid_map.compute_path_for(player.grid_pos, cell, Enemy._living_enemy_cells(enemies))
	if path.size() < 2:
		return
	var truncated := path.size() - 1 > PLAYER_MOVE_RANGE
	if truncated:
		path = path.slice(0, PLAYER_MOVE_RANGE + 1)
	state = TurnState.BUSY
	grid_map.show_path(path)
	await player.walk_path(path)
	grid_map.clear_path()
	if truncated:
		var from := path[0]
		var to := player.grid_pos
		# "MOVED FROM ... TO ..." rather than "PLAYER MOVED FROM ... TO ..." —
		# fits _announce_label's box on one line (measured: 7px needed vs a
		# 17px-tall box at this font) instead of wrapping to two lines that
		# only just fit with a few px of slack.
		var movement_dialogue : String = "MOVED FROM %d,%d TO %d,%d" % [from.x, from.y, to.x, to.y]
		#dialogue.announce()
		ui_panel.Dialogue.announce(movement_dialogue, ui_message_label, dialogue,get_tree())
		
	if state == TurnState.BUSY:
		state = TurnState.PLAYER_TURN
	# The move is the player's one action-enabling step each turn — open the
	# battle panel automatically right after it lands so Attack/Magic/End
	# turn are one click away, instead of requiring a separate manual
	# menu_toggle press every time.
	ui_panel.open()

func _on_action_chosen(action: String) -> void:
	if state != TurnState.PLAYER_TURN:
		return
	match action:
		"attack":
			_try_player_attack(false)
		"magic":
			_try_player_attack(true)
		"end":
			ui_panel.close()
			#state : int, tree: SceneTree, enemies : Array [EnemyUnit], player: PlayerUnit, grid_map: TacticsGrid, weapon_fx: WeaponFx, battle_mgt : BattleManager
			Enemy._start_enemy_turn(get_tree(),enemies, player,grid_map, weapon_fx,self)

# to do:
# (1) move to a player class

## Closes the panel only once the action actually succeeds — a failed
## attempt (out of range, not enough MP) leaves it open so the player can
## pick something else, matching how battle_menu.gd originally behaved.
##
## With multiple enemies, there's no target-picker UI (out of scope here —
## this is about the turn/combat logic surviving more than one enemy, not a
## new targeting feature), so ATTACK/MAGIC auto-target the nearest living
## enemy, same as most SRPGs default to when a target isn't chosen by hand.
func _try_player_attack(is_magic: bool) -> void:
	var target := Enemy._nearest_enemy(player.grid_pos, enemies)
	if target == null:
		return

	var dist := Utils._distance(player.grid_pos, target.grid_pos)
	var range_limit := MAGIC_RANGE if is_magic else ATTACK_RANGE

	if is_magic and player.mp < MAGIC_COST:
		ui_panel.Dialogue.announce("NOT ENOUGH MP",ui_message_label, dialogue,get_tree())
		return
	if dist > range_limit:
		ui_panel.Dialogue.announce("OUT OF RANGE", ui_message_label, dialogue ,get_tree())
		return

	state = TurnState.BUSY
	player.face_towards(target.grid_pos)
	# weapons.png is a sword — only the physical ATTACK gets the swing effect;
	# MAGIC has no matching art yet, so it keeps just the existing
	# state-hold from play_attack() below rather than showing a sword for a
	# spell.
	if not is_magic:
		weapon_fx.play_swing(player.position, player.facing)
	var damage: int = MAGIC_DAMAGE if is_magic else max(1, player.atk - target.def)
	if is_magic:
		player.mp -= MAGIC_COST
	target.take_damage(damage)

	await player.play_attack()
	ui_panel.update_stats(player)
	ui_panel.close()

	# Reports the effect of the action that was just taken, mirroring the
	# move announcement above — same one-line budget (measured against
	# _announce_label: fits up to ~22 chars at this font/box size).
	var verb := "MAGIC" if is_magic else "ATTACK"
	if target.is_alive():
		var is_alive_text = "%s HIT FOR %d DMG" % [verb, damage]
		# bugs: 
		# (1) I am routing all game dialogue to a single dialogue class subsystem
		ui_panel.Dialogue.announce(is_alive_text, ui_message_label, dialogue, get_tree())
		#dialogue.announce()
	else:
		var enemy_defeated_text = "%s DEFEATED ENEMY" % verb
		#dialogue.announce("%s DEFEATED ENEMY" % verb)
		ui_panel.Dialogue.announce(enemy_defeated_text,ui_message_label,dialogue,get_tree())
		
		# Flashed/hidden right here, at the moment this specific enemy dies,
		# rather than deferred to _end_battle() — with more than one enemy,
		# killing one mid-battle needs its own feedback whether or not it
		# was the last one standing (_end_battle only fires once ALL of them
		# are dead).
		await target.play_defeat()

	if Enemy._all_enemies_defeated(enemies):
		await _end_battle("GAME WON")
		return
	#state : int, tree: SceneTree, enemies : Array [EnemyUnit], player: PlayerUnit, grid_map: TacticsGrid, weapon_fx: WeaponFx, battle_mgt : BattleManager
	Enemy._start_enemy_turn( get_tree(), enemies,player,grid_map,weapon_fx,self)





## Square-ring search outward from `near` for the closest cell not already
## in `occupied` — only ever needed once, in _ready(), to un-stack a freshly
## duplicated enemy that still shares its original's exact grid_pos. Falls
## back to `near` itself if the grid is somehow completely full (never
## happens on a 10x10 board with a handful of units).
func _find_free_cell(near: Vector2i, occupied: Array[Vector2i]) -> Vector2i:
	if grid_map.is_within_grid(near) and near not in occupied:
		return near
	for radius in range(1, grid_map.GRID_SIZE * 2):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if max(abs(dx), abs(dy)) != radius:
					continue
				var c := near + Vector2i(dx, dy)
				if grid_map.is_within_grid(c) and c not in occupied:
					return c
	return near

## defeated is whichever side just hit 0 HP — null for the WON case, since
## with multiple enemies each one already gets flashed/hidden individually
## the moment it dies (_try_player_attack), not deferred to here. The
## GAME OVER case still passes `player` to flash/hide here, since there's
## only ever one player unit. Either way, the result is then announced
## through the Dialogue UI (same as the normal per-hit reports, ## 5b)
## before the scene fades out and returns to the title. Replaces an earlier
## version that flashed the whole screen white immediately on defeat via a
## static ui_panel result label, with no per-unit feedback at all.
func _end_battle(message: String, defeated: Unit = null) -> void:
	state = TurnState.GAME_OVER
	if defeated:
		await defeated.play_defeat()
	await ui_panel.Dialogue.announce(message, ui_message_label, dialogue,get_tree())
	#await dialogue.announce(message)
	
	await _fade.fade_out()
	
	# to do:
	# (1) implement a win and loss screen
	get_tree().change_scene_to_packed(load("res://TItleScreen.tscn"))


class Utils:
	# A separate Utils class for all math helper functions
	
	func a() -> void:
		pass
	static func _distance(a: Vector2i, b: Vector2i) -> int:
		return abs(a.x - b.x) + abs(a.y - b.y)


# to do :
# (1) separate player and enemy ai logic into separate classes (1/2)
class Enemy:
	func a() -> void: 
		pass
	static func _all_enemies_defeated(enemies : Array[EnemyUnit]) -> bool:
		for e in enemies:
			if e.is_alive():
				return false
		return true
	
	## Nearest living enemy to `from` by grid distance (ties broken by array
	## order) — null only if every enemy is already dead, which shouldn't happen
	## mid-battle since _all_enemies_defeated() ends things first.
	static func _nearest_enemy(from: Vector2i, enemies : Array[EnemyUnit]) -> EnemyUnit:
		var nearest: EnemyUnit = null
		var nearest_dist := -1
		for e in enemies:
			if not e.is_alive():
				continue
			var d := Utils._distance(from, e.grid_pos)
			if nearest == null or d < nearest_dist:
				nearest = e
				nearest_dist = d
		return nearest
	
	#1. The function looks at the 4 squares touching the player: above, below, left and right.
	#2. It picks whichever of those is closest to the enemy, so the enemy takes the shortest trip.
	#3. It skips any square that would be off the edge of the board.
	#4. If all 4 squares are off the board, the enemy just stays where it is.
	static func _adjacent_cell_near(target: Vector2i, from: Vector2i, _grid_map: TacticsGrid) -> Vector2i:
		#print_stack() # what processes call this function?
		var candidates := [
			target + Vector2i(1, 0), target + Vector2i(-1, 0),
			target + Vector2i(0, 1), target + Vector2i(0, -1),
		]
		candidates.sort_custom(func(a, b): return Utils._distance(a, from) < Utils._distance(b, from))
		for c in candidates:
			if _grid_map.is_within_grid(c) and c != target:
				return c
		return from
		
	## Grid cells every living enemy occupies, used as pathfinding blockers.
	## `excluding` leaves one specific enemy out of its own list when it's that
	## enemy's turn to path (so it doesn't treat its own current cell as solid).
	static func _living_enemy_cells(enemies : Array[EnemyUnit],excluding: EnemyUnit = null ) -> Array[Vector2i]:
		var cells: Array[Vector2i] = []
		for e in enemies:
			if e.is_alive() and e != excluding:
				cells.append(e.grid_pos)
		return cells
	
	"Enemy AI Logic"
	#1. Not adjacent to the player (_distance > 1) → find the nearest walkable cell next to the player (_adjacent_cell_near), pathfind to it (grid_map.compute_path_for), and move (capped by ENEMY_MOVE_RANGE).
	#2. Adjacent to the player (checked again after moving, in case the move closed the gap) → face the player and attack with a basic melee hit (e.atk - player.def, minimum 1).'''

	## Each living enemy acts once, in array order (the order they were
	## discovered under the scene root in _ready()) — not simultaneously, so two
	## enemies can't both path into the same cell at once. Blockers are
	## recomputed per-enemy (_living_enemy_cells(e) excludes e itself but
	## includes every other still-living enemy plus the player), so earlier
	## enemies in the loop already occupy their new cells by the time a later
	## one paths, the same way the player can't be pathed through either.
	static func _start_enemy_turn( tree: SceneTree, enemies : Array [EnemyUnit], player: PlayerUnit, grid_map: TacticsGrid, weapon_fx: WeaponFx, battle_mgt : BattleManager) -> void:
		battle_mgt.state = TurnState.ENEMY_TURN
		await tree.create_timer(0.3).timeout

		for e in enemies:
			if not e.is_alive():
				continue
			if not player.is_alive():
				break
			if Utils._distance(e.grid_pos, player.grid_pos) > 1:
				var target := _adjacent_cell_near(player.grid_pos, e.grid_pos, grid_map)
				# `+` between a typed Array[Vector2i] and an untyped [x] literal
				# produces an untyped result at runtime and compute_path_for()
				# rejects it (typed-array parameter) — append() instead of
				# concatenating keeps the static type intact.
				var blockers := _living_enemy_cells(enemies,e)
				blockers.append(player.grid_pos)
				var path: Array[Vector2i] = grid_map.compute_path_for(e.grid_pos, target, blockers)
				if path.size() - 1 > ENEMY_MOVE_RANGE:
					path = path.slice(0, ENEMY_MOVE_RANGE + 1)
				if path.size() > 1:
					await e.move_along(path)
			if Utils._distance(e.grid_pos, player.grid_pos) <= 1:
				e.face_towards(player.grid_pos)
				weapon_fx.play_swing(e.position, e.facing)
				player.take_damage(max(1, e.atk - player.def))

		if not player.is_alive():
			await battle_mgt._end_battle("GAME OVER", player)
			return

		battle_mgt.state = TurnState.PLAYER_TURN

class Player:
	func a() -> void:
		pass

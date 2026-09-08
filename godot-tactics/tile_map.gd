class_name TacticsGrid
extends TileMap

# Grid system: cursor + pathfinding.
# Grid dimensions intentionally stay at Godot's existing 10x10 (not GB's 15x15).

const GRID_SIZE := 10
const CELL_PX := 16

const TILE_GRASS := Vector2i(0, 0)
const TILE_CURSOR := Vector2i(9, 0)
const TILE_PATH := Vector2i(18, 0)  # last tile in 16x16_gameboy_tileset_1.png

const CURSOR_REPEAT_DELAY := 0.16  # mirrors GB's INPUT_DELAY key-repeat feel

signal confirm_pressed(cell: Vector2i)
signal cursor_moved(cell: Vector2i)

## Set to false while a menu/UI panel has focus, to suppress grid input —
## mirrors GB's main() only reading d-pad/A for the grid when ui_visible == 0.
var input_enabled: bool = true

var cursor_cell: Vector2i = Vector2i.ZERO
var path_cells: Array[Vector2i] = []

var _astar := AStarGrid2D.new()
var _repeat_timer := 0.0

func _ready() -> void:
	for x in GRID_SIZE:
		for y in GRID_SIZE:
			set_cell(0, Vector2i(x, y), 0, TILE_GRASS, 0)

	_astar.region = Rect2i(0, 0, GRID_SIZE, GRID_SIZE)
	_astar.cell_shape = AStarGrid2D.CELL_SHAPE_SQUARE
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_astar.update()

	_redraw_overlay()

func is_within_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < GRID_SIZE and cell.y < GRID_SIZE

# Every cell is Grass today; keep this hook generic so future terrain types
# (water, walls, ...) only need to change here, mirroring GB's is_walkable().
func is_walkable(cell: Vector2i) -> bool:
	return is_within_grid(cell)

func grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL_PX + CELL_PX / 2.0, cell.y * CELL_PX + CELL_PX / 2.0)

## 4-directional A* from `from` to `to`. `blockers` (other units' occupied
## cells) are temporarily treated as solid so units can't path through each
## other — mirrors GB's is_walkable() callback plus its own occupancy checks.
func compute_path_for(from: Vector2i, to: Vector2i, blockers: Array[Vector2i]) -> Array[Vector2i]:
	if not is_within_grid(from) or not is_within_grid(to):
		return []
	for b in blockers:
		if is_within_grid(b):
			_astar.set_point_solid(b, true)

	var path: Array[Vector2i] = []
	if not _astar.is_point_solid(to):
		path = _astar.get_id_path(from, to)

	for b in blockers:
		if is_within_grid(b):
			_astar.set_point_solid(b, false)
	return path

func show_path(path: Array[Vector2i]) -> void:
	path_cells = path
	_redraw_overlay()

func clear_path() -> void:
	path_cells = []
	_redraw_overlay()

func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseMotion:
		var tile: Vector2i = local_to_map(get_local_mouse_position())
		if is_within_grid(tile):
			_set_cursor(tile)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Clicking a tile both moves the cursor there and confirms it in one
		# action, so a click always does something even if no prior
		# mouse-motion event set the cursor on this tile yet.
		var tile: Vector2i = local_to_map(get_local_mouse_position())
		if is_within_grid(tile):
			_set_cursor(tile)
			confirm_pressed.emit(cursor_cell)
	elif event.is_action_pressed("ui_accept"):
		confirm_pressed.emit(cursor_cell)

func _process(delta: float) -> void:
	if not input_enabled:
		_repeat_timer = 0.0
		return

	var dir := Vector2i.ZERO
	if Input.is_action_pressed("ui_left"):
		dir = Vector2i(-1, 0)
	elif Input.is_action_pressed("ui_right"):
		dir = Vector2i(1, 0)
	elif Input.is_action_pressed("ui_up"):
		dir = Vector2i(0, -1)
	elif Input.is_action_pressed("ui_down"):
		dir = Vector2i(0, 1)

	if dir == Vector2i.ZERO:
		_repeat_timer = 0.0
		return

	var just_pressed := Input.is_action_just_pressed("ui_left") \
		or Input.is_action_just_pressed("ui_right") \
		or Input.is_action_just_pressed("ui_up") \
		or Input.is_action_just_pressed("ui_down")

	if just_pressed:
		_repeat_timer = 0.0
		_try_move_cursor(dir)
		return

	_repeat_timer += delta
	if _repeat_timer >= CURSOR_REPEAT_DELAY:
		_repeat_timer = 0.0
		_try_move_cursor(dir)

func _try_move_cursor(dir: Vector2i) -> void:
	var target := cursor_cell + dir
	if is_within_grid(target):
		_set_cursor(target)

func _set_cursor(cell: Vector2i) -> void:
	if cell == cursor_cell:
		return
	cursor_cell = cell
	cursor_moved.emit(cursor_cell)
	_redraw_overlay()

func _redraw_overlay() -> void:
	for x in GRID_SIZE:
		for y in GRID_SIZE:
			erase_cell(1, Vector2i(x, y))
	for i in range(1, path_cells.size()):
		set_cell(1, path_cells[i], 0, TILE_PATH, 0)
	set_cell(1, cursor_cell, 0, TILE_CURSOR, 0)

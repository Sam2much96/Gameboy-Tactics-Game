# Godot Tactics — API Reference (for porting)

`CODEBASE.md` explains *why* each system exists and how it maps back to the
GBDK/C build. This document is the companion to it: a flat, class-by-class
listing of every field and function in `godot-tactics/*.gd`, so a port to
another engine/language can be done method-by-method without re-reading the
narrative. Read `CODEBASE.md` first for context; use this as the checklist.

Signatures use GDScript's own types. `void` methods that `await` something
internally are marked **(async)** — a port needs the equivalent of a
coroutine/promise there, not a plain synchronous call.

## 1. Class hierarchy

```
Node2D
└─ BattleManager                  scripts/battle_manager.gd

CanvasLayer
└─ FadeOverlay                    fade_overlay.gd

Resource
└─ UnitStats                      scripts/unit_stats.gd

Sprite2D
├─ Unit                           unit.gd
│  ├─ PlayerUnit                  player_unit.gd
│  └─ EnemyUnit                   scripts/enemy_unit.gd
├─ WeaponFx                       scripts/weapon_fx.gd
└─ (title_screen_pointer.gd — no class_name)

TileMap
├─ TacticsGrid                    tile_map.gd
├─ UIPanel                        UI.gd
└─ DialogueUI                     scripts/dialogue.gd

Control
└─ (title_screen.gd — no class_name)
```

Composition (not inheritance): `BattleManager` owns/references one
`TacticsGrid`, one `PlayerUnit`, N `EnemyUnit`, one `WeaponFx`, one
`UIPanel`, one `DialogueUI`, one `FadeOverlay`. Nothing else holds a
reference back to `BattleManager` — every other class only emits signals or
exposes public methods, so `BattleManager` is the single orchestrator. This
is the shape to preserve when porting: one "turn controller" object driving
several independent, unaware-of-each-other subsystems.

---

## 2. `UnitStats` — data only

Plain data resource, no methods. Backs `resources/player_stats.tres` /
`resources/enemy_stats.tres`.

| Field | Type | Default |
|---|---|---|
| `max_hp` | int | 10 |
| `atk` | int | 5 |
| `def` | int | 2 |
| `max_mp` | int | 0 |

Port as a plain struct/dict loaded from whatever data format the target uses
(JSON, YAML, a const table) — no behavior to carry over.

---

## 3. `Unit` (base class)

Shared grid-bound character state for both sides.

**Fields:** `faction: Faction{PLAYER,ENEMY}`, `max_hp/atk/def/max_mp: int`,
`hp/mp: int`, `grid_pos: Vector2i`. `CELL_PX = 16`, `DEFEAT_FLASH_COUNT = 5`,
`DEFEAT_FLASH_TIME = 0.08`.

| Method | Params | Returns | Description |
|---|---|---|---|
| `_ready()` | — | void | Sets `hp = max_hp`, `mp = max_mp`, snaps world position to `grid_pos`. Runs before any parent's `_ready()` (Godot: children ready first) — a port must guarantee the same ordering if start position depends on it. |
| `grid_to_world(cell)` | `Vector2i` | `Vector2` | Cell → pixel center: `cell * CELL_PX + CELL_PX/2`. |
| `is_alive()` | — | `bool` | `hp > 0`. |
| `take_damage(amount)` | `int` | void | `hp = max(hp - amount, 0)`. No death event/signal — callers check `is_alive()` themselves afterward. |
| `play_defeat()` **(async)** | — | void | Flickers visibility off/on `DEFEAT_FLASH_COUNT` times (`DEFEAT_FLASH_TIME` each), ends hidden. Shared by both subclasses so it lives here. |

---

## 4. `PlayerUnit extends Unit`

**Fields:** `stats: UnitStats` (`@export`, preloaded from
`player_stats.tres`), `facing: Dir{DOWN,LEFT,RIGHT,UP}`,
`anim_state: AnimState{IDLE,WALK,ATTACK}`, `is_moving: bool`.
`DIR_FRAME` maps `Dir → sprite frame index` (0-3). `STEP_TIME = 0.2`.

| Method | Params | Returns | Description |
|---|---|---|---|
| `_ready()` | — | void | Sets `faction = PLAYER`, copies `max_hp/atk/def/max_mp` from `stats`, calls `super._ready()`, applies starting frame. |
| `_apply_frame()` | — | void | `frame = DIR_FRAME[facing]`. |
| `set_state(state)` | `AnimState` | void | Sets `anim_state`, reapplies frame. |
| `walk_path(path)` **(async)** | `Array[Vector2i]` (path[0] = current cell) | void | Steps one grid cell at a time; each step tweens `position` over `STEP_TIME`, updates `facing`/`grid_pos`. Sets `WALK` state on entry, `IDLE` on exit. No-op if `path.size() < 2`. |
| `play_attack()` **(async)** | — | void | `ATTACK` state for 0.3s, then back to `IDLE`. Purely cosmetic — does not deal damage itself. |
| `face_towards(target)` | `Vector2i` | void | Sets `facing` toward `target` (whichever axis has the larger delta wins), reapplies frame. |
| `_dir_from_delta(d)` | `Vector2i` | `Dir` | Cardinal direction from a step delta. |

---

## 5. `EnemyUnit extends Unit`

**Fields:** `stats: UnitStats` (from `enemy_stats.tres`), `facing: Dir`.
`STEP_TIME = 0.2`. No `AnimState` — enemies only ever show a facing frame,
no idle/walk/attack split.

| Method | Params | Returns | Description |
|---|---|---|---|
| `_ready()` | — | void | Same stat-copy pattern as `PlayerUnit._ready()`, sets `faction = ENEMY`. |
| `move_along(path)` **(async)** | `Array[Vector2i]` | void | Same per-step tween loop as `PlayerUnit.walk_path()`, no animation-state bookkeeping. |
| `face_towards(target)` | `Vector2i` | void | Identical logic to `PlayerUnit.face_towards()` — duplicated, not shared, since there's no common mixin for it. |
| `_dir_from_delta(d)` | `Vector2i` | `Dir` | Duplicate of `PlayerUnit`'s version. |

**Porting note:** `move_along`/`face_towards`/`_dir_from_delta` are
byte-for-byte the same logic as their `PlayerUnit` counterparts. Worth
collapsing into one shared method on `Unit` in the ported version rather
than copying the duplication forward.

---

## 6. `TacticsGrid extends TileMap`

Grid rendering, cursor input, and pathfinding — the one system with no
dependency on turn/combat state.

**Fields:** `GRID_SIZE = 10`, `CELL_PX = 16`, tile atlas coords
(`TILE_GRASS`, `TILE_CURSOR`, `TILE_PATH`), `CURSOR_REPEAT_DELAY = 0.16`,
`input_enabled: bool`, `cursor_cell: Vector2i`, `path_cells: Array[Vector2i]`,
internal `_astar: AStarGrid2D`, `_repeat_timer: float`.

**Signals:** `confirm_pressed(cell)`, `cursor_moved(cell)`.

| Method | Params | Returns | Description |
|---|---|---|---|
| `_ready()` | — | void | Paints every cell `TILE_GRASS`, configures the `AStarGrid2D` (4-directional, no diagonals), draws initial overlay. |
| `is_within_grid(cell)` | `Vector2i` | `bool` | Bounds check against `GRID_SIZE`. |
| `is_walkable(cell)` | `Vector2i` | `bool` | Terrain hook — currently just `is_within_grid(cell)` (every cell is grass). Extend here for water/walls/etc. |
| `grid_to_world(cell)` | `Vector2i` | `Vector2` | Same formula as `Unit.grid_to_world` — duplicated, not shared. |
| `compute_path_for(from, to, blockers)` | `Vector2i, Vector2i, Array[Vector2i]` | `Array[Vector2i]` | 4-directional A*. Temporarily marks `blockers` solid, finds path (empty if `to` is itself blocked), then un-marks them. Returns `[]` if `from`/`to` are out of bounds. |
| `show_path(path)` | `Array[Vector2i]` | void | Stores `path_cells`, redraws overlay. |
| `clear_path()` | — | void | Clears `path_cells`, redraws overlay. |
| `_unhandled_input(event)` | `InputEvent` | void | Mouse-move → moves cursor; left-click → moves cursor *and* emits `confirm_pressed`; `ui_accept` → emits `confirm_pressed` at current cursor. Skipped entirely if `input_enabled == false`. |
| `_process(delta)` | `float` | void | Polls arrow keys every frame; first press moves immediately, held press repeats every `CURSOR_REPEAT_DELAY`. Skipped if `input_enabled == false`. |
| `_try_move_cursor(dir)` | `Vector2i` | void | Moves cursor by `dir` if the target cell is in-bounds. |
| `_set_cursor(cell)` | `Vector2i` | void | Updates `cursor_cell`, emits `cursor_moved`, redraws overlay. No-op if unchanged. |
| `_redraw_overlay()` | — | void | Clears layer-1 tiles, redraws `path_cells` + cursor. |

**Porting note:** `compute_path_for` is the only pathfinding entry point
used by `BattleManager` — a port just needs *a* 4-directional A* with
temporary-solid support behind this same signature; Godot's `AStarGrid2D`
itself doesn't need to survive the port.

---

## 7. `UIPanel extends TileMap` (the battle action menu)

Slide-in/out MAGIC/ATTACK/END panel + HP/ATK/DEF/MP display.

**Fields:** `ACTIONS = ["attack","magic","end"]`, `SLIDE_TIME = 0.35`,
`CLICK_FLASH_COLOR`, `CLICK_FLASH_TIME = 0.15`, `is_open: bool`,
`_buttons: Array[Button]` (3, scene-bound), label refs for HP/ATK/DEF/MP,
`_message_label: Label` (built in code).

**Signals:** `opened`, `closed`, `action_chosen(action: String)`.

| Method | Params | Returns | Description |
|---|---|---|---|
| `_ready()` | — | void | Registers the `menu_toggle` input action, matches camera zoom, builds `_message_label`, computes shown/hidden positions, starts hidden, wires each button's `pressed` to `_on_option_pressed`. |
| `_build_message_label()` | — | void | Constructs the one label not scene-authored (the transient "OUT OF RANGE"/"NOT ENOUGH MP" line). |
| `update_stats(player)` | `Unit` | void | Writes `HP x/y`, `ATK x`, `DEF x`, `MP x/y` into the four labels. |
| `flash_message(text)` **(async)** | `String` | void | Shows `text` in `_message_label` for 1s, then clears it. |
| `close()` | — | void | Slides out, only if currently open and not mid-slide. Caller-driven — the panel never auto-closes on a failed action. |
| `open()` | — | void | Slides in, only if currently closed and not mid-slide. |
| `_on_option_pressed(index)` | `int` | void | Announces the button's own label text via `DialogueUI`, flashes the button, emits `action_chosen(ACTIONS[index])`. |
| `_flash_button(button)` | `Button` | void | Tints `button` yellow then tweens back to white. |
| `_match_camera_zoom()` | — | void | Scales this node to match the active `Camera2D`'s zoom (compensates for `CanvasLayer` ignoring camera zoom). |
| `_input(event)` | `InputEvent` | void | Handles `menu_toggle` (Tab) to open/close; consumes the event so Godot's native focus-cycling doesn't also react to Tab. |
| `_slide_in()` **(async)** | — | void | Sets `is_open = true`, emits `opened` *before* the tween finishes, tweens into `_shown_position`, then grabs focus on the first button. |
| `_slide_out()` **(async)** | — | void | Tweens into `_hidden_position`, then hides, sets `is_open = false`, emits `closed`. |
| `_panel_height()` | — | `float` | Reads back the painted tile area's height (× scale) for slide distance. |
| `_ensure_menu_toggle_action()` | — | void | Registers the `menu_toggle` input action bound to Tab, if not already present. |

**Porting note:** `opened`/`closed`/`action_chosen` are the entire contract
`BattleManager` depends on — a port's equivalent widget just needs those
three events and the `open()`/`close()`/`update_stats()`/`flash_message()`
calls; the tile-painted rendering and Tab-vs-focus quirk are Godot-specific
and don't need to survive.

---

## 8. `DialogueUI extends TileMap` (status/announcement bar)

Bottom-of-screen slide-in panel for one-line system messages.

**Fields:** `SLIDE_TIME = 0.35`, `ANNOUNCE_TIME = 1.6`, `BOTTOM_MARGIN = 8.0`,
`is_open: bool`, `_manual_open: bool`, `_sliding: bool`.

| Method | Params | Returns | Description |
|---|---|---|---|
| `_ready()` | — | void | Registers `dialogue_toggle` action, matches camera zoom, computes shown/hidden positions, starts hidden. |
| `_compute_shown_position()` | — | `Vector2` | Anchors the panel so its *painted content's* bottom edge sits `BOTTOM_MARGIN` above the real viewport bottom, reading actual viewport size + painted tile bounds rather than a guessed constant. |
| `announce(text)` **(async)** | `String` | void | Sets the label text, slides in if not already open, holds `ANNOUNCE_TIME`, then slides out — unless `_manual_open` is set, or a newer `announce()` call already replaced the text. |
| `_input(event)` | `InputEvent` | void | Handles `dialogue_toggle` (D) — toggles `_manual_open` and slides accordingly. |
| `_slide_in()` **(async)** | — | void | Same pattern as `UIPanel._slide_in()` minus the signal/focus parts. |
| `_slide_out()` **(async)** | — | void | Same pattern as `UIPanel._slide_out()`. |
| `_panel_height()` | — | `float` | Same idea as `UIPanel._panel_height()`. |
| `_match_camera_zoom()` | — | void | Duplicate of `UIPanel`'s version. |
| `_ensure_dialogue_toggle_action()` | — | void | Registers `dialogue_toggle` bound to D. |

**Porting note:** only `announce(text)` is called from outside this file
(by `BattleManager` and `UIPanel`) — that's the whole surface a port needs
to replicate; the manual-toggle/slide mechanics can be reimplemented however
fits the target UI framework.

---

## 9. `WeaponFx extends Sprite2D` (attack swing effect)

**Fields:** `ATTACK_FRAMES: {Dir: [int,int]}` (2-frame swing per cardinal
direction), `FRAME_TIME = 0.14`, `_playing: bool`.

| Method | Params | Returns | Description |
|---|---|---|---|
| `_ready()` | — | void | Starts hidden, frame 0. |
| `play_swing(at_position, direction)` **(async)** | `Vector2, int` | void | No-op if already playing. Positions itself, shows, steps through the 2 frames for `direction`, then hides. Not awaited by its caller (`BattleManager`) — plays concurrently rather than blocking the turn. |

`Dir` enum values (`DOWN,LEFT,RIGHT,UP` = `0,1,2,3`) are shared by
convention with `PlayerUnit.Dir`/`EnemyUnit.Dir` — a caller's `facing` int
passes straight through as `direction` with no translation. **A port must
preserve this same ordinal mapping** or translate explicitly at the call
site.

---

## 10. `FadeOverlay extends CanvasLayer` (screen transitions)

| Method | Params | Returns | Description |
|---|---|---|---|
| `_ready()` | — | void | Builds a full-screen transparent-white `ColorRect` on layer 100. |
| `snap_opaque()` | — | void | Sets alpha to 1 instantly (no tween). |
| `snap_transparent()` | — | void | Sets alpha to 0 instantly. |
| `fade_out(duration=0.4)` **(async)** | `float` | void | Tweens alpha 0→1. |
| `fade_in(duration=0.4)` **(async)** | `float` | void | Tweens alpha 1→0. |

Fades to **white**, not black/transparent-black — intentional, matches the
GB build's palette-fade endpoint (see `CODEBASE.md ## 7`). Keep this if the
port cares about that visual parity; otherwise it's an arbitrary color
choice.

---

## 11. `BattleManager extends Node2D` — turn/combat orchestrator

This is the class that actually implements "turn-based mechanics" — every
other class above is a subsystem it drives. See `CODEBASE.md ## 6` for the
full narrative; this is the flat method list.

**Fields:** `TurnState{PLAYER_TURN, BUSY, ENEMY_TURN, GAME_OVER}`,
combat constants (`ATTACK_RANGE=1`, `MAGIC_RANGE=2`, `MAGIC_COST=3`,
`MAGIC_DAMAGE=8`, `PLAYER_MOVE_RANGE=4`, `ENEMY_MOVE_RANGE=4`,
`PLAYER_START`), references to `grid_map`, `player`, `weapon_fx`,
`ui_panel`, `dialogue`, `enemies: Array[EnemyUnit]`, `_fade: FadeOverlay`,
`state: TurnState`.

| Method | Params | Returns | Description |
|---|---|---|---|
| `_ready()` **(async)** | — | void | Places `player` at `PLAYER_START`; discovers every `EnemyUnit` child into `enemies`; de-stacks any enemy sharing a cell with something else (`_find_free_cell`); creates and snaps `FadeOverlay` opaque; wires `grid_map`/`ui_panel` signals; fades in. |
| `_on_panel_opened()` | — | void | Refreshes stat display, disables grid input. |
| `_on_panel_closed()` | — | void | Re-enables grid input. |
| `_on_confirm_pressed(cell)` **(async)** | `Vector2i` | void | **Move step.** Ignored outside `PLAYER_TURN` or while the panel is open. Computes a path to `cell` (blocked by all living enemies), truncates it to `PLAYER_MOVE_RANGE` if longer, walks it, announces if truncated, then auto-opens `ui_panel`. |
| `_on_action_chosen(action)` | `String` | void | Dispatches `UIPanel.action_chosen` → `_try_player_attack(false)` / `_try_player_attack(true)` / (close panel + `_start_enemy_turn()`). |
| `_try_player_attack(is_magic)` **(async)** | `bool` | void | **Act step.** Auto-targets `_nearest_enemy`. Validates MP (magic) and range, flashing a rejection message and returning early on failure — panel stays open. On success: faces target, plays swing (physical only), applies damage, plays attack animation, refreshes stats, closes panel, announces the hit/kill, plays the target's defeat animation if it died, then either ends the battle (`_all_enemies_defeated()`) or hands off to `_start_enemy_turn()`. |
| `_start_enemy_turn()` **(async)** | — | void | Each living enemy, in array order: paths adjacent to the player if not already (blocked by every *other* living enemy + the player), then attacks if in range. Breaks early if the player dies mid-loop. Ends in `_end_battle("GAME OVER", player)` or back to `PLAYER_TURN`. |
| `_adjacent_cell_near(target, from)` | `Vector2i, Vector2i` | `Vector2i` | Picks whichever in-bounds cell orthogonally adjacent to `target` is closest to `from`. |
| `_distance(a, b)` | `Vector2i, Vector2i` | `int` | Manhattan distance. |
| `_nearest_enemy(from)` | `Vector2i` | `EnemyUnit?` | Nearest living enemy by Manhattan distance, ties broken by array order; `null` if none alive. |
| `_all_enemies_defeated()` | — | `bool` | True iff every enemy in `enemies` is dead. |
| `_living_enemy_cells(excluding=null)` | `EnemyUnit?` | `Array[Vector2i]` | Every living enemy's `grid_pos`, optionally leaving one out (used when that one is the enemy currently pathing). |
| `_find_free_cell(near, occupied)` | `Vector2i, Array[Vector2i]` | `Vector2i` | Square-ring search outward from `near` for the nearest cell not in `occupied`. Only used once, in `_ready()`, to un-stack a duplicated enemy node. |
| `_end_battle(message, defeated=null)` **(async)** | `String, Unit?` | void | Sets `GAME_OVER`. If `defeated` given, plays its defeat animation. Announces `message` ("GAME WON"/"GAME OVER"), fades out, returns to the title scene. |

### Turn state machine

```
PLAYER_TURN --(move)--> BUSY --(move finishes)--> PLAYER_TURN
PLAYER_TURN --(attack/magic succeeds)--> BUSY --> PLAYER_TURN (or GAME_OVER on win)
PLAYER_TURN --(end turn)--> ENEMY_TURN --> PLAYER_TURN (or GAME_OVER on loss)
any --> GAME_OVER (terminal)
```

`BUSY` exists purely to gate grid/menu input while an animation-driving
`await` is in flight; a port using real async/await or a coroutine
scheduler could fold `BUSY` into "an action is in progress" rather than a
distinct enum value, as long as input stays gated for the same window.

---

## 12. Title-screen scripts (menu only, not part of battle)

Not part of the turn-based system, listed for completeness since they're in
the same project.

### `title_screen.gd extends Control` (no `class_name`)

| Method | Params | Returns | Description |
|---|---|---|---|
| `_ready()` | — | void | Wires each of 3 buttons' `pressed` to `_on_option_chosen`, focuses the first. |
| `_unhandled_input(event)` | `InputEvent` | void | Up/down moves focus between the 3 options; `ui_accept` confirms the focused one. |
| `_on_option_chosen(i)` **(async)** | `int` | void | Option 2 (Multiplayer) does nothing (matches GB). Options 0/1 (Start/Continue) fade out and load `main.tscn` — identical behavior for both, no save system exists. |

### `title_screen_pointer.gd extends Sprite2D` (no `class_name`)

| Method | Params | Returns | Description |
|---|---|---|---|
| `_ready()` | — | void | Sets idle texture, connects `visibility_changed` to update OS mouse-cursor visibility. |
| `_exit_tree()` | — | void | Restores the OS mouse cursor. |
| `_process(delta)` | `float` | void | Skipped if not visible. Follows the mouse (+ `pointer_offset`), swaps texture between idle/clicked based on left-mouse-button state. |
| `_update_mouse_mode()` | — | void | Hides the OS cursor while this node is visible in the tree, shows it otherwise. |

---

## 13. Godot-specific mechanisms to replace when porting

These are the engine features load-bearing enough to need a direct
equivalent in the target — everything else above is plain logic/data:

| Mechanism | Used by | Replace with |
|---|---|---|
| `await`/coroutine functions (`Tween.finished`, `Timer.timeout`) | almost every animated method (`walk_path`, `play_swing`, `announce`, `_slide_in/out`, `_end_battle`, ...) | The target's async/await, promises, or a coroutine/sequencer system — timing behavior (steps finish before the next line runs) is depended on throughout |
| `Tween` (`create_tween().tween_property(...)`) | movement steps, panel slides, fade, button flash | Any interpolation/animation system driving position, color, or alpha over time |
| Signals (`confirm_pressed`, `cursor_moved`, `opened`, `closed`, `action_chosen`) | `TacticsGrid`, `UIPanel` → `BattleManager` | An event/observer/callback system — `BattleManager` never polls, it only reacts |
| `AStarGrid2D` | `TacticsGrid.compute_path_for` | Any 4-directional A* with temporary-solid-cell support |
| `@export` fields (`stats`, `grid_pos`, `pointer_offset`) | `PlayerUnit`, `EnemyUnit`, `Unit`, `title_screen_pointer.gd` | Externally-authored/serialized instance data (level/scene editor fields, or a config file per instance) |
| `@onready` scene-tree lookups (`$Path/To/Node`) | most `_ready()` methods | Explicit references injected/wired at construction time |
| `CanvasLayer` ignoring `Camera2D` zoom (`_match_camera_zoom()` workaround) | `UIPanel`, `DialogueUI` | Only relevant if the target has the same "UI layer ignores world camera zoom" behavior — otherwise this workaround has nothing to port |
| `get_tree().change_scene_to_packed(...)` | `_end_battle`, `_on_option_chosen` | Whatever scene/state transition mechanism the target uses |
| `InputMap.add_action` at runtime (`menu_toggle`, `dialogue_toggle`) | `UIPanel`, `DialogueUI` | Static input bindings are simplest in most other engines — this only exists because Godot's input actions are normally defined in project settings, not code |

# Godot Tactics — Codebase Guide (read against the Game Boy build)

This document explains every script in `godot-tactics/` by walking through what
it does and which part of the GBDK/C build in `src/` it corresponds to. Read it
alongside the actual files — it points at specific functions rather than
repeating their bodies.

## 1. How the two builds relate

`src/` is a real Game Boy ROM built with GBDK: a 15x15 grid tactics demo with a
d-pad cursor, A* pathfinding, a player animation state machine, a slide-in
battle menu, and a title screen — but its battle menu is an unfinished stub
(`main.c` has a literal `/* TODO: act on ui_menu_idx */`) and its enemy
(`struct GameCharacter enemy;` in `main.c`) is declared but never set up.

`godot-tactics/` re-implements the same systems in GDScript, one file per
system, and then **finishes the battle system for real** — HP/ATK/DEF/MP,
an actual opponent, a full turn loop, win/lose — since that's what GB never
got around to. Where GB is silent or incomplete, Godot had to make a design
call; those calls are called out explicitly below and in `## 8`.

Everything in `godot-tactics/*.gd` is flat (no subfolders), matching how the
project was already laid out before this work started.

## 2. File map

| Godot file | GB equivalent(s) | System |
|---|---|---|
| `tile_map.gd` (class `TacticsGrid`) | `src/main.c` (`grid[][]`, `handle_input()`, `draw_cursor()`, `init_overlay()`) + `src/pathfinding/astar.c` | Grid, cursor, pathfinding |
| `unit.gd` (class `Unit`) | `src/characters/player_character.c` (`struct GameCharacter`) | Shared base for any grid-bound character |
| `player_unit.gd` (class `PlayerUnit`) | `src/characters/player.c`, `player_anim.c` | Player movement + animation |
| `scripts/enemy_unit.gd` (class `EnemyUnit`) | `src/main.c`'s unused `enemy` variable | Opponent + simple AI (new — GB never built this) |
| `scripts/unit_stats.gd` (class `UnitStats`) | none — GB's numbers were hardcoded UI text, not data | `Resource` type backing `resources/player_stats.tres`/`enemy_stats.tres` — see `## 4` |
| `scripts/weapon_fx.gd` (class `WeaponFx`) | none — GB has no attack VFX at all | Shared sword-swing effect for both sides' physical attacks — see `## 5b` |
| `UI.gd` (class `UIPanel`) | `src/UI/UI.c`, `ui_text.c`, `ui_pointer.c`, `main.c`'s `UI_ANIM_SHOWING`/`UI_ANIM_HIDING` | Tile-painted MAGIC/ATTACK/END panel — stats, result HUD, real combat wiring — see `## 5` |
| `scripts/dialogue.gd` (class `DialogueUI`) | none — GB has no equivalent ambient status display | Short system announcements (e.g. move-range cap) + manual toggle, both slide from the bottom — see `## 5b` |
| `scripts/battle_manager.gd` (class `BattleManager`) | `src/main.c`'s stub battle-menu handling | Turn loop, movement range, combat math, win/lose (new) |
| `fade_overlay.gd` (class `FadeOverlay`) | `src/main.c` (`fadeout()`, `fadein()`) | Screen transitions |
| `title_screen.gd` | `src/titlescreen/titlescreen.c` (`run_titlescreen()`) | Title menu, keyboard/mouse selection |
| `title_screen_pointer.gd` (`helpers/pointers.tscn`) | `src/UI/ui_pointer.c` (`UIPointer`) | Mouse-following pointer — reused on the title screen *and* in `main.tscn`'s UI panel |
| `Music.tscn` (pre-existing, untouched) | `src/gbt_player.c/.s` (tracker playback engine) | Background music |

`main.tscn` wires `tile_map.gd`, `unit.gd`/`player_unit.gd`/`enemy_unit.gd`,
`UI.gd`, `dialogue.gd`, `weapon_fx.gd`, and `battle_manager.gd` together into
the playable grid. `TItleScreen.tscn` + `title_screen.gd` is the separate
title scene. Character/tile art now lives under `character/`, weapon/item
art under `weapons/`, and most gameplay scripts under `scripts/` — `UI.gd`,
`tile_map.gd`, `unit.gd`, `player_unit.gd`, `fade_overlay.gd`,
`title_screen.gd`, and `title_screen_pointer.gd` are the exceptions still at
the project root. Data resources (currently just the two unit-stats `.tres`
files, `## 4`) live under `resources/`.

## 3. Grid, cursor & pathfinding — `tile_map.gd`

**GB side:** `main.c` keeps a `Cell grid[GRID_SIZE][GRID_SIZE]` (15x15), moves
a cursor sprite with `handle_input()` (d-pad only, with `INPUT_DELAY` repeat),
and finds a route with `pathfinding/astar.c`'s hand-rolled heap-based A*
(`astar_find`), then shows it with `draw_path_tiles()`/`clear_path_tiles()`.

**Godot side (`TacticsGrid`):**
- Grid stays **10x10** (`GRID_SIZE`), not GB's 15x15 — kept as-is per an
  earlier decision to not change the pre-existing Godot grid size.
- `_ready()` fills every cell with `TILE_GRASS` on TileMap layer 0.
- The cursor is **one shared `cursor_cell`**, driven by *both* input paths
  (GB only has the d-pad):
  - Mouse: `_unhandled_input`'s `InputEventMouseMotion` branch calls
    `local_to_map(get_local_mouse_position())`.
  - Keyboard: `_process()` polls `ui_left/right/up/down` every frame, with
    `CURSOR_REPEAT_DELAY` (0.16s) reproducing GB's `INPUT_DELAY` key-repeat
    feel via `_try_move_cursor()`.
- Confirming a destination — GB's A button — is `ui_accept` **or** a left
  mouse click (`InputEventMouseButton`, `MOUSE_BUTTON_LEFT`); a click sets the
  cursor and confirms in the same event, so it works even without a prior
  hover. Both paths emit the `confirm_pressed(cell)` signal; `battle_manager.gd`
  is the only listener and decides what to do with it (see `## 6`).
- Pathfinding uses Godot's built-in `AStarGrid2D` instead of porting GB's
  custom heap A*, with `diagonal_mode = DIAGONAL_MODE_NEVER` to keep the same
  4-directional movement. `compute_path_for(from, to, blockers)` temporarily
  marks `blockers` (the other unit's cell) solid so units can't path through
  each other, mirroring what GB's `is_walkable()` callback plus its own
  occupancy logic would need to do.
- `show_path()` / `clear_path()` draw/erase `TILE_PATH` on layer 1 along the
  route — this is GB's `draw_path_tiles()`/`clear_path_tiles()`. `_redraw_overlay()`
  clears the whole layer-1 grid and redraws path + cursor tiles together,
  same blunt-but-simple approach the original (pre-rewrite) `tile_map.gd` used
  for its mouse-hover highlight.
- `input_enabled` is the equivalent of GB's `if (!ui_visible)` guard around
  grid input in `main()`'s loop — `battle_manager.gd` sets it `false` while the
  battle menu (`UI.gd`, `## 5`) is open.
- `is_walkable()` always returns true today (every cell is grass) but exists
  as an explicit hook — same intent as the `// add TILE_WATER, TILE_MOUNTAIN,
  etc. here later` comment in GB's `main.c`.

**Tile indices** (`TILE_GRASS`, `TILE_CURSOR`, `TILE_PATH`) are atlas
coordinates into `16x16_gameboy_tileset_1.png`, registered one-by-one in
`main.tscn`'s `TileSetAtlasSource` (`N:0/0 = 0` lines — each `N` is an atlas
column that has to be explicitly registered before `set_cell()` can use it).
Current values: grass = tile 0, cursor = tile 9, path highlight = tile 18
(the last tile in the strip, 19 tiles total, indices 0–18).

## 4. Characters — `unit.gd`, `player_unit.gd`, `enemy_unit.gd`

**GB side:** `player_character.c` defines `struct GameCharacter` (sprite IDs +
position only — no stats, since GB's UI numbers were hardcoded). `player.c`
sets up the player's four OAM sprite slots and assembles a 16x16 metasprite
from 8x8 GB tiles (`movegamecharacter()`). `player_anim.c` is a small state
machine: direction (`DIR_DOWN/LEFT/RIGHT/UP`) × state (`ANIM_IDLE/WALK/ATTACK`)
→ a GBTD tile index, applied to OAM via `player_anim_apply()`.

**Godot side:**
- `Unit` (base class, extends `Sprite2D`) is what `struct GameCharacter`
  *would* be if it needed real stats: `hp/max_hp`, `atk`, `def`, `mp/max_mp`,
  `grid_pos`, `faction`. Godot's `Sprite2D` already draws a 16x16 sprite
  natively, so none of GB's four-OAM-tile assembly (`movegamecharacter`,
  `spriteids[4]`) has an equivalent here — that plumbing existed on GB purely
  because the hardware can't otherwise show a 16x16 sprite. Also carries
  `play_defeat()` (new, no GB equivalent — GB's battle menu never resolved
  combat far enough to need a defeat animation): flickers `visible` off/on
  `DEFEAT_FLASH_COUNT` times, ends hidden. Lives here rather than on either
  subclass since both `PlayerUnit` and `EnemyUnit` need it —
  `battle_manager.gd`'s `_end_battle()` (`## 6`) calls it on whichever unit
  just hit 0 HP.
- `PlayerUnit` (extends `Unit`) reimplements `player_anim.c`'s table as
  `DIR_FRAME` (a `Dir → hframe index` dict) plus `set_state()`. **Important:**
  GB's own `WALK_FRAME_COUNT`/`ATTACK_FRAME_COUNT` are both `1`, and both
  point at the same `GBTD_IDLE_*` indices — i.e. GB doesn't actually have
  walk/attack animation frames yet, it just aliases idle. `PlayerUnit` does
  the same on purpose (frames 4–6 of the 7-frame sprite sheet are unused,
  reserved for when real walk/attack art exists on either build).
  - `walk_path()` is GB's `move_path_step` loop in `main()`'s `while(1)`:
    steps one grid cell at a time, using a `Tween` per step (`STEP_TIME =
    0.2s`, standing in for GB's `MOVE_DELAY = 12` frames at ~60fps) instead of
    a per-frame counter, since Godot has coroutines where GB has a state
    machine driven by `wait_vbl_done()`.
  - `play_attack()` and `face_towards()` don't have direct GB equivalents —
    GB's battle menu never got far enough to need them (see `## 6`).
- `EnemyUnit` (extends `Unit`) is the enemy GB *declared* (`struct
  GameCharacter enemy;` in `main.c`) but never initialized, drew, or gave
  behavior to. It reuses the same direction/step-tween pattern as
  `PlayerUnit` but without an animation-state table (no idle/walk/attack
  split — just a facing frame), since GB left nothing to mirror here beyond
  the bare character struct.
- **Stats are data, not code.** `PlayerUnit`/`EnemyUnit` no longer hardcode
  `max_hp`/`atk`/`def`/`max_mp` as literals in `_ready()` — each has
  `@export var stats: UnitStats`, a custom `Resource` type
  (`scripts/unit_stats.gd`) preloaded from a standalone `.tres` file
  (`resources/player_stats.tres`, `resources/enemy_stats.tres`), and
  `_ready()` just copies `stats.max_hp` etc. into the real fields. The
  `.tres` files are plain text and editable directly — in the Inspector, a
  text editor, or any other process — without touching GDScript.
  `@export` also means a specific scene instance can override `stats` with
  a different resource via the Inspector if ever needed, while still
  defaulting to the shared file. No GB equivalent — GB's numbers were
  hardcoded UI text (`ui_write_text()`), not a data structure at all.

## 5. Battle menu — `UI.gd`

**GB side:** `UI/UI.c` is a static 20x18 Window-layer tilemap for the panel
background. `UI/ui_text.c` draws characters onto the Window a cell at a time
(`ui_print`). `UI/ui_pointer.c`'s `UIPointer` is a reusable 16x16 sprite with
a two-frame "flash" animation (`pointer_anim_select`) used both here and on
the title screen. `main.c` slides the panel in/out one Window row per VBL
frame (`UI_ANIM_SHOWING`/`UI_ANIM_HIDING`) and writes MAGIC/ATTACK/END plus
static `HP 10` / `ATK 5` text once, via `ui_write_text()` — numbers that never
change because nothing was ever wired up to update them.

**Godot side:** this used to be two separate, duplicate systems —
`battle_menu.gd` (a code-built `Panel`, the only one actually wired into
combat) and `UI.gd` (a hand-painted `TileMap` panel, closer to GB's real
Window-layer art but purely cosmetic). `battle_menu.gd` and its scene node
are now deleted; `UI.gd` absorbed everything from it that was actually load-
bearing. `WindowLayer/UI_Menu` is a real `TileMap` painted with 8x8 tiles
cut from `16x16_gameboy_tileset_1.png` (`TileSetAtlasSource_efxa6`,
`texture_region_size = Vector2i(8, 8)`), with `Attack`/`Magic`/`End turn`
`Button`s laid out on top via a child `VBoxContainer`.

**Sizing & slide.** `_match_camera_zoom()` sets this node's own `scale` to
match the active `Camera2D`'s zoom (`Vector2(8, 8)` in `main.tscn`) —
needed because `WindowLayer` is a `CanvasLayer`, which renders in raw screen
pixels and ignores the camera's zoom entirely; without this the panel's 8x8
tiles would render at native size next to the zoomed-in grid and look tiny.
The slide then reads its own painted size back with `get_used_rect().size *
tile_set.tile_size` (scaled by the applied `scale.y`) so the distance always
matches whatever's actually drawn, and `menu_toggle` slides the whole node
— tiles and buttons together — between shown/hidden positions with a
`Tween`, mirroring `UI_ANIM_SHOWING`/`HIDING` as a plain slide rather than
GB's row-by-row reveal.

**Signals.** `UIPanel` (this file's `class_name`) emits `opened` the instant
SELECT is pressed (before the slide-in even finishes, so nothing can happen
mid-animation) and `closed` only once fully hidden again, plus
`action_chosen(action: String)` when a button is pressed. `battle_manager.gd`
listens to all three: `opened`/`closed` suppress grid input and refresh the
stats display (`## 6`), `action_chosen` is what actually resolves combat —
this is the wiring `battle_menu.gd` used to own.

**Buttons.** `_buttons` (`$VBoxContainer/{Button,Button2,Button3}`) are
wired to `_on_option_pressed(index)`, one shared handler rather than three
separate ones, matched to `ACTIONS := ["attack", "magic", "end"]` by index.
Every press calls `_dialogue.announce(button.text)` — a direct sibling
reference (`$"../Dialogue_UI"`, `## 5b`) rather than routing through
`battle_manager.gd`, since all that's needed is the button's own display
text at the exact point it's pressed; the `action_chosen` action strings
don't literally match it anyway (`"end"` vs `"End turn"`). An earlier
version used `print_debug(button.text)` here, which only ever showed up in
the editor's Output panel, not in-game — this is what "connect the buttons
to print their names" turned into once that was pointed out. Also flashes
the button (`_flash_button()` tints it `CLICK_FLASH_COLOR` then eases back
to white — a guaranteed-visible click reaction regardless of theme, since
these are `flat = true` buttons) and emits `action_chosen`. **It does not
close itself unconditionally** — `close()` is a public method `battle_manager.gd` calls
only after an action actually succeeds (see `## 6`); a failed attempt (out
of range, not enough MP) needs to leave the panel open so the player can
pick something else, same as `battle_menu.gd` originally did. (An earlier
version of this file *did* always close on any press — that was correct
only while the buttons had no real logic to fail; once real combat
resolution was wired in, "always close" would have hidden failure feedback.)
`open()` mirrors `close()` (guarded the same way: only acts if not already
open/mid-slide) and lets `battle_manager.gd` show the panel programmatically
— used to auto-open it right after the player's move lands (`## 6`) instead
of only ever responding to a manual `menu_toggle` press.

**Keyboard navigation** is native Godot `Button` focus, not a hand-rolled
index/pointer system: the buttons' `focus_neighbor_top`/`focus_neighbor_bottom`
(wired directly in `main.tscn`) chain them together, so arrow keys move
focus and `ui_accept` (Enter/Space) activates whichever one has it —
`GameboyTheme.tres` supplies the focus/pressed styling. `_slide_in()` grabs
focus on the first button so this works immediately on open without a prior
Tab or click.

**Stats.** `update_stats()`/`flash_message()` are what `ui_write_text()`'s
numbers *should* have been if GB had wired them to real data.
`_hp_label`/`_atk_label`/`_def_label`/`_mp_label` are no longer built in
code — they're `@onready` references to hand-placed `Label`/`Label2`/
`Label3`/`Label4` under a scene-authored `VBoxContainer2` (a sibling of the
buttons' own `VBoxContainer`, both children of `UI_Menu`), which handles
their layout itself the same way the buttons' container already did.
`_message_label` is the one exception still built in code
(`_build_message_label()`) — `flash_message()`'s short "OUT OF RANGE"/"NOT
ENOUGH MP" line has no scene-authored equivalent, only the four stats do.

There used to also be a separate `_hud`/`_result_label` (a sibling `Control`
holding a win/lose text label, shown via `show_result()`) — removed now that
`battle_manager.gd`'s `_end_battle()` (`## 6`) reports the win/lose result
through the Dialogue UI instead (`dialogue.announce("GAME WON"/"GAME
OVER")`, `## 5b`), the same mechanism it already uses for per-hit combat
reports, rather than a second, separate result display. (There also used to
be a `_turn_label`/`set_turn_text()` showing "YOUR TURN"/"ENEMY TURN" on the
old `_hud` — removed earlier. `dialogue.gd`/`DialogueUI` briefly grew its
own equivalent turn label too — also removed; turn indication comes from the
UI buttons' own state, not a separate text label anywhere.)

**Input action.** `_ensure_menu_toggle_action()` registers `menu_toggle` at
runtime, bound to **Tab** — matching GB's SELECT conceptually. Tab is also
Godot's built-in focus-cycle key, and with real `Button` focus navigation
wired via `focus_neighbor_top`/`bottom` (above), a naively-handled Tab press
would let a focused button's focus-cycling swallow it at the engine level
before `menu_toggle` ever saw it, silently breaking the panel's close. The
fix: handle it in `_input()` rather than `_unhandled_input()`, and call
`get_viewport().set_input_as_handled()` when consumed. `_input()` fires
before Godot's own GUI/focus handling gets a chance to process the event, so
claiming it there first stops focus-cycling from ever seeing it — verified
directly: a focused button stays focused after this consumes Tab, instead of
cycling away as it would under `_unhandled_input`. (Two earlier attempts at
this — disabling button focus entirely, then moving the binding to M —
both got reverted; this is the fix that keeps Tab *and* survives a focused
button.)

## 5b. System announcements & attack effects — `dialogue.gd`, `weapon_fx.gd`

Two small systems, both new — GB has no ambient status display and no attack
VFX at all, so neither has a GB side to compare against.

**`DialogueUI`** (`WindowLayer/Dialogue_UI`, a `TileMap` sibling of
`UI_Menu`, *not* nested inside `UI_Menu`'s toggleable panel) is the "prints
out all system info to the UI" stub turned into its first real use, now with
its own hand-painted panel art (a second `TileSetAtlasSource` using the same
8x8 tileset as `UI_Menu`) and a scene-authored `Control/Label` for the text
rather than one built in code — `@onready var _announce_label: Label =
$Control/Label`, a direct child since the script is attached to
`Dialogue_UI` itself. (An earlier version wrote this as
`$WindowLayer/Dialogue_UI/Control/Label` — a path that only makes sense from
somewhere *above* `Dialogue_UI`, not from a script attached to it; from here
that looks for a child of `Dialogue_UI` literally named "WindowLayer", which
doesn't exist, and fails to resolve.)

`announce()` shows a short-lived status line — the move-range-cap notice
from `## 6`, and now also `UI.gd`'s Attack/Magic/End turn button presses
(`## 5`, via a direct sibling reference, not routed through
`battle_manager.gd`): slides the whole panel up from the **bottom** of the
screen (`_slide_in()`/`_slide_out()`, mirroring `UI.gd`'s `## 5`
Tween-between-two-positions approach, but with `_hidden_position` computed
*below* `_shown_position` instead of above it, since this one enters from
the opposite edge), holds for `ANNOUNCE_TIME`, then slides back down —
guarded so an older `announce()` call's delayed hide can't cut off a newer
message that overwrote it first.

`_shown_position` isn't just the node's raw scene position — it's computed
by `_compute_shown_position()`. The painted tiles start well down this
TileMap's own local space (`get_used_rect().position.y` is row 13, not row
0 — there's blank canvas above the actual panel art), so naively using the
node's raw position as "shown" left most of the panel below the real
screen's bottom edge even at rest: verified directly, the painted content
spanned screen Y 599–791 against a 648-tall viewport, i.e. only its top
~50px was ever actually visible. `_compute_shown_position()` instead
anchors the painted content's bottom edge just above the real viewport's
bottom edge (`BOTTOM_MARGIN = 8px`), reading `get_viewport().get_visible_rect().size`
at runtime rather than a guessed constant, so it stays correct if the art
is repainted or the window is resized — verified against the project's
real 1152×648 viewport: content now renders at screen Y 448–640, fully
inside `[0, 648]`.

It can also be opened/closed manually now, the same way `UI_Menu` is, but on
its **own key**: `dialogue_toggle` (bound to **D**), self-registered via
`_ensure_dialogue_toggle_action()` mirroring `UI.gd`'s
`_ensure_menu_toggle_action()` exactly (own action name, `_input()` +
`get_viewport().set_input_as_handled()`, same reasoning as `## 5`'s Tab fix
even though D isn't a special engine key — consistent defensive pattern
either way). Deliberately a separate key from `menu_toggle`, not the same
one, so the battle panel and this status panel can be shown independently
instead of always sliding together. `_manual_open` tracks whether a
`dialogue_toggle` press is holding the panel open; `announce()`'s own
auto-hide checks this flag first so it can't slide the panel away out from
under someone who explicitly opened it — verified directly: triggering
`announce()` while manually opened leaves the panel open past
`ANNOUNCE_TIME` instead of auto-closing.

Like `UI.gd`, it calls `_match_camera_zoom()` on itself since it's under the
same zoom-ignoring `WindowLayer` `CanvasLayer` (`## 5`) — the same fix
duplicated a second time rather than factored out, which would be worth
doing if a third UI layer needs it.

No turn indicator lives here — `UI.gd` had a `_turn_label` briefly, then
this file grew its own equivalent right after that one was removed, and
that got removed too. Turn state is planned to surface through the
MAGIC/ATTACK/END buttons' own state once end-turn is wired to them directly
(`## 5`), not a separate text label.

**`WeaponFx`** (`Weapon`, a `Sprite2D` sibling under the scene root, not
owned by either unit) plays a 2-frame slice of `weapons.png`, positioned
wherever `play_swing(at_position, direction)` is told to appear. It's a
shared prop rather than something each `Unit` owns because it's purely
visual and reused identically for both sides; `battle_manager.gd` (`## 6`)
is what actually calls it, once per physical attack, at the attacker's
position, passing the attacker's own `facing`. Guards against re-triggering
mid-swing with a simple `_playing` flag; not awaited by its caller, so it
plays concurrently with whatever else that attack is doing rather than
blocking the turn.

`weapons.png`'s 8 frames rotate a sword through 45° steps (a full turn) —
verified visually: frame 0 is straight down, 2 is straight left, 4 is
straight up, 6 is straight right, with a diagonal frame between each
cardinal pair. This used to just play all 8 back-to-back as one
direction-agnostic flourish regardless of which way the attacker was
facing. Now split into 4 non-overlapping 2-frame swings via
`ATTACK_FRAMES`, one per cardinal facing — `{DOWN: [0,1], LEFT: [2,3], UP:
[4,5], RIGHT: [6,7]}` — each pair starting at that direction's own cardinal
frame and arcing into the adjacent diagonal, so the sword actually swings
toward wherever the attacker is facing instead of always doing a full
rotation. `WeaponFx.Dir`'s DOWN/LEFT/RIGHT/UP ordering (and underlying int
values) deliberately matches `PlayerUnit.Dir`/`EnemyUnit.Dir`, so either
unit's `facing` passes straight through as `direction` with no translation
needed — verified directly (dir 0/1/2/3 in play back frames [0,1]/[2,3]/
[6,7]/[4,5] respectively, and a real in-range attack with the player facing
RIGHT correctly played frame 6).

## 6. Turn-based battle — `battle_manager.gd`

This is the one system with **no real GB counterpart** — `main.c`'s handling
of `ui_menu_idx` is a literal `/* TODO */`, so everything here is new,
built per an explicit decision to flesh the battle system out for real rather
than leave it a stub.

- `TurnState` (`PLAYER_TURN → BUSY → ENEMY_TURN → GAME_OVER`) is the turn
  loop GB never built. `_ready()` positions `player` on the grid (`PLAYER_START`),
  creates a `FadeOverlay`, and wires `grid_map.confirm_pressed` /
  `ui_panel.action_chosen` / `ui_panel.opened` / `ui_panel.closed` to
  handlers. Note there's no `_unhandled_input`/menu-toggle handling here
  anymore — `ui_panel` (`UI.gd`) owns opening/closing itself (`## 5`), this
  file only reacts to the result.
  - `PLAYER_START` and the `Camera2D` in `main.tscn` need to stay mutually
    consistent: the camera is positioned/zoomed to frame the battlefield
    (currently `position = Vector2(80, 80)`, `zoom = Vector2(6, 6)`, chosen
    to comfortably fit the default `Player`/`Enemy` start cells on the
    project's real 1152×648 viewport — verified directly, not eyeballed).
    Moving `PLAYER_START` or any enemy's `grid_pos` (below) significantly,
    or changing the grid size, can push a unit back out of frame; there's no
    camera-follow logic, it's a fixed view — worth rechecking manually after
    adding or repositioning enemies.

**Multiple enemies.** `enemies: Array[EnemyUnit]` replaces what used to be a
single `@onready var enemy: EnemyUnit = $Enemy` — populated in `_ready()` by
scanning `get_children()` for anything that `is EnemyUnit`, rather than
bound to one hardcoded node path. This is specifically what makes
duplicating the `Enemy` node in the editor (`Enemy2`, `Enemy3`, ...) work
without any script change: every `EnemyUnit` sibling under the scene root is
picked up automatically, however many there are.
  - Each enemy's starting cell comes from its own `grid_pos`, now an
    `@export` on `Unit` (`## 4`) rather than a single shared constant —
    `Unit._ready()` already does `position = grid_to_world(grid_pos)`, and
    since children ready before their parent, that runs *before*
    `BattleManager._ready()`, so a scene-authored `grid_pos` per enemy just
    works with no extra plumbing. `main.tscn`'s original `Enemy` node got an
    explicit `grid_pos = Vector2i(7, 7)` override added to preserve its
    exact previous start cell (it used to come from the now-removed
    `ENEMY_START` constant instead).
  - One case a scene-authored `grid_pos` can't cover on its own: Godot's
    Ctrl+D duplicate offsets the copy's pixel `position` slightly but *not*
    by a whole grid cell, so a freshly duplicated enemy silently shares its
    original's exact `grid_pos` until someone edits it. `_ready()` guards
    against this: it builds an `occupied` list starting with the player's
    cell, and for each enemy already in that list (or off-grid), reassigns
    its `grid_pos` via `_find_free_cell()` — a square-ring search outward
    from its current cell for the nearest unoccupied one — before appending
    it and moving to the next. So a blind duplicate-and-run still produces
    two distinct, playable starting positions; moving the duplicate to a
    deliberate cell via the Inspector (editing its `grid_pos`) still always
    wins over the auto-placement, since the guard only triggers on an actual
    collision.
  - Combat logic follows: `_nearest_enemy(from)` (nearest living enemy by
    grid distance, ties broken by array order), `_all_enemies_defeated()`,
    and `_living_enemy_cells(excluding)` (every living enemy's `grid_pos`,
    optionally leaving one out) are the shared helpers the rest of this file
    builds on instead of reading `enemy.grid_pos`/`enemy.is_alive()`
    directly.
- `_on_panel_opened()`/`_on_panel_closed()` set `grid_map.input_enabled`
  (false/true) and refresh the stats display (`ui_panel.update_stats(player)`
  right as it opens) — this is what stops `TacticsGrid` (`## 3`) from
  accepting clicks/pathing while the menu is up. (An earlier version of this
  recomputed from *two* independently-toggled panels' state, since
  `battle_menu.gd` and `UI.gd` used to be separate systems that could each be
  open; now that they're merged into one, it's back to a direct set.)
- `_on_confirm_pressed()` is the "move" half of a turn: computes a path with
  `TacticsGrid.compute_path_for(player.grid_pos, cell, _living_enemy_cells())`
  — every living enemy's cell blocks the player's path, not just one — shows
  it, walks it, clears it. This is the
  Godot-side equivalent of GB's A-button path/highlight/walk sequence in
  `main()`, just gated by `TurnState` instead of running any time. GB places
  no cap on path length at all; this now does — `PLAYER_MOVE_RANGE = 4`
  (new, GB has no movement-range concept to port). A path longer than the
  cap is **truncated** to the first `PLAYER_MOVE_RANGE` steps rather than the
  whole move being rejected, so clicking a far cell still moves you as far
  as allowed instead of doing nothing; `dialogue.announce("MOVED FROM %d,%d
  TO %d,%d" % [...])` (`DialogueUI`, `## 5b`) then reports the move — `from`
  is `path[0]` (the path's own start cell, not a separately-tracked
  variable), `to` is `player.grid_pos` read after `walk_path()` finishes, so
  it reflects where the truncated move actually landed. "MOVED FROM..."
  rather than "PLAYER MOVED FROM..." specifically because it was measured
  against `_announce_label`'s actual font/box: the longer phrasing wraps to
  2 lines that only just fit the 17px-tall box (14px needed), while dropping
  the redundant "PLAYER" fits on a single line with real margin (7px
  needed). Earlier versions showed first a static "MAX RANGE REACHED"
  message, then just the destination tile alone, here instead. Once the move
  lands, `ui_panel.open()` (`UIPanel.open()`, `## 5` — a new method mirroring
  its existing `close()`) slides the battle panel open automatically, so
  Attack/Magic/End turn are one click away right after moving instead of
  requiring a separate manual `menu_toggle` press every turn. This reuses
  `_on_panel_opened()`'s existing wiring (`## 5`/above) to disable grid input
  the moment it opens, same as if the player had pressed Tab themselves.
- `_on_action_chosen()` / `_try_player_attack()` is the "act" half — what GB's
  `/* TODO */` would have needed to become: range checks (`ATTACK_RANGE = 1`,
  `MAGIC_RANGE = 2`), MP cost (`MAGIC_COST = 3`), and damage
  (`max(1, atk - def)` for physical, flat `MAGIC_DAMAGE = 8` ignoring `def`
  for magic). With more than one enemy and no target-picker UI (a
  deliberately separate feature from just surviving multiple enemies, so out
  of scope here), `_try_player_attack()` auto-targets `_nearest_enemy(player.grid_pos)`
  — the nearest *living* enemy — the same default most SRPGs fall back to
  without an explicit target selection step; `target == null` (every enemy
  already dead, shouldn't happen mid-battle) bails out with no action. Calls
  `ui_panel.close()` only once an action actually succeeds — see `## 5` for
  why that's not the panel's own job to decide unconditionally. A physical
  ATTACK also fires `weapon_fx.play_swing(player.position, player.facing)`
  (fire-and-forget, not awaited) — the attacker's own `facing` (already
  updated by the `face_towards()` call just above) picks which of
  `WeaponFx`'s 4 directional swings plays, see `## 5b`. MAGIC doesn't, since
  `weapons.png` is a sword and there's no spell-effect art yet to trigger
  instead. Once damage is applied, `dialogue.announce("%s HIT FOR %d DMG" %
  [verb, damage])` (or `"%s DEFEATED ENEMY"` if that hit dropped the target
  to 0 HP) reports the effect the same way the move announcement does —
  same one-line budget on `_announce_label`, measured the same way
  (`"ATTACK HIT FOR 99 DMG"` still fits on one line at this font/box size,
  so no realistic damage value can overflow it). A kill also immediately
  `await`s `target.play_defeat()` (`## 4`) right there — flashed/hidden the
  moment *that* enemy dies, not deferred to `_end_battle()`, since with
  multiple enemies a kill needs its own feedback whether or not it was the
  last one standing. `_all_enemies_defeated()` (not "is the enemy dead") is
  what actually ends the battle.
- `_start_enemy_turn()` is entirely new: every living enemy in `enemies`
  acts once, in array order — not simultaneously, so two enemies can never
  both path into the same cell at once. Each one paths toward the player if
  not already adjacent (`_adjacent_cell_near`, picking whichever open
  neighbor of the player's cell is closest to it), then attacks if in range,
  same per-enemy logic the single-enemy version used to run once. Its path
  gets the same `ENEMY_MOVE_RANGE = 4` truncation as the player's, and
  blockers are `_living_enemy_cells(e)` (every *other* living enemy, `e`
  left out of its own blocker list) plus the player's cell appended — so an
  enemy later in the loop already treats an earlier one's *new* position as
  solid, the same way it already treats the player's cell as solid. (`+` on
  a typed `Array[Vector2i]` and an untyped `[x]` literal silently produces
  an untyped array at runtime, which `compute_path_for()`'s typed-array
  parameter then rejects — caught via a real runtime test with 2 enemies;
  fixed by `append()`-ing onto the typed array instead of concatenating.)
  Each enemy's attack triggers the same `weapon_fx.play_swing()` at
  `e.position`, passing `e.facing` (set by its own `face_towards()` call
  just above, same as the player's). The loop also bails early
  (`if not player.is_alive(): break`) so a second/third enemy doesn't keep
  acting against an already-defeated player.
- `_end_battle(message, defeated = null)` is the sequence that plays once
  either the player or every enemy is dead: if `defeated` is passed (always
  `player`, for the `GAME OVER` case — there's only ever one player unit),
  `await defeated.play_defeat()` (`## 4`) flickers and hides it right on the
  battlefield first. The `GAME WON` case passes nothing, since — per the
  per-kill handling above — whichever enemy died last already got its own
  flash/hide at the moment it happened; there's no single "the enemy" left
  to flash again here. Either way, `await dialogue.announce(message)`
  (`"GAME WON"`/`"GAME OVER"`, `## 5b`) reports the result the same way a
  normal attack does, held for its usual `ANNOUNCE_TIME` and slid away
  again, and only then does `_fade.fade_out()` + `change_scene_to_packed`
  return to the title — reusing `FadeOverlay` the way GB's `main()` reuses
  `fadeout()` between the game and the title screen. An earlier version
  fired a full-screen white fade immediately on defeat with a static
  `ui_panel` result label and no per-unit feedback at all; this replaces
  that with the defeated unit's own flash/disappear plus the same Dialogue
  UI used for every other combat report, so the ending reads as "that unit
  lost" before it cuts to "here's the result" and back to title.

## 7. Fades & title screen

- `fade_overlay.gd`: a full-screen `ColorRect` faded via `Tween` on
  `color:a`. GB's `fadeout()`/`fadein()` (`main.c`) step `BGP_REG` through
  `0xE4 → 0xF9 → 0xFE → 0xFF` — ending on an **all-white** palette — so this
  fades to white, not black, to match. `snap_opaque()`/`snap_transparent()`
  let `battle_manager.gd` start a scene already-white and fade *in*, the way
  GB's `main()` calls `fadeout()` before reloading VRAM and `fadein()` after.
- Title-screen selection and pointer are split across two scripts on two
  different nodes, since a single node can only carry one script and this
  scene's `$Control/Sprite2D` was repurposed into a `TextureButton` with its
  own job:
  - `title_screen.gd` (on the scene root) mirrors `titlescreen.c`'s
    `run_titlescreen()` menu loop: a 3-option list (`_buttons`), navigated
    with `ui_up`/`ui_down` and confirmed with `ui_accept`, plus each
    `Button`'s native `pressed` signal for mouse clicks. Keyboard-selected
    feedback is each `Button`'s built-in focus outline (`grab_focus()`) —
    there's no hand icon tracking the selection anymore (see below).
    - Option index `2` (Multiplayer) intentionally does nothing on confirm,
      matching GB's own `TITLE_MULTIPLAYER` case in `titlescreen.c`, which
      "plays the selection animation but stays on the menu" —
      `src/multiplayer/` has no networking code at all on the GB side, and
      building real multiplayer was explicitly out of scope here too.
    - START and CONTINUE both just fade out and load `main.tscn` — GB has no
      save/load either (`main.c` has an explicit `Future:` TODO to
      distinguish them once one exists), so this doesn't invent a save
      system GB doesn't have.
  - `title_screen_pointer.gd` (on `$Control/Sprite2D`, a plain `Sprite2D`) is
    a mouse-following pointer instead: it repositions itself to the mouse
    every `_process()` frame and swaps `texture` by hand between
    `hand_1.webp`/`hand_2.webp` based on
    `Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)`, to show the "clicked"
    look while the left mouse button is held. This is GB's
    `UIPointer`/`pointer_anim_select` (`src/UI/ui_pointer.c`) re-purposed for
    mouse-driven rather than d-pad-driven selection — same two textures, same
    normal-vs-pressed idea, continuous position instead of snapping between
    fixed menu-row coordinates.
    - This node used to be a `TextureButton` (relying on its native
      `texture_normal`/`texture_pressed` swap instead of the manual one
      above), which caused a real bug: a `TextureButton` is a `Control`, and
      `Control`s always participate in Godot's mouse hit-testing regardless
      of `mouse_filter` tuning. Since this pointer always sits exactly on top
      of the mouse (that's its whole job) and renders above the real UI
      buttons in z-order, it was silently intercepting clicks meant for
      whatever button was actually under the cursor — reported as "the
      SpritePointer doesn't trigger the buttons when clicked." A plain
      `Sprite2D` is never a `Control`, so it can't participate in GUI input
      routing or block a click at all — the fix is architectural (change the
      node type), not a `mouse_filter` value. `helpers/pointers.tscn`'s root
      node type changed accordingly, and both scenes that instance it
      (`main.tscn`, `TItleScreen.tscn`) had their now-invalid `Control`-only
      instance overrides (`mouse_filter`, `layout_mode`/`offset_*`) removed —
      `TItleScreen.tscn`'s `offset_left`/`offset_top` were converted to an
      equivalent `position` instead of just being dropped, so the pointer's
      starting placement didn't shift.
    - It's now its own reusable scene, `helpers/pointers.tscn`, and is also
      instanced inside `main.tscn` under `WindowLayer/UI_Menu` — the same
      pointer used for both the title screen and the in-game panel from
      `## 5`. It hides the OS mouse cursor while it's actually visible on
      screen, and shows it again the instant it isn't — driven by
      `visibility_changed`/`is_visible_in_tree()`, not by `_ready()`/
      `_exit_tree()`. That distinction matters here specifically because of
      the reuse: on the title screen this node is visible immediately, but
      in `main.tscn` its parent `UI_Menu` starts hidden (`UI.gd`) and
      only becomes visible when the panel slides open. Hiding the cursor
      unconditionally in `_ready()` would hide it for the *entire* game
      session — including regular grid gameplay, where this pointer never
      renders to replace it — leaving no visible cursor at all. Gating on
      real visibility keeps its effect scoped to only when it's shown, so it
      doesn't interfere with the grid's own cursor (`tile_map.gd`'s
      mouse-hover highlight) during normal play.
    - `pointers.tscn`'s root bakes in `scale = Vector2(2, 2)`, tuned for the
      title screen's ancestor scale (`Control`'s `~4.67`, giving a combined
      render scale of `~9.34`). Nested under `UI_Menu` instead, it would
      also inherit that node's `~8` scale from `_match_camera_zoom()` (`##
      5`) on top of its own baked-in `2`, combining to `~16` — visibly
      oversized next to the panel. `main.tscn`'s instance of this node
      overrides `scale = Vector2(1, 1)` to correct for its *own* parent
      context (bringing the combined scale back down to `~8`, close to the
      original `~9.34`) without touching the shared scene or the title
      screen's instance, which still uses the baked-in `2`.

## 8. Where Godot deliberately differs from GB

| Decision | GB build | Godot build | Why |
|---|---|---|---|
| Grid size | 15x15 | 10x10 | Kept the size the Godot project already had rather than matching GB. |
| Input | d-pad only | mouse *and* keyboard | Mouse support already existed in the pre-existing `tile_map.gd`; kept it and added keyboard alongside. |
| Battle menu | Stub (`/* TODO */`, no combat resolves) | Full turn-based system: HP/ATK/DEF/MP, enemy AI, win/lose | Explicitly requested — GB's own build never finished this. |
| Enemy | Declared, never implemented | Real unit with AI | Same reason. |
| Multiplayer | Menu option present, plays an animation, does nothing | Same — menu option present, does nothing | Explicitly deprioritized; GB has no networking to port from either. |
| Save/Continue | Not implemented (explicit GB TODO) | Not implemented — CONTINUE behaves like START | Nothing to port; not invented on the Godot side either. |
| Level art (`levels/level1.c`) | Included in `main.c` but never drawn — dead code | Not ported | Confirmed unused in the actual GB `main()` before starting. |

## 9. Tuning reference

| Want to change... | Edit |
|---|---|
| Grid size | `GRID_SIZE` in `tile_map.gd` |
| Cursor/path/grass tile art | `TILE_GRASS`/`TILE_CURSOR`/`TILE_PATH` in `tile_map.gd` — remember to also register any new atlas coordinate as `N:0/0 = 0` under `main.tscn`'s `TileSetAtlasSource` |
| Player/enemy stats | `resources/player_stats.tres` / `resources/enemy_stats.tres` — edit the `.tres` directly, no code change needed |
| Attack/magic range, magic cost/damage | Constants at the top of `battle_manager.gd` |
| Movement speed | `STEP_TIME` in `player_unit.gd` / `enemy_unit.gd` |
| Player starting position | `PLAYER_START` in `battle_manager.gd` — keep in view of the `Camera2D` below |
| Enemy starting position(s) | each `EnemyUnit`'s own `grid_pos` (`@export`, Inspector or `.tscn` text) — no code change; add more enemies by duplicating the `Enemy` node, they're discovered automatically (`## 6`) |
| Camera framing | `Camera2D` `position`/`zoom` in `main.tscn` — currently `(80,80)`/`6` to fit both start positions on the real 1152×648 viewport; fixed, not follow-based |
| Movement range per turn | `PLAYER_MOVE_RANGE`/`ENEMY_MOVE_RANGE` in `battle_manager.gd` |
| Menu-toggle key binding (default: Tab) | `_ensure_menu_toggle_action()` in `UI.gd` |
| Dialogue panel toggle key binding (default: D) | `_ensure_dialogue_toggle_action()` in `dialogue.gd` |
| Battle panel stat label positions | `VBoxContainer2` in `main.tscn` (scene-authored — no code to edit) |
| Win/lose messages | `"GAME WON"`/`"GAME OVER"` strings passed to `_end_battle()` in `battle_manager.gd` |
| Defeat flash speed/count | `DEFEAT_FLASH_COUNT`/`DEFEAT_FLASH_TIME` in `unit.gd` |
| System-announcement layout/timing | `dialogue.gd` (`_announce_label` position, `ANNOUNCE_TIME`) |
| Dialogue panel's on-screen height/gap when shown | `BOTTOM_MARGIN` in `dialogue.gd` |
| Weapon-swing speed/frames | `ATTACK_FRAMES`/`FRAME_TIME` in `weapon_fx.gd` |
| Fade color/speed | `fade_overlay.gd` (`Color(1,1,1,...)`, `duration` args) |
| Mouse-pointer centering on the title screen | `pointer_offset` export on `title_screen_pointer.gd` (editable directly in the Inspector, no code change needed) |

## 10. Known rough edges

- Battle panel and title-screen hand-pointer positions are reasonable
  estimates (computed from layout, not pixel-checked in the editor) — nudge
  the constants above if anything looks off. Stat label positions are
  scene-authored now (`VBoxContainer2`), so this no longer applies to them;
  the win/lose result no longer has its own on-screen position at all, since
  it now goes through the Dialogue UI's existing label instead of a
  separately-positioned one (`## 5`/`## 6`).
- `title_screen_pointer.gd`'s `pointer_offset` default (`-24, -24`) is a
  guess at centering the hand texture under the mouse based on the button's
  rect size in `TItleScreen.tscn`, not a pixel-verified value.
- `EnemyUnit`'s 4-frame direction order is assumed to match `PlayerUnit`'s
  convention (down/left/right/up) — not independently verified against
  `Enemy1.png`.
- No terrain variety yet — `is_walkable()` in `tile_map.gd` and the `TileType`
  switch in GB's `main.c` are both single-case today; both were written with
  the hook in place for when that changes.
- No target-picker UI for ATTACK/MAGIC with multiple enemies — always
  auto-targets the nearest living one (`## 6`). Fine for the current demo;
  would need real work (click-to-select a specific enemy sprite) if the
  player should ever be able to choose.
- Enemy AI doesn't flank or route around a blocked chokepoint — verified
  directly with 2 enemies approaching the player from the same side: the
  first enemy took the only adjacent cell, and the second (blocked from
  reaching any other adjacent cell by `_living_enemy_cells()`'s blockers)
  just stayed put that turn rather than pathing around to a different side.
  Not a bug — `_adjacent_cell_near()` was never designed to consider a
  second enemy's presence — but worth knowing before assuming multiple
  enemies will always surround the player efficiently.
- Camera framing is still a fixed view (see `## 6`) — adding enemies or
  moving their `grid_pos` far from the default battlefield area can put them
  outside the `Camera2D`'s current `position`/`zoom`, the same caveat that
  already applied to `PLAYER_START`/the old single `ENEMY_START`.

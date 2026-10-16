#pragma bank 1   /* battle scene code lives in ROM bank 1 — see battle/battle.h */

#include <gb/gb.h>
#include <gbdk/font.h>
#include "battle.h"
#include "../music.h"
#include "../fade.h"
#include "../tileset.h"
#include "../grid/grid.h"
#include "../UI/ui_text.h"
#include "../UI/battle_menu.h"
#include "../UI/dialogue.h"
#include "../characters/unit.h"
#include "../weapons/weapon_fx.h"

// ─────────────────────────────────────────────
// CONSTANTS — same names/values as battle_manager.gd
// ─────────────────────────────────────────────

typedef enum { PLAYER_TURN, BUSY, ENEMY_TURN, GAME_OVER } TurnState;

#define ATTACK_RANGE  1u
#define MAGIC_RANGE   2u
#define MAGIC_COST    3u
#define MAGIC_DAMAGE  8u

/* Max cells either side can move in one turn.  A longer path is truncated
   to its first N steps (a partial move toward the target) rather than the
   move being rejected outright. */
#define PLAYER_MOVE_RANGE 4u
#define ENEMY_MOVE_RANGE  4u

/* Top-left corner of the map (Godot's PLAYER_START is (2,2)). */
#define PLAYER_START_X 0u
#define PLAYER_START_Y 0u

/* Timings in VBLs (~60 per second) */
#define MOVE_DELAY          12u  // frames per cell stepped (~5 cells/sec)
#define ENEMY_TURN_DELAY    18u  // pause before the enemies act (0.3 s)
#define ATTACK_HOLD         18u  // player's attack pose (play_attack, 0.3 s)
#define DEFEAT_FLASH_COUNT  5u
#define DEFEAT_FLASH_TIME   5u   // VBLs per on/off half-flash (0.08 s)

/* One row per enemy: starting cell, stats, sprite art.  Mirrors
   main.tscn's Enemy and Enemy2, which both sit on (7,7); the second gets
   un-stacked by find_free_cell() just as Godot does for a freshly
   duplicated node.  On the GB, that second slot is the boss_1 character
   (same stats as the regular enemy, different art).
   Add a row to add an enemy (4 OAM slots each from ENEMY_OAM_BASE; the GB
   shows at most 10 sprites per scanline, i.e. 5 units side by side,
   cursor and sword included). */
typedef struct {
    AStarPos         cell;
    const UnitStats *stats;
    uint8_t          tile_base;
} EnemySpawn;

static const EnemySpawn ENEMY_SPAWNS[] = {
    { { 7u, 7u }, &ENEMY_STATS, ENEMY_TILE_BASE },
    { { 7u, 7u }, &ENEMY_STATS, BOSS_TILE_BASE  },
};
#define ENEMY_COUNT ((uint8_t)(sizeof(ENEMY_SPAWNS) / sizeof(ENEMY_SPAWNS[0])))

// ─────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────

static Unit      player;
static Unit      enemies[ENEMY_COUNT];
static TurnState state;
static uint8_t   battle_over;

static AStarPos move_path[ASTAR_MAX_PATH];
static AStarPos blockers[ENEMY_COUNT + 1u];
static char     msg_buf[41];

static void end_battle(const char *message, Unit *defeated);
static void start_enemy_turn(void);

// ─────────────────────────────────────────────
// FRAME LOOP
// Godot runs these as coroutines (await tween/timer); here every waiting
// sequence calls battle_frame() itself, which keeps the menu animation,
// dialogue strip, sword swing and music running underneath it.
// ─────────────────────────────────────────────

static void world_show(void)
{
    uint8_t i;
    unit_place(&player);
    for (i = 0u; i < ENEMY_COUNT; i++) unit_place(&enemies[i]);
    cursor_draw();
}

static void world_hide(void)
{
    uint8_t i;
    unit_hide_sprites(&player);
    for (i = 0u; i < ENEMY_COUNT; i++) unit_hide_sprites(&enemies[i]);
    cursor_hide();
    weapon_fx_hide();
}

static void battle_frame(void)
{
    wait_vbl_done();
    // Restore player, enemies and cursor once the panel is gone.
    if (menu_tick() == MENU_EVT_CLOSED) world_show();
    dialogue_tick();
    weapon_fx_tick();
    /* Advance multi-frame animations (walk, attack) at their defined speeds. */
    player_anim_tick(&player_anim);
    music_update();
}

static void wait_frames(uint8_t n)
{
    while (n--) battle_frame();
}

/* The panel covers the whole screen and sprites draw over the Window, so
   hide everything on the grid before it slides in.  Refreshes the stats
   as it opens, like Godot's _on_panel_opened(). */
static void open_menu(void)
{
    menu_set_stats(&player);
    if (menu_open()) world_hide();
}

/* Close the panel and wait until the battlefield is visible again. */
static void close_menu_and_wait(void)
{
    if (menu_close())
        while (menu_is_open()) battle_frame();
}

// ─────────────────────────────────────────────
// HELPERS — battle_manager.gd's Utils / Enemy inner classes
// ─────────────────────────────────────────────

static uint8_t melee_damage(const Unit *attacker, const Unit *target)
{
    // max(1, atk - def)
    return (attacker->atk > target->def) ? (uint8_t)(attacker->atk - target->def) : 1u;
}

static uint8_t all_enemies_defeated(void)
{
    uint8_t i;
    for (i = 0u; i < ENEMY_COUNT; i++)
        if (unit_is_alive(&enemies[i])) return 0u;
    return 1u;
}

/* Nearest living enemy by grid distance (ties broken by array order) —
   NULL only if every enemy is already dead. */
static Unit *nearest_enemy(uint8_t x, uint8_t y)
{
    Unit   *nearest = 0;
    uint8_t best = 0xFFu;
    uint8_t i, d;
    for (i = 0u; i < ENEMY_COUNT; i++) {
        if (!unit_is_alive(&enemies[i])) continue;
        d = grid_distance(x, y, enemies[i].gx, enemies[i].gy);
        if (d < best) { best = d; nearest = &enemies[i]; }
    }
    return nearest;
}

/* Of the 4 cells touching the target, pick the in-grid one closest to
   `from` (ties in +x, -x, +y, -y order).  Like Godot's version it doesn't
   check who's standing there — a taken cell just yields no path.  Falls
   back to `from` if none are on the grid. */
static void adjacent_cell_near(uint8_t tx, uint8_t ty, uint8_t fx, uint8_t fy,
                               uint8_t *ox, uint8_t *oy)
{
    static const int8_t DX[4] = { 1, -1, 0,  0 };
    static const int8_t DY[4] = { 0,  0, 1, -1 };
    uint8_t best = 0xFFu;
    uint8_t i, d;
    int8_t  cx, cy;

    *ox = fx;
    *oy = fy;
    for (i = 0u; i < 4u; i++) {
        cx = (int8_t)tx + DX[i];
        cy = (int8_t)ty + DY[i];
        if (!grid_in_bounds(cx, cy)) continue;
        d = grid_distance((uint8_t)cx, (uint8_t)cy, fx, fy);
        if (d < best) { best = d; *ox = (uint8_t)cx; *oy = (uint8_t)cy; }
    }
}

/* Cells of every living enemy except `excluding`, written to out.
   Returns the count. */
static uint8_t living_enemy_cells(const Unit *excluding, AStarPos *out)
{
    uint8_t i, n = 0u;
    for (i = 0u; i < ENEMY_COUNT; i++) {
        if (!unit_is_alive(&enemies[i]) || &enemies[i] == excluding) continue;
        out[n].x = enemies[i].gx;
        out[n].y = enemies[i].gy;
        n++;
    }
    return n;
}

static uint8_t cell_taken(int8_t x, int8_t y, const AStarPos *occ, uint8_t n)
{
    uint8_t i;
    for (i = 0u; i < n; i++)
        if ((int8_t)occ[i].x == x && (int8_t)occ[i].y == y) return 1u;
    return 0u;
}

/* Square-ring search outward from `near` for the closest cell not in occ —
   only needed at battle start, to un-stack enemies sharing a spawn cell. */
static AStarPos find_free_cell(AStarPos near, const AStarPos *occ, uint8_t n)
{
    int8_t r, dx, dy, x, y, adx, ady;
    AStarPos c;
    if (grid_in_bounds((int8_t)near.x, (int8_t)near.y) &&
        !cell_taken((int8_t)near.x, (int8_t)near.y, occ, n)) return near;
    for (r = 1; r < (int8_t)(GRID_W * 2u); r++) {
        for (dx = -r; dx <= r; dx++) {
            for (dy = -r; dy <= r; dy++) {
                adx = dx < 0 ? -dx : dx;
                ady = dy < 0 ? -dy : dy;
                if ((adx > ady ? adx : ady) != r) continue;
                x = (int8_t)near.x + dx;
                y = (int8_t)near.y + dy;
                if (grid_in_bounds(x, y) && !cell_taken(x, y, occ, n)) {
                    c.x = (uint8_t)x;
                    c.y = (uint8_t)y;
                    return c;
                }
            }
        }
    }
    return near;
}

// ─────────────────────────────────────────────
// UNIT SEQUENCES — walk_path / play_attack / play_defeat
// ─────────────────────────────────────────────

/* Walk one cell at a time along path (path[0] = the unit's own cell),
   facing each step and sliding 16 px over MOVE_DELAY frames.  Restores
   each highlighted cell as it's stepped off, the last one on arrival. */
static void walk_path(Unit *u, const AStarPos *path, uint8_t len)
{
    uint8_t s, t;
    int16_t x0, y0, dx, dy;

    unit_set_anim(u, ANIM_WALK);
    for (s = 1u; s < len; s++) {
        unit_set_facing(u, unit_dir_from_step(path[s - 1u].x, path[s - 1u].y,
                                              path[s].x, path[s].y));
        x0 = CELL_OAM_X(path[s - 1u].x);
        y0 = CELL_OAM_Y(path[s - 1u].y);
        dx = (int16_t)CELL_OAM_X(path[s].x) - x0;
        dy = (int16_t)CELL_OAM_Y(path[s].y) - y0;
        u->gx = path[s].x;
        u->gy = path[s].y;
        for (t = 1u; t <= MOVE_DELAY; t++) {
            // Signed divide: MOVE_DELAY is unsigned, and a negative dx/dy
            // (moving left/up) would otherwise be converted to a huge
            // unsigned value and throw the sprite off-screen.
            unit_move_pixels(u, (uint8_t)(x0 + dx * (int16_t)t / (int16_t)MOVE_DELAY),
                                (uint8_t)(y0 + dy * (int16_t)t / (int16_t)MOVE_DELAY));
            battle_frame();
        }
        // Clear the cell the unit just stepped off.
        if (s >= 2u) grid_restore_cell(path[s - 1u].x, path[s - 1u].y);
    }
    grid_restore_cell(path[len - 1u].x, path[len - 1u].y);
    unit_set_anim(u, ANIM_IDLE);
}

static void play_attack(Unit *u)
{
    unit_set_anim(u, ANIM_ATTACK);
    wait_frames(ATTACK_HOLD);
    unit_set_anim(u, ANIM_IDLE);
}

/* Flicker a few times, then leave the unit hidden. */
static void play_defeat(Unit *u)
{
    uint8_t i;
    for (i = 0u; i < DEFEAT_FLASH_COUNT; i++) {
        unit_hide_sprites(u);
        wait_frames(DEFEAT_FLASH_TIME);
        unit_place(u);
        wait_frames(DEFEAT_FLASH_TIME);
    }
    u->visible = 0u;
    unit_place(u);
}

static void wait_for_swing(void)
{
    while (weapon_fx_playing()) battle_frame();
}

// ─────────────────────────────────────────────
// PLAYER TURN — Godot's _on_confirm_pressed / _on_action_chosen
// ─────────────────────────────────────────────

/* A on a grid cell: path there (living enemies block), capped at
   PLAYER_MOVE_RANGE, walk it, then open the battle panel. */
static void on_confirm(void)
{
    uint8_t steps, truncated, n;
    uint8_t from_x, from_y;
    char *p;

    if (state != PLAYER_TURN || menu_is_open()) return;
    n = living_enemy_cells(0, blockers);
    steps = grid_compute_path(player.gx, player.gy, cursor_x, cursor_y,
                              blockers, n, move_path);
    if (steps < 2u) return;

    truncated = (uint8_t)(steps - 1u) > PLAYER_MOVE_RANGE;
    if (truncated) steps = PLAYER_MOVE_RANGE + 1u;

    state  = BUSY;
    from_x = move_path[0].x;
    from_y = move_path[0].y;
    grid_show_path(move_path, steps);   // highlight the full route on BKG
    walk_path(&player, move_path, steps);

    if (truncated) {
        p = ui_str_cat(msg_buf, "MOVED FROM ");
        p = ui_str_u8(p, from_x);  p = ui_str_cat(p, ",");
        p = ui_str_u8(p, from_y);  p = ui_str_cat(p, " TO ");
        p = ui_str_u8(p, player.gx); p = ui_str_cat(p, ",");
        ui_str_u8(p, player.gy);
        announce(msg_buf);
    }

    if (state == BUSY) state = PLAYER_TURN;
    // The move is the player's action-enabling step each turn — open the
    // panel right after it lands so MAGIC/ATTACK/END are one press away.
    open_menu();
}

/* ATTACK / MAGIC on the nearest living enemy.  A failed attempt (not
   enough MP, out of range) leaves the panel open to pick something else. */
static void try_player_attack(uint8_t is_magic)
{
    Unit   *target = nearest_enemy(player.gx, player.gy);
    uint8_t range  = is_magic ? MAGIC_RANGE : ATTACK_RANGE;
    uint8_t damage;
    char   *p;

    if (!target) return;
    if (is_magic && player.mp < MAGIC_COST) {
        announce("NOT ENOUGH MP");
        return;
    }
    if (grid_distance(player.gx, player.gy, target->gx, target->gy) > range) {
        announce("OUT OF RANGE");
        return;
    }

    state = BUSY;
    // Godot's panel only covers part of the view; the GB one covers the
    // whole screen, so let it slide away first and play the hit in view.
    close_menu_and_wait();

    unit_face_towards(&player, target->gx, target->gy);
    // weapons is a sword — only the physical ATTACK gets the swing effect;
    // MAGIC has no matching art yet.
    if (!is_magic) weapon_fx_play(player.spr.x, player.spr.y, player.facing);
    damage = is_magic ? MAGIC_DAMAGE : melee_damage(&player, target);
    if (is_magic) player.mp -= MAGIC_COST;
    unit_take_damage(target, damage);

    play_attack(&player);
    wait_for_swing();
    menu_set_stats(&player);

    p = ui_str_cat(msg_buf, is_magic ? "MAGIC" : "ATTACK");
    if (unit_is_alive(target)) {
        p = ui_str_cat(p, " HIT FOR ");
        p = ui_str_u8(p, damage);
        ui_str_cat(p, " DMG");
        announce(msg_buf);
    } else {
        ui_str_cat(p, " DEFEATED ENEMY");
        announce(msg_buf);
        // Flashed/hidden the moment this enemy dies, whether or not it was
        // the last one standing.
        play_defeat(target);
    }

    if (all_enemies_defeated()) {
        end_battle("GAME WON", 0);
        return;
    }
    start_enemy_turn();
}

static void on_action(uint8_t idx)
{
    if (state != PLAYER_TURN) return;
    announce(menu_label(idx));
    switch (idx) {
    case MENU_ATTACK: try_player_attack(0u); break;
    case MENU_MAGIC:  try_player_attack(1u); break;
    case MENU_END:
        close_menu_and_wait();
        start_enemy_turn();
        break;
    }
}

// ─────────────────────────────────────────────
// ENEMY TURN — battle_manager.gd's Enemy._start_enemy_turn()
// Each living enemy acts once, in array order: path toward the player if
// not adjacent (capped at ENEMY_MOVE_RANGE; other enemies and the player
// block), then attack if adjacent.
// ─────────────────────────────────────────────

static void start_enemy_turn(void)
{
    uint8_t i, n, steps, tx, ty;
    Unit   *e;

    state = ENEMY_TURN;
    wait_frames(ENEMY_TURN_DELAY);

    for (i = 0u; i < ENEMY_COUNT; i++) {
        e = &enemies[i];
        if (!unit_is_alive(e)) continue;
        if (!unit_is_alive(&player)) break;

        if (grid_distance(e->gx, e->gy, player.gx, player.gy) > 1u) {
            adjacent_cell_near(player.gx, player.gy, e->gx, e->gy, &tx, &ty);
            n = living_enemy_cells(e, blockers);
            blockers[n].x = player.gx;
            blockers[n].y = player.gy;
            n++;
            steps = grid_compute_path(e->gx, e->gy, tx, ty, blockers, n, move_path);
            if (steps > ENEMY_MOVE_RANGE + 1u) steps = ENEMY_MOVE_RANGE + 1u;
            if (steps > 1u) walk_path(e, move_path, steps);
        }
        if (grid_distance(e->gx, e->gy, player.gx, player.gy) <= 1u) {
            unit_face_towards(e, player.gx, player.gy);
            weapon_fx_play(e->spr.x, e->spr.y, e->facing);
            unit_take_damage(&player, melee_damage(e, &player));
            // Wait it out so each enemy's hit is seen (and the next
            // enemy's swing isn't swallowed by the one-at-a-time guard).
            wait_for_swing();
        }
    }

    if (!unit_is_alive(&player)) {
        end_battle("GAME OVER", &player);
        return;
    }
    state = PLAYER_TURN;
}

/* defeated: the player for GAME OVER (flashed here); NULL for GAME WON,
   since each enemy was already flashed the moment it died. */
static void end_battle(const char *message, Unit *defeated)
{
    state = GAME_OVER;
    if (defeated) play_defeat(defeated);
    announce(message);
    do battle_frame(); while (dialogue_busy());
    fadeout();
    battle_over = 1u;
}

// ─────────────────────────────────────────────
// SETUP + INPUT LOOP
// ─────────────────────────────────────────────

static void load_scene(void)
{
    uint8_t  i, n;
    AStarPos occupied[ENEMY_COUNT + 1u];
    AStarPos c;

    // Font must be loaded FIRST — font_init resets the VRAM tile counter to 0.
    // font_min occupies VRAM tiles 0-36 (37 tiles: blank + digits + A-Z).
    font_init();
    font_load(font_min);
    ui_load_glyphs();

    // Game map tileset: 31 tiles at TILE_BASE=37.
    set_bkg_data(TILE_BASE, 31, Tileset);
    // Dedicated UI border tiles: 8 tiles at UI_TILE_BASE=68.
    set_bkg_data(UI_TILE_BASE, 8, UI_Tiles);

    unit_load_tiles();
    weapon_fx_init();

    // Clear the full 20×18 BKG tilemap so stale VRAM from the title screen
    // can't bleed through anywhere the grid doesn't draw.
    {
        uint8_t t = TILE_BASE;   // Tileset[0] = blank
        for (uint8_t y = 0; y < 18; y++)
            for (uint8_t x = 0; x < 20; x++)
                set_bkg_tiles(x, y, 1, 1, &t);
    }
    grid_init(); // populate grid[][] with TILE_GRASS for each cell
    grid_draw();
    scroll_bkg(0, 0);

    menu_init();
    dialogue_init();

    // Units: the player first, then each enemy — un-stacking any enemy
    // whose spawn cell is off-grid or already taken.
    unit_init(&player, FACTION_PLAYER, &PLAYER_STATS, PLAYER_TILE_BASE, 0u,
              PLAYER_START_X, PLAYER_START_Y);
    occupied[0].x = player.gx;
    occupied[0].y = player.gy;
    n = 1u;
    for (i = 0u; i < ENEMY_COUNT; i++) {
        c = find_free_cell(ENEMY_SPAWNS[i].cell, occupied, n);
        unit_init(&enemies[i], FACTION_ENEMY, ENEMY_SPAWNS[i].stats,
                  ENEMY_SPAWNS[i].tile_base,
                  ENEMY_OAM_BASE + i * 4u, c.x, c.y);
        occupied[n++] = c;
    }

    cursor_x = 0u;
    cursor_y = 0u;
    cursor_init();
    cursor_draw();
    menu_set_stats(&player);

    SHOW_BKG;
    SHOW_SPRITES;
    DISPLAY_ON;
}

void run_battle(void) BANKED
{
    uint8_t keys, pressed, idx;
    uint8_t prev_keys;

    load_scene();
    state       = PLAYER_TURN;
    battle_over = 0u;
    fadein();

    prev_keys = joypad();   // the title's A press may still be held
    while (!battle_over)
    {
        battle_frame();

        // ── Button edge detection (one joypad read per frame) ──
        keys      = joypad();
        pressed   = keys & ~prev_keys;
        prev_keys = keys;

        if (state != PLAYER_TURN) continue;

        if (pressed & J_SELECT)
        {
            // SELECT toggles the panel (ignored mid-animation).
            if (menu_is_ready())      menu_close();
            else if (!menu_is_open()) open_menu();
        }
        else if (menu_is_ready())
        {
            // ── UI menu navigation ──
            idx = menu_handle_input(pressed);
            if (idx != MENU_NONE) on_action(idx);
        }
        else if (!menu_is_open())
        {
            // ── Grid game input ──
            if (pressed & J_B) dialogue_toggle();
            // A button: find a path to the cursor and start walking.
            if (pressed & J_A) on_confirm();
            else if (cursor_handle_input(keys)) cursor_draw();
        }
    }
}

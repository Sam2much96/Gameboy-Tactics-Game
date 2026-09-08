#include <gb/gb.h>
#include <gbdk/platform.h>
#include <gbdk/font.h>
#include "tileset.h"
#include "levels/level1.h"
#include "gbt_player.h"
#include "UI/UI.h"
#include "UI/ui_text.h"
#include "UI/ui_pointer.h"
#include "pathfinding/astar.h"

#include "titlescreen/titlescreen.h"

// player character
#include "characters/player_character.c"
#include "characters/player.c"
#include "characters/player_anim.c"

struct GameCharacter player;
struct GameCharacter enemy;
UBYTE spritesize = 8;
/**

To do
(1) Add in a player character struct
(2) add in collision detection
(3) Add in some music
(4) Implement grid logic
(5) implement music
(6) add in player character metasprite
(6) make gameplay 16 px dimensions, not 8 px
*/

// load music
extern const unsigned char *song_Data[];

// ─────────────────────────────────────────────
// FORWARD DECLARATIONS
// GBDK's compiler requires functions to be declared
// before they are called. Add any new functions here.
// ─────────────────────────────────────────────

void init_grid(void);
void draw_grid(void);
void init_overlay(void);
void clear_overlay(void);
void draw_cursor(void);
uint8_t handle_input(void);
void fadeout(void);
void fadein(void);
void setupPlayer(void);
void movegamecharacter(struct GameCharacter *character, UINT8 x, UINT8 y);

// ─────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────

#define GRID_SIZE 15    // 4×4 tile grid
#define GRID_ORIGIN_X 0 // grid starts at tile column 0
#define GRID_ORIGIN_Y 0 // grid starts at tile row 0

#define INPUT_DELAY 10

// ─────────────────────────────────────────────
// TILE INDICES — both already exist in Tileset[]
// No extra tiles need to be loaded into VRAM.
// Tile 1: grass tile
// ─────────────────────────────────────────────

// Tile indices are absolute VRAM positions.
// font_min occupies tiles 0-36; Tileset[] at 37-67; Player at 68-71.
// Cursor gets its own slot at 72 so font/tileset loads can never clobber it.
#define GRASS_TILE         (TILE_BASE + 1)
#define EMPTY_TILE         (TILE_BASE + 0)
/* Selector[0] = cursor sprite, Selector[1] = path-highlight BKG tile */
#define PATH_HIGHLIGHT_TILE (SELECTOR_TILE_BASE + 1)

UINT8 i;

// ─────────────────────────────────────────────
// TILE TYPE ENUM
// Replaces the Godot string "Type": "Grass"
// Using an enum is cheaper than storing strings on the Game Boy
// ─────────────────────────────────────────────

typedef enum
{
    TILE_GRASS = 1, // corresponds to Dic[cell]["Type"] = "Grass"
    // add TILE_WATER, TILE_MOUNTAIN, etc. here later
} TileType;

// ─────────────────────────────────────────────
// CELL STRUCT
// Replaces Godot's dictionary per cell:
//   { "Type": "Grass", "Position": str(Vector2(x,y)) }
// We skip storing Position explicitly — on GB we can always
// derive it from the array index (x + y * GRID_SIZE)
// ─────────────────────────────────────────────

typedef struct
{
    TileType type; // what kind of tile this cell is
} Cell;

// ─────────────────────────────────────────────
// THE GRID — equivalent to Godot's Dic{}
// A flat array used as a 2D map: Dic[grid[x][y]]
// ─────────────────────────────────────────────

Cell grid[GRID_SIZE][GRID_SIZE];

// ─────────────────────────────────────────────
// CURSOR STATE
// Replaces mouse position tracking:
//   var tile = local_to_map(get_global_mouse_position())
// On Game Boy there is no mouse — the d-pad moves the cursor instead
// ─────────────────────────────────────────────

uint8_t cursor_x = 0; // current cursor column (0 to GRID_SIZE-1)
uint8_t cursor_y = 0; // current cursor row    (0 to GRID_SIZE-1)

uint8_t input_timer = 0;
uint8_t prev_keys   = 0; // joypad state from previous frame (for edge detection)
uint8_t ui_visible   = 0u; // 0 = hidden, 1 = shown
uint8_t ui_menu_idx  = 0u; // index of highlighted menu option (0-2)
UIPointer ui_ptr;           // the reusable 16×16 pointer sprite

// Screen-Y pixel position of each menu option (Window is at screen y=0).
// Options are at Window rows 2, 4, 6 → screen y 16, 32, 48.
#define UI_MENU_COUNT 3
static const uint8_t UI_MENU_Y[UI_MENU_COUNT] = { 16u, 32u, 48u };
#define UI_MENU_X 8u  // sprite pointer fixed at Window col 1 (screen x=8)

// ── UI slide animation ────────────────────────────────────────────────────
// Each SELECT press plays a row-by-row reveal (top→bottom) or a row-by-row
// clear (bottom→top).  One Window row is drawn/erased per VBL frame.
#define UI_ANIM_IDLE    0u
#define UI_ANIM_SHOWING 1u
#define UI_ANIM_HIDING  2u
static uint8_t ui_anim     = UI_ANIM_IDLE;
static uint8_t ui_anim_row = 0u;

// ── Player animation state machine ───────────────────────────────────────
static PlayerAnim player_anim;          /* direction + state + frame        */

// ── A* path playback state ────────────────────────────────────────────────
#define MOVE_DELAY 12           // frames between each tile step (~5 tiles/sec)
AStarPos move_path[ASTAR_MAX_PATH];
uint8_t  move_path_len  = 0;   // total steps in current path (0 = idle)
uint8_t  move_path_step = 0;   // next step index to execute
uint8_t  move_timer     = 0;   // counts up to MOVE_DELAY

// Shared row buffer — avoids stack allocation inside the animation helpers.
static uint8_t win_row_buf[UIWidth];

/* Write one row of the UI tilemap to the Window layer.
   UI[] values 1-8 map to UI_Tiles[0-7] at UI_TILE_BASE.
   Value 0 and value 9 (blank fill used in the panel interior) both → tile 0. */
static void win_write_row(uint8_t row) {
    uint8_t col;
    for (col = 0u; col < UIWidth; col++) {
        uint8_t t = UI[(uint16_t)row * UIWidth + col];
        win_row_buf[col] = (t >= 1u && t <= 8u) ? (uint8_t)(UI_TILE_BASE + t - 1u) : 0u;
    }
    set_win_tiles(0u, row, UIWidth, 1u, win_row_buf);
}

// Erase one Window row (fill with blank tile 0 = font_min blank glyph).
static void win_clear_row(uint8_t row) {
    uint8_t col;
    for (col = 0u; col < UIWidth; col++) win_row_buf[col] = 0u;
    set_win_tiles(0u, row, UIWidth, 1u, win_row_buf);
}

// ── Path highlight helpers ────────────────────────────────────────────────
// Restore one BKG cell to whatever the grid data says it should be.
static void restore_bkg_tile(uint8_t gx, uint8_t gy) {
    uint8_t t;
    switch (grid[gx][gy].type) {
    case TILE_GRASS: t = GRASS_TILE; break;
    default:         t = EMPTY_TILE; break;
    }
    set_bkg_tiles(GRID_ORIGIN_X + gx, GRID_ORIGIN_Y + gy, 1u, 1u, &t);
}

// Draw the path-highlight tile (Selector[1]) over every step in the current
// path except step 0 (the player's starting tile).
static void draw_path_tiles(void) {
    uint8_t t = PATH_HIGHLIGHT_TILE;
    uint8_t i;
    for (i = 1u; i < move_path_len; i++) {
        set_bkg_tiles(GRID_ORIGIN_X + move_path[i].x,
                      GRID_ORIGIN_Y + move_path[i].y, 1u, 1u, &t);
    }
}

// Restore every highlighted step in the current path (used before a new
// path overwrites move_path[], so all tiles are cleaned up at once).
static void clear_path_tiles(void) {
    uint8_t i;
    for (i = 1u; i < move_path_len; i++) {
        restore_bkg_tile(move_path[i].x, move_path[i].y);
    }
}

// Write all text content on top of the tile map (called once per show cycle).
static void ui_write_text(void) {
    ui_print(3u,  2u, "MAGIC");
    ui_print(3u,  4u, "ATTACK");
    ui_print(3u,  6u, "END");
    ui_print(14u, 2u, "HP");
    ui_print_uint8(17u, 2u, 10u);
    ui_print(14u, 4u, "ATK");
    ui_print_uint8(18u, 4u, 5u);
}

// ── Player grid position (mirrors player.x/y but in tile coords) ──────────
// Initial value matches setupPlayer: OAM (104,16) → screen (96,0) → tile (12,0)
uint8_t player_grid_x = 12;
uint8_t player_grid_y = 0;

// ─────────────────────────────────────────────
// init_grid()
// Populates grid[][] with default cell data.
// Equivalent to Godot's _ready() loop:
//   for x in GridSize / for y in GridSize
//     Dic[cell] = { "Type": "Grass", ... }
//
// Does NOT call set_bkg_tiles() — level1 already covers
// the full 20×18 screen so the BKG is already drawn.
// ─────────────────────────────────────────────

void init_grid(void)
{
    for (uint8_t y = 0; y < GRID_SIZE; y++)
    {
        for (uint8_t x = 0; x < GRID_SIZE; x++)
        {
            grid[x][y].type = TILE_GRASS;
        }
    }
}

// ─────────────────────────────────────────────
// init_overlay()
// Sets up the Window layer as the selection overlay.
// Equivalent to Godot's layer 1 (second TileMap layer).
// Fills the grid region with EMPTY_TILE (tile 0) so
// the BKG shows through everywhere by default.
// ─────────────────────────────────────────────

void init_overlay(void)
{
    /* Selector[0] = cursor sprite — load into sprite VRAM. */
    set_sprite_data(SELECTOR_TILE_BASE, 1, Selector);
    /* Selector[1] = path-highlight — must be loaded via set_bkg_data so the
       BKG layer reads it from the correct tile bank (sprite VRAM and BKG VRAM
       are separate until both are explicitly written). */
    set_bkg_data(PATH_HIGHLIGHT_TILE, 1, Selector + 16u);
    set_sprite_tile(4, SELECTOR_TILE_BASE);
    set_sprite_prop(4, S_PALETTE);
    OBP1_REG = 0x00;
}

// ─────────────────────────────────────────────
// clear_overlay()
// Erases all highlights from the Window layer.
// Equivalent to Godot's per-frame erase loop:
//   for y in GridSize / for x in GridSize
//     erase_cell(1, Vector2(x,y))
// ─────────────────────────────────────────────

void clear_overlay(void)
{
    // No-op: sprite floats above BKG without modifying any tile data,
    // so there is nothing to restore when the cursor moves.
}

// ─────────────────────────────────────────────
// draw_grid()
// Draws the BKG layer directly from grid[][] data.
// Replaces the static set_bkg_tiles(0, 0, 20, 18, level1) call.
// Each cell's TileType maps to a tile index in Tileset[].
// ─────────────────────────────────────────────

void draw_grid(void)
{
    for (uint8_t y = 0; y < GRID_SIZE; y++)
    {
        for (uint8_t x = 0; x < GRID_SIZE; x++)
        {
            uint8_t t;

            // Map TileType → tileset index
            // Extend this switch when adding new terrain types
            switch (grid[x][y].type)
            {
            case TILE_GRASS:
                t = GRASS_TILE;
                break; // tile 1 — small grass
            default:
                t = EMPTY_TILE;
                break; // tile 0 — fallback
            }

            // Draw one tile onto the BKG layer at this grid position
            set_bkg_tiles(GRID_ORIGIN_X + x, GRID_ORIGIN_Y + y, 1, 1, &t);
        }
    }
}

// ─────────────────────────────────────────────
// draw_cursor()
// Places tile 14 on the Window layer at the cursor position.
// Equivalent to Godot's:
//   if Dic.has(tile): set_cell(1, tile, 0, Vector2i(9,0), 0)
// Bounds check is unnecessary — handle_input() clamps the cursor.
// ─────────────────────────────────────────────

void draw_cursor(void)
{
    // Game Boy OAM offsets: X+8 and Y+16 map hardware coords to screen pixel (0,0).
    move_sprite(4, (GRID_ORIGIN_X + cursor_x) * 8 + 8,
                (GRID_ORIGIN_Y + cursor_y) * 8 + 16);
}

// ─────────────────────────────────────────────
// handle_input()
// Moves the cursor with the d-pad, one tile at a time.
// Replaces Godot's mouse → local_to_map() position tracking.
// Returns 1 if the cursor moved this frame, 0 otherwise.
// ─────────────────────────────────────────────

uint8_t handle_input(void)
{
    uint8_t keys = joypad();
    uint8_t moved = 0;

    if (input_timer == 0)
    {
        if ((keys & J_RIGHT) && cursor_x < GRID_SIZE - 1)
        {
            cursor_x++;
            moved = 1;
        }
        else if ((keys & J_LEFT) && cursor_x > 0)
        {
            cursor_x--;
            moved = 1;
        }
        else if ((keys & J_DOWN) && cursor_y < GRID_SIZE - 1)
        {
            cursor_y++;
            moved = 1;
        }
        else if ((keys & J_UP) && cursor_y > 0)
        {
            cursor_y--;
            moved = 1;
        }

        if (moved)
            input_timer = INPUT_DELAY; // arm the repeat delay after a move
    }
    else
    {
        input_timer--; // count down delay, block movement until it hits 0
    }

    // Release detection: reset timer instantly when no direction is held,
    // so the first press of a new direction always feels immediate.
    if (!(keys & (J_RIGHT | J_LEFT | J_UP | J_DOWN)))
    {
        input_timer = 0;
    }

    return moved;
}

// ─────────────────────────────────────────────
// Fade in / out functions
// ─────────────────────────────────────────────
void performantdelay(UINT8 numloops)
{
    UINT8 ii;
    for (ii = 0; ii < numloops; ii++)
    {
        wait_vbl_done();
    }
}

void fadeout(void)
{
    // uses pallette manipulation to trigger a fadeout effect
    for (i = 0; i < 4; i++)
    {
        switch (i)
        {
        case 0:
            BGP_REG = 0xE4;
            break;
        case 1:
            BGP_REG = 0xF9;
            break;
        case 2:
            BGP_REG = 0xFE;
            break;
        case 3:
            BGP_REG = 0xFF;
            break;
        }
        performantdelay(10);
    }
}

void fadein(void)
{
    // uses pallette manipulation to trigger a fadeout effect
    for (i = 0; i < 3; i++)
    {
        switch (i)
        {
        case 0:
            BGP_REG = 0xFE;
            break;
        case 1:
            BGP_REG = 0xF9;
            break;
        case 2:
            BGP_REG = 0xE4;
            break;
        }
        performantdelay(10);
    }
}

// ─────────────────────────────────────────────
// Player & Enemy Metatiles setup
// ─────────────────────────────────────────────

void setupPlayer(void)
{
    // loads sprite data and position into memory
    // Top-right of the 15x15 grid: tile column 12, row 0
    // Screen pixel (96, 0) → raw OAM x = screen_x+8, y = screen_y+16
    player.x = 104;
    player.y = 16;
    player.width = 16;
    player.height = 16;

    /* OAM slots 0-3 are permanently assigned to the player.
       player_anim_apply() writes the tile indices; movegamecharacter() writes
       the screen positions.  The spriteids are still used by movegamecharacter. */
    player.spriteids[0] = 0;
    player.spriteids[1] = 1;
    player.spriteids[2] = 2;
    player.spriteids[3] = 3;

    /* Initialise the animation state machine and push the initial frame. */
    player_anim_init(&player_anim);
    player_anim_apply(&player_anim);

    // Player uses OBP0 with a normal palette so it is visible
    OBP0_REG = 0xE4;

    // move the character
    movegamecharacter(&player, player.x, player.y);
}

void movegamecharacter(struct GameCharacter *character, UINT8 x, UINT8 y)
{
    // takes a game character as a struct along with positional data and moves everything
    move_sprite(character->spriteids[0], x, y);
    move_sprite(character->spriteids[1], x + spritesize, y);
    move_sprite(character->spriteids[2], x, y + spritesize);
    move_sprite(character->spriteids[3], x + spritesize, y + spritesize);
}

// ── A* walkability callback ───────────────────────────────────────────────
// Returns 1 if the tile at (x,y) can be entered by the player.
// Extend this when new TileTypes (water, walls, etc.) are added.
static uint8_t is_walkable(uint8_t x, uint8_t y) {
    return grid[x][y].type == TILE_GRASS;
}

// ─────────────────────────────────────────────
// main()
// ─────────────────────────────────────────────

void main(void)
{
    DISPLAY_OFF;
    disable_interrupts();
    gbt_play(song_Data, 2, 7);
    gbt_loop(1);
    set_interrupts(VBL_IFLAG);
    enable_interrupts();

    // BGP_REG = 0xE4;

    /* Only returns on START or CONTINUE; MULTIPLAYER loops inside the titlescreen.
       Future: inspect return value to distinguish START vs CONTINUE (load save). */
    run_titlescreen();
    fadeout();         /* fade to white before reloading VRAM for the game */

    // Font must be loaded FIRST — font_init resets the VRAM tile counter to 0.
    // font_min occupies VRAM tiles 0-36 (37 tiles: blank + digits + A-Z).
    font_init();
    font_load(font_min);

    // Game map tileset: 31 tiles at TILE_BASE=37.
    set_bkg_data(TILE_BASE, 31, Tileset);

    // Dedicated UI border tiles: 8 tiles at UI_TILE_BASE=68.
    set_bkg_data(UI_TILE_BASE, 8, UI_Tiles);

    // Player sprite tiles: 16 tiles (4 frames × 4 sub-tiles) at PLAYER_TILE_BASE=76.
    set_sprite_data(PLAYER_TILE_BASE, 16, Player);

    setupPlayer(); // assign OAM slots 0-3 to VRAM tiles PLAYER_TILE_BASE..+3

    // Clear the full 20×18 BKG tilemap so stale VRAM from the boot ROM
    // doesn't bleed through outside the grid area.
    {
        uint8_t t = EMPTY_TILE;
        for (uint8_t y = 0; y < 18; y++)
            for (uint8_t x = 0; x < 20; x++)
                set_bkg_tiles(x, y, 1, 1, &t);
    }

    init_grid(); // populate grid[][] with TILE_GRASS for each cell
    draw_grid();

    fadein();

    scroll_bkg(0, 0);
    SHOW_BKG;
    SHOW_SPRITES;

    // ── Grid and overlay setup ────────────────────────────────────────

    init_overlay(); // set up cursor sprite (OAM slot 4, OBP1)
    draw_cursor();  // draw initial highlight at (0,0)

    // UI pointer: OAM slots 5-8, VRAM tiles 73-76.
    // Starts hidden; shown when the UI panel is toggled open with SELECT.
    pointer_init(&ui_ptr, POINTER_TILE_BASE, POINTER_OAM_BASE);

    // Position the Window at screen (0,0) — content is written lazily by
    // the slide-in animation, so nothing is drawn here.
    move_win(7u, 0u);

    DISPLAY_ON;

    while (1)
    {
        wait_vbl_done();

        // ── UI slide animation (one Window row per VBL frame) ────────────
        if (ui_anim == UI_ANIM_SHOWING) {
            win_write_row(ui_anim_row++);
            if (ui_anim_row >= UIHeight) {
                // All rows revealed — write text and activate the menu.
                ui_write_text();
                ui_visible  = 1u;
                ui_menu_idx = 0u;
                pointer_move(&ui_ptr, UI_MENU_X, UI_MENU_Y[0u]);
                ui_anim = UI_ANIM_IDLE;
            }
        } else if (ui_anim == UI_ANIM_HIDING) {
            win_clear_row(--ui_anim_row);
            if (ui_anim_row == 0u) {
                HIDE_WIN;
                // Restore player and cursor now that the panel is gone.
                movegamecharacter(&player,
                                  player_grid_x * 8 + 8,
                                  player_grid_y * 8 + 16);
                draw_cursor();
                ui_anim = UI_ANIM_IDLE;
            }
        }

        // ── Button edge detection (one joypad read shared by SELECT and A) ──
        uint8_t keys = joypad();

        // Only accept SELECT while no animation is already running.
        if ((keys & J_SELECT) && !(prev_keys & J_SELECT) &&
            ui_anim == UI_ANIM_IDLE)
        {
            if (!ui_visible) {
                // Hide player (OAM 0-3) and cursor (OAM 4) before panel slides in.
                move_sprite(0, 0, 0);
                move_sprite(1, 0, 0);
                move_sprite(2, 0, 0);
                move_sprite(3, 0, 0);
                move_sprite(4, 0, 0);
                // Slide the panel down from the top, one row per frame.
                SHOW_WIN;
                ui_anim     = UI_ANIM_SHOWING;
                ui_anim_row = 0u;
            } else {
                // Slide the panel back up, one row per frame.
                pointer_hide(&ui_ptr);
                ui_visible  = 0u;
                ui_anim     = UI_ANIM_HIDING;
                ui_anim_row = UIHeight;
            }
        }

        if (ui_visible)
        {
            // ── UI menu navigation ────────────────────────────────────────
            if ((keys & J_UP) && !(prev_keys & J_UP))
            {
                if (ui_menu_idx > 0)
                {
                    ui_menu_idx--;
                    pointer_move(&ui_ptr, UI_MENU_X, UI_MENU_Y[ui_menu_idx]);
                }
            }
            if ((keys & J_DOWN) && !(prev_keys & J_DOWN))
            {
                if (ui_menu_idx < UI_MENU_COUNT - 1)
                {
                    ui_menu_idx++;
                    pointer_move(&ui_ptr, UI_MENU_X, UI_MENU_Y[ui_menu_idx]);
                }
            }
            if ((keys & J_A) && !(prev_keys & J_A))
            {
                pointer_anim_select(&ui_ptr);
                /* TODO: act on ui_menu_idx (MAGIC=0, ATTACK=1, END=2) */
            }
        }
        else
        {
            // ── Grid game input ───────────────────────────────────────────
            // A button: find a path to the cursor and start walking.
            if ((keys & J_A) && !(prev_keys & J_A))
            {
                // Erase any previous path highlight before writing a new one.
                if (move_path_len > 0u) clear_path_tiles();

                uint8_t steps = astar_find(player_grid_x, player_grid_y,
                                           cursor_x, cursor_y,
                                           is_walkable, move_path);
                if (steps > 1u)
                {
                    move_path_len  = steps;
                    move_path_step = 1u;
                    move_timer     = 0u;
                    draw_path_tiles();   // highlight the full route on BKG
                }
                else
                {
                    move_path_len = 0u;  // no path — nothing to highlight
                }
            }

            if (handle_input())
            {
                clear_overlay();
                draw_cursor();
            }
        }

        prev_keys = keys;

        // ── Advance player one tile every MOVE_DELAY frames ───────────────
        if (move_path_step < move_path_len)
        {
            if (++move_timer >= MOVE_DELAY)
            {
                move_timer = 0;
                uint8_t s = move_path_step;

                /* Determine facing direction from this path step. */
                {
                    PlayerDir step_dir;
                    if      (move_path[s].x > move_path[s - 1u].x) step_dir = DIR_RIGHT;
                    else if (move_path[s].x < move_path[s - 1u].x) step_dir = DIR_LEFT;
                    else if (move_path[s].y > move_path[s - 1u].y) step_dir = DIR_DOWN;
                    else                                            step_dir = DIR_UP;
                    player_anim_set_dir(&player_anim, step_dir);
                    player_anim_set_state(&player_anim, ANIM_WALK);
                    player_anim_apply(&player_anim);
                }

                player_grid_x = move_path[s].x;
                player_grid_y = move_path[s].y;
                movegamecharacter(&player,
                                  player_grid_x * 8 + 8,
                                  player_grid_y * 8 + 16);

                // Clear the tile the player just stepped off.
                if (s >= 2u) restore_bkg_tile(move_path[s - 1u].x,
                                              move_path[s - 1u].y);

                move_path_step++;

                // When the player lands on the destination, return to idle.
                if (move_path_step >= move_path_len) {
                    restore_bkg_tile(move_path[s].x, move_path[s].y);
                    player_anim_set_state(&player_anim, ANIM_IDLE);
                    player_anim_apply(&player_anim);
                }
            }
        }

        /* Advance multi-frame animations (walk, attack) at their defined speeds. */
        player_anim_tick(&player_anim);

        gbt_update();
    }
}
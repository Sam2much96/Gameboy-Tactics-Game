#pragma bank 1   /* battle scene code lives in ROM bank 1 — see battle/battle.h */

#include "grid.h"
#include "../UI/ui_text.h"   /* TILE_BASE, SELECTOR_TILE_BASE, CURSOR_* */

_Static_assert(GRID_W == ASTAR_GRID_W && GRID_H == ASTAR_GRID_H,
    "grid.h and astar.h disagree on the grid size");

#define INPUT_DELAY 10

// Tile indices are absolute VRAM positions (see ui_text.h's VRAM layout).
#define GRASS_TILE          (TILE_BASE + 1)
#define EMPTY_TILE          (TILE_BASE + 0)
/* Selector[1] = path-highlight BKG tile */
#define PATH_HIGHLIGHT_TILE (SELECTOR_TILE_BASE + 1)

// ─────────────────────────────────────────────
// THE GRID — equivalent to Godot's Dic{}
// ─────────────────────────────────────────────

Cell grid[GRID_W][GRID_H];

uint8_t cursor_x = 0; // current cursor column (0 to GRID_W-1)
uint8_t cursor_y = 0; // current cursor row    (0 to GRID_H-1)

static uint8_t input_timer = 0;

/* Corner of the cursor box: top row + left column, color 1.  OBP1 maps it
   to white; flipping it into the other three corners closes the box. */
static const unsigned char cursor_corner[16] = {
    0xFF,0x00, 0x80,0x00, 0x80,0x00, 0x80,0x00,
    0x80,0x00, 0x80,0x00, 0x80,0x00, 0x80,0x00,
};

// ─────────────────────────────────────────────
// grid_init()
// Populates grid[][] with default cell data.
// Equivalent to Godot's _ready() loop:
//   for x in GridSize / for y in GridSize
//     Dic[cell] = { "Type": "Grass", ... }
// ─────────────────────────────────────────────

void grid_init(void)
{
    /* Selector[1] = path-highlight — must be loaded via set_bkg_data so the
       BKG layer reads it from the correct tile bank. */
    set_bkg_data(PATH_HIGHLIGHT_TILE, 1, Selector + 16u);

    for (uint8_t y = 0; y < GRID_H; y++)
    {
        for (uint8_t x = 0; x < GRID_W; x++)
        {
            grid[x][y].type = TILE_GRASS;
        }
    }
}

// Fill one 16×16 cell (2×2 BKG tiles) with a single tile index.
static void fill_cell(uint8_t gx, uint8_t gy, uint8_t t)
{
    uint8_t tiles[4];
    tiles[0] = tiles[1] = tiles[2] = tiles[3] = t;
    set_bkg_tiles(GRID_ORIGIN_X + gx * 2u, GRID_ORIGIN_Y + gy * 2u, 2u, 2u, tiles);
}

void grid_restore_cell(uint8_t gx, uint8_t gy)
{
    // Map TileType → tileset index
    // Extend this switch when adding new terrain types
    switch (grid[gx][gy].type)
    {
    case TILE_GRASS: fill_cell(gx, gy, GRASS_TILE); break;
    default:         fill_cell(gx, gy, EMPTY_TILE); break;
    }
}

void grid_highlight_cell(uint8_t gx, uint8_t gy)
{
    fill_cell(gx, gy, PATH_HIGHLIGHT_TILE);
}

// ─────────────────────────────────────────────
// grid_draw()
// Draws the BKG layer directly from grid[][] data.
// ─────────────────────────────────────────────

void grid_draw(void)
{
    for (uint8_t y = 0; y < GRID_H; y++)
        for (uint8_t x = 0; x < GRID_W; x++)
            grid_restore_cell(x, y);
}

uint8_t grid_in_bounds(int8_t x, int8_t y)
{
    return x >= 0 && y >= 0 && x < (int8_t)GRID_W && y < (int8_t)GRID_H;
}

uint8_t grid_distance(uint8_t ax, uint8_t ay, uint8_t bx, uint8_t by)
{
    uint8_t dx = (ax > bx) ? (ax - bx) : (bx - ax);
    uint8_t dy = (ay > by) ? (ay - by) : (by - ay);
    return dx + dy;
}

void grid_show_path(const AStarPos *path, uint8_t len)
{
    uint8_t i;
    for (i = 1u; i < len; i++) grid_highlight_cell(path[i].x, path[i].y);
}

void grid_clear_path(const AStarPos *path, uint8_t len)
{
    uint8_t i;
    for (i = 1u; i < len; i++) grid_restore_cell(path[i].x, path[i].y);
}

// ── A* walkability callback ───────────────────────────────────────────────
// Returns 1 if the tile at (x,y) can be entered: terrain must be walkable
// (extend this when new TileTypes are added) and no unit may stand there.
static const AStarPos *path_blockers;
static uint8_t         path_blocker_count;

static uint8_t path_walkable(uint8_t x, uint8_t y)
{
    uint8_t i;
    if (grid[x][y].type != TILE_GRASS) return 0u;
    for (i = 0u; i < path_blocker_count; i++)
        if (path_blockers[i].x == x && path_blockers[i].y == y) return 0u;
    return 1u;
}

uint8_t grid_compute_path(uint8_t sx, uint8_t sy, uint8_t tx, uint8_t ty,
                          const AStarPos *blockers, uint8_t n,
                          AStarPos *out)
{
    if (!grid_in_bounds((int8_t)sx, (int8_t)sy) ||
        !grid_in_bounds((int8_t)tx, (int8_t)ty)) return 0u;
    path_blockers      = blockers;
    path_blocker_count = n;
    /* A* never reaches an unwalkable goal and returns 0, which is exactly
       Godot's "target is solid → empty path". */
    return astar_find(sx, sy, tx, ty, path_walkable, out);
}

// ─────────────────────────────────────────────
// Cursor — replaces mouse position tracking:
//   var tile = local_to_map(get_global_mouse_position())
// On Game Boy there is no mouse — the d-pad moves the cursor instead
// ─────────────────────────────────────────────

void cursor_init(void)
{
    uint8_t b = CURSOR_OAM_BASE;
    set_sprite_data(CURSOR_TILE_BASE, 1u, cursor_corner);
    set_sprite_tile(b + 0u, CURSOR_TILE_BASE);
    set_sprite_tile(b + 1u, CURSOR_TILE_BASE);
    set_sprite_tile(b + 2u, CURSOR_TILE_BASE);
    set_sprite_tile(b + 3u, CURSOR_TILE_BASE);
    set_sprite_prop(b + 0u, S_PALETTE);                      /* TL */
    set_sprite_prop(b + 1u, S_PALETTE | S_FLIPX);            /* TR */
    set_sprite_prop(b + 2u, S_PALETTE | S_FLIPY);            /* BL */
    set_sprite_prop(b + 3u, S_PALETTE | S_FLIPX | S_FLIPY);  /* BR */
    OBP1_REG = 0x00;   /* every shade → white */
}

void cursor_draw(void)
{
    uint8_t x = CELL_OAM_X(cursor_x);
    uint8_t y = CELL_OAM_Y(cursor_y);
    uint8_t b = CURSOR_OAM_BASE;
    move_sprite(b + 0u, x,      y);
    move_sprite(b + 1u, x + 8u, y);
    move_sprite(b + 2u, x,      y + 8u);
    move_sprite(b + 3u, x + 8u, y + 8u);
}

void cursor_hide(void)
{
    uint8_t i;
    for (i = 0u; i < 4u; i++) move_sprite(CURSOR_OAM_BASE + i, 0u, 0u);
}

// ─────────────────────────────────────────────
// cursor_handle_input()
// Moves the cursor with the d-pad, one cell at a time.
// Returns 1 if the cursor moved this frame, 0 otherwise.
// ─────────────────────────────────────────────

uint8_t cursor_handle_input(uint8_t keys)
{
    uint8_t moved = 0;

    if (input_timer == 0)
    {
        if ((keys & J_RIGHT) && cursor_x < GRID_W - 1)
        {
            cursor_x++;
            moved = 1;
        }
        else if ((keys & J_LEFT) && cursor_x > 0)
        {
            cursor_x--;
            moved = 1;
        }
        else if ((keys & J_DOWN) && cursor_y < GRID_H - 1)
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

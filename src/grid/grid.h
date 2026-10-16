#ifndef GRID_GRID_H
#define GRID_GRID_H

#include <gb/gb.h>
#include "../pathfinding/astar.h"

/* ── Grid, cursor & pathfinding ──────────────────────────────────────────────
   Godot equivalent: tile_map.gd (TacticsGrid).

   Cells are 16×16 px (2×2 BKG tiles) so a 16×16 unit fills exactly one cell
   and neighbours never overlap — the old 8 px grid put adjacent units on top
   of each other.  10×9 cells fill the whole 160×144 screen (Godot's grid is
   10×10, but only 10×9 fits).  The dialogue box (UI/dialogue.c) slides up
   over the bottom two rows while a message is showing; sprites always
   draw above the Window, so a unit standing there shows on top of it. */

#define GRID_W   10u
#define GRID_H   9u
#define CELL_PX  16u
#define GRID_ORIGIN_X 0u   /* grid starts at BKG tile column 0 */
#define GRID_ORIGIN_Y 0u   /* grid starts at BKG tile row 0    */

/* Hardware OAM coordinates of a cell's top-left corner. */
#define CELL_OAM_X(gx) ((uint8_t)((gx) * CELL_PX + 8u))
#define CELL_OAM_Y(gy) ((uint8_t)((gy) * CELL_PX + 16u))

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

typedef struct
{
    TileType type; // what kind of tile this cell is
} Cell;

extern Cell grid[GRID_W][GRID_H];

/* Cursor cell — shared by the d-pad and battle.c's A-button handling. */
extern uint8_t cursor_x;
extern uint8_t cursor_y;

/* Fill grid[][] with grass and draw it to the BKG layer. */
void grid_init(void);
void grid_draw(void);

uint8_t grid_in_bounds(int8_t x, int8_t y);

/* Manhattan distance — Godot's Utils._distance(). */
uint8_t grid_distance(uint8_t ax, uint8_t ay, uint8_t bx, uint8_t by);

/* Restore one cell to its terrain tile / paint it with the path highlight. */
void grid_restore_cell(uint8_t gx, uint8_t gy);
void grid_highlight_cell(uint8_t gx, uint8_t gy);

/* Highlight / restore every step of a path except step 0 (the mover's cell). */
void grid_show_path(const AStarPos *path, uint8_t len);
void grid_clear_path(const AStarPos *path, uint8_t len);

/* 4-directional A* from (sx,sy) to (tx,ty) — Godot's compute_path_for().
   Cells in blockers[0..n) are treated as solid for this search only, so
   units can't path through each other.  A blocked target yields no path.
   Returns the step count written to out (>= 2 on success) or 0. */
uint8_t grid_compute_path(uint8_t sx, uint8_t sy, uint8_t tx, uint8_t ty,
                          const AStarPos *blockers, uint8_t n,
                          AStarPos *out);

/* 16×16 cursor box: 4 sprites at CURSOR_OAM_BASE built from one corner tile. */
void cursor_init(void);
void cursor_draw(void);
void cursor_hide(void);

/* D-pad cursor movement with INPUT_DELAY key repeat.  Pass this frame's
   joypad() state; returns 1 if the cursor moved. */
uint8_t cursor_handle_input(uint8_t keys);

#endif /* GRID_GRID_H */

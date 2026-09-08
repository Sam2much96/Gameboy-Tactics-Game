#ifndef ASTAR_H
#define ASTAR_H

#include <gb/gb.h>

/* Grid dimensions — must match GRID_SIZE in main.c */
#define ASTAR_GRID_W  15
#define ASTAR_GRID_H  15

/* Maximum path length returned.
   Longest possible route on a 15x15 grid is 28 steps (corner to corner);
   32 gives a safe margin without wasting WRAM. */
#define ASTAR_MAX_PATH  32

/* One step in the returned path. */
typedef struct {
    uint8_t x;
    uint8_t y;
} AStarPos;

/*
 * Walkability callback.  Return non-zero if tile (x,y) can be traversed.
 *
 * Typical implementation in main.c:
 *   uint8_t is_walkable(uint8_t x, uint8_t y) {
 *       return grid[x][y].type == TILE_GRASS;
 *   }
 */
typedef uint8_t (*astar_walkable_fn)(uint8_t x, uint8_t y);

/*
 * astar_find — run A* from (sx,sy) to (gx,gy).
 *
 * out_path  : caller-supplied array of at least ASTAR_MAX_PATH AStarPos.
 *             Index 0 = start tile, index (return value - 1) = goal tile.
 * walkable  : callback that says which tiles can be entered.
 *
 * Returns the number of steps written into out_path (>= 2 on success),
 * or 0 if no path exists.
 */
uint8_t astar_find(uint8_t sx, uint8_t sy,
                   uint8_t gx, uint8_t gy,
                   astar_walkable_fn walkable,
                   AStarPos *out_path);

#endif /* ASTAR_H */

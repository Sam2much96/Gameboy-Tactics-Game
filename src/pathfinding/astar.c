#include <string.h>
#include "astar.h"

/* ── Index mapping ────────────────────────────────────────────────────────
   Row stride rounded up to 16 (next power of 2 ≥ ASTAR_GRID_W = 15).
   IDX(x,y) becomes a bit-shift + OR instead of  y * 15 + x,
   saving several instructions on the SM83 for every neighbour lookup.    */
#define ASTAR_STRIDE  16
#define ASTAR_TOTAL   (ASTAR_STRIDE * ASTAR_GRID_H)   /* 240 slots        */
#define IDX(x, y)     (((uint8_t)(y) << 4) | (uint8_t)(x))

/* ── Per-node state (four flat arrays, not a struct array) ────────────────
   Flat arrays let us reset each field with a single memset call rather
   than a nested struct-field loop.                                        */
static uint8_t node_g    [ASTAR_TOTAL]; /* g-cost from start; 0xFF = unvisited */
static uint8_t node_flags[ASTAR_TOTAL]; /* FLAG_OPEN | FLAG_CLOSED              */
static uint8_t node_par_x[ASTAR_TOTAL]; /* parent x; 0xFF = no parent          */
static uint8_t node_par_y[ASTAR_TOTAL]; /* parent y                             */

#define FLAG_OPEN   0x01
#define FLAG_CLOSED 0x02

/* ── Min-heap (binary heap on f = g + h) ─────────────────────────────────
   Replaces the O(n) linear scan in pop_best with O(log n) operations.
   Lazy deletion: stale entries pushed before a node was closed are simply
   skipped when popped (FLAG_CLOSED check).  With a consistent heuristic
   each node is pushed at most once, so heap_size ≤ 225 always.           */
typedef struct { uint8_t f; uint8_t x; uint8_t y; } HeapEntry;
static HeapEntry heap[ASTAR_GRID_W * ASTAR_GRID_H];   /* 225 × 3 = 675 B */
static uint8_t   heap_size;

static void heap_push(uint8_t f, uint8_t x, uint8_t y) {
    uint8_t i = heap_size++;
    heap[i].f = f;
    heap[i].x = x;
    heap[i].y = y;
    /* Sift up until heap property holds */
    while (i > 0) {
        uint8_t p = (i - 1u) >> 1;
        if (heap[p].f <= heap[i].f) break;
        HeapEntry tmp = heap[p]; heap[p] = heap[i]; heap[i] = tmp;
        i = p;
    }
}

/* Pop the entry with the lowest f; caller must ensure heap_size > 0. */
static void heap_pop(uint8_t *ox, uint8_t *oy) {
    *ox = heap[0].x;
    *oy = heap[0].y;
    heap[0] = heap[--heap_size];
    /* Sift down */
    uint8_t i = 0;
    while (1) {
        uint8_t l = (i << 1) + 1u;
        uint8_t r = l + 1u;
        uint8_t s = i;
        if (l < heap_size && heap[l].f < heap[s].f) s = l;
        if (r < heap_size && heap[r].f < heap[s].f) s = r;
        if (s == i) break;
        HeapEntry tmp = heap[s]; heap[s] = heap[i]; heap[i] = tmp;
        i = s;
    }
}

/* ── Heuristic ───────────────────────────────────────────────────────────*/
static uint8_t manhattan(uint8_t ax, uint8_t ay, uint8_t bx, uint8_t by) {
    uint8_t dx = (ax > bx) ? (ax - bx) : (bx - ax);
    uint8_t dy = (ay > by) ? (ay - by) : (by - ay);
    return dx + dy;
}

static const int8_t DIR_DX[4] = {  0,  0, -1,  1 };
static const int8_t DIR_DY[4] = { -1,  1,  0,  0 };

/* ── Public API ──────────────────────────────────────────────────────────*/
uint8_t astar_find(uint8_t sx, uint8_t sy,
                   uint8_t gx, uint8_t gy,
                   astar_walkable_fn walkable,
                   AStarPos *out_path)
{
    /* Two byte-fill passes — far faster than the old nested struct loop */
    memset(node_g,     0xFF, ASTAR_TOTAL);
    memset(node_flags, 0,    ASTAR_TOTAL);
    heap_size = 0;

    uint8_t si = IDX(sx, sy);
    node_g    [si] = 0;
    node_flags[si] = FLAG_OPEN;
    node_par_x[si] = 0xFF;          /* sentinel: start tile has no parent */
    heap_push(manhattan(sx, sy, gx, gy), sx, sy);

    while (heap_size > 0) {
        uint8_t cx, cy;
        heap_pop(&cx, &cy);

        uint8_t ci = IDX(cx, cy);

        /* Lazy deletion: discard entries pushed before this node was closed */
        if (node_flags[ci] & FLAG_CLOSED) continue;
        node_flags[ci] = FLAG_CLOSED;

        if (cx == gx && cy == gy) {
            /* ── Reconstruct path (two passes; no large stack arrays) ───── */
            /* Pass 1: count steps from goal back to start */
            uint8_t len = 0;
            uint8_t tx = gx, ty = gy;
            while (len < ASTAR_MAX_PATH) {
                ++len;
                uint8_t px = node_par_x[IDX(tx, ty)];
                if (px == 0xFF) break;
                uint8_t py = node_par_y[IDX(tx, ty)];
                tx = px; ty = py;
            }
            /* Pass 2: retrace and write start→goal (index from the end) */
            uint8_t i = len;
            tx = gx; ty = gy;
            while (i > 0) {
                --i;
                out_path[i].x = tx;
                out_path[i].y = ty;
                uint8_t px = node_par_x[IDX(tx, ty)];
                if (px == 0xFF) break;
                uint8_t py = node_par_y[IDX(tx, ty)];
                tx = px; ty = py;
            }
            return len;
        }

        /* ── Expand 4 neighbours ──────────────────────────────────────── */
        uint8_t cg  = node_g[ci];
        uint8_t dir;
        for (dir = 0; dir < 4; ++dir) {
            int8_t nx = (int8_t)cx + DIR_DX[dir];
            int8_t ny = (int8_t)cy + DIR_DY[dir];
            if (nx < 0 || ny < 0 ||
                nx >= (int8_t)ASTAR_GRID_W ||
                ny >= (int8_t)ASTAR_GRID_H)
                continue;

            uint8_t ux = (uint8_t)nx;
            uint8_t uy = (uint8_t)ny;
            uint8_t ni = IDX(ux, uy);

            if (node_flags[ni] & FLAG_CLOSED) continue;
            if (!walkable(ux, uy))            continue;

            uint8_t ng = cg + 1u;
            if (ng < node_g[ni]) {
                node_g    [ni] = ng;
                node_par_x[ni] = cx;
                node_par_y[ni] = cy;
                /* Push new entry; stale old entry (if any) ignored via lazy deletion */
                heap_push(ng + manhattan(ux, uy, gx, gy), ux, uy);
            }
        }
    }

    return 0;   /* no path found */
}

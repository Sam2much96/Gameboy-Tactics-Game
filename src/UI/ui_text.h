#ifndef UI_TEXT_H
#define UI_TEXT_H

#include <gb/gb.h>

/* ── VRAM layout ────────────────────────────────────────────────────────────
   These live here (not in the GBMB-generated UI.h) so regenerating the map
   files never clobbers them.

   tiles  0- 36:  font_min glyphs        (font_init + font_load)
   tiles 37- 67:  game Tileset[]         (31 tiles, TILE_BASE + 0..30)
   tiles 68- 75:  UI_Tiles[]             (8 tiles,  UI_TILE_BASE + 0..7)
   tiles 76- 91:  Player[]               (16 tiles: 4 frames × 4 sub-tiles)
   tiles 92- 94:  Selector[]             ( 3 tiles: cursor, path-highlight, blank)
   tiles 95-102:  PointerSprites[]       ( 8 tiles: 2 frames × 4 sub-tiles)
   ──────────────────────────────────────────────────────────────────────── */
#define TILE_BASE          37
#define UI_TILE_BASE       (TILE_BASE + 31)          /* = 68 — dedicated UI border tiles  */
#define PLAYER_TILE_BASE   (UI_TILE_BASE + 8)        /* = 76 — 4 frames × 4 sub-tiles     */
#define SELECTOR_TILE_BASE (PLAYER_TILE_BASE + 16)   /* = 92 — cursor(+0), highlight(+1)  */
#define POINTER_TILE_BASE  (SELECTOR_TILE_BASE + 3)  /* = 95                               */

/* Default OAM slots.
   Slots 0-3 = player, slot 4 = grid cursor, slots 5-8 = UI pointer. */
#define POINTER_OAM_BASE  5

/* Tile arrays defined in ui_text.c (included from the respective data files). */
extern unsigned char UI_Tiles[];
extern unsigned char Selector[];

/* Write a null-terminated ASCII string to the Window tilemap.
   win_x / win_y are Window tile coordinates (0,0 = top-left of window).
   Supported characters: '0'-'9', 'A'-'Z', 'a'-'z'.  Everything else = blank. */
void ui_print(uint8_t win_x, uint8_t win_y, const char *str);

/* Write a decimal uint8 (0-255) to the Window tilemap. */
void ui_print_uint8(uint8_t win_x, uint8_t win_y, uint8_t value);

#endif /* UI_TEXT_H */

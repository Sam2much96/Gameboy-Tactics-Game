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
   tiles103-118:  Enemy[]                (16 tiles: 4 frames × 4 sub-tiles)
   tiles119-150:  Weapons[]              (32 tiles: 8 frames × 4 sub-tiles)
   tile     151:  grid cursor corner     ( 1 tile, flipped ×4 into a 16×16 box)
   tiles152-153:  extra glyphs '/' ','   ( 2 tiles, font_min has no punctuation)
   ──────────────────────────────────────────────────────────────────────── */
#define TILE_BASE          37u
#define UI_TILE_BASE       (TILE_BASE + 31u)          /* = 68 — dedicated UI border tiles  */
#define PLAYER_TILE_BASE   (UI_TILE_BASE + 8u)        /* = 76 — 4 frames × 4 sub-tiles     */
#define SELECTOR_TILE_BASE (PLAYER_TILE_BASE + 16u)   /* = 92 — cursor(+0), highlight(+1)  */
#define POINTER_TILE_BASE  (SELECTOR_TILE_BASE + 3u)  /* = 95                               */
#define ENEMY_TILE_BASE    (POINTER_TILE_BASE + 8u)   /* = 103 — 4 frames × 4 sub-tiles    */
#define WEAPON_TILE_BASE   (ENEMY_TILE_BASE + 16u)    /* = 119 — 8 frames × 4 sub-tiles    */
#define CURSOR_TILE_BASE   (WEAPON_TILE_BASE + 32u)   /* = 151                              */
#define GLYPH_TILE_BASE    (CURSOR_TILE_BASE + 1u)    /* = 152 — '/', ','                   */

/* OAM slots.
   Slots 0-3 = player (hardwired in player_anim_apply), 4-7 = weapon swing,
   8-11 = grid cursor, 12-15 = UI pointer, 16+ = enemies (4 slots each).
   The weapon sits right after the player so it draws over enemies it hits. */
#define WEAPON_OAM_BASE   4
#define CURSOR_OAM_BASE   8
#define POINTER_OAM_BASE  12
#define ENEMY_OAM_BASE    16

/* Tile arrays defined in ui_text.c (included from the respective data files). */
extern unsigned char UI_Tiles[];
extern unsigned char Selector[];

/* Write a null-terminated ASCII string to the Window tilemap.
   win_x / win_y are Window tile coordinates (0,0 = top-left of window).
   Supported characters: '0'-'9', 'A'-'Z', 'a'-'z'.  Everything else = blank. */
void ui_print(uint8_t win_x, uint8_t win_y, const char *str);

/* Write a decimal uint8 (0-255) to the Window tilemap. */
void ui_print_uint8(uint8_t win_x, uint8_t win_y, uint8_t value);

/* Load the extra punctuation glyphs ('/' and ',') into GLYPH_TILE_BASE.
   Call after font_load, whenever the scene's VRAM is (re)loaded. */
void ui_load_glyphs(void);

/* Blank a w×h block of the Window tilemap. */
void ui_clear(uint8_t win_x, uint8_t win_y, uint8_t w, uint8_t h);

/* Clear a w×h box, then word-wrap str into it (breaks at spaces; a word
   longer than w is cut).  Text that doesn't fit in h lines is dropped. */
void ui_print_wrapped(uint8_t win_x, uint8_t win_y, uint8_t w, uint8_t h,
                      const char *str);

/* Tiny string builders for status messages (no sprintf on the hot path).
   Both append at dst and return the new end (always NUL-terminated). */
char *ui_str_cat(char *dst, const char *src);
char *ui_str_u8(char *dst, uint8_t value);

#endif /* UI_TEXT_H */

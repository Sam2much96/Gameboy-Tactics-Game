#pragma bank 1   /* battle scene code lives in ROM bank 1 — see battle/battle.h */

#include "ui_text.h"
#include "UI tiles/UI_tiles.c"
#include "selector highlight tiles/selector.c"

/* Punctuation font_min doesn't have.  Color 3 on color 0, same as the
   font_min glyphs font_load() expands, so they match on screen. */
static const unsigned char ui_glyphs[2u * 16u] = {
    /* '/' */ 0x02,0x02, 0x04,0x04, 0x08,0x08, 0x10,0x10,
              0x20,0x20, 0x40,0x40, 0x00,0x00, 0x00,0x00,
    /* ',' */ 0x00,0x00, 0x00,0x00, 0x00,0x00, 0x00,0x00,
              0x18,0x18, 0x18,0x18, 0x30,0x30, 0x00,0x00,
};

/* Map an ASCII character to its font_min VRAM tile index.
   font_min tile layout: 0=blank, 1-10='0'-'9', 11-36='A'-'Z' (case-insensitive). */
static uint8_t char_to_tile(char ch) {
    if (ch >= '0' && ch <= '9') return (uint8_t)(1  + (ch - '0'));
    if (ch >= 'A' && ch <= 'Z') return (uint8_t)(11 + (ch - 'A'));
    if (ch >= 'a' && ch <= 'z') return (uint8_t)(11 + (ch - 'a'));
    if (ch == '/') return GLYPH_TILE_BASE + 0u;
    if (ch == ',') return GLYPH_TILE_BASE + 1u;
    return 0;
}

void ui_load_glyphs(void) {
    set_bkg_data(GLYPH_TILE_BASE, 2u, ui_glyphs);
}

void ui_print(uint8_t win_x, uint8_t win_y, const char *str) {
    uint8_t tile;
    while (*str) {
        tile = char_to_tile(*str++);
        set_win_tiles(win_x++, win_y, 1, 1, &tile);
    }
}

void ui_print_uint8(uint8_t win_x, uint8_t win_y, uint8_t value) {
    uint8_t hundreds = value / 100;
    uint8_t tens     = (value % 100) / 10;
    uint8_t ones     = value % 10;
    uint8_t tile;

    if (hundreds > 0) {
        tile = char_to_tile('0' + hundreds);
        set_win_tiles(win_x++, win_y, 1, 1, &tile);
    }
    if (hundreds > 0 || tens > 0) {
        tile = char_to_tile('0' + tens);
        set_win_tiles(win_x++, win_y, 1, 1, &tile);
    }
    tile = char_to_tile('0' + ones);
    set_win_tiles(win_x, win_y, 1, 1, &tile);
}

void ui_clear(uint8_t win_x, uint8_t win_y, uint8_t w, uint8_t h) {
    uint8_t blank = 0u;
    uint8_t x, y;
    for (y = 0u; y < h; y++)
        for (x = 0u; x < w; x++)
            set_win_tiles(win_x + x, win_y + y, 1, 1, &blank);
}

void ui_print_wrapped(uint8_t win_x, uint8_t win_y, uint8_t w, uint8_t h,
                      const char *str) {
    uint8_t line = 0u;
    uint8_t col  = 0u;
    uint8_t len, tile;

    ui_clear(win_x, win_y, w, h);
    while (*str && line < h) {
        if (*str == ' ') { str++; continue; }

        /* Measure the next word; wrap first if it won't fit on this line. */
        for (len = 0u; str[len] && str[len] != ' '; len++) ;
        if (col > 0u && col + 1u + len > w) { line++; col = 0u; }
        if (line >= h) break;
        if (col > 0u) col++;   /* the space between words */

        while (*str && *str != ' ') {
            if (col < w) {
                tile = char_to_tile(*str);
                set_win_tiles(win_x + col, win_y + line, 1, 1, &tile);
                col++;
            }
            str++;
        }
    }
}

char *ui_str_cat(char *dst, const char *src) {
    while (*src) *dst++ = *src++;
    *dst = 0;
    return dst;
}

char *ui_str_u8(char *dst, uint8_t value) {
    if (value >= 100u) *dst++ = (char)('0' + value / 100u);
    if (value >= 10u)  *dst++ = (char)('0' + (value / 10u) % 10u);
    *dst++ = (char)('0' + value % 10u);
    *dst = 0;
    return dst;
}

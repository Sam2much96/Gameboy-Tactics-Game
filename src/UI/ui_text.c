#include "ui_text.h"
#include "UI tiles/UI_tiles.c"
#include "selector highlight tiles/selector.c"

/* Map an ASCII character to its font_min VRAM tile index.
   font_min tile layout: 0=blank, 1-10='0'-'9', 11-36='A'-'Z' (case-insensitive). */
static uint8_t char_to_tile(char ch) {
    if (ch >= '0' && ch <= '9') return (uint8_t)(1  + (ch - '0'));
    if (ch >= 'A' && ch <= 'Z') return (uint8_t)(11 + (ch - 'A'));
    if (ch >= 'a' && ch <= 'z') return (uint8_t)(11 + (ch - 'a'));
    return 0;
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

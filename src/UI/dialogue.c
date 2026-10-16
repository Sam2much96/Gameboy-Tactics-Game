#pragma bank 1   /* battle scene code lives in ROM bank 1 — see battle/battle.h */

#include "dialogue.h"
#include "battle_menu.h"
#include "ui_text.h"
#include "dialogue_ui/DialogueBox.h"
#include "dialogue_ui/DialogueBox.c"

#define ANNOUNCE_TIME  96u    /* VBLs held on screen — Godot's 1.6 s */
/* DIalogueBox[] is 20×6 but its rows 0-1 are blank padding; the box
   itself (top border, 2 text rows, bottom border) is rows 2-5. */
#define BOX_MAP_ROW    2u
#define STRIP_COLS     20u
#define STRIP_ROWS     4u     /* Window rows the box occupies         */
#define TEXT_X         1u     /* text area inside the border          */
#define TEXT_Y         1u
#define TEXT_W         18u
#define TEXT_H         2u
#define BOX_BLANK      8u     /* map value past UI_tiles' 8 tiles     */
#define STRIP_SHOWN_Y  112u   /* WY with the whole box on screen      */
#define STRIP_HIDDEN_Y 144u   /* WY just below the bottom edge        */
#define SLIDE_PX       2u     /* per VBL — 16 frames in or out        */
#define TEXT_MAX       36u    /* 2 lines × 18 columns                 */

static char    dlg_text[TEXT_MAX + 1u];
static uint8_t dlg_timer;     /* hold frames left; 0 = expired        */
static uint8_t dlg_manual;    /* pinned open by dialogue_toggle()     */
static uint8_t strip_on;      /* strip currently owns the Window      */
static uint8_t strip_y;       /* current WY while strip_on            */
static uint8_t in_menu;       /* text currently shown in the menu     */

/* Paint the box frame into Window rows 0-3.  The map is 4-bit packed
   (two cells per byte, high nibble first) with tile offset 0, so a value
   v maps straight onto UI_Tiles[v] at UI_TILE_BASE. */
static void box_draw(void)
{
    uint8_t  row_buf[STRIP_COLS];
    uint8_t  row, col, v;
    uint16_t i;
    for (row = 0u; row < STRIP_ROWS; row++) {
        for (col = 0u; col < STRIP_COLS; col++) {
            i = (uint16_t)(BOX_MAP_ROW + row) * DIalogueBoxWidth + col;
            v = DIalogueBox[i >> 1];
            v = (i & 1u) ? (v & 0x0Fu) : (v >> 4);
            row_buf[col] = (v < BOX_BLANK) ? (uint8_t)(UI_TILE_BASE + v) : 0u;
        }
        set_win_tiles(0u, row, STRIP_COLS, 1u, row_buf);
    }
}

static void strip_draw(void)
{
    ui_print_wrapped(TEXT_X, TEXT_Y, TEXT_W, TEXT_H, dlg_text);
}

void dialogue_init(void)
{
    dlg_text[0] = 0;
    dlg_timer   = 0u;
    dlg_manual  = 0u;
    strip_on    = 0u;
    strip_y     = STRIP_HIDDEN_Y;
    in_menu     = 0u;
}

void announce(const char *text)
{
    uint8_t i;
    for (i = 0u; i < TEXT_MAX && text[i]; i++) dlg_text[i] = text[i];
    dlg_text[i] = 0;
    dlg_timer = ANNOUNCE_TIME;

    if (menu_is_open()) {
        menu_show_message(dlg_text);
        in_menu = 1u;
    } else if (strip_on) {
        strip_draw();
    }
}

void dialogue_toggle(void)
{
    dlg_manual = !dlg_manual;
}

void dialogue_tick(void)
{
    // ── Menu owns the Window: route text there, keep counting down ──
    if (menu_is_open()) {
        strip_on = 0u;            /* menu_open() already took the Window */
        strip_y  = STRIP_HIDDEN_Y;
        if (dlg_timer && !in_menu) {
            menu_show_message(dlg_text);
            in_menu = 1u;
        }
        if (dlg_timer && --dlg_timer == 0u && in_menu) {
            menu_show_message("");
            in_menu = 0u;
        }
        return;
    }
    in_menu = 0u;

    // ── Box: slide in, hold, slide out (SLIDE_PX per VBL) ─────────────
    if (dlg_timer || dlg_manual) {
        if (!strip_on) {
            strip_on = 1u;
            strip_y  = STRIP_HIDDEN_Y;
            box_draw();
            strip_draw();
            move_win(7u, strip_y);
            SHOW_WIN;
        }
        if (strip_y > STRIP_SHOWN_Y) {
            strip_y -= SLIDE_PX;
            move_win(7u, strip_y);
        } else if (dlg_timer) {
            dlg_timer--;          /* hold time only counts once fully shown */
        }
    } else if (strip_on) {
        if (strip_y < STRIP_HIDDEN_Y) {
            strip_y += SLIDE_PX;
            move_win(7u, strip_y);
        } else {
            HIDE_WIN;
            ui_clear(0u, 0u, STRIP_COLS, STRIP_ROWS);
            strip_on = 0u;
        }
    }
}

uint8_t dialogue_busy(void)
{
    if (dlg_timer) return 1u;
    return strip_on && !dlg_manual;
}

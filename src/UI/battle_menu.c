#pragma bank 1   /* battle scene code lives in ROM bank 1 — see battle/battle.h */

#include "battle_menu.h"
#include "UI.h"
#include "ui_text.h"
#include "ui_pointer.h"

// Screen-Y pixel position of each menu option (Window is at screen y=0).
// Options are at Window rows 2, 4, 6 → screen y 16, 32, 48.
#define UI_MENU_COUNT 3
static const uint8_t UI_MENU_Y[UI_MENU_COUNT] = { 16u, 32u, 48u };
#define UI_MENU_X 8u  // sprite pointer fixed at Window col 1 (screen x=8)

static const char *const UI_MENU_LABEL[UI_MENU_COUNT] = { "MAGIC", "ATTACK", "END" };

/* Stats go in the right-hand box (interior cols 14-18), message text in the
   empty area under the left box (cols 0-12, rows 13-15). */
#define STAT_X   14u
#define STAT_W   5u
#define MSG_X    0u
#define MSG_Y    13u
#define MSG_W    13u
#define MSG_H    3u

// ── UI slide animation ────────────────────────────────────────────────────
// Each open/close plays a row-by-row reveal (top→bottom) or a row-by-row
// clear (bottom→top).  One Window row is drawn/erased per VBL frame.
#define UI_ANIM_IDLE    0u
#define UI_ANIM_SHOWING 1u
#define UI_ANIM_HIDING  2u
static uint8_t ui_anim     = UI_ANIM_IDLE;
static uint8_t ui_anim_row = 0u;
static uint8_t ui_visible  = 0u; // 1 = fully shown and accepting input
static uint8_t ui_owned    = 0u; // 1 while showing, shown or hiding
static uint8_t ui_menu_idx = 0u; // index of highlighted menu option (0-2)
static UIPointer ui_ptr;         // the reusable 16×16 pointer sprite

static uint8_t     stat_hp, stat_max_hp, stat_atk, stat_def, stat_mp, stat_max_mp;
static const char *msg_text = "";

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

// "10/10" style value, left-aligned in the stat column.
static void print_stat_pair(uint8_t row, uint8_t a, uint8_t b) {
    char buf[8];
    char *p = ui_str_u8(buf, a);
    *p++ = '/';
    ui_str_u8(p, b);
    ui_clear(STAT_X, row, STAT_W, 1u);
    ui_print(STAT_X, row, buf);
}

static void draw_stats(void) {
    ui_print(STAT_X, 2u, "HP");
    print_stat_pair(3u, stat_hp, stat_max_hp);
    ui_print(STAT_X, 5u, "MP");
    print_stat_pair(6u, stat_mp, stat_max_mp);
    ui_print(STAT_X, 8u, "ATK");
    ui_clear(STAT_X, 9u, STAT_W, 1u);
    ui_print_uint8(STAT_X, 9u, stat_atk);
    ui_print(STAT_X, 11u, "DEF");
    ui_clear(STAT_X, 12u, STAT_W, 1u);
    ui_print_uint8(STAT_X, 12u, stat_def);
}

// Write all text content on top of the tile map (called once per show cycle).
static void ui_write_text(void) {
    ui_print(3u, 2u, UI_MENU_LABEL[MENU_MAGIC]);
    ui_print(3u, 4u, UI_MENU_LABEL[MENU_ATTACK]);
    ui_print(3u, 6u, UI_MENU_LABEL[MENU_END]);
    draw_stats();
    ui_print_wrapped(MSG_X, MSG_Y, MSG_W, MSG_H, msg_text);
}

void menu_init(void) {
    uint8_t row;
    ui_anim     = UI_ANIM_IDLE;
    ui_visible  = 0u;
    ui_owned    = 0u;
    ui_menu_idx = 0u;
    msg_text    = "";
    // UI pointer: OAM slots POINTER_OAM_BASE..+3, VRAM POINTER_TILE_BASE..+7.
    // Starts hidden; shown when the panel finishes sliding in.
    pointer_init(&ui_ptr, POINTER_TILE_BASE, POINTER_OAM_BASE);
    for (row = 0u; row < UIHeight; row++) win_clear_row(row);
    HIDE_WIN;
}

uint8_t menu_open(void) {
    uint8_t row;
    if (ui_owned || ui_anim != UI_ANIM_IDLE) return 0u;
    // The dialogue box may be using rows 0-3 at the bottom of the
    // screen; take the Window back and blank those rows before revealing.
    for (row = 0u; row < 4u; row++) win_clear_row(row);
    move_win(7u, 0u);
    SHOW_WIN;
    ui_owned    = 1u;
    ui_anim     = UI_ANIM_SHOWING;
    ui_anim_row = 0u;
    return 1u;
}

uint8_t menu_close(void) {
    if (!ui_visible || ui_anim != UI_ANIM_IDLE) return 0u;
    pointer_hide(&ui_ptr);
    ui_visible  = 0u;
    ui_anim     = UI_ANIM_HIDING;
    ui_anim_row = UIHeight;
    return 1u;
}

uint8_t menu_is_open(void)  { return ui_owned; }
uint8_t menu_is_ready(void) { return ui_visible; }

uint8_t menu_tick(void) {
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
            ui_owned = 0u;
            ui_anim  = UI_ANIM_IDLE;
            return MENU_EVT_CLOSED;
        }
    }
    return MENU_EVT_NONE;
}

uint8_t menu_handle_input(uint8_t pressed) {
    if (!ui_visible) return MENU_NONE;
    if ((pressed & J_UP) && ui_menu_idx > 0u) {
        ui_menu_idx--;
        pointer_move(&ui_ptr, UI_MENU_X, UI_MENU_Y[ui_menu_idx]);
    }
    if ((pressed & J_DOWN) && ui_menu_idx < UI_MENU_COUNT - 1u) {
        ui_menu_idx++;
        pointer_move(&ui_ptr, UI_MENU_X, UI_MENU_Y[ui_menu_idx]);
    }
    if (pressed & J_A) {
        pointer_anim_select(&ui_ptr);
        return ui_menu_idx;
    }
    return MENU_NONE;
}

void menu_set_stats(const Unit *u) {
    stat_hp     = u->hp;
    stat_max_hp = u->max_hp;
    stat_atk    = u->atk;
    stat_def    = u->def;
    stat_mp     = u->mp;
    stat_max_mp = u->max_mp;
    if (ui_visible) draw_stats();
}

void menu_show_message(const char *text) {
    msg_text = text;
    if (ui_visible) ui_print_wrapped(MSG_X, MSG_Y, MSG_W, MSG_H, msg_text);
}

const char *menu_label(uint8_t idx) {
    return UI_MENU_LABEL[idx];
}

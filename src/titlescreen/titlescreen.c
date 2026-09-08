#include <gb/gb.h>
#include "titlescreen.h"
#include "../UI/ui_pointer.h"
#include "../gbt_player.h"

#include "titlescreen_data.c"
#include "titlescreen_map.c"

#define TITLESCREEN_TILE_COUNT (sizeof(titlescreen_data) / 16u)

_Static_assert(TITLESCREEN_TILE_COUNT <= 255u,
    "Titlescreen exceeds 255 unique tiles (GB hardware limit — simplify the art)");

/* ── Inline menu font ────────────────────────────────────────────────────────
   Loaded into sprite VRAM slots 8-19 (pointer occupies 0-7).
   Sprite color 0 is TRANSPARENT — text floats over the BKG art with no
   white background.  5-pixel-wide glyphs using bits 7-3 of each row byte;
   color 3 (both 2bpp planes = 1); text sprites use OBP1 (OBP1_REG=0x00)
   which maps color 3 → 00 → white on DMG.                                  */
#define TITLE_FONT_VRAM  8u
#define TF_S  (TITLE_FONT_VRAM +  0u)
#define TF_T  (TITLE_FONT_VRAM +  1u)
#define TF_A  (TITLE_FONT_VRAM +  2u)
#define TF_R  (TITLE_FONT_VRAM +  3u)
#define TF_C  (TITLE_FONT_VRAM +  4u)
#define TF_O  (TITLE_FONT_VRAM +  5u)
#define TF_N  (TITLE_FONT_VRAM +  6u)
#define TF_I  (TITLE_FONT_VRAM +  7u)
#define TF_U  (TITLE_FONT_VRAM +  8u)
#define TF_E  (TITLE_FONT_VRAM +  9u)
#define TF_M  (TITLE_FONT_VRAM + 10u)
#define TF_L  (TITLE_FONT_VRAM + 11u)

static const uint8_t title_font[12u * 16u] = {
 /* S */  0x70,0x70, 0x88,0x88, 0x80,0x80, 0x70,0x70, 0x08,0x08, 0x88,0x88, 0x70,0x70, 0x00,0x00,
 /* T */  0xF8,0xF8, 0x20,0x20, 0x20,0x20, 0x20,0x20, 0x20,0x20, 0x20,0x20, 0x20,0x20, 0x00,0x00,
 /* A */  0x70,0x70, 0x88,0x88, 0x88,0x88, 0xF8,0xF8, 0x88,0x88, 0x88,0x88, 0x88,0x88, 0x00,0x00,
 /* R */  0xF0,0xF0, 0x88,0x88, 0x88,0x88, 0xF0,0xF0, 0xA0,0xA0, 0x90,0x90, 0x88,0x88, 0x00,0x00,
 /* C */  0x70,0x70, 0x88,0x88, 0x80,0x80, 0x80,0x80, 0x80,0x80, 0x88,0x88, 0x70,0x70, 0x00,0x00,
 /* O */  0x70,0x70, 0x88,0x88, 0x88,0x88, 0x88,0x88, 0x88,0x88, 0x88,0x88, 0x70,0x70, 0x00,0x00,
 /* N */  0x88,0x88, 0xC8,0xC8, 0xA8,0xA8, 0x98,0x98, 0x88,0x88, 0x88,0x88, 0x88,0x88, 0x00,0x00,
 /* I */  0xF8,0xF8, 0x20,0x20, 0x20,0x20, 0x20,0x20, 0x20,0x20, 0x20,0x20, 0xF8,0xF8, 0x00,0x00,
 /* U */  0x88,0x88, 0x88,0x88, 0x88,0x88, 0x88,0x88, 0x88,0x88, 0x88,0x88, 0x70,0x70, 0x00,0x00,
 /* E */  0xF8,0xF8, 0x80,0x80, 0x80,0x80, 0xF0,0xF0, 0x80,0x80, 0x80,0x80, 0xF8,0xF8, 0x00,0x00,
 /* M */  0x88,0x88, 0xD8,0xD8, 0xA8,0xA8, 0x88,0x88, 0x88,0x88, 0x88,0x88, 0x88,0x88, 0x00,0x00,
 /* L */  0x80,0x80, 0x80,0x80, 0x80,0x80, 0x80,0x80, 0x80,0x80, 0x80,0x80, 0xF8,0xF8, 0x00,0x00,
};

static const uint8_t tiles_start[]    = { TF_S, TF_T, TF_A, TF_R, TF_T };
static const uint8_t tiles_continue[] = { TF_C, TF_O, TF_N, TF_T, TF_I, TF_N, TF_U, TF_E };
static const uint8_t tiles_multi[]    = { TF_M, TF_U, TF_L, TF_T, TF_I };

/* Assign consecutive OAM slots to a string of 8×8 sprite characters.
   Each character occupies one OAM slot and one 8-pixel column.            */
static void place_text(uint8_t oam_base, const uint8_t *text, uint8_t len,
                       uint8_t screen_x, uint8_t screen_y) {
    uint8_t j;
    uint8_t raw_x = screen_x + 8u;
    uint8_t raw_y = screen_y + 16u;
    for (j = 0u; j < len; j++) {
        set_sprite_tile(oam_base + j, text[j]);
        set_sprite_prop(oam_base + j, S_PALETTE);  /* use OBP1 → white */
        move_sprite(oam_base + j, raw_x + (uint8_t)(j * 8u), raw_y);
    }
}

/* ── Menu layout ─────────────────────────────────────────────────────────────
   Each label is individually centered on the 160-px wide screen:
     START   (5 chars = 40px): text_x = (160-40)/2 = 60, ptr_x = 60-16 = 44
     CONTINUE(8 chars = 64px): text_x = (160-64)/2 = 48, ptr_x = 48-16 = 32
     MULTI   (5 chars = 40px): same as START
   OAM: 0-3 = pointer, 4-8 = START, 9-16 = CONTINUE, 17-21 = MULTI (22 total).
   Max sprites per scanline: 10 (CONTINUE row with pointer active).            */
#define TITLE_MENU_COUNT  3u
#define TITLE_PTR_VRAM    0u
#define TITLE_PTR_OAM     0u
#define TITLE_TEXT_OAM    4u

static const uint8_t TITLE_MENU_Y[TITLE_MENU_COUNT]    = { 106u, 120u, 134u };
static const uint8_t TITLE_MENU_PTR_X[TITLE_MENU_COUNT] = {  44u,  32u,  44u };
static const uint8_t TITLE_MENU_TEXT_X[TITLE_MENU_COUNT] = {  60u,  48u,  60u };

TitleResult run_titlescreen(void)
{
    uint8_t j;
    uint8_t menu_idx  = 0u;
    uint8_t prev_keys = 0u;
    UIPointer ptr;

    set_bkg_data(0, (uint8_t)TITLESCREEN_TILE_COUNT, titlescreen_data);
    set_bkg_tiles(0, 0, 20, 18, titlescreen_map);

    set_sprite_data(TITLE_FONT_VRAM, 12u, title_font);

    place_text(TITLE_TEXT_OAM + 0u,  tiles_start,    5u, TITLE_MENU_TEXT_X[0u], TITLE_MENU_Y[0u]);
    place_text(TITLE_TEXT_OAM + 5u,  tiles_continue, 8u, TITLE_MENU_TEXT_X[1u], TITLE_MENU_Y[1u]);
    place_text(TITLE_TEXT_OAM + 13u, tiles_multi,    5u, TITLE_MENU_TEXT_X[2u], TITLE_MENU_Y[2u]);

    OBP0_REG = 0xE4;   /* pointer palette: normal (color 3 = black) */
    OBP1_REG = 0x00;   /* text palette: all shades → white           */
    SHOW_BKG;
    SHOW_SPRITES;
    DISPLAY_ON;

    pointer_init(&ptr, TITLE_PTR_VRAM, TITLE_PTR_OAM);
    pointer_move(&ptr, TITLE_MENU_PTR_X[0u], TITLE_MENU_Y[0u]);

    while (1)
    {
        wait_vbl_done();
        gbt_update();

        uint8_t keys = joypad();

        if ((keys & J_UP) && !(prev_keys & J_UP) && menu_idx > 0u)
        {
            menu_idx--;
            pointer_move(&ptr, TITLE_MENU_PTR_X[menu_idx], TITLE_MENU_Y[menu_idx]);
        }
        else if ((keys & J_DOWN) && !(prev_keys & J_DOWN) &&
                 menu_idx < TITLE_MENU_COUNT - 1u)
        {
            menu_idx++;
            pointer_move(&ptr, TITLE_MENU_PTR_X[menu_idx], TITLE_MENU_Y[menu_idx]);
        }
        else if ((keys & J_A) && !(prev_keys & J_A))
        {
            pointer_anim_select(&ptr);

            if (menu_idx < 2u)
            {
                /* Clear all titlescreen sprites before returning so they don't
                   persist into the game scene (OAM is not reset on scene change). */
                pointer_hide(&ptr);
                for (j = TITLE_TEXT_OAM; j < TITLE_TEXT_OAM + 18u; j++)
                    move_sprite(j, 0u, 0u);
                return (TitleResult)menu_idx;
            }
            /* MULTI: animation plays, stay on the menu. */
        }

        prev_keys = keys;
    }
}

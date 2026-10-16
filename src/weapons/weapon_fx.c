#pragma bank 1   /* battle scene code lives in ROM bank 1 — see battle/battle.h */

#include "weapon_fx.h"
#include "../UI/ui_text.h"   /* WEAPON_TILE_BASE, WEAPON_OAM_BASE */

#include "weapons.h"
#include "weapons.c"         /* Weapons[] tile data */

#define SWING_FRAMES  3u
#define FRAME_TIME    8u     /* VBLs per frame — Godot's FRAME_TIME 0.14s */
#define REACH_PX      8      /* how far in front of the attacker it's drawn */

/* Indexed by PlayerDir (DOWN, LEFT, RIGHT, UP); each sweeps clockwise
   through the facing direction. */
static const uint8_t SWING[4][SWING_FRAMES] = {
    { 3u, 4u, 5u },   /* DIR_DOWN  */
    { 5u, 6u, 7u },   /* DIR_LEFT  */
    { 1u, 2u, 3u },   /* DIR_RIGHT */
    { 7u, 0u, 1u },   /* DIR_UP    */
};
static const int8_t DIR_DX[4] = { 0, -1, 1,  0 };
static const int8_t DIR_DY[4] = { 1,  0, 0, -1 };

static uint8_t   fx_step;    /* 0 = idle, else 1-based frame being shown */
static uint8_t   fx_timer;
static PlayerDir fx_dir;

static void show_frame(uint8_t frame)
{
    uint8_t base = WEAPON_TILE_BASE + frame * 4u;
    uint8_t b    = WEAPON_OAM_BASE;
    /* GBTD column-major → OAM row-major (+1↔+2 cross-wire, as player_anim) */
    set_sprite_tile(b + 0u, base + 0u);
    set_sprite_tile(b + 1u, base + 2u);
    set_sprite_tile(b + 2u, base + 1u);
    set_sprite_tile(b + 3u, base + 3u);
}

void weapon_fx_init(void)
{
    uint8_t i;
    set_sprite_data(WEAPON_TILE_BASE, 32u, Weapons);
    for (i = 0u; i < 4u; i++) set_sprite_prop(WEAPON_OAM_BASE + i, 0u);
    fx_step = 0u;
    weapon_fx_hide();
}

void weapon_fx_hide(void)
{
    uint8_t i;
    for (i = 0u; i < 4u; i++) move_sprite(WEAPON_OAM_BASE + i, 0u, 0u);
}

void weapon_fx_play(uint8_t oam_x, uint8_t oam_y, PlayerDir dir)
{
    uint8_t x = (uint8_t)(oam_x + DIR_DX[dir] * REACH_PX);
    uint8_t y = (uint8_t)(oam_y + DIR_DY[dir] * REACH_PX);
    uint8_t b = WEAPON_OAM_BASE;

    if (fx_step) return;   /* Godot's _playing guard */
    fx_dir   = dir;
    fx_step  = 1u;
    fx_timer = 0u;
    show_frame(SWING[dir][0]);
    move_sprite(b + 0u, x,      y);
    move_sprite(b + 1u, x + 8u, y);
    move_sprite(b + 2u, x,      y + 8u);
    move_sprite(b + 3u, x + 8u, y + 8u);
}

void weapon_fx_tick(void)
{
    if (!fx_step) return;
    if (++fx_timer < FRAME_TIME) return;
    fx_timer = 0u;
    if (fx_step >= SWING_FRAMES) {
        fx_step = 0u;
        weapon_fx_hide();
        return;
    }
    show_frame(SWING[fx_dir][fx_step]);
    fx_step++;
}

uint8_t weapon_fx_playing(void)
{
    return fx_step != 0u;
}

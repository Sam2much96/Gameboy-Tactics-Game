#ifndef WEAPON_FX_H
#define WEAPON_FX_H

#include <gb/gb.h>
#include "../characters/player_anim.h"   /* PlayerDir */

/* ── Attack-swing effect ─────────────────────────────────────────────────────
   Godot equivalent: weapon_fx.gd (WeaponFx).  One shared sword sprite
   (OAM WEAPON_OAM_BASE..+3) that battle.c plays at whichever unit is
   attacking, for both sides' physical attacks.

   Weapons[] holds 8 frames rotating the blade clockwise in 45° steps:
     0 = up, 1 = up-right, 2 = right, 3 = down-right,
     4 = down, 5 = down-left, 6 = left, 7 = up-left
   A swing is the 3 frames centred on the attacker's facing, drawn half a
   cell in front of it, so the blade sweeps an arc toward the target.

   Non-blocking: weapon_fx_play() starts it, weapon_fx_tick() (once per VBL)
   advances it, weapon_fx_playing() says whether it's still going. */

void    weapon_fx_init(void);
void    weapon_fx_play(uint8_t oam_x, uint8_t oam_y, PlayerDir dir);
void    weapon_fx_tick(void);
uint8_t weapon_fx_playing(void);
void    weapon_fx_hide(void);

#endif /* WEAPON_FX_H */

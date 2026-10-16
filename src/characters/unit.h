#ifndef UNIT_H
#define UNIT_H

#include <gb/gb.h>
#include "player_character.c"   /* struct GameCharacter */
#include "player_anim.h"        /* PlayerDir, PlayerAnimState, PlayerAnim */
#include "unit_stats.h"

/* ── Grid-bound battle unit ──────────────────────────────────────────────────
   Godot equivalent: unit.gd (Unit) + player_unit.gd / enemy_unit.gd.

   struct GameCharacter still does the 16×16-from-four-8×8-sprites plumbing;
   Unit adds what a battle needs on top of it — grid cell, stats, facing.
   Facing uses PlayerDir for both factions so the weapon swing and AI never
   need to translate between them.

   The player must use OAM slots 0-3: player_anim_apply() writes its tiles
   there directly.  Enemies take 4 consecutive slots from ENEMY_OAM_BASE. */

typedef enum {
    FACTION_PLAYER = 0,
    FACTION_ENEMY  = 1
} Faction;

typedef struct {
    struct GameCharacter spr;   /* OAM slots + current OAM x/y           */
    Faction   faction;
    uint8_t   gx, gy;           /* grid cell                              */
    uint8_t   hp, max_hp;
    uint8_t   atk, def;
    uint8_t   mp, max_mp;
    PlayerDir facing;
    uint8_t   visible;          /* 0 once play_defeat() has hidden it     */
} Unit;

/* The player's direction × state animation machine (player_anim.c). */
extern PlayerAnim player_anim;

/* Load Player[] and Enemy[] into sprite VRAM. */
void unit_load_tiles(void);

/* Stats are copied from s; hp/mp start full.  Snaps the sprite to (gx,gy). */
void unit_init(Unit *u, Faction faction, const UnitStats *s,
               uint8_t oam_base, uint8_t gx, uint8_t gy);

/* Put the sprite at a raw OAM position (used mid-step while walking). */
void unit_move_pixels(Unit *u, uint8_t oam_x, uint8_t oam_y);

/* Snap the sprite to its grid cell, or hide it if !visible. */
void unit_place(Unit *u);

/* Move the sprite off-screen without changing u->visible (menu open). */
void unit_hide_sprites(Unit *u);

void      unit_set_facing(Unit *u, PlayerDir dir);
void      unit_face_towards(Unit *u, uint8_t tx, uint8_t ty);
PlayerDir unit_dir_from_step(uint8_t ax, uint8_t ay, uint8_t bx, uint8_t by);

/* Player: switch idle/walk/attack.  Enemies have no state split (one
   facing frame each, like enemy_unit.gd), so this is a no-op for them. */
void unit_set_anim(Unit *u, PlayerAnimState state);

uint8_t unit_is_alive(const Unit *u);
void    unit_take_damage(Unit *u, uint8_t amount);

#endif /* UNIT_H */

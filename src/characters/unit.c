#pragma bank 1   /* battle scene code lives in ROM bank 1 — see battle/battle.h */

#include "unit.h"
#include "../grid/grid.h"      /* CELL_OAM_X/Y */
#include "../UI/ui_text.h"     /* PLAYER_TILE_BASE, ENEMY_TILE_BASE */

#include "player.c"            /* Player[] tile data */
#include "Enemy1.h"
#include "Enemy1.c"            /* Enemy1[] tile data */

#define SPRITE_SIZE 8u

PlayerAnim player_anim;

/* Enemy1[] frame order is down, left, UP, right — not the player's
   down/left/right/up — so map PlayerDir → GBTD frame explicitly.
   (godot-tactics' enemy_unit.gd uses `frame = facing` and so shows the
   back view when facing right; worth fixing there too.) */
static const uint8_t ENEMY_DIR_FRAME[4] = {
    0u,   /* DIR_DOWN  */
    1u,   /* DIR_LEFT  */
    3u,   /* DIR_RIGHT */
    2u,   /* DIR_UP    */
};

void unit_load_tiles(void)
{
    set_sprite_data(PLAYER_TILE_BASE, 16u, Player);
    set_sprite_data(ENEMY_TILE_BASE,  16u, Enemy1);
}

static void apply_frame(Unit *u)
{
    if (u->faction == FACTION_PLAYER) {
        player_anim_set_dir(&player_anim, u->facing);
        player_anim_apply(&player_anim);
    } else {
        uint8_t base = ENEMY_TILE_BASE + ENEMY_DIR_FRAME[u->facing] * 4u;
        /* GBTD column-major sub-tile order: +0=TL, +1=BL, +2=TR, +3=BR.
           OAM slot layout: 0=TL, 1=TR, 2=BL, 3=BR → cross-wire +1↔+2. */
        set_sprite_tile(u->spr.spriteids[0], base + 0u);
        set_sprite_tile(u->spr.spriteids[1], base + 2u);
        set_sprite_tile(u->spr.spriteids[2], base + 1u);
        set_sprite_tile(u->spr.spriteids[3], base + 3u);
    }
}

void unit_init(Unit *u, Faction faction, const UnitStats *s,
               uint8_t oam_base, uint8_t gx, uint8_t gy)
{
    uint8_t i;
    u->faction = faction;
    u->max_hp  = s->max_hp;
    u->atk     = s->atk;
    u->def     = s->def;
    u->max_mp  = s->max_mp;
    u->hp      = u->max_hp;
    u->mp      = u->max_mp;
    u->gx      = gx;
    u->gy      = gy;
    u->facing  = DIR_DOWN;
    u->visible = 1u;

    u->spr.width  = 16u;
    u->spr.height = 16u;
    for (i = 0u; i < 4u; i++) {
        u->spr.spriteids[i] = oam_base + i;
        set_sprite_prop(oam_base + i, 0u);   /* OBP0, no flip */
    }

    if (faction == FACTION_PLAYER) player_anim_init(&player_anim);
    apply_frame(u);
    unit_place(u);
}

void unit_move_pixels(Unit *u, uint8_t oam_x, uint8_t oam_y)
{
    // takes a game character as a struct along with positional data and moves everything
    struct GameCharacter *c = &u->spr;
    c->x = oam_x;
    c->y = oam_y;
    move_sprite(c->spriteids[0], oam_x,               oam_y);
    move_sprite(c->spriteids[1], oam_x + SPRITE_SIZE, oam_y);
    move_sprite(c->spriteids[2], oam_x,               oam_y + SPRITE_SIZE);
    move_sprite(c->spriteids[3], oam_x + SPRITE_SIZE, oam_y + SPRITE_SIZE);
}

void unit_hide_sprites(Unit *u)
{
    uint8_t i;
    for (i = 0u; i < 4u; i++) move_sprite(u->spr.spriteids[i], 0u, 0u);
}

void unit_place(Unit *u)
{
    if (u->visible) unit_move_pixels(u, CELL_OAM_X(u->gx), CELL_OAM_Y(u->gy));
    else            unit_hide_sprites(u);
}

void unit_set_facing(Unit *u, PlayerDir dir)
{
    u->facing = dir;
    apply_frame(u);
}

PlayerDir unit_dir_from_step(uint8_t ax, uint8_t ay, uint8_t bx, uint8_t by)
{
    if (bx > ax) return DIR_RIGHT;
    if (bx < ax) return DIR_LEFT;
    if (by > ay) return DIR_DOWN;
    return DIR_UP;
}

/* Face along whichever axis the target is further away on — same rule as
   Godot's face_towards(): ties go horizontal. */
void unit_face_towards(Unit *u, uint8_t tx, uint8_t ty)
{
    uint8_t adx = (tx > u->gx) ? (tx - u->gx) : (u->gx - tx);
    uint8_t ady = (ty > u->gy) ? (ty - u->gy) : (u->gy - ty);
    if (adx >= ady) unit_set_facing(u, (tx >= u->gx) ? DIR_RIGHT : DIR_LEFT);
    else            unit_set_facing(u, (ty >= u->gy) ? DIR_DOWN  : DIR_UP);
}

void unit_set_anim(Unit *u, PlayerAnimState state)
{
    if (u->faction != FACTION_PLAYER) return;
    player_anim_set_state(&player_anim, state);
    player_anim_apply(&player_anim);
}

uint8_t unit_is_alive(const Unit *u)
{
    return u->hp > 0u;
}

void unit_take_damage(Unit *u, uint8_t amount)
{
    u->hp = (amount >= u->hp) ? 0u : (uint8_t)(u->hp - amount);
}

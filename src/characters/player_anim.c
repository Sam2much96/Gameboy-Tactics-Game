#include "player_anim.h"
#include "../UI/ui_text.h"   /* PLAYER_TILE_BASE */

/* ── VBL frames per animation frame ─────────────────────────────────────── */
#define WALK_SPEED   10u  /* VBLs between walk frames   */
#define ATTACK_SPEED  6u  /* VBLs between attack frames */

/* ── Frame count per state ───────────────────────────────────────────────────
   Increase when you add the corresponding tiles to player.c.
   Each new frame adds 4 GB sub-tiles (one GBTD 16×16 tile).               */
#define IDLE_FRAME_COUNT   1u
#define WALK_FRAME_COUNT   1u  /* → 2 once walk tiles are in the tileset */
#define ATTACK_FRAME_COUNT 1u  /* → 2 once attack tiles are in the tileset */

/* ── Per-direction frame tables ──────────────────────────────────────────────
   Each array lists GBTD tile indices for that direction, in frame order.
   To add a new walk frame: append a GBTD_WALK_*_1 value and bump
   WALK_FRAME_COUNT above.  Same pattern for attack.                        */

static const uint8_t idle_frames_down [IDLE_FRAME_COUNT]   = { GBTD_IDLE_DOWN   };
static const uint8_t idle_frames_left [IDLE_FRAME_COUNT]   = { GBTD_IDLE_LEFT   };
static const uint8_t idle_frames_right[IDLE_FRAME_COUNT]   = { GBTD_IDLE_RIGHT  };
static const uint8_t idle_frames_up   [IDLE_FRAME_COUNT]   = { GBTD_IDLE_UP     };

static const uint8_t walk_frames_down [WALK_FRAME_COUNT]   = { GBTD_WALK_DOWN_0   };
static const uint8_t walk_frames_left [WALK_FRAME_COUNT]   = { GBTD_WALK_LEFT_0   };
static const uint8_t walk_frames_right[WALK_FRAME_COUNT]   = { GBTD_WALK_RIGHT_0  };
static const uint8_t walk_frames_up   [WALK_FRAME_COUNT]   = { GBTD_WALK_UP_0     };

static const uint8_t attack_frames_down [ATTACK_FRAME_COUNT] = { GBTD_ATTACK_DOWN_0   };
static const uint8_t attack_frames_left [ATTACK_FRAME_COUNT] = { GBTD_ATTACK_LEFT_0   };
static const uint8_t attack_frames_right[ATTACK_FRAME_COUNT] = { GBTD_ATTACK_RIGHT_0  };
static const uint8_t attack_frames_up   [ATTACK_FRAME_COUNT] = { GBTD_ATTACK_UP_0     };

/* ── Internal helpers ────────────────────────────────────────────────────── */

static uint8_t state_frame_count(PlayerAnimState state) {
    switch (state) {
    case ANIM_WALK:   return WALK_FRAME_COUNT;
    case ANIM_ATTACK: return ATTACK_FRAME_COUNT;
    default:          return IDLE_FRAME_COUNT;
    }
}

static uint8_t state_speed(PlayerAnimState state) {
    switch (state) {
    case ANIM_WALK:   return WALK_SPEED;
    case ANIM_ATTACK: return ATTACK_SPEED;
    default:          return 0u;
    }
}

/* Return the GBTD tile number for (state, dir, frame). */
static uint8_t gbtd_tile(PlayerAnimState state, PlayerDir dir, uint8_t frame) {
    switch (state) {
    case ANIM_WALK:
        switch (dir) {
        case DIR_LEFT:  return walk_frames_left[frame];
        case DIR_RIGHT: return walk_frames_right[frame];
        case DIR_UP:    return walk_frames_up[frame];
        default:        return walk_frames_down[frame];
        }
    case ANIM_ATTACK:
        switch (dir) {
        case DIR_LEFT:  return attack_frames_left[frame];
        case DIR_RIGHT: return attack_frames_right[frame];
        case DIR_UP:    return attack_frames_up[frame];
        default:        return attack_frames_down[frame];
        }
    default: /* ANIM_IDLE */
        switch (dir) {
        case DIR_LEFT:  return idle_frames_left[frame];
        case DIR_RIGHT: return idle_frames_right[frame];
        case DIR_UP:    return idle_frames_up[frame];
        default:        return idle_frames_down[frame];
        }
    }
}

/* ── Public functions ────────────────────────────────────────────────────── */

void player_anim_init(PlayerAnim *a) {
    a->dir   = DIR_DOWN;
    a->state = ANIM_IDLE;
    a->frame = 0u;
    a->timer = 0u;
}

void player_anim_set_dir(PlayerAnim *a, PlayerDir dir) {
    a->dir   = dir;
    a->frame = 0u;
    a->timer = 0u;
}

void player_anim_set_state(PlayerAnim *a, PlayerAnimState state) {
    if (a->state == state) return;
    a->state = state;
    a->frame = 0u;
    a->timer = 0u;
}

void player_anim_apply(const PlayerAnim *a) {
    uint8_t gbtd = gbtd_tile(a->state, a->dir, a->frame);
    uint8_t base = PLAYER_TILE_BASE + gbtd * 4u;
    /* GBTD column-major sub-tile order: +0=TL, +1=BL, +2=TR, +3=BR.
       OAM slot layout: 0=TL, 1=TR, 2=BL, 3=BR → cross-wire +1↔+2. */
    set_sprite_tile(0, base + 0u);  /* TL */
    set_sprite_tile(1, base + 2u);  /* TR */
    set_sprite_tile(2, base + 1u);  /* BL */
    set_sprite_tile(3, base + 3u);  /* BR */
}

uint8_t player_anim_tick(PlayerAnim *a) {
    uint8_t count = state_frame_count(a->state);
    uint8_t speed = state_speed(a->state);
    if (count <= 1u || speed == 0u) return 0u;  /* single-frame — nothing to do */
    if (++a->timer >= speed) {
        a->timer = 0u;
        a->frame = (a->frame + 1u) % count;
        player_anim_apply(a);
        return 1u;
    }
    return 0u;
}

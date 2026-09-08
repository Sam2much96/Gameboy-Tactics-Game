#ifndef PLAYER_ANIM_H
#define PLAYER_ANIM_H

#include <gb/gb.h>

/* ── Directional GBTD tile indices ───────────────────────────────────────────
   Each value is a 0-based index into Player[] (one GBTD 16×16 tile = 4 GB
   sub-tiles).  Adjust to match the frame order in your exported player.c.

   Idle frames use the current 4-tile tileset (indices 0-3).
   Walk / attack frames are placeholders — replace the values and increase the
   corresponding FRAME_COUNT constants in player_anim.c once you add tiles.  */

/* Idle */
#define GBTD_IDLE_DOWN   0u
#define GBTD_IDLE_LEFT   1u
#define GBTD_IDLE_RIGHT  2u
#define GBTD_IDLE_UP     3u

/* Walk cycle — add one GBTD index per new step frame per direction */
#define GBTD_WALK_DOWN_0   0u
#define GBTD_WALK_LEFT_0   1u
#define GBTD_WALK_RIGHT_0  2u
#define GBTD_WALK_UP_0     3u
/* Uncomment and fill in when walk frame 1 tiles are exported:
#define GBTD_WALK_DOWN_1   4u
#define GBTD_WALK_LEFT_1   5u
#define GBTD_WALK_RIGHT_1  6u
#define GBTD_WALK_UP_1     7u */

/* Attack — same pattern */
#define GBTD_ATTACK_DOWN_0   0u
#define GBTD_ATTACK_LEFT_0   1u
#define GBTD_ATTACK_RIGHT_0  2u
#define GBTD_ATTACK_UP_0     3u

/* ── Types ───────────────────────────────────────────────────────────────── */

typedef enum {
    DIR_DOWN  = 0,
    DIR_LEFT  = 1,
    DIR_RIGHT = 2,
    DIR_UP    = 3
} PlayerDir;

typedef enum {
    ANIM_IDLE   = 0,
    ANIM_WALK   = 1,
    ANIM_ATTACK = 2
} PlayerAnimState;

typedef struct {
    PlayerDir       dir;    /* current facing direction              */
    PlayerAnimState state;  /* current animation state               */
    uint8_t         frame;  /* frame index within the current state  */
    uint8_t         timer;  /* VBL counter — drives frame advance    */
} PlayerAnim;

/* ── API ─────────────────────────────────────────────────────────────────── */

/* Reset to idle / facing down.  Call once after VRAM is loaded. */
void player_anim_init(PlayerAnim *a);

/* Change facing direction; resets to frame 0 of the current state. */
void player_anim_set_dir(PlayerAnim *a, PlayerDir dir);

/* Transition to a new state; resets to frame 0.  No-op if already in that state. */
void player_anim_set_state(PlayerAnim *a, PlayerAnimState state);

/* Write the current (dir, state, frame) to OAM tiles 0-3.
   Call any time the state changes and whenever the screen re-appears. */
void player_anim_apply(const PlayerAnim *a);

/* Call once per VBL frame.  Advances multi-frame animations (walk, attack).
   Returns 1 if the visible frame changed (useful for footstep sounds etc). */
uint8_t player_anim_tick(PlayerAnim *a);

#endif /* PLAYER_ANIM_H */

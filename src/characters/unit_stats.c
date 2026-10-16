#pragma bank 1   /* battle scene code lives in ROM bank 1 — see battle/battle.h */

#include "unit_stats.h"

/* Mirrors the .tres files in godot-tactics/resources/ — keep the two builds in sync. */

/* resources/player_stats.tres */
const UnitStats PLAYER_STATS = {
    10u,  /* max_hp */
    5u,   /* atk    */
    2u,   /* def    */
    5u,   /* max_mp */
};

/* resources/enemy_stats.tres */
const UnitStats ENEMY_STATS = {
    8u,   /* max_hp */
    4u,   /* atk    */
    1u,   /* def    */
    0u,   /* max_mp */
};

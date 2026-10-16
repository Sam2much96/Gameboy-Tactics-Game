#ifndef UNIT_STATS_H
#define UNIT_STATS_H

#include <gb/gb.h>

/* Base combat stats for a unit — Godot equivalent: unit_stats.gd
   (UnitStats) backing resources/player_stats.tres / enemy_stats.tres.
   The numbers themselves live in unit_stats.c, apart from any logic, so
   balancing never means touching battle code. */

typedef struct {
    uint8_t max_hp;
    uint8_t atk;
    uint8_t def;
    uint8_t max_mp;
} UnitStats;

extern const UnitStats PLAYER_STATS;
extern const UnitStats ENEMY_STATS;
extern const UnitStats BOSS_STATS;

#endif /* UNIT_STATS_H */

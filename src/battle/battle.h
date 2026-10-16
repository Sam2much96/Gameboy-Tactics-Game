#ifndef BATTLE_H
#define BATTLE_H

/* ── Turn-based battle scene ─────────────────────────────────────────────────
   Godot equivalent: battle_manager.gd (BattleManager) — main.tscn's game
   scene as a whole.

   Loads the scene's VRAM, runs PLAYER_TURN → BUSY → ENEMY_TURN until the
   player or every enemy is down, announces GAME WON / GAME OVER, fades to
   white, and returns so main() can go back to the title screen.

   ROM banks: bank 0 was already ~90% full, so this scene's modules (battle,
   grid, astar, unit, unit_stats, player_anim, weapon_fx, battle_menu,
   dialogue, ui_text) are compiled into bank 1 with `#pragma bank 1`.
   run_battle() is the one BANKED entry point: the call from main() maps
   bank 1, and everything inside calls each other directly.  Two rules
   keep bank 1 mapped while inside:
     - call music_update(), never gbt_update() directly;
     - bank-0 helpers (fade, ui_pointer, GBDK) are fine to call. */

#include <gb/gb.h>

void run_battle(void) BANKED;

#endif /* BATTLE_H */

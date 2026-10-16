#include <gb/gb.h>
#include <gbdk/platform.h>
#include "gbt_player.h"
#include "fade.h"
#include "battle/battle.h"

#include "titlescreen/titlescreen.h"

/**

To do
(1) Add in a player character struct
(2) add in collision detection
(3) Add in some music
(4) Implement grid logic
(5) implement music
(6) add in player character metasprite
(6) make gameplay 16 px dimensions, not 8 px   — done: grid/grid.h
*/

// load music
extern const unsigned char *song_Data[];

/* Where everything that used to live here went (Godot file in brackets):
     grid, cursor, path highlight  → grid/grid.c            (tile_map.gd)
     battle panel slide + pointer  → UI/battle_menu.c       (UI.gd)
     status announcements          → UI/dialogue.c          (dialogue.gd)
     player / enemy units, stats   → characters/unit.c,
                                     characters/unit_stats.c (unit*.gd, *.tres)
     sword swing                   → weapons/weapon_fx.c    (weapon_fx.gd)
     turn loop, combat, enemy AI   → battle/battle.c        (battle_manager.gd)
     fadeout() / fadein()          → fade.c                 (fade_overlay.gd) */

// Hide all 40 sprites so nothing from the battle leaks onto the title.
static void clear_sprites(void)
{
    uint8_t i;
    for (i = 0u; i < 40u; i++) move_sprite(i, 0u, 0u);
}

// ─────────────────────────────────────────────
// main()
// ─────────────────────────────────────────────

void main(void)
{
    DISPLAY_OFF;
    disable_interrupts();
    gbt_play(song_Data, 2, 7);
    gbt_loop(1);
    set_interrupts(VBL_IFLAG);
    enable_interrupts();

    while (1)
    {
        /* Only returns on START or CONTINUE; MULTIPLAYER loops inside the titlescreen.
           Future: inspect return value to distinguish START vs CONTINUE (load save). */
        run_titlescreen();
        fadeout();         /* fade to white before reloading VRAM for the game */

        /* Returns after GAME WON / GAME OVER has been announced and the
           screen has faded to white — then it's back to the title, the way
           battle_manager.gd's _end_battle() changes scene to TItleScreen. */
        run_battle();

        DISPLAY_OFF;
        HIDE_WIN;
        clear_sprites();
        BGP_REG = 0xE4;    /* undo the fade — the title draws with the normal palette */
    }
}

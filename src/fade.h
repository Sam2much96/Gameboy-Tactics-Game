#ifndef FADE_H
#define FADE_H

#include <gb/gb.h>

/* Game Boy palette fades — moved out of main.c so both the title→battle
   transition (main.c) and the battle's own end-of-match fade (battle.c)
   can use them.  Godot equivalent: fade_overlay.gd (FadeOverlay).

   Fades step BGP (background + window) and OBP0 (units) through
   0xE4 → 0xF9 → 0xFE → 0xFF, ending all-white, ~10 VBLs per step. */

void performantdelay(uint8_t numloops);
void fadeout(void);
void fadein(void);

#endif /* FADE_H */

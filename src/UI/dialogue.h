#ifndef DIALOGUE_H
#define DIALOGUE_H

#include <gb/gb.h>

/* ── System announcements ────────────────────────────────────────────────────
   Godot equivalent: dialogue.gd (DialogueUI) + UI.gd's Dialogue.announce().

   The bordered box from dialogue_ui/DialogueBox.c (GBMB map, UI_tiles.gbr)
   with 2 lines of 18 columns inside.  It slides up from the bottom of the
   screen (its 4 box rows → Window rows 0-3, shown at WY 112), holds for
   ANNOUNCE_TIME, then slides away.
   The GB has a single Window layer, so while the battle menu owns it the
   same text is shown in the menu's message area instead.

   Not queued — a new announce() replaces the text and restarts the hold.
   dialogue_toggle() (B button) pins the box open / unpins it, like
   Godot's dialogue_toggle; a pinned box never auto-hides. */

/* Copy text (up to 40 chars, word-wrapped onto 2 lines) and show it. */
void announce(const char *text);

void dialogue_init(void);
void dialogue_tick(void);      /* once per VBL, after menu_tick() */
void dialogue_toggle(void);

/* 1 while an announcement is still on screen (holding or sliding).  A
   pinned box doesn't count once its hold time has run out, so callers
   waiting on an announcement can't stall forever — Godot's announce()
   returns early when _manual_open is set. */
uint8_t dialogue_busy(void);

#endif /* DIALOGUE_H */

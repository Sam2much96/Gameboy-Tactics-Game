#ifndef BATTLE_MENU_H
#define BATTLE_MENU_H

#include <gb/gb.h>
#include "../characters/unit.h"

/* ── MAGIC / ATTACK / END battle panel ───────────────────────────────────────
   Godot equivalent: UI.gd (UIPanel).  The full-screen Window panel from
   UI.c, revealed one row per VBL top→bottom and cleared bottom→top, with
   the UIPointer marking the selected option, live HP/MP/ATK/DEF on the
   right, and a short message area under the options (the dialogue's text
   is routed here while the panel owns the Window).

   The panel covers the whole screen, so whoever opens it hides the world
   sprites first and restores them on MENU_EVT_CLOSED (battle.c does). */

#define MENU_MAGIC   0u
#define MENU_ATTACK  1u
#define MENU_END     2u
#define MENU_NONE    0xFFu

/* menu_tick() events */
#define MENU_EVT_NONE    0u
#define MENU_EVT_CLOSED  1u   /* fully hidden again — Godot's `closed` */

void menu_init(void);

/* Start the slide in/out.  Return 1 if it started (no-op mid-animation,
   or if already open/closed) — Godot's open()/close(). */
uint8_t menu_open(void);
uint8_t menu_close(void);

/* 1 from the moment menu_open() starts until the hide finishes — the
   Window belongs to the panel for that whole span (Godot's is_open). */
uint8_t menu_is_open(void);

/* 1 only once fully revealed and accepting input. */
uint8_t menu_is_ready(void);

/* Advance the reveal/clear animation by one row.  Call once per VBL. */
uint8_t menu_tick(void);

/* Up/down move the pointer; A plays the select flash and returns the
   chosen MENU_* index.  Pass newly-pressed buttons.  MENU_NONE otherwise. */
uint8_t menu_handle_input(uint8_t pressed);

/* Show this unit's stats (redrawn immediately if the panel is up). */
void menu_set_stats(const Unit *u);

/* Message line under the options; "" clears it. */
void menu_show_message(const char *text);

/* Label of an option, for announcing the press. */
const char *menu_label(uint8_t idx);

#endif /* BATTLE_MENU_H */

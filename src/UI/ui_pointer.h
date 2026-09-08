#ifndef UI_POINTER_H
#define UI_POINTER_H

#include <gb/gb.h>

/*
 * UIPointer — reusable 16×16 pointer sprite built from the four
 * tileset tiles that form the pointer graphic (indices 18-21).
 *
 * The tile data is embedded in ui_pointer.c so the pointer works in
 * any scene (title screen, menus, in-game) without depending on the
 * main game tileset being loaded into VRAM.
 *
 * Usage
 * -----
 *   UIPointer ptr;
 *   pointer_init(&ptr, vram_slot, oam_slot);  // load tiles, assign OAM
 *   pointer_move(&ptr, screen_x, screen_y);   // position it
 *   pointer_hide(&ptr);                        // move off-screen
 *
 * vram_slot : first VRAM tile index to use (occupies vram_slot .. +3).
 *             Must not overlap font, tileset, player, or cursor VRAM.
 *             In-game default: POINTER_TILE_BASE (defined in UI.h).
 *
 * oam_slot  : first OAM sprite slot (occupies oam_slot .. +3).
 *             In-game default: POINTER_OAM_BASE (defined in UI.h).
 *
 * Palette   : caller is responsible for setting OBP0_REG / OBP1_REG
 *             before calling pointer_init.  The pointer uses OBP0 by
 *             default (set_sprite_prop is not called here).
 */

typedef struct {
    uint8_t vram_base;
    uint8_t oam_base;
} UIPointer;

/* Load both animation frames (8 tiles: vram_base..+7) and assign OAM slots.
   Call this AFTER any set_bkg_data call that might overwrite that VRAM range. */
void pointer_init(UIPointer *p, uint8_t vram_base, uint8_t oam_base);

/* Position the top-left corner of the 16×16 pointer at screen pixel (x,y). */
void pointer_move(UIPointer *p, uint8_t screen_x, uint8_t screen_y);

/* Move all four sprites to OAM (0,0) — off-screen, invisible. */
void pointer_hide(UIPointer *p);

/* Flash the pointer from frame 0 → frame 1 → frame 0 (~14 frames total).
   Blocks while the animation plays — call just before acting on a selection. */
void pointer_anim_select(UIPointer *p);

#endif /* UI_POINTER_H */

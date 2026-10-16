;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.5.1 #15267 (Mac OS X ppc)
;--------------------------------------------------------
	.module main
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _main
	.globl _run_titlescreen
	.globl b_run_battle
	.globl _run_battle
	.globl _fadeout
	.globl _gbt_loop
	.globl _gbt_play
	.globl _display_off
	.globl _set_interrupts
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
	.area _HRAM
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _DATA
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _INITIALIZED
;--------------------------------------------------------
; absolute external ram data
;--------------------------------------------------------
	.area _DABS (ABS)
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
	.area _HOME
	.area _GSINIT
	.area _GSFINAL
	.area _GSINIT
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area _HOME
	.area _HOME
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area _CODE
;src/main.c:35: static void clear_sprites(void)
;	---------------------------------
; Function clear_sprites
; ---------------------------------
_clear_sprites:
;src/main.c:38: for (i = 0u; i < 40u; i++) move_sprite(i, 0u, 0u);
	ld	c, #0x00
00103$:
;/Users/apple/gbdk/include/gb/gb.h:1973: OAM_item_t * itm = &shadow_OAM[nb];
	ld	de, #_shadow_OAM+0
	ld	l, c
	xor	a, a
	ld	h, a
	add	hl, hl
	add	hl, hl
	add	hl, de
;/Users/apple/gbdk/include/gb/gb.h:1974: itm->y=y, itm->x=x;
	xor	a, a
	ld	(hl+), a
	ld	(hl), a
;src/main.c:38: for (i = 0u; i < 40u; i++) move_sprite(i, 0u, 0u);
	inc	c
	ld	a, c
	sub	a, #0x28
	jr	C, 00103$
;src/main.c:39: }
	ret
;src/main.c:45: void main(void)
;	---------------------------------
; Function main
; ---------------------------------
_main::
;src/main.c:47: DISPLAY_OFF;
	call	_display_off
;/Users/apple/gbdk/include/gb/gb.h:811: __asm__("di");
	di
;src/main.c:49: gbt_play(song_Data, 2, 7);
	ld	a, #0x07
	push	af
	inc	sp
	ld	a, #0x02
	ld	de, #_song_Data
	call	_gbt_play
;src/main.c:50: gbt_loop(1);
	ld	a, #0x01
	call	_gbt_loop
;src/main.c:51: set_interrupts(VBL_IFLAG);
	ld	a, #0x01
	call	_set_interrupts
;/Users/apple/gbdk/include/gb/gb.h:795: __asm__("ei");
	ei
;src/main.c:54: while (1)
00102$:
;src/main.c:58: run_titlescreen();
	call	_run_titlescreen
;src/main.c:59: fadeout();         /* fade to white before reloading VRAM for the game */
	call	_fadeout
;src/main.c:64: run_battle();
	ld	e, #b_run_battle
	ld	hl, #_run_battle
	call	___sdcc_bcall_ehl
;src/main.c:66: DISPLAY_OFF;
	call	_display_off
;src/main.c:67: HIDE_WIN;
	ldh	a, (_LCDC_REG + 0)
	and	a, #0xdf
	ldh	(_LCDC_REG + 0), a
;src/main.c:68: clear_sprites();
	call	_clear_sprites
;src/main.c:69: BGP_REG = 0xE4;    /* undo the fade — the title draws with the normal palette */
	ld	a, #0xe4
	ldh	(_BGP_REG + 0), a
;src/main.c:71: }
	jr	00102$
	.area _CODE
	.area _INITIALIZER
	.area _CABS (ABS)

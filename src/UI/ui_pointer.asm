;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.5.1 #15267 (Mac OS X ppc)
;--------------------------------------------------------
	.module ui_pointer
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _set_sprite_data
	.globl _wait_vbl_done
	.globl _PointerSprites
	.globl _pointer_init
	.globl _pointer_move
	.globl _pointer_anim_select
	.globl _pointer_hide
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
_PointerSprites::
	.ds 128
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
;src/UI/ui_pointer.c:19: void pointer_init(UIPointer *p, uint8_t vram_base, uint8_t oam_base) {
;	---------------------------------
; Function pointer_init
; ---------------------------------
_pointer_init::
	add	sp, #-5
	ldhl	sp,	#3
	ld	(hl), e
	inc	hl
	ld	(hl), d
	ld	b, a
;src/UI/ui_pointer.c:20: p->vram_base = vram_base;
	ld	a, (hl-)
	ld	l, (hl)
	ld	h, a
	ld	(hl), b
;src/UI/ui_pointer.c:21: p->oam_base  = oam_base;
	ldhl	sp,	#3
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	inc	de
	ldhl	sp,	#7
	ld	a, (hl)
	ld	(de), a
;src/UI/ui_pointer.c:24: set_sprite_data(vram_base, 8, PointerSprites);
	ld	de, #_PointerSprites
	push	de
	ld	a, #0x08
	push	af
	inc	sp
	push	bc
	inc	sp
	call	_set_sprite_data
	add	sp, #4
;src/UI/ui_pointer.c:28: set_sprite_prop(oam_base + 0, 0);
	ldhl	sp,	#7
	ld	c, (hl)
;/Users/apple/gbdk/include/gb/gb.h:1946: shadow_OAM[nb].prop=prop;
	ld	l, c
	ld	h, #0x00
	add	hl, hl
	add	hl, hl
	ld	e, l
	ld	d, h
	ld	hl,#_shadow_OAM + 1
	add	hl,de
	inc	hl
	inc	hl
	ld	(hl), #0x00
;src/UI/ui_pointer.c:29: set_sprite_prop(oam_base + 1, 0);
	ldhl	sp,	#2
	ld	(hl), c
	ld	a, (hl-)
	dec	hl
	inc	a
	ld	(hl), a
	ld	c, (hl)
;/Users/apple/gbdk/include/gb/gb.h:1946: shadow_OAM[nb].prop=prop;
	xor	a, a
	ld	l, c
	ld	h, a
	add	hl, hl
	add	hl, hl
	push	de
	ld	de, #_shadow_OAM
	add	hl, de
	inc	hl
	inc	hl
	inc	hl
	pop	de
	ld	(hl), #0x00
;src/UI/ui_pointer.c:30: set_sprite_prop(oam_base + 2, 0);
	ldhl	sp,	#2
	ld	a, (hl-)
	add	a, #0x02
	ld	(hl), a
	ld	c, (hl)
;/Users/apple/gbdk/include/gb/gb.h:1946: shadow_OAM[nb].prop=prop;
	xor	a, a
	ld	l, c
	ld	h, a
	add	hl, hl
	add	hl, hl
	push	de
	ld	de, #_shadow_OAM
	add	hl, de
	inc	hl
	inc	hl
	inc	hl
	pop	de
	ld	(hl), #0x00
;src/UI/ui_pointer.c:31: set_sprite_prop(oam_base + 3, 0);
	ldhl	sp,	#2
	inc	(hl)
	inc	(hl)
	inc	(hl)
;/Users/apple/gbdk/include/gb/gb.h:1946: shadow_OAM[nb].prop=prop;
	ld	l, (hl)
	ld	h, #0x00
	add	hl, hl
	add	hl, hl
	push	de
	ld	de, #_shadow_OAM
	add	hl, de
	inc	hl
	inc	hl
	inc	hl
	pop	de
	ld	(hl), #0x00
;/Users/apple/gbdk/include/gb/gb.h:1887: shadow_OAM[nb].tile=tile;
	ld	hl,#_shadow_OAM + 1
	add	hl,de
	inc	hl
	ld	(hl), b
;src/UI/ui_pointer.c:34: set_sprite_tile(oam_base + 1, vram_base + 2);  /* TR (GBTD index 2) */
	ld	c, b
	inc	c
	inc	c
	ldhl	sp,	#0
;/Users/apple/gbdk/include/gb/gb.h:1887: shadow_OAM[nb].tile=tile;
	ld	l, (hl)
	ld	h, #0x00
	add	hl, hl
	add	hl, hl
	ld	de, #_shadow_OAM
	add	hl, de
	inc	hl
	inc	hl
	ld	(hl), c
;src/UI/ui_pointer.c:35: set_sprite_tile(oam_base + 2, vram_base + 1);  /* BL (GBTD index 1) */
	ld	c, b
	inc	c
	ldhl	sp,	#1
;/Users/apple/gbdk/include/gb/gb.h:1887: shadow_OAM[nb].tile=tile;
	ld	l, (hl)
	ld	h, #0x00
	add	hl, hl
	add	hl, hl
	ld	de, #_shadow_OAM
	add	hl, de
	inc	hl
	inc	hl
	ld	(hl), c
;src/UI/ui_pointer.c:36: set_sprite_tile(oam_base + 3, vram_base + 3);  /* BR (GBTD index 3) */
	inc	b
	inc	b
	inc	b
	ldhl	sp,	#2
;/Users/apple/gbdk/include/gb/gb.h:1887: shadow_OAM[nb].tile=tile;
	ld	l, (hl)
	ld	de, #_shadow_OAM+0
	ld	h, #0x00
	add	hl, hl
	add	hl, hl
	add	hl, de
	inc	hl
	inc	hl
	ld	(hl), b
;src/UI/ui_pointer.c:38: pointer_hide(p);
	ldhl	sp,	#3
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	call	_pointer_hide
;src/UI/ui_pointer.c:39: }
	add	sp, #5
	pop	hl
	inc	sp
	jp	(hl)
;src/UI/ui_pointer.c:41: void pointer_move(UIPointer *p, uint8_t screen_x, uint8_t screen_y) {
;	---------------------------------
; Function pointer_move
; ---------------------------------
_pointer_move::
	add	sp, #-4
;src/UI/ui_pointer.c:43: uint8_t ox = screen_x + 8u;
	add	a, #0x08
	ld	c, a
;src/UI/ui_pointer.c:44: uint8_t oy = screen_y + 16u;
	ldhl	sp,	#6
	ld	a, (hl)
	add	a, #0x10
	ldhl	sp,	#0
	ld	(hl), a
;src/UI/ui_pointer.c:45: uint8_t b  = p->oam_base;
	inc	de
	ld	a, (de)
	ld	b, a
;/Users/apple/gbdk/include/gb/gb.h:1973: OAM_item_t * itm = &shadow_OAM[nb];
	ld	l, b
	ld	h, #0x00
	add	hl, hl
	add	hl, hl
	ld	de, #_shadow_OAM
	add	hl, de
;/Users/apple/gbdk/include/gb/gb.h:1974: itm->y=y, itm->x=x;
	push	hl
	ldhl	sp,	#2
	ld	a, (hl)
	pop	hl
	ld	(hl+), a
	ld	(hl), c
;src/UI/ui_pointer.c:48: move_sprite(b + 1, ox + 8u, oy);       /* top-right */
	ld	a, c
	add	a, #0x08
	ld	e, a
	ldhl	sp,	#1
	ld	a, e
	ld	(hl+), a
	ld	(hl), b
	ld	a, (hl+)
	inc	a
	ld	(hl), a
;/Users/apple/gbdk/include/gb/gb.h:1973: OAM_item_t * itm = &shadow_OAM[nb];
	ld	b, (hl)
	xor	a, a
	ld	l, b
	ld	h, a
	add	hl, hl
	add	hl, hl
	push	de
	ld	de, #_shadow_OAM
	add	hl, de
	pop	de
;/Users/apple/gbdk/include/gb/gb.h:1974: itm->y=y, itm->x=x;
	push	hl
	ldhl	sp,	#2
	ld	a, (hl)
	pop	hl
	ld	(hl+), a
	push	hl
	ldhl	sp,	#3
	ld	a, (hl)
	pop	hl
	ld	(hl), a
;src/UI/ui_pointer.c:49: move_sprite(b + 2, ox,      oy + 8u);  /* bot-left  */
	ldhl	sp,	#0
	ld	a, (hl)
	add	a, #0x08
	ld	d, a
	ldhl	sp,	#3
	ld	a, d
	ld	(hl-), a
	ld	b, (hl)
	inc	b
	inc	b
;/Users/apple/gbdk/include/gb/gb.h:1973: OAM_item_t * itm = &shadow_OAM[nb];
	ld	l, b
	ld	h, #0x00
	add	hl, hl
	add	hl, hl
	push	de
	ld	de, #_shadow_OAM
	add	hl, de
	pop	de
;/Users/apple/gbdk/include/gb/gb.h:1974: itm->y=y, itm->x=x;
	push	hl
	ldhl	sp,	#5
	ld	a, (hl)
	pop	hl
	ld	(hl+), a
	ld	(hl), c
;src/UI/ui_pointer.c:50: move_sprite(b + 3, ox + 8u, oy + 8u);  /* bot-right */
	ldhl	sp,	#2
	ld	c, (hl)
	inc	c
	inc	c
	inc	c
;/Users/apple/gbdk/include/gb/gb.h:1973: OAM_item_t * itm = &shadow_OAM[nb];
	xor	a, a
	ld	l, c
	ld	h, a
	add	hl, hl
	add	hl, hl
	ld	bc, #_shadow_OAM
	add	hl, bc
;/Users/apple/gbdk/include/gb/gb.h:1974: itm->y=y, itm->x=x;
	ld	(hl), d
	inc	hl
	ld	(hl), e
;src/UI/ui_pointer.c:50: move_sprite(b + 3, ox + 8u, oy + 8u);  /* bot-right */
;src/UI/ui_pointer.c:51: }
	add	sp, #4
	pop	hl
	inc	sp
	jp	(hl)
;src/UI/ui_pointer.c:53: void pointer_anim_select(UIPointer *p) {
;	---------------------------------
; Function pointer_anim_select
; ---------------------------------
_pointer_anim_select::
	add	sp, #-5
;src/UI/ui_pointer.c:59: uint8_t b = p->oam_base;
	ld	c, e
	ld	b, d
	inc	bc
	ld	a, (bc)
	ldhl	sp,	#4
	ld	(hl), a
;src/UI/ui_pointer.c:60: uint8_t v = p->vram_base;
	ld	a, (de)
	ldhl	sp,	#0
	ld	(hl), a
;src/UI/ui_pointer.c:63: set_sprite_tile(b + 0u, v + 4u);   /* TL — frame 1 */
	ld	c, (hl)
	inc	c
	inc	c
	inc	c
	inc	c
;/Users/apple/gbdk/include/gb/gb.h:1887: shadow_OAM[nb].tile=tile;
	ldhl	sp,	#4
	ld	b, (hl)
	xor	a, a
	sla	b
	adc	a, a
	sla	b
	adc	a, a
	ldhl	sp,	#1
	ld	(hl), b
	inc	hl
	ld	(hl), a
	ld	de, #_shadow_OAM
	ld	a, (hl-)
	ld	l, (hl)
	ld	h, a
	add	hl, de
	inc	hl
	inc	hl
	ld	e, l
	ld	d, h
	ld	a, c
	ld	(de), a
;src/UI/ui_pointer.c:64: set_sprite_tile(b + 1u, v + 6u);   /* TR — frame 1 */
	ldhl	sp,	#0
	ld	a, (hl)
	add	a, #0x06
	ld	c, a
	ldhl	sp,	#4
	ld	a, (hl-)
	inc	a
	ld	(hl), a
;/Users/apple/gbdk/include/gb/gb.h:1887: shadow_OAM[nb].tile=tile;
	ld	l, (hl)
	xor	a, a
	ld	h, a
	add	hl, hl
	add	hl, hl
	ld	de, #_shadow_OAM
	add	hl, de
	inc	hl
	inc	hl
	ld	(hl), c
;src/UI/ui_pointer.c:65: set_sprite_tile(b + 2u, v + 5u);   /* BL — frame 1 */
	ldhl	sp,	#0
	ld	a, (hl)
	add	a, #0x05
	ld	c, a
	ldhl	sp,	#4
	ld	e, (hl)
	inc	e
	inc	e
	ld	b, e
;/Users/apple/gbdk/include/gb/gb.h:1887: shadow_OAM[nb].tile=tile;
	xor	a, a
	ld	l, b
	ld	h, a
	add	hl, hl
	add	hl, hl
	push	de
	ld	de, #_shadow_OAM
	add	hl, de
	inc	hl
	inc	hl
	pop	de
	ld	(hl), c
;src/UI/ui_pointer.c:66: set_sprite_tile(b + 3u, v + 7u);   /* BR — frame 1 */
	ldhl	sp,	#0
	ld	a, (hl)
	add	a, #0x07
	ld	c, a
	ldhl	sp,	#4
	inc	(hl)
	inc	(hl)
	inc	(hl)
;/Users/apple/gbdk/include/gb/gb.h:1887: shadow_OAM[nb].tile=tile;
	ld	l, (hl)
	xor	a, a
	ld	h, a
	add	hl, hl
	add	hl, hl
	push	de
	ld	de, #_shadow_OAM
	add	hl, de
	inc	hl
	inc	hl
	pop	de
	ld	(hl), c
;src/UI/ui_pointer.c:67: for (i = 0u; i < 10u; i++) wait_vbl_done();
	ld	c, #0x0a
00113$:
	call	_wait_vbl_done
	dec	c
	jr	NZ, 00113$
;/Users/apple/gbdk/include/gb/gb.h:1887: shadow_OAM[nb].tile=tile;
	ld	bc, #_shadow_OAM+0
	ldhl	sp,	#1
	ld	a,	(hl+)
	ld	h, (hl)
	ld	l, a
	add	hl, bc
	inc	hl
	inc	hl
	ld	c, l
	ld	b, h
	ldhl	sp,	#0
	ld	a, (hl)
	ld	(bc), a
;src/UI/ui_pointer.c:70: set_sprite_tile(b + 1u, v + 2u);   /* TR — frame 0 */
	ld	c, (hl)
	inc	c
	inc	c
;/Users/apple/gbdk/include/gb/gb.h:1887: shadow_OAM[nb].tile=tile;
	ldhl	sp,	#3
	ld	l, (hl)
	ld	h, #0x00
	add	hl, hl
	add	hl, hl
	push	de
	ld	de, #_shadow_OAM
	add	hl, de
	inc	hl
	inc	hl
	pop	de
	ld	(hl), c
;src/UI/ui_pointer.c:71: set_sprite_tile(b + 2u, v + 1u);   /* BL — frame 0 */
	ldhl	sp,	#0
	ld	c, (hl)
	inc	c
;/Users/apple/gbdk/include/gb/gb.h:1887: shadow_OAM[nb].tile=tile;
	xor	a, a
	ld	l, e
	ld	h, a
	add	hl, hl
	add	hl, hl
	ld	a, l
	add	a, #<(_shadow_OAM)
	ld	e, a
	ld	a, h
	adc	a, #>(_shadow_OAM)
	ld	d, a
	inc	de
	inc	de
	ld	a, c
	ld	(de), a
;src/UI/ui_pointer.c:72: set_sprite_tile(b + 3u, v + 3u);   /* BR — frame 0 */
	ldhl	sp,	#0
	ld	c, (hl)
	inc	c
	inc	c
	inc	c
;/Users/apple/gbdk/include/gb/gb.h:1887: shadow_OAM[nb].tile=tile;
	ldhl	sp,	#4
	ld	e, (hl)
	xor	a, a
	ld	l, e
	ld	h, a
	add	hl, hl
	add	hl, hl
	ld	de, #_shadow_OAM
	add	hl, de
	inc	hl
	inc	hl
	ld	(hl), c
;src/UI/ui_pointer.c:73: for (i = 0u; i < 4u; i++) wait_vbl_done();
	ld	c, #0x04
00116$:
	call	_wait_vbl_done
	dec	c
	jr	NZ, 00116$
;src/UI/ui_pointer.c:74: }
	add	sp, #5
	ret
;src/UI/ui_pointer.c:76: void pointer_hide(UIPointer *p) {
;	---------------------------------
; Function pointer_hide
; ---------------------------------
_pointer_hide::
;src/UI/ui_pointer.c:78: uint8_t b = p->oam_base;
	inc	de
	ld	a, (de)
	ld	e, a
;/Users/apple/gbdk/include/gb/gb.h:1973: OAM_item_t * itm = &shadow_OAM[nb];
	ld	bc, #_shadow_OAM+0
	ld	l, e
	xor	a, a
	ld	h, a
	add	hl, hl
	add	hl, hl
	add	hl, bc
;/Users/apple/gbdk/include/gb/gb.h:1974: itm->y=y, itm->x=x;
	xor	a, a
	ld	(hl+), a
	ld	(hl), a
;src/UI/ui_pointer.c:80: move_sprite(b + 1, 0, 0);
	ld	d, e
	inc	d
;/Users/apple/gbdk/include/gb/gb.h:1973: OAM_item_t * itm = &shadow_OAM[nb];
	ld	bc, #_shadow_OAM+0
	ld	l, d
	ld	h, #0x00
	add	hl, hl
	add	hl, hl
	add	hl, bc
;/Users/apple/gbdk/include/gb/gb.h:1974: itm->y=y, itm->x=x;
	xor	a, a
	ld	(hl+), a
	ld	(hl), a
;src/UI/ui_pointer.c:81: move_sprite(b + 2, 0, 0);
	ld	d, e
	inc	d
	inc	d
;/Users/apple/gbdk/include/gb/gb.h:1973: OAM_item_t * itm = &shadow_OAM[nb];
	ld	bc, #_shadow_OAM+0
	ld	l, d
	ld	h, #0x00
	add	hl, hl
	add	hl, hl
	add	hl, bc
;/Users/apple/gbdk/include/gb/gb.h:1974: itm->y=y, itm->x=x;
	xor	a, a
	ld	(hl+), a
	ld	(hl), a
;src/UI/ui_pointer.c:82: move_sprite(b + 3, 0, 0);
	inc	e
	inc	e
	inc	e
;/Users/apple/gbdk/include/gb/gb.h:1973: OAM_item_t * itm = &shadow_OAM[nb];
	ld	bc, #_shadow_OAM+0
	xor	a, a
	ld	l, e
	ld	h, a
	add	hl, hl
	add	hl, hl
	add	hl, bc
;/Users/apple/gbdk/include/gb/gb.h:1974: itm->y=y, itm->x=x;
	xor	a, a
	ld	(hl+), a
	ld	(hl), a
;src/UI/ui_pointer.c:82: move_sprite(b + 3, 0, 0);
;src/UI/ui_pointer.c:83: }
	ret
	.area _CODE
	.area _INITIALIZER
__xinit__PointerSprites:
	.db #0x03	; 3
	.db #0x03	; 3
	.db #0x07	; 7
	.db #0x04	; 4
	.db #0x0f	; 15
	.db #0x0d	; 13
	.db #0x1f	; 31
	.db #0x10	; 16
	.db #0x7f	; 127
	.db #0x70	; 112	'p'
	.db #0x6f	; 111	'o'
	.db #0x50	; 80	'P'
	.db #0x7f	; 127
	.db #0x40	; 64
	.db #0x6f	; 111	'o'
	.db #0x50	; 80	'P'
	.db #0x6f	; 111	'o'
	.db #0x50	; 80	'P'
	.db #0x48	; 72	'H'
	.db #0x7f	; 127
	.db #0x76	; 118	'v'
	.db #0x77	; 119	'w'
	.db #0x03	; 3
	.db #0x03	; 3
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x0f	; 15
	.db #0x0f	; 15
	.db #0x1f	; 31
	.db #0x1f	; 31
	.db #0x0f	; 15
	.db #0x0f	; 15
	.db #0x80	; 128
	.db #0x80	; 128
	.db #0xc0	; 192
	.db #0x40	; 64
	.db #0xfe	; 254
	.db #0xfe	; 254
	.db #0xff	; 255
	.db #0x01	; 1
	.db #0xff	; 255
	.db #0x01	; 1
	.db #0xc3	; 195
	.db #0x3f	; 63
	.db #0xdc	; 220
	.db #0x3c	; 60
	.db #0xa0	; 160
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0xe0	; 224
	.db #0x40	; 64
	.db #0xc0	; 192
	.db #0xc0	; 192
	.db #0xc0	; 192
	.db #0x80	; 128
	.db #0x80	; 128
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0xe0	; 224
	.db #0xe0	; 224
	.db #0xf0	; 240
	.db #0xf0	; 240
	.db #0xe0	; 224
	.db #0xe0	; 224
	.db #0x03	; 3
	.db #0x03	; 3
	.db #0x07	; 7
	.db #0x04	; 4
	.db #0x0f	; 15
	.db #0x0d	; 13
	.db #0x1f	; 31
	.db #0x10	; 16
	.db #0x7f	; 127
	.db #0x70	; 112	'p'
	.db #0x6f	; 111	'o'
	.db #0x50	; 80	'P'
	.db #0x7f	; 127
	.db #0x40	; 64
	.db #0x6f	; 111	'o'
	.db #0x50	; 80	'P'
	.db #0x6f	; 111	'o'
	.db #0x50	; 80	'P'
	.db #0x48	; 72	'H'
	.db #0x7f	; 127
	.db #0x76	; 118	'v'
	.db #0x77	; 119	'w'
	.db #0x03	; 3
	.db #0x03	; 3
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x0f	; 15
	.db #0x0f	; 15
	.db #0x1f	; 31
	.db #0x1f	; 31
	.db #0x0f	; 15
	.db #0x0f	; 15
	.db #0x80	; 128
	.db #0x80	; 128
	.db #0xc0	; 192
	.db #0x40	; 64
	.db #0xf8	; 248
	.db #0xf8	; 248
	.db #0xe4	; 228
	.db #0x1c	; 28
	.db #0xe4	; 228
	.db #0x1c	; 28
	.db #0xe4	; 228
	.db #0x1c	; 28
	.db #0xd8	; 216
	.db #0x38	; 56	'8'
	.db #0xa0	; 160
	.db #0x60	; 96
	.db #0x60	; 96
	.db #0xe0	; 224
	.db #0x40	; 64
	.db #0xc0	; 192
	.db #0xc0	; 192
	.db #0xc0	; 192
	.db #0x80	; 128
	.db #0x80	; 128
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0xe0	; 224
	.db #0xe0	; 224
	.db #0xf0	; 240
	.db #0xf0	; 240
	.db #0xe0	; 224
	.db #0xe0	; 224
	.area _CABS (ABS)

;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.5.1 #15267 (Mac OS X ppc)
;--------------------------------------------------------
	.module ui_text
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _set_win_tiles
	.globl _Selector
	.globl _UI_Tiles
	.globl _ui_print
	.globl _ui_print_uint8
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
_UI_Tiles::
	.ds 128
_Selector::
	.ds 48
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
;src/UI/ui_text.c:7: static uint8_t char_to_tile(char ch) {
;	---------------------------------
; Function char_to_tile
; ---------------------------------
_char_to_tile:
;src/UI/ui_text.c:8: if (ch >= '0' && ch <= '9') return (uint8_t)(1  + (ch - '0'));
	ld	c, a
	xor	a, #0x80
	sub	a, #0xb0
	jr	C, 00102$
	ld	e, c
	ld	a,#0x39
	ld	d,a
	sub	a, c
	bit	7, e
	jr	Z, 00154$
	bit	7, d
	jr	NZ, 00155$
	cp	a, a
	jr	00155$
00154$:
	bit	7, d
	jr	Z, 00155$
	scf
00155$:
	jr	C, 00102$
	ld	a, c
	add	a, #0xd1
	ret
00102$:
;src/UI/ui_text.c:9: if (ch >= 'A' && ch <= 'Z') return (uint8_t)(11 + (ch - 'A'));
	ld	a, c
	xor	a, #0x80
	sub	a, #0xc1
	jr	C, 00105$
	ld	e, c
	ld	a,#0x5a
	ld	d,a
	sub	a, c
	bit	7, e
	jr	Z, 00156$
	bit	7, d
	jr	NZ, 00157$
	cp	a, a
	jr	00157$
00156$:
	bit	7, d
	jr	Z, 00157$
	scf
00157$:
	jr	C, 00105$
	ld	a, c
	add	a, #0xca
	ret
00105$:
;src/UI/ui_text.c:10: if (ch >= 'a' && ch <= 'z') return (uint8_t)(11 + (ch - 'a'));
	ld	a, c
	xor	a, #0x80
	sub	a, #0xe1
	jr	C, 00108$
	ld	e, c
	ld	a,#0x7a
	ld	d,a
	sub	a, c
	bit	7, e
	jr	Z, 00158$
	bit	7, d
	jr	NZ, 00159$
	cp	a, a
	jr	00159$
00158$:
	bit	7, d
	jr	Z, 00159$
	scf
00159$:
	jr	C, 00108$
	ld	a, c
	add	a, #0xaa
	ret
00108$:
;src/UI/ui_text.c:11: return 0;
	xor	a, a
;src/UI/ui_text.c:12: }
	ret
;src/UI/ui_text.c:14: void ui_print(uint8_t win_x, uint8_t win_y, const char *str) {
;	---------------------------------
; Function ui_print
; ---------------------------------
_ui_print::
	dec	sp
	ld	d, a
;src/UI/ui_text.c:16: while (*str) {
	ldhl	sp,	#3
	ld	a, (hl+)
	ld	c, a
	ld	b, (hl)
00101$:
	ld	a, (bc)
	or	a, a
	jr	Z, 00104$
;src/UI/ui_text.c:17: tile = char_to_tile(*str++);
	inc	bc
	push	bc
	push	de
	call	_char_to_tile
	pop	de
	pop	bc
	ldhl	sp,	#0
	ld	(hl), a
;src/UI/ui_text.c:18: set_win_tiles(win_x++, win_y, 1, 1, &tile);
	ld	a, d
	inc	d
	push	de
	ld	hl, #2
	add	hl, sp
	push	hl
	ld	h, #0x01
	push	hl
	inc	sp
	ld	h, #0x01
	push	hl
	inc	sp
	ld	h, e
	push	hl
	inc	sp
	push	af
	inc	sp
	call	_set_win_tiles
	add	sp, #6
	pop	de
	jr	00101$
00104$:
;src/UI/ui_text.c:20: }
	inc	sp
	pop	hl
	pop	af
	jp	(hl)
;src/UI/ui_text.c:22: void ui_print_uint8(uint8_t win_x, uint8_t win_y, uint8_t value) {
;	---------------------------------
; Function ui_print_uint8
; ---------------------------------
_ui_print_uint8::
	add	sp, #-4
	ld	b, a
	ldhl	sp,	#3
	ld	(hl), e
;src/UI/ui_text.c:23: uint8_t hundreds = value / 100;
	ldhl	sp,	#6
	ld	c, (hl)
	push	bc
	ld	e, #0x64
	ld	a, c
	call	__divuchar
	ld	a, c
	pop	bc
	ldhl	sp,	#1
	ld	(hl), a
;src/UI/ui_text.c:24: uint8_t tens     = (value % 100) / 10;
	push	bc
	ld	e, #0x64
	ld	a, c
	call	__moduchar
	ld	a, c
	ld	e, #0x0a
	call	__divuchar
	ld	a, c
	pop	bc
	ldhl	sp,	#2
	ld	(hl), a
;src/UI/ui_text.c:25: uint8_t ones     = value % 10;
	push	bc
	ld	e, #0x0a
	ld	a, c
	call	__moduchar
	pop	af
	ld	b, a
;src/UI/ui_text.c:28: if (hundreds > 0) {
	ldhl	sp,	#1
	ld	a, (hl)
	or	a, a
	jr	Z, 00102$
;src/UI/ui_text.c:29: tile = char_to_tile('0' + hundreds);
	ld	a, (hl)
	add	a, #0x30
	push	bc
	call	_char_to_tile
	pop	bc
;src/UI/ui_text.c:30: set_win_tiles(win_x++, win_y, 1, 1, &tile);
	ldhl	sp,#0
	ld	(hl), a
	ld	e, l
	ld	d, h
	ld	a, b
	inc	b
	push	de
	ld	h, #0x01
	push	hl
	inc	sp
	ld	h, #0x01
	push	hl
	inc	sp
	ldhl	sp,	#7
	ld	h, (hl)
	push	hl
	inc	sp
	push	af
	inc	sp
	call	_set_win_tiles
	add	sp, #6
00102$:
;src/UI/ui_text.c:32: if (hundreds > 0 || tens > 0) {
	ldhl	sp,	#1
	ld	a, (hl)
	or	a, a
	jr	NZ, 00103$
	inc	hl
	ld	a, (hl)
	or	a, a
	jr	Z, 00104$
00103$:
;src/UI/ui_text.c:33: tile = char_to_tile('0' + tens);
	ldhl	sp,	#2
	ld	a, (hl)
	add	a, #0x30
	push	bc
	call	_char_to_tile
	pop	bc
;src/UI/ui_text.c:34: set_win_tiles(win_x++, win_y, 1, 1, &tile);
	ldhl	sp,#0
	ld	(hl), a
	ld	e, l
	ld	d, h
	ld	a, b
	inc	b
	push	de
	ld	h, #0x01
	push	hl
	inc	sp
	ld	h, #0x01
	push	hl
	inc	sp
	ldhl	sp,	#7
	ld	h, (hl)
	push	hl
	inc	sp
	push	af
	inc	sp
	call	_set_win_tiles
	add	sp, #6
00104$:
;src/UI/ui_text.c:36: tile = char_to_tile('0' + ones);
	ld	a, c
	add	a, #0x30
	push	bc
	call	_char_to_tile
	pop	bc
;src/UI/ui_text.c:37: set_win_tiles(win_x, win_y, 1, 1, &tile);
	ldhl	sp,#0
	ld	(hl), a
	push	hl
	ld	hl, #0x101
	push	hl
	ldhl	sp,	#7
	ld	a, (hl)
	push	af
	inc	sp
	push	bc
	inc	sp
	call	_set_win_tiles
	add	sp, #6
;src/UI/ui_text.c:38: }
	add	sp, #4
	pop	hl
	inc	sp
	jp	(hl)
	.area _CODE
	.area _INITIALIZER
__xinit__UI_Tiles:
	.db #0x1f	; 31
	.db #0x1f	; 31
	.db #0x3f	; 63
	.db #0x20	; 32
	.db #0x70	; 112	'p'
	.db #0x40	; 64
	.db #0xe0	; 224
	.db #0x87	; 135
	.db #0xc3	; 195
	.db #0x8f	; 143
	.db #0xc4	; 196
	.db #0x9c	; 156
	.db #0xc8	; 200
	.db #0x98	; 152
	.db #0xc8	; 200
	.db #0x98	; 152
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0xf8	; 248
	.db #0xf8	; 248
	.db #0xfc	; 252
	.db #0x04	; 4
	.db #0x0e	; 14
	.db #0x02	; 2
	.db #0x07	; 7
	.db #0xe1	; 225
	.db #0xc3	; 195
	.db #0xf1	; 241
	.db #0x23	; 35
	.db #0x39	; 57	'9'
	.db #0x13	; 19
	.db #0x19	; 25
	.db #0x13	; 19
	.db #0x19	; 25
	.db #0x13	; 19
	.db #0x19	; 25
	.db #0x13	; 19
	.db #0x19	; 25
	.db #0x13	; 19
	.db #0x19	; 25
	.db #0x13	; 19
	.db #0x19	; 25
	.db #0x13	; 19
	.db #0x19	; 25
	.db #0x13	; 19
	.db #0x19	; 25
	.db #0x13	; 19
	.db #0x19	; 25
	.db #0x13	; 19
	.db #0x19	; 25
	.db #0xc8	; 200
	.db #0x98	; 152
	.db #0xc8	; 200
	.db #0x98	; 152
	.db #0xc8	; 200
	.db #0x98	; 152
	.db #0xc8	; 200
	.db #0x98	; 152
	.db #0xc8	; 200
	.db #0x98	; 152
	.db #0xc8	; 200
	.db #0x98	; 152
	.db #0xc8	; 200
	.db #0x98	; 152
	.db #0xc8	; 200
	.db #0x98	; 152
	.db #0x13	; 19
	.db #0x19	; 25
	.db #0x13	; 19
	.db #0x19	; 25
	.db #0x23	; 35
	.db #0x39	; 57	'9'
	.db #0xc3	; 195
	.db #0xf1	; 241
	.db #0x07	; 7
	.db #0xe1	; 225
	.db #0x0e	; 14
	.db #0x02	; 2
	.db #0xfc	; 252
	.db #0x04	; 4
	.db #0xf8	; 248
	.db #0xf8	; 248
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0x00	; 0
	.db #0xff	; 255
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0xff	; 255
	.db #0x00	; 0
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xc8	; 200
	.db #0x98	; 152
	.db #0xc8	; 200
	.db #0x98	; 152
	.db #0xc4	; 196
	.db #0x9c	; 156
	.db #0xc3	; 195
	.db #0x8f	; 143
	.db #0xe0	; 224
	.db #0x87	; 135
	.db #0x70	; 112	'p'
	.db #0x40	; 64
	.db #0x3f	; 63
	.db #0x20	; 32
	.db #0x1f	; 31
	.db #0x1f	; 31
__xinit__Selector:
	.db #0xff	; 255
	.db #0x00	; 0
	.db #0x81	; 129
	.db #0x00	; 0
	.db #0x81	; 129
	.db #0x00	; 0
	.db #0x81	; 129
	.db #0x00	; 0
	.db #0x81	; 129
	.db #0x00	; 0
	.db #0x81	; 129
	.db #0x00	; 0
	.db #0x81	; 129
	.db #0x00	; 0
	.db #0xff	; 255
	.db #0x00	; 0
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0xff	; 255
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.db #0x00	; 0
	.area _CABS (ABS)

;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.5.1 #15267 (Mac OS X ppc)
;--------------------------------------------------------
	.module ui_text
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _set_win_tiles
	.globl _set_bkg_data
	.globl _Selector
	.globl _UI_Tiles
	.globl _ui_load_glyphs
	.globl _ui_print
	.globl _ui_print_uint8
	.globl _ui_clear
	.globl _ui_print_wrapped
	.globl _ui_str_cat
	.globl _ui_str_u8
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
	.area _CODE_1
;src/UI/ui_text.c:18: static uint8_t char_to_tile(char ch) {
;	---------------------------------
; Function char_to_tile
; ---------------------------------
_char_to_tile:
;src/UI/ui_text.c:19: if (ch >= '0' && ch <= '9') return (uint8_t)(1  + (ch - '0'));
	ld	c, a
	xor	a, #0x80
	sub	a, #0xb0
	jr	C, 00102$
	ld	e, c
	ld	a,#0x39
	ld	d,a
	sub	a, c
	bit	7, e
	jr	Z, 00172$
	bit	7, d
	jr	NZ, 00173$
	cp	a, a
	jr	00173$
00172$:
	bit	7, d
	jr	Z, 00173$
	scf
00173$:
	jr	C, 00102$
	ld	a, c
	add	a, #0xd1
	ret
00102$:
;src/UI/ui_text.c:20: if (ch >= 'A' && ch <= 'Z') return (uint8_t)(11 + (ch - 'A'));
	ld	a, c
	xor	a, #0x80
	sub	a, #0xc1
	jr	C, 00105$
	ld	e, c
	ld	a,#0x5a
	ld	d,a
	sub	a, c
	bit	7, e
	jr	Z, 00174$
	bit	7, d
	jr	NZ, 00175$
	cp	a, a
	jr	00175$
00174$:
	bit	7, d
	jr	Z, 00175$
	scf
00175$:
	jr	C, 00105$
	ld	a, c
	add	a, #0xca
	ret
00105$:
;src/UI/ui_text.c:21: if (ch >= 'a' && ch <= 'z') return (uint8_t)(11 + (ch - 'a'));
	ld	a, c
	xor	a, #0x80
	sub	a, #0xe1
	jr	C, 00108$
	ld	e, c
	ld	a,#0x7a
	ld	d,a
	sub	a, c
	bit	7, e
	jr	Z, 00176$
	bit	7, d
	jr	NZ, 00177$
	cp	a, a
	jr	00177$
00176$:
	bit	7, d
	jr	Z, 00177$
	scf
00177$:
	jr	C, 00108$
	ld	a, c
	add	a, #0xaa
	ret
00108$:
;src/UI/ui_text.c:22: if (ch == '/') return GLYPH_TILE_BASE + 0u;
	ld	a, c
	sub	a, #0x2f
	jr	NZ, 00111$
	ld	a, #0x98
	ret
00111$:
;src/UI/ui_text.c:23: if (ch == ',') return GLYPH_TILE_BASE + 1u;
	ld	a, c
	sub	a, #0x2c
;src/UI/ui_text.c:24: return 0;
	ld	a, #0x99
	ret	Z
	xor	a, a
;src/UI/ui_text.c:25: }
	ret
_ui_glyphs:
	.db #0x02	; 2
	.db #0x02	; 2
	.db #0x04	; 4
	.db #0x04	; 4
	.db #0x08	; 8
	.db #0x08	; 8
	.db #0x10	; 16
	.db #0x10	; 16
	.db #0x20	; 32
	.db #0x20	; 32
	.db #0x40	; 64
	.db #0x40	; 64
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
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x18	; 24
	.db #0x30	; 48	'0'
	.db #0x30	; 48	'0'
	.db #0x00	; 0
	.db #0x00	; 0
;src/UI/ui_text.c:27: void ui_load_glyphs(void) {
;	---------------------------------
; Function ui_load_glyphs
; ---------------------------------
_ui_load_glyphs::
;src/UI/ui_text.c:28: set_bkg_data(GLYPH_TILE_BASE, 2u, ui_glyphs);
	ld	de, #_ui_glyphs
	push	de
	ld	hl, #0x298
	push	hl
	call	_set_bkg_data
	add	sp, #4
;src/UI/ui_text.c:29: }
	ret
;src/UI/ui_text.c:31: void ui_print(uint8_t win_x, uint8_t win_y, const char *str) {
;	---------------------------------
; Function ui_print
; ---------------------------------
_ui_print::
	dec	sp
	ld	d, a
;src/UI/ui_text.c:33: while (*str) {
	ldhl	sp,	#3
	ld	a, (hl+)
	ld	c, a
	ld	b, (hl)
00101$:
	ld	a, (bc)
	or	a, a
	jr	Z, 00104$
;src/UI/ui_text.c:34: tile = char_to_tile(*str++);
	inc	bc
	push	bc
	push	de
	call	_char_to_tile
	pop	de
	pop	bc
	ldhl	sp,	#0
	ld	(hl), a
;src/UI/ui_text.c:35: set_win_tiles(win_x++, win_y, 1, 1, &tile);
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
;src/UI/ui_text.c:37: }
	inc	sp
	pop	hl
	pop	af
	jp	(hl)
;src/UI/ui_text.c:39: void ui_print_uint8(uint8_t win_x, uint8_t win_y, uint8_t value) {
;	---------------------------------
; Function ui_print_uint8
; ---------------------------------
_ui_print_uint8::
	add	sp, #-4
	ld	b, a
	ldhl	sp,	#3
	ld	(hl), e
;src/UI/ui_text.c:40: uint8_t hundreds = value / 100;
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
;src/UI/ui_text.c:41: uint8_t tens     = (value % 100) / 10;
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
;src/UI/ui_text.c:42: uint8_t ones     = value % 10;
	push	bc
	ld	e, #0x0a
	ld	a, c
	call	__moduchar
	pop	af
	ld	b, a
;src/UI/ui_text.c:45: if (hundreds > 0) {
	ldhl	sp,	#1
	ld	a, (hl)
	or	a, a
	jr	Z, 00102$
;src/UI/ui_text.c:46: tile = char_to_tile('0' + hundreds);
	ld	a, (hl)
	add	a, #0x30
	push	bc
	call	_char_to_tile
	pop	bc
;src/UI/ui_text.c:47: set_win_tiles(win_x++, win_y, 1, 1, &tile);
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
;src/UI/ui_text.c:49: if (hundreds > 0 || tens > 0) {
	ldhl	sp,	#1
	ld	a, (hl)
	or	a, a
	jr	NZ, 00103$
	inc	hl
	ld	a, (hl)
	or	a, a
	jr	Z, 00104$
00103$:
;src/UI/ui_text.c:50: tile = char_to_tile('0' + tens);
	ldhl	sp,	#2
	ld	a, (hl)
	add	a, #0x30
	push	bc
	call	_char_to_tile
	pop	bc
;src/UI/ui_text.c:51: set_win_tiles(win_x++, win_y, 1, 1, &tile);
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
;src/UI/ui_text.c:53: tile = char_to_tile('0' + ones);
	ld	a, c
	add	a, #0x30
	push	bc
	call	_char_to_tile
	pop	bc
;src/UI/ui_text.c:54: set_win_tiles(win_x, win_y, 1, 1, &tile);
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
;src/UI/ui_text.c:55: }
	add	sp, #4
	pop	hl
	inc	sp
	jp	(hl)
;src/UI/ui_text.c:57: void ui_clear(uint8_t win_x, uint8_t win_y, uint8_t w, uint8_t h) {
;	---------------------------------
; Function ui_clear
; ---------------------------------
_ui_clear::
	dec	sp
	dec	sp
	ldhl	sp,	#1
;src/UI/ui_text.c:58: uint8_t blank = 0u;
	ld	(hl-), a
	ld	(hl), #0x00
;src/UI/ui_text.c:60: for (y = 0u; y < h; y++)
	ld	b, #0x00
00107$:
	ld	a, b
	ldhl	sp,	#5
	sub	a, (hl)
	jr	NC, 00109$
;src/UI/ui_text.c:61: for (x = 0u; x < w; x++)
	ld	a, e
	add	a, b
	ld	d, a
	ld	c, #0x00
00104$:
	ld	a, c
	ldhl	sp,	#4
	sub	a, (hl)
	jr	NC, 00108$
;src/UI/ui_text.c:62: set_win_tiles(win_x + x, win_y + y, 1, 1, &blank);
	ldhl	sp,	#1
	ld	a, (hl)
	add	a, c
	push	de
	ld	hl, #2
	add	hl, sp
	push	hl
	ld	h, #0x01
	push	hl
	inc	sp
	ld	h, #0x01
	ld	l, d
	push	hl
	push	af
	inc	sp
	call	_set_win_tiles
	add	sp, #6
	pop	de
;src/UI/ui_text.c:61: for (x = 0u; x < w; x++)
	inc	c
	jr	00104$
00108$:
;src/UI/ui_text.c:60: for (y = 0u; y < h; y++)
	inc	b
	jr	00107$
00109$:
;src/UI/ui_text.c:63: }
	inc	sp
	inc	sp
	pop	hl
	pop	af
	jp	(hl)
;src/UI/ui_text.c:65: void ui_print_wrapped(uint8_t win_x, uint8_t win_y, uint8_t w, uint8_t h,
;	---------------------------------
; Function ui_print_wrapped
; ---------------------------------
_ui_print_wrapped::
	add	sp, #-11
	ldhl	sp,	#5
	ld	(hl-), a
;src/UI/ui_text.c:68: uint8_t col  = 0u;
	ld	a, e
	ld	(hl+), a
	inc	hl
	ld	(hl), #0x00
;src/UI/ui_text.c:71: ui_clear(win_x, win_y, w, h);
	ldhl	sp,	#14
	ld	a, (hl-)
	ld	d, a
	ld	e, (hl)
	push	de
	ldhl	sp,	#6
	ld	a, (hl+)
	ld	e, a
	ld	a, (hl)
	call	_ui_clear
;src/UI/ui_text.c:72: while (*str && line < h) {
	ldhl	sp,	#7
	ld	(hl), #0x00
00118$:
	ldhl	sp,	#15
	ld	a, (hl)
	ldhl	sp,	#9
	ld	(hl), a
	ldhl	sp,	#16
	ld	a, (hl)
	ldhl	sp,	#10
	ld	(hl-), a
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, (de)
	ld	c, a
	or	a, a
	jp	Z, 00125$
	ldhl	sp,	#7
	ld	a, (hl)
	ldhl	sp,	#14
	sub	a, (hl)
	jp	NC, 00125$
;src/UI/ui_text.c:73: if (*str == ' ') { str++; continue; }
	ld	a, c
	sub	a, #0x20
	jr	NZ, 00133$
	ldhl	sp,#9
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	l, e
	ld	h, d
	inc	hl
	push	hl
	ld	a, l
	ldhl	sp,	#17
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#16
	ld	(hl), a
	jr	00118$
;src/UI/ui_text.c:76: for (len = 0u; str[len] && str[len] != ' '; len++) ;
00133$:
	ldhl	sp,	#8
	ld	(hl), #0x00
00123$:
	ldhl	sp,#15
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ldhl	sp,	#8
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	inc	sp
	inc	sp
	ld	e, l
	ld	d, h
	push	de
	ld	a, (de)
	or	a, a
	jr	Z, 00103$
	sub	a, #0x20
	jr	Z, 00103$
	ldhl	sp,	#8
	inc	(hl)
	jr	00123$
00103$:
;src/UI/ui_text.c:77: if (col > 0u && col + 1u + len > w) { line++; col = 0u; }
	ldhl	sp,	#6
	ld	a, (hl)
	or	a, a
	jr	Z, 00105$
	ld	a, (hl+)
	inc	hl
	ld	c, a
	xor	a, a
	ld	b, a
	inc	bc
	ld	l, (hl)
	ld	h, #0x00
	add	hl, bc
	ld	c, l
	ld	b, h
	ldhl	sp,	#13
	ld	e, (hl)
	ld	d, #0x00
	ld	a, e
	sub	a, c
	ld	a, d
	sbc	a, b
	jr	NC, 00105$
	ldhl	sp,	#7
	inc	(hl)
	dec	hl
	ld	(hl), #0x00
00105$:
;src/UI/ui_text.c:78: if (line >= h) break;
	ldhl	sp,	#7
	ld	a, (hl)
	ldhl	sp,	#14
	sub	a, (hl)
	jr	NC, 00125$
;src/UI/ui_text.c:79: if (col > 0u) col++;   /* the space between words */
	ldhl	sp,	#6
	ld	a, (hl)
	or	a, a
	jr	Z, 00141$
	inc	(hl)
;src/UI/ui_text.c:81: while (*str && *str != ' ') {
00141$:
	ldhl	sp,	#4
	ld	a, (hl)
	ldhl	sp,	#7
	add	a, (hl)
	ldhl	sp,	#3
	ld	(hl), a
	ldhl	sp,	#6
	ld	a, (hl+)
	inc	hl
	ld	(hl), a
00114$:
	ldhl	sp,#9
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, (de)
	ld	c,a
	or	a,a
	jp	Z,00118$
	sub	a, #0x20
	jp	Z, 00118$
;src/UI/ui_text.c:82: if (col < w) {
	dec	hl
	dec	hl
	ld	a, (hl)
	ldhl	sp,	#13
	sub	a, (hl)
	jr	NC, 00112$
;src/UI/ui_text.c:83: tile = char_to_tile(*str);
	ld	a, c
	call	_char_to_tile
;src/UI/ui_text.c:84: set_win_tiles(win_x + col, win_y + line, 1, 1, &tile);
	ldhl	sp,#2
	ld	(hl), a
	ld	c, l
	ld	b, h
	ldhl	sp,	#5
	ld	a, (hl)
	ldhl	sp,	#8
	add	a, (hl)
	push	bc
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
;src/UI/ui_text.c:85: col++;
	ldhl	sp,	#8
	inc	(hl)
	ld	a, (hl-)
	dec	hl
	ld	(hl), a
00112$:
;src/UI/ui_text.c:87: str++;
	ldhl	sp,	#9
	inc	(hl)
	jr	NZ, 00238$
	inc	hl
	inc	(hl)
00238$:
	ldhl	sp,	#9
	ld	a, (hl)
	ldhl	sp,	#15
	ld	(hl), a
	ldhl	sp,	#10
	ld	a, (hl)
	ldhl	sp,	#16
	ld	(hl), a
	jr	00114$
00125$:
;src/UI/ui_text.c:90: }
	add	sp, #11
	pop	hl
	add	sp, #4
	jp	(hl)
;src/UI/ui_text.c:92: char *ui_str_cat(char *dst, const char *src) {
;	---------------------------------
; Function ui_str_cat
; ---------------------------------
_ui_str_cat::
;src/UI/ui_text.c:93: while (*src) *dst++ = *src++;
00101$:
	ld	a, (bc)
	or	a, a
	jr	Z, 00103$
	inc	bc
	ld	(de), a
	inc	de
	jr	00101$
00103$:
;src/UI/ui_text.c:94: *dst = 0;
	xor	a, a
	ld	(de), a
;src/UI/ui_text.c:95: return dst;
	ld	c, e
	ld	b, d
;src/UI/ui_text.c:96: }
	ret
;src/UI/ui_text.c:98: char *ui_str_u8(char *dst, uint8_t value) {
;	---------------------------------
; Function ui_str_u8
; ---------------------------------
_ui_str_u8::
	ld	c, e
	ld	b, d
	ld	h, a
;src/UI/ui_text.c:99: if (value >= 100u) *dst++ = (char)('0' + value / 100u);
	ld	l, h
	ld	a, h
	sub	a, #0x64
	jr	C, 00102$
	ld	a, l
	push	hl
	push	bc
	ld	e, #0x64
	call	__divuchar
	ld	a, c
	pop	bc
	pop	hl
	add	a, #0x30
	ld	(bc), a
	inc	bc
00102$:
;src/UI/ui_text.c:100: if (value >= 10u)  *dst++ = (char)('0' + (value / 10u) % 10u);
	ld	a, h
	sub	a, #0x0a
	jr	C, 00104$
	ld	a, l
	push	hl
	push	bc
	ld	e, #0x0a
	call	__divuchar
	ld	a, c
	ld	e, #0x0a
	call	__moduchar
	ld	a, c
	pop	bc
	pop	hl
	add	a, #0x30
	ld	(bc), a
	inc	bc
00104$:
;src/UI/ui_text.c:101: *dst++ = (char)('0' + value % 10u);
	ld	a, l
	push	bc
	ld	e, #0x0a
	call	__moduchar
	ld	a, c
	pop	bc
	add	a, #0x30
	ld	(bc), a
	inc	bc
;src/UI/ui_text.c:102: *dst = 0;
	xor	a, a
	ld	(bc), a
;src/UI/ui_text.c:103: return dst;
;src/UI/ui_text.c:104: }
	ret
	.area _CODE_1
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

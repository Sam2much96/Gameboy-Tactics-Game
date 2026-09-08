;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.5.1 #15267 (Mac OS X ppc)
;--------------------------------------------------------
	.module main
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _main
	.globl _performantdelay
	.globl _run_titlescreen
	.globl _astar_find
	.globl _pointer_anim_select
	.globl _pointer_hide
	.globl _pointer_move
	.globl _pointer_init
	.globl _ui_print_uint8
	.globl _ui_print
	.globl _gbt_update
	.globl _gbt_loop
	.globl _gbt_play
	.globl _font_load
	.globl _font_init
	.globl _set_sprite_data
	.globl _set_win_tiles
	.globl _set_bkg_tiles
	.globl _set_bkg_data
	.globl _display_off
	.globl _wait_vbl_done
	.globl _set_interrupts
	.globl _joypad
	.globl _player_grid_y
	.globl _player_grid_x
	.globl _move_timer
	.globl _move_path_step
	.globl _move_path_len
	.globl _ui_menu_idx
	.globl _ui_visible
	.globl _prev_keys
	.globl _input_timer
	.globl _cursor_y
	.globl _cursor_x
	.globl _spritesize
	.globl _Player
	.globl _move_path
	.globl _ui_ptr
	.globl _grid
	.globl _i
	.globl _enemy
	.globl _player
	.globl _player_anim_init
	.globl _player_anim_set_dir
	.globl _player_anim_set_state
	.globl _player_anim_apply
	.globl _player_anim_tick
	.globl _init_grid
	.globl _init_overlay
	.globl _clear_overlay
	.globl _draw_grid
	.globl _draw_cursor
	.globl _handle_input
	.globl _fadeout
	.globl _fadein
	.globl _setupPlayer
	.globl _movegamecharacter
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
	.area _HRAM
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _DATA
_player::
	.ds 8
_enemy::
	.ds 8
_i::
	.ds 1
_grid::
	.ds 225
_ui_ptr::
	.ds 2
_player_anim:
	.ds 4
_move_path::
	.ds 64
_win_row_buf:
	.ds 20
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _INITIALIZED
_Player::
	.ds 256
_spritesize::
	.ds 1
_cursor_x::
	.ds 1
_cursor_y::
	.ds 1
_input_timer::
	.ds 1
_prev_keys::
	.ds 1
_ui_visible::
	.ds 1
_ui_menu_idx::
	.ds 1
_ui_anim:
	.ds 1
_ui_anim_row:
	.ds 1
_move_path_len::
	.ds 1
_move_path_step::
	.ds 1
_move_timer::
	.ds 1
_player_grid_x::
	.ds 1
_player_grid_y::
	.ds 1
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
;src/characters/player_anim.c:37: static uint8_t state_frame_count(PlayerAnimState state) {
;	---------------------------------
; Function state_frame_count
; ---------------------------------
_state_frame_count:
;src/characters/player_anim.c:38: switch (state) {
	cp	a, #0x01
	jr	Z, 00101$
	sub	a, #0x02
	jr	Z, 00102$
	jr	00103$
;src/characters/player_anim.c:39: case ANIM_WALK:   return WALK_FRAME_COUNT;
00101$:
	ld	a, #0x01
	ret
;src/characters/player_anim.c:40: case ANIM_ATTACK: return ATTACK_FRAME_COUNT;
00102$:
	ld	a, #0x01
	ret
;src/characters/player_anim.c:41: default:          return IDLE_FRAME_COUNT;
00103$:
	ld	a, #0x01
;src/characters/player_anim.c:42: }
;src/characters/player_anim.c:43: }
	ret
_idle_frames_down:
	.db #0x00	; 0
_idle_frames_left:
	.db #0x01	; 1
_idle_frames_right:
	.db #0x02	; 2
_idle_frames_up:
	.db #0x03	; 3
_walk_frames_down:
	.db #0x00	; 0
_walk_frames_left:
	.db #0x01	; 1
_walk_frames_right:
	.db #0x02	; 2
_walk_frames_up:
	.db #0x03	; 3
_attack_frames_down:
	.db #0x00	; 0
_attack_frames_left:
	.db #0x01	; 1
_attack_frames_right:
	.db #0x02	; 2
_attack_frames_up:
	.db #0x03	; 3
;src/characters/player_anim.c:45: static uint8_t state_speed(PlayerAnimState state) {
;	---------------------------------
; Function state_speed
; ---------------------------------
_state_speed:
;src/characters/player_anim.c:46: switch (state) {
	cp	a, #0x01
	jr	Z, 00101$
	sub	a, #0x02
	jr	Z, 00102$
	jr	00103$
;src/characters/player_anim.c:47: case ANIM_WALK:   return WALK_SPEED;
00101$:
	ld	a, #0x0a
	ret
;src/characters/player_anim.c:48: case ANIM_ATTACK: return ATTACK_SPEED;
00102$:
	ld	a, #0x06
	ret
;src/characters/player_anim.c:49: default:          return 0u;
00103$:
	xor	a, a
;src/characters/player_anim.c:50: }
;src/characters/player_anim.c:51: }
	ret
;src/characters/player_anim.c:54: static uint8_t gbtd_tile(PlayerAnimState state, PlayerDir dir, uint8_t frame) {
;	---------------------------------
; Function gbtd_tile
; ---------------------------------
_gbtd_tile:
	dec	sp
	ld	c, a
;src/characters/player_anim.c:57: switch (dir) {
	ld	a, e
	dec	a
	ld	a, #0x01
	jr	Z, 00200$
	xor	a, a
00200$:
	ld	l, a
	ld	a, e
	sub	a, #0x02
	ld	a, #0x01
	jr	Z, 00202$
	xor	a, a
00202$:
	push	hl
	ldhl	sp,	#2
	ld	(hl), a
	pop	hl
	ld	a, e
	sub	a, #0x03
	ld	a, #0x01
	jr	Z, 00204$
	xor	a, a
00204$:
	ld	e, a
;src/characters/player_anim.c:55: switch (state) {
	ld	a, c
	dec	a
	jr	Z, 00101$
	ld	a, c
	sub	a, #0x02
	jr	Z, 00107$
	jp	00113$
;src/characters/player_anim.c:56: case ANIM_WALK:
00101$:
;src/characters/player_anim.c:57: switch (dir) {
	ld	a, l
	or	a, a
	jr	NZ, 00102$
	ldhl	sp,	#0
	ld	a, (hl)
	or	a, a
	jr	NZ, 00103$
	or	a, e
	jr	NZ, 00104$
	jr	00105$
;src/characters/player_anim.c:58: case DIR_LEFT:  return walk_frames_left[frame];
00102$:
	ld	bc, #_walk_frames_left+0
	ldhl	sp,	#3
	ld	l, (hl)
	ld	h, #0x00
	add	hl, bc
	ld	c, l
	ld	b, h
	ld	a, (bc)
	jp	00120$
;src/characters/player_anim.c:59: case DIR_RIGHT: return walk_frames_right[frame];
00103$:
	ld	bc, #_walk_frames_right+0
	ldhl	sp,	#3
	ld	l, (hl)
	ld	h, #0x00
	add	hl, bc
	ld	c, l
	ld	b, h
	ld	a, (bc)
	jp	00120$
;src/characters/player_anim.c:60: case DIR_UP:    return walk_frames_up[frame];
00104$:
	ld	bc, #_walk_frames_up+0
	ldhl	sp,	#3
	ld	l, (hl)
	ld	h, #0x00
	add	hl, bc
	ld	c, l
	ld	b, h
	ld	a, (bc)
	jp	00120$
;src/characters/player_anim.c:61: default:        return walk_frames_down[frame];
00105$:
	ld	bc, #_walk_frames_down+0
	ldhl	sp,	#3
	ld	l, (hl)
	ld	h, #0x00
	add	hl, bc
	ld	c, l
	ld	b, h
	ld	a, (bc)
	jp	00120$
;src/characters/player_anim.c:63: case ANIM_ATTACK:
00107$:
;src/characters/player_anim.c:64: switch (dir) {
	ld	a, l
	or	a, a
	jr	NZ, 00108$
	ldhl	sp,	#0
	ld	a, (hl)
	or	a, a
	jr	NZ, 00109$
	or	a, e
	jr	NZ, 00110$
	jr	00111$
;src/characters/player_anim.c:65: case DIR_LEFT:  return attack_frames_left[frame];
00108$:
	ld	bc, #_attack_frames_left+0
	ldhl	sp,	#3
	ld	l, (hl)
	ld	h, #0x00
	add	hl, bc
	ld	c, l
	ld	b, h
	ld	a, (bc)
	jr	00120$
;src/characters/player_anim.c:66: case DIR_RIGHT: return attack_frames_right[frame];
00109$:
	ld	bc, #_attack_frames_right+0
	ldhl	sp,	#3
	ld	l, (hl)
	ld	h, #0x00
	add	hl, bc
	ld	c, l
	ld	b, h
	ld	a, (bc)
	jr	00120$
;src/characters/player_anim.c:67: case DIR_UP:    return attack_frames_up[frame];
00110$:
	ld	bc, #_attack_frames_up+0
	ldhl	sp,	#3
	ld	l, (hl)
	ld	h, #0x00
	add	hl, bc
	ld	c, l
	ld	b, h
	ld	a, (bc)
	jr	00120$
;src/characters/player_anim.c:68: default:        return attack_frames_down[frame];
00111$:
	ld	bc, #_attack_frames_down+0
	ldhl	sp,	#3
	ld	l, (hl)
	ld	h, #0x00
	add	hl, bc
	ld	c, l
	ld	b, h
	ld	a, (bc)
	jr	00120$
;src/characters/player_anim.c:70: default: /* ANIM_IDLE */
00113$:
;src/characters/player_anim.c:71: switch (dir) {
	ld	a, l
	or	a, a
	jr	NZ, 00114$
	ldhl	sp,	#0
	ld	a, (hl)
	or	a, a
	jr	NZ, 00115$
	or	a, e
	jr	NZ, 00116$
	jr	00117$
;src/characters/player_anim.c:72: case DIR_LEFT:  return idle_frames_left[frame];
00114$:
	ld	bc, #_idle_frames_left+0
	ldhl	sp,	#3
	ld	l, (hl)
	ld	h, #0x00
	add	hl, bc
	ld	c, l
	ld	b, h
	ld	a, (bc)
	jr	00120$
;src/characters/player_anim.c:73: case DIR_RIGHT: return idle_frames_right[frame];
00115$:
	ld	bc, #_idle_frames_right+0
	ldhl	sp,	#3
	ld	l, (hl)
	ld	h, #0x00
	add	hl, bc
	ld	c, l
	ld	b, h
	ld	a, (bc)
	jr	00120$
;src/characters/player_anim.c:74: case DIR_UP:    return idle_frames_up[frame];
00116$:
	ld	bc, #_idle_frames_up+0
	ldhl	sp,	#3
	ld	l, (hl)
	ld	h, #0x00
	add	hl, bc
	ld	c, l
	ld	b, h
	ld	a, (bc)
	jr	00120$
;src/characters/player_anim.c:75: default:        return idle_frames_down[frame];
00117$:
	ld	bc, #_idle_frames_down+0
	ldhl	sp,	#3
	ld	l, (hl)
	ld	h, #0x00
	add	hl, bc
	ld	c, l
	ld	b, h
	ld	a, (bc)
;src/characters/player_anim.c:77: }
00120$:
;src/characters/player_anim.c:78: }
	inc	sp
	pop	hl
	inc	sp
	jp	(hl)
;src/characters/player_anim.c:82: void player_anim_init(PlayerAnim *a) {
;	---------------------------------
; Function player_anim_init
; ---------------------------------
_player_anim_init::
;src/characters/player_anim.c:83: a->dir   = DIR_DOWN;
	xor	a, a
	ld	(de), a
;src/characters/player_anim.c:84: a->state = ANIM_IDLE;
	ld	l, e
	ld	h, d
	inc	hl
	ld	(hl), #0x00
;src/characters/player_anim.c:85: a->frame = 0u;
	ld	l, e
	ld	h, d
	inc	hl
	inc	hl
	ld	(hl), #0x00
;src/characters/player_anim.c:86: a->timer = 0u;
	inc	de
	inc	de
	inc	de
	xor	a, a
	ld	(de), a
;src/characters/player_anim.c:87: }
	ret
;src/characters/player_anim.c:89: void player_anim_set_dir(PlayerAnim *a, PlayerDir dir) {
;	---------------------------------
; Function player_anim_set_dir
; ---------------------------------
_player_anim_set_dir::
;src/characters/player_anim.c:90: a->dir   = dir;
	ld	(de), a
;src/characters/player_anim.c:91: a->frame = 0u;
	ld	l, e
	ld	h, d
	inc	hl
	inc	hl
	ld	(hl), #0x00
;src/characters/player_anim.c:92: a->timer = 0u;
	inc	de
	inc	de
	inc	de
	xor	a, a
	ld	(de), a
;src/characters/player_anim.c:93: }
	ret
;src/characters/player_anim.c:95: void player_anim_set_state(PlayerAnim *a, PlayerAnimState state) {
;	---------------------------------
; Function player_anim_set_state
; ---------------------------------
_player_anim_set_state::
	ld	c, e
	ld	b, d
;src/characters/player_anim.c:96: if (a->state == state) return;
	ld	l, c
	ld	h, b
	inc	hl
	ld	e, (hl)
	cp	a, e
	ret	Z
;src/characters/player_anim.c:97: a->state = state;
	ld	(hl), a
;src/characters/player_anim.c:98: a->frame = 0u;
	ld	l, c
	ld	h, b
	inc	hl
	inc	hl
	ld	(hl), #0x00
;src/characters/player_anim.c:99: a->timer = 0u;
	inc	bc
	inc	bc
	inc	bc
	xor	a, a
	ld	(bc), a
;src/characters/player_anim.c:100: }
	ret
;src/characters/player_anim.c:102: void player_anim_apply(const PlayerAnim *a) {
;	---------------------------------
; Function player_anim_apply
; ---------------------------------
_player_anim_apply::
;src/characters/player_anim.c:103: uint8_t gbtd = gbtd_tile(a->state, a->dir, a->frame);
	ld	l, e
	ld	h, d
	inc	hl
	inc	hl
	ld	b, (hl)
	ld	a, (de)
	ld	c, a
	inc	de
	ld	a, (de)
	push	bc
	inc	sp
	ld	e, c
	call	_gbtd_tile
;src/characters/player_anim.c:104: uint8_t base = PLAYER_TILE_BASE + gbtd * 4u;
	add	a, a
	add	a, a
	add	a, #0x4c
	ld	c, a
;/Users/apple/gbdk/include/gb/gb.h:1887: shadow_OAM[nb].tile=tile;
	ld	hl, #(_shadow_OAM + 2)
	ld	(hl), c
;src/characters/player_anim.c:108: set_sprite_tile(1, base + 2u);  /* TR */
	ld	b, c
	inc	b
	inc	b
;/Users/apple/gbdk/include/gb/gb.h:1887: shadow_OAM[nb].tile=tile;
	ld	hl, #(_shadow_OAM + 6)
	ld	(hl), b
;src/characters/player_anim.c:109: set_sprite_tile(2, base + 1u);  /* BL */
	ld	b, c
	inc	b
;/Users/apple/gbdk/include/gb/gb.h:1887: shadow_OAM[nb].tile=tile;
	ld	hl, #(_shadow_OAM + 10)
	ld	(hl), b
;src/characters/player_anim.c:110: set_sprite_tile(3, base + 3u);  /* BR */
	inc	c
	inc	c
	inc	c
;/Users/apple/gbdk/include/gb/gb.h:1887: shadow_OAM[nb].tile=tile;
	ld	hl, #(_shadow_OAM + 14)
	ld	(hl), c
;src/characters/player_anim.c:110: set_sprite_tile(3, base + 3u);  /* BR */
;src/characters/player_anim.c:111: }
	ret
;src/characters/player_anim.c:113: uint8_t player_anim_tick(PlayerAnim *a) {
;	---------------------------------
; Function player_anim_tick
; ---------------------------------
_player_anim_tick::
;src/characters/player_anim.c:114: uint8_t count = state_frame_count(a->state);
	push	de
	inc	de
	ld	a, (de)
	push	de
	call	_state_frame_count
	ld	c, a
	pop	de
;src/characters/player_anim.c:115: uint8_t speed = state_speed(a->state);
	ld	a, (de)
	push	bc
	call	_state_speed
	ld	e, a
	pop	bc
;src/characters/player_anim.c:116: if (count <= 1u || speed == 0u) return 0u;  /* single-frame — nothing to do */
	ld	a, #0x01
	sub	a, c
	jr	NC, 00101$
	ld	a, e
	or	a, a
	jr	NZ, 00102$
00101$:
	xor	a, a
	jr	00106$
00102$:
;src/characters/player_anim.c:117: if (++a->timer >= speed) {
	pop	hl
	push	hl
	inc	hl
	inc	hl
	inc	hl
	inc	(hl)
	ld	a, (hl)
	sub	a, e
	jr	C, 00105$
;src/characters/player_anim.c:118: a->timer = 0u;
	ld	(hl), #0x00
;src/characters/player_anim.c:119: a->frame = (a->frame + 1u) % count;
	pop	de
	push	de
	inc	de
	inc	de
	ld	a, (de)
	ld	l, a
	xor	a, a
	ld	h, a
	inc	hl
	xor	a, a
	push	de
	ld	b, a
	ld	e, l
	ld	d, h
	call	__moduint
	pop	de
	ld	a, c
	ld	(de), a
;src/characters/player_anim.c:120: player_anim_apply(a);
	pop	de
	push	de
	call	_player_anim_apply
;src/characters/player_anim.c:121: return 1u;
	ld	a, #0x01
	jr	00106$
00105$:
;src/characters/player_anim.c:123: return 0u;
	xor	a, a
00106$:
;src/characters/player_anim.c:124: }
	inc	sp
	inc	sp
	ret
;src/main.c:159: static void win_write_row(uint8_t row) {
;	---------------------------------
; Function win_write_row
; ---------------------------------
_win_write_row:
	add	sp, #-3
	ldhl	sp,	#2
	ld	(hl), a
;src/main.c:161: for (col = 0u; col < UIWidth; col++) {
	ld	c, #0x00
00102$:
;src/main.c:162: uint8_t t = UI[(uint16_t)row * UIWidth + col];
	ldhl	sp,	#2
	ld	a, (hl-)
	dec	hl
	ld	(hl+), a
	ld	(hl), #0x00
	pop	de
	push	de
	ld	l, e
	ld	h, d
	add	hl, hl
	add	hl, hl
	add	hl, de
	add	hl, hl
	add	hl, hl
	ld	e, c
	ld	d, #0x00
	add	hl, de
	ld	de, #_UI
	add	hl, de
	ld	e, (hl)
;src/main.c:163: win_row_buf[col] = (t >= 1u && t <= 8u) ? (uint8_t)(UI_TILE_BASE + t - 1u) : 0u;
	ld	hl, #_win_row_buf
	ld	b, #0x00
	add	hl, bc
	ld	a, e
	sub	a, #0x01
	jr	C, 00106$
	ld	a, #0x08
	sub	a, e
	jr	C, 00106$
	ld	a, e
	add	a, #0x43
	jr	00107$
00106$:
	xor	a, a
00107$:
	ld	(hl), a
;src/main.c:161: for (col = 0u; col < UIWidth; col++) {
	inc	c
	ld	a, c
	sub	a, #0x14
	jr	C, 00102$
;src/main.c:165: set_win_tiles(0u, row, UIWidth, 1u, win_row_buf);
	ld	de, #_win_row_buf
	push	de
	ld	hl, #0x114
	push	hl
	ldhl	sp,	#6
	ld	h, (hl)
	ld	l, #0x00
	push	hl
	call	_set_win_tiles
;src/main.c:166: }
	add	sp, #9
	ret
_UI_MENU_Y:
	.db #0x10	; 16
	.db #0x20	; 32
	.db #0x30	; 48	'0'
;src/main.c:169: static void win_clear_row(uint8_t row) {
;	---------------------------------
; Function win_clear_row
; ---------------------------------
_win_clear_row:
	ld	b, a
;src/main.c:171: for (col = 0u; col < UIWidth; col++) win_row_buf[col] = 0u;
	ld	de, #_win_row_buf+0
	ld	c, #0x00
00102$:
	ld	l, c
	ld	h, #0x00
	add	hl, de
	ld	(hl), #0x00
	inc	c
	ld	a, c
	sub	a, #0x14
	jr	C, 00102$
;src/main.c:172: set_win_tiles(0u, row, UIWidth, 1u, win_row_buf);
	push	de
	ld	hl, #0x114
	push	hl
	push	bc
	inc	sp
	xor	a, a
	push	af
	inc	sp
	call	_set_win_tiles
	add	sp, #6
;src/main.c:173: }
	ret
;src/main.c:177: static void restore_bkg_tile(uint8_t gx, uint8_t gy) {
;	---------------------------------
; Function restore_bkg_tile
; ---------------------------------
_restore_bkg_tile:
	dec	sp
	ld	c, a
	ld	b, e
;src/main.c:179: switch (grid[gx][gy].type) {
	ld	e, c
	ld	d, #0x00
	ld	l, e
	ld	h, d
	add	hl, hl
	add	hl, de
	add	hl, hl
	add	hl, de
	add	hl, hl
	add	hl, de
	ld	de, #_grid
	add	hl, de
	ld	e, b
	ld	d, #0x00
	add	hl, de
	ld	a, (hl)
	dec	a
	jr	NZ, 00102$
;src/main.c:180: case TILE_GRASS: t = GRASS_TILE; break;
	ldhl	sp,	#0
	ld	(hl), #0x26
	jr	00103$
;src/main.c:181: default:         t = EMPTY_TILE; break;
00102$:
	ldhl	sp,	#0
	ld	(hl), #0x25
;src/main.c:182: }
00103$:
;src/main.c:183: set_bkg_tiles(GRID_ORIGIN_X + gx, GRID_ORIGIN_Y + gy, 1u, 1u, &t);
	ld	hl, #0
	add	hl, sp
	push	hl
	ld	hl, #0x101
	push	hl
	push	bc
	call	_set_bkg_tiles
;src/main.c:184: }
	add	sp, #7
	ret
;src/main.c:188: static void draw_path_tiles(void) {
;	---------------------------------
; Function draw_path_tiles
; ---------------------------------
_draw_path_tiles:
	dec	sp
;src/main.c:189: uint8_t t = PATH_HIGHLIGHT_TILE;
	ldhl	sp,	#0
	ld	(hl), #0x5d
;src/main.c:191: for (i = 1u; i < move_path_len; i++) {
	ld	c, #0x01
00103$:
	ld	a, c
	ld	hl, #_move_path_len
	sub	a, (hl)
	jr	NC, 00105$
;src/main.c:193: GRID_ORIGIN_Y + move_path[i].y, 1u, 1u, &t);
	ld	l, c
	xor	a, a
	ld	h, a
	add	hl, hl
	ld	de, #_move_path
	add	hl, de
	ld	e, l
	ld	d, h
	inc	de
	ld	a, (de)
;src/main.c:192: set_bkg_tiles(GRID_ORIGIN_X + move_path[i].x,
	ld	d, (hl)
	ld	hl, #0
	add	hl, sp
	push	hl
	ld	h, #0x01
	push	hl
	inc	sp
	ld	h, #0x01
	push	hl
	inc	sp
	push	af
	inc	sp
	push	de
	inc	sp
	call	_set_bkg_tiles
	add	sp, #6
;src/main.c:191: for (i = 1u; i < move_path_len; i++) {
	inc	c
	jr	00103$
00105$:
;src/main.c:195: }
	inc	sp
	ret
;src/main.c:199: static void clear_path_tiles(void) {
;	---------------------------------
; Function clear_path_tiles
; ---------------------------------
_clear_path_tiles:
;src/main.c:201: for (i = 1u; i < move_path_len; i++) {
	ld	c, #0x01
00103$:
	ld	a, c
	ld	hl, #_move_path_len
	sub	a, (hl)
	ret	NC
;src/main.c:202: restore_bkg_tile(move_path[i].x, move_path[i].y);
	ld	l, c
	xor	a, a
	ld	h, a
	add	hl, hl
	ld	de, #_move_path
	add	hl, de
	ld	e, l
	ld	d, h
	inc	de
	ld	a, (de)
	ld	e, a
	ld	a, (hl)
	push	bc
	call	_restore_bkg_tile
	pop	bc
;src/main.c:201: for (i = 1u; i < move_path_len; i++) {
	inc	c
;src/main.c:204: }
	jr	00103$
;src/main.c:207: static void ui_write_text(void) {
;	---------------------------------
; Function ui_write_text
; ---------------------------------
_ui_write_text:
;src/main.c:208: ui_print(3u,  2u, "MAGIC");
	ld	de, #___str_0
	push	de
	ld	e, #0x02
	ld	a, #0x03
	call	_ui_print
;src/main.c:209: ui_print(3u,  4u, "ATTACK");
	ld	de, #___str_1
	push	de
	ld	e, #0x04
	ld	a, #0x03
	call	_ui_print
;src/main.c:210: ui_print(3u,  6u, "END");
	ld	de, #___str_2
	push	de
	ld	e, #0x06
	ld	a, #0x03
	call	_ui_print
;src/main.c:211: ui_print(14u, 2u, "HP");
	ld	de, #___str_3
	push	de
	ld	e, #0x02
	ld	a, #0x0e
	call	_ui_print
;src/main.c:212: ui_print_uint8(17u, 2u, 10u);
	ld	a, #0x0a
	push	af
	inc	sp
	ld	e, #0x02
	ld	a, #0x11
	call	_ui_print_uint8
;src/main.c:213: ui_print(14u, 4u, "ATK");
	ld	de, #___str_4
	push	de
	ld	e, #0x04
	ld	a, #0x0e
	call	_ui_print
;src/main.c:214: ui_print_uint8(18u, 4u, 5u);
	ld	a, #0x05
	push	af
	inc	sp
	ld	e, #0x04
	ld	a, #0x12
	call	_ui_print_uint8
;src/main.c:215: }
	ret
___str_0:
	.ascii "MAGIC"
	.db 0x00
___str_1:
	.ascii "ATTACK"
	.db 0x00
___str_2:
	.ascii "END"
	.db 0x00
___str_3:
	.ascii "HP"
	.db 0x00
___str_4:
	.ascii "ATK"
	.db 0x00
;src/main.c:233: void init_grid(void)
;	---------------------------------
; Function init_grid
; ---------------------------------
_init_grid::
;src/main.c:235: for (uint8_t y = 0; y < GRID_SIZE; y++)
	ld	c, #0x00
00107$:
	ld	a, c
	sub	a, #0x0f
	ret	NC
;src/main.c:237: for (uint8_t x = 0; x < GRID_SIZE; x++)
	ld	b, #0x00
00104$:
	ld	a, b
	sub	a, #0x0f
	jr	NC, 00108$
;src/main.c:239: grid[x][y].type = TILE_GRASS;
	ld	e, b
	ld	d, #0x00
	ld	l, e
	ld	h, d
	add	hl, hl
	add	hl, de
	add	hl, hl
	add	hl, de
	add	hl, hl
	add	hl, de
	ld	de, #_grid
	add	hl, de
	ld	e, c
	ld	d, #0x00
	add	hl, de
	ld	(hl), #0x01
;src/main.c:237: for (uint8_t x = 0; x < GRID_SIZE; x++)
	inc	b
	jr	00104$
00108$:
;src/main.c:235: for (uint8_t y = 0; y < GRID_SIZE; y++)
	inc	c
;src/main.c:242: }
	jr	00107$
;src/main.c:252: void init_overlay(void)
;	---------------------------------
; Function init_overlay
; ---------------------------------
_init_overlay::
;src/main.c:255: set_sprite_data(SELECTOR_TILE_BASE, 1, Selector);
	ld	de, #_Selector
	push	de
	ld	hl, #0x15c
	push	hl
	call	_set_sprite_data
	add	sp, #4
;src/main.c:259: set_bkg_data(PATH_HIGHLIGHT_TILE, 1, Selector + 16u);
	ld	de, #(_Selector + 16)
	push	de
	ld	hl, #0x15d
	push	hl
	call	_set_bkg_data
	add	sp, #4
;/Users/apple/gbdk/include/gb/gb.h:1887: shadow_OAM[nb].tile=tile;
	ld	hl, #(_shadow_OAM + 18)
;/Users/apple/gbdk/include/gb/gb.h:1946: shadow_OAM[nb].prop=prop;
	ld	a, #0x5c
	ld	(hl+), a
	ld	(hl), #0x10
;src/main.c:262: OBP1_REG = 0x00;
	xor	a, a
	ldh	(_OBP1_REG + 0), a
;src/main.c:263: }
	ret
;src/main.c:273: void clear_overlay(void)
;	---------------------------------
; Function clear_overlay
; ---------------------------------
_clear_overlay::
;src/main.c:277: }
	ret
;src/main.c:286: void draw_grid(void)
;	---------------------------------
; Function draw_grid
; ---------------------------------
_draw_grid::
	dec	sp
	dec	sp
;src/main.c:288: for (uint8_t y = 0; y < GRID_SIZE; y++)
	ld	b, #0x00
00110$:
	ld	a, b
	sub	a, #0x0f
	jr	NC, 00112$
;src/main.c:290: for (uint8_t x = 0; x < GRID_SIZE; x++)
	ldhl	sp,	#1
	ld	(hl), #0x00
00107$:
	ldhl	sp,	#1
	ld	a, (hl)
	sub	a, #0x0f
	jr	NC, 00111$
;src/main.c:296: switch (grid[x][y].type)
	ld	e, (hl)
	ld	d, #0x00
	ld	l, e
	ld	h, d
	add	hl, hl
	add	hl, de
	add	hl, hl
	add	hl, de
	add	hl, hl
	add	hl, de
	ld	de, #_grid
	add	hl, de
	ld	e, b
	ld	d, #0x00
	add	hl, de
	ld	a, (hl)
	dec	a
	jr	NZ, 00102$
;src/main.c:299: t = GRASS_TILE;
	ldhl	sp,	#0
	ld	(hl), #0x26
;src/main.c:300: break; // tile 1 — small grass
	jr	00103$
;src/main.c:301: default:
00102$:
;src/main.c:302: t = EMPTY_TILE;
	ldhl	sp,	#0
	ld	(hl), #0x25
;src/main.c:304: }
00103$:
;src/main.c:307: set_bkg_tiles(GRID_ORIGIN_X + x, GRID_ORIGIN_Y + y, 1, 1, &t);
	ld	hl, #0
	add	hl, sp
	push	hl
	ld	hl, #0x101
	push	hl
	push	bc
	inc	sp
	ldhl	sp,	#6
	ld	a, (hl)
	push	af
	inc	sp
	call	_set_bkg_tiles
	add	sp, #6
;src/main.c:290: for (uint8_t x = 0; x < GRID_SIZE; x++)
	ldhl	sp,	#1
	inc	(hl)
	jr	00107$
00111$:
;src/main.c:288: for (uint8_t y = 0; y < GRID_SIZE; y++)
	inc	b
	jr	00110$
00112$:
;src/main.c:310: }
	inc	sp
	inc	sp
	ret
;src/main.c:320: void draw_cursor(void)
;	---------------------------------
; Function draw_cursor
; ---------------------------------
_draw_cursor::
;src/main.c:324: (GRID_ORIGIN_Y + cursor_y) * 8 + 16);
	ld	a, (_cursor_y)
	add	a, a
	add	a, a
	add	a, a
	add	a, #0x10
	ld	b, a
;src/main.c:323: move_sprite(4, (GRID_ORIGIN_X + cursor_x) * 8 + 8,
	ld	a, (_cursor_x)
	add	a, a
	add	a, a
	add	a, a
	add	a, #0x08
	ld	c, a
;/Users/apple/gbdk/include/gb/gb.h:1973: OAM_item_t * itm = &shadow_OAM[nb];
	ld	hl, #(_shadow_OAM + 16)
;/Users/apple/gbdk/include/gb/gb.h:1974: itm->y=y, itm->x=x;
	ld	a, b
	ld	(hl+), a
	ld	(hl), c
;src/main.c:324: (GRID_ORIGIN_Y + cursor_y) * 8 + 16);
;src/main.c:325: }
	ret
;src/main.c:334: uint8_t handle_input(void)
;	---------------------------------
; Function handle_input
; ---------------------------------
_handle_input::
;src/main.c:336: uint8_t keys = joypad();
	call	_joypad
	ld	c, a
;src/main.c:337: uint8_t moved = 0;
	ld	b, #0x00
;src/main.c:339: if (input_timer == 0)
	ld	a, (#_input_timer)
	or	a, a
	jr	NZ, 00119$
;src/main.c:341: if ((keys & J_RIGHT) && cursor_x < GRID_SIZE - 1)
	bit	0, c
	jr	Z, 00113$
	ld	hl, #_cursor_x
	ld	a, (hl)
	sub	a, #0x0e
	jr	NC, 00113$
;src/main.c:343: cursor_x++;
	inc	(hl)
;src/main.c:344: moved = 1;
	ld	b, #0x01
	jr	00114$
00113$:
;src/main.c:346: else if ((keys & J_LEFT) && cursor_x > 0)
	bit	1, c
	jr	Z, 00109$
	ld	hl, #_cursor_x
	ld	a, (hl)
	or	a, a
	jr	Z, 00109$
;src/main.c:348: cursor_x--;
	dec	(hl)
;src/main.c:349: moved = 1;
	ld	b, #0x01
	jr	00114$
00109$:
;src/main.c:351: else if ((keys & J_DOWN) && cursor_y < GRID_SIZE - 1)
	bit	3, c
	jr	Z, 00105$
	ld	hl, #_cursor_y
	ld	a, (hl)
	sub	a, #0x0e
	jr	NC, 00105$
;src/main.c:353: cursor_y++;
	inc	(hl)
;src/main.c:354: moved = 1;
	ld	b, #0x01
	jr	00114$
00105$:
;src/main.c:356: else if ((keys & J_UP) && cursor_y > 0)
	bit	2, c
	jr	Z, 00114$
	ld	hl, #_cursor_y
	ld	a, (hl)
	or	a, a
	jr	Z, 00114$
;src/main.c:358: cursor_y--;
	dec	(hl)
;src/main.c:359: moved = 1;
	ld	b, #0x01
00114$:
;src/main.c:362: if (moved)
	ld	a, b
	or	a, a
	jr	Z, 00120$
;src/main.c:363: input_timer = INPUT_DELAY; // arm the repeat delay after a move
	ld	hl, #_input_timer
	ld	(hl), #0x0a
	jr	00120$
00119$:
;src/main.c:367: input_timer--; // count down delay, block movement until it hits 0
	ld	hl, #_input_timer
	dec	(hl)
00120$:
;src/main.c:372: if (!(keys & (J_RIGHT | J_LEFT | J_UP | J_DOWN)))
	ld	a, c
;src/main.c:374: input_timer = 0;
	and	a,#0x0f
	jr	NZ, 00122$
	ld	(#_input_timer),a
00122$:
;src/main.c:377: return moved;
	ld	a, b
;src/main.c:378: }
	ret
;src/main.c:383: void performantdelay(UINT8 numloops)
;	---------------------------------
; Function performantdelay
; ---------------------------------
_performantdelay::
	ld	c, a
;src/main.c:386: for (ii = 0; ii < numloops; ii++)
	ld	b, #0x00
00103$:
	ld	a, b
	sub	a, c
	ret	NC
;src/main.c:388: wait_vbl_done();
	call	_wait_vbl_done
;src/main.c:386: for (ii = 0; ii < numloops; ii++)
	inc	b
;src/main.c:390: }
	jr	00103$
;src/main.c:392: void fadeout(void)
;	---------------------------------
; Function fadeout
; ---------------------------------
_fadeout::
;src/main.c:395: for (i = 0; i < 4; i++)
	xor	a, a
	ld	(#_i),a
00107$:
;src/main.c:397: switch (i)
	ld	a, #0x03
	ld	hl, #_i
	sub	a, (hl)
	jr	C, 00105$
	ld	c, (hl)
	ld	b, #0x00
	ld	hl, #00125$
	add	hl, bc
	add	hl, bc
	ld	c, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, c
	jp	(hl)
00125$:
	.dw	00101$
	.dw	00102$
	.dw	00103$
	.dw	00104$
;src/main.c:399: case 0:
00101$:
;src/main.c:400: BGP_REG = 0xE4;
	ld	a, #0xe4
	ldh	(_BGP_REG + 0), a
;src/main.c:401: break;
	jr	00105$
;src/main.c:402: case 1:
00102$:
;src/main.c:403: BGP_REG = 0xF9;
	ld	a, #0xf9
	ldh	(_BGP_REG + 0), a
;src/main.c:404: break;
	jr	00105$
;src/main.c:405: case 2:
00103$:
;src/main.c:406: BGP_REG = 0xFE;
	ld	a, #0xfe
	ldh	(_BGP_REG + 0), a
;src/main.c:407: break;
	jr	00105$
;src/main.c:408: case 3:
00104$:
;src/main.c:409: BGP_REG = 0xFF;
	ld	a, #0xff
	ldh	(_BGP_REG + 0), a
;src/main.c:411: }
00105$:
;src/main.c:412: performantdelay(10);
	ld	a, #0x0a
	call	_performantdelay
;src/main.c:395: for (i = 0; i < 4; i++)
	ld	hl, #_i
	inc	(hl)
	ld	a, (hl)
	sub	a, #0x04
	jr	C, 00107$
;src/main.c:414: }
	ret
;src/main.c:416: void fadein(void)
;	---------------------------------
; Function fadein
; ---------------------------------
_fadein::
;src/main.c:419: for (i = 0; i < 3; i++)
	xor	a, a
	ld	(#_i),a
00106$:
;src/main.c:421: switch (i)
	ld	a, (#_i)
	or	a, a
	jr	Z, 00101$
	ld	a, (#_i)
	dec	a
	jr	Z, 00102$
	ld	a, (#_i)
	sub	a, #0x02
	jr	Z, 00103$
	jr	00104$
;src/main.c:423: case 0:
00101$:
;src/main.c:424: BGP_REG = 0xFE;
	ld	a, #0xfe
	ldh	(_BGP_REG + 0), a
;src/main.c:425: break;
	jr	00104$
;src/main.c:426: case 1:
00102$:
;src/main.c:427: BGP_REG = 0xF9;
	ld	a, #0xf9
	ldh	(_BGP_REG + 0), a
;src/main.c:428: break;
	jr	00104$
;src/main.c:429: case 2:
00103$:
;src/main.c:430: BGP_REG = 0xE4;
	ld	a, #0xe4
	ldh	(_BGP_REG + 0), a
;src/main.c:432: }
00104$:
;src/main.c:433: performantdelay(10);
	ld	a, #0x0a
	call	_performantdelay
;src/main.c:419: for (i = 0; i < 3; i++)
	ld	hl, #_i
	inc	(hl)
	ld	a, (hl)
	sub	a, #0x03
	jr	C, 00106$
;src/main.c:435: }
	ret
;src/main.c:441: void setupPlayer(void)
;	---------------------------------
; Function setupPlayer
; ---------------------------------
_setupPlayer::
;src/main.c:446: player.x = 104;
	ld	hl, #(_player + 4)
;src/main.c:447: player.y = 16;
	ld	a, #0x68
	ld	(hl+), a
;src/main.c:448: player.width = 16;
	ld	a, #0x10
	ld	(hl+), a
	ld	(hl), #0x10
;src/main.c:449: player.height = 16;
	ld	hl, #_player + 7
	ld	(hl), #0x10
;src/main.c:454: player.spriteids[0] = 0;
	ld	hl, #_player
;src/main.c:455: player.spriteids[1] = 1;
	xor	a, a
	ld	(hl+), a
	ld	(hl), #0x01
;src/main.c:456: player.spriteids[2] = 2;
	ld	hl, #_player + 2
	ld	(hl), #0x02
;src/main.c:457: player.spriteids[3] = 3;
	ld	hl, #_player + 3
	ld	(hl), #0x03
;src/main.c:460: player_anim_init(&player_anim);
	ld	de, #_player_anim+0
	push	de
	call	_player_anim_init
	pop	de
;src/main.c:461: player_anim_apply(&player_anim);
	call	_player_anim_apply
;src/main.c:464: OBP0_REG = 0xE4;
	ld	a, #0xe4
	ldh	(_OBP0_REG + 0), a
;src/main.c:467: movegamecharacter(&player, player.x, player.y);
	ld	hl, #(_player + 5)
	ld	b, (hl)
	ld	a, (#(_player + 4) + 0)
	push	bc
	inc	sp
	ld	de, #_player
	call	_movegamecharacter
;src/main.c:468: }
	ret
;src/main.c:470: void movegamecharacter(struct GameCharacter *character, UINT8 x, UINT8 y)
;	---------------------------------
; Function movegamecharacter
; ---------------------------------
_movegamecharacter::
	dec	sp
	ldhl	sp,	#0
	ld	(hl), a
;src/main.c:473: move_sprite(character->spriteids[0], x, y);
	ld	a, (de)
	ld	c, a
;/Users/apple/gbdk/include/gb/gb.h:1973: OAM_item_t * itm = &shadow_OAM[nb];
	xor	a, a
	ld	l, c
	ld	h, a
	add	hl, hl
	add	hl, hl
	ld	bc, #_shadow_OAM
	add	hl, bc
	ld	c, l
	ld	b, h
;/Users/apple/gbdk/include/gb/gb.h:1974: itm->y=y, itm->x=x;
	ldhl	sp,	#3
	ld	a, (hl)
	ld	(bc), a
	inc	bc
	ldhl	sp,	#0
	ld	a, (hl)
	ld	(bc), a
;src/main.c:474: move_sprite(character->spriteids[1], x + spritesize, y);
	ld	a, (hl)
	ld	hl, #_spritesize
	add	a, (hl)
	ld	c, a
	ld	l, e
	ld	h, d
	inc	hl
	ld	b, (hl)
;/Users/apple/gbdk/include/gb/gb.h:1973: OAM_item_t * itm = &shadow_OAM[nb];
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
	ldhl	sp,	#5
	ld	a, (hl)
	pop	hl
	ld	(hl+), a
	ld	(hl), c
;src/main.c:475: move_sprite(character->spriteids[2], x, y + spritesize);
	ldhl	sp,	#3
	ld	a, (hl)
	ld	hl, #_spritesize
	add	a, (hl)
	ld	c, a
	ld	l, e
	ld	h, d
	inc	hl
	inc	hl
	ld	b, (hl)
;/Users/apple/gbdk/include/gb/gb.h:1973: OAM_item_t * itm = &shadow_OAM[nb];
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
	ld	a, c
	ld	(hl+), a
	ld	c, l
	ld	b, h
	ldhl	sp,	#0
	ld	a, (hl)
	ld	(bc), a
;src/main.c:476: move_sprite(character->spriteids[3], x + spritesize, y + spritesize);
	ldhl	sp,	#3
	ld	a, (hl)
	ld	hl, #_spritesize
	add	a, (hl)
	ld	b, a
	ldhl	sp,	#0
	ld	a, (hl)
	ld	hl, #_spritesize
	add	a, (hl)
	ld	c, a
	inc	de
	inc	de
	inc	de
	ld	a, (de)
;/Users/apple/gbdk/include/gb/gb.h:1973: OAM_item_t * itm = &shadow_OAM[nb];
	ld	l, a
	ld	h, #0x00
	add	hl, hl
	add	hl, hl
	ld	de, #_shadow_OAM
	add	hl, de
;/Users/apple/gbdk/include/gb/gb.h:1974: itm->y=y, itm->x=x;
	ld	(hl), b
	inc	hl
	ld	(hl), c
;src/main.c:476: move_sprite(character->spriteids[3], x + spritesize, y + spritesize);
;src/main.c:477: }
	inc	sp
	pop	hl
	inc	sp
	jp	(hl)
;src/main.c:482: static uint8_t is_walkable(uint8_t x, uint8_t y) {
;	---------------------------------
; Function is_walkable
; ---------------------------------
_is_walkable:
	ld	b, a
	ld	c, e
;src/main.c:483: return grid[x][y].type == TILE_GRASS;
	ld	e, b
	ld	d, #0x00
	ld	l, e
	ld	h, d
	add	hl, hl
	add	hl, de
	add	hl, hl
	add	hl, de
	add	hl, hl
	add	hl, de
	ld	de, #_grid
	add	hl, de
	ld	e, c
	ld	d, #0x00
	add	hl, de
	ld	a, (hl)
	dec	a
	ld	a, #0x01
	ret	Z
	xor	a, a
;src/main.c:484: }
	ret
;src/main.c:490: void main(void)
;	---------------------------------
; Function main
; ---------------------------------
_main::
	add	sp, #-12
;src/main.c:492: DISPLAY_OFF;
	call	_display_off
;/Users/apple/gbdk/include/gb/gb.h:811: __asm__("di");
	di
;src/main.c:494: gbt_play(song_Data, 2, 7);
	ld	a, #0x07
	push	af
	inc	sp
	ld	a, #0x02
	ld	de, #_song_Data
	call	_gbt_play
;src/main.c:495: gbt_loop(1);
	ld	a, #0x01
	call	_gbt_loop
;src/main.c:496: set_interrupts(VBL_IFLAG);
	ld	a, #0x01
	call	_set_interrupts
;/Users/apple/gbdk/include/gb/gb.h:795: __asm__("ei");
	ei
;src/main.c:503: run_titlescreen();
	call	_run_titlescreen
;src/main.c:504: fadeout();         /* fade to white before reloading VRAM for the game */
	call	_fadeout
;src/main.c:508: font_init();
	call	_font_init
;src/main.c:509: font_load(font_min);
	ld	de, #_font_min
	push	de
	call	_font_load
	pop	hl
;src/main.c:512: set_bkg_data(TILE_BASE, 31, Tileset);
	ld	de, #_Tileset
	push	de
	ld	hl, #0x1f25
	push	hl
	call	_set_bkg_data
	add	sp, #4
;src/main.c:515: set_bkg_data(UI_TILE_BASE, 8, UI_Tiles);
	ld	de, #_UI_Tiles
	push	de
	ld	hl, #0x844
	push	hl
	call	_set_bkg_data
	add	sp, #4
;src/main.c:518: set_sprite_data(PLAYER_TILE_BASE, 16, Player);
	ld	de, #_Player
	push	de
	ld	hl, #0x104c
	push	hl
	call	_set_sprite_data
	add	sp, #4
;src/main.c:520: setupPlayer(); // assign OAM slots 0-3 to VRAM tiles PLAYER_TILE_BASE..+3
	call	_setupPlayer
;src/main.c:525: uint8_t t = EMPTY_TILE;
	ldhl	sp,	#0
	ld	(hl), #0x25
;src/main.c:526: for (uint8_t y = 0; y < 18; y++)
	ld	c, #0x00
00178$:
	ld	a, c
	sub	a, #0x12
	jr	NC, 00102$
;src/main.c:527: for (uint8_t x = 0; x < 20; x++)
	ld	e, #0x00
00175$:
	ld	a, e
	sub	a, #0x14
	jr	NC, 00179$
;src/main.c:528: set_bkg_tiles(x, y, 1, 1, &t);
	push	de
	ld	hl, #2
	add	hl, sp
	push	hl
	ld	hl, #0x101
	push	hl
	ld	d, c
	push	de
	call	_set_bkg_tiles
	add	sp, #6
	pop	de
;src/main.c:527: for (uint8_t x = 0; x < 20; x++)
	inc	e
	jr	00175$
00179$:
;src/main.c:526: for (uint8_t y = 0; y < 18; y++)
	inc	c
	jr	00178$
00102$:
;src/main.c:531: init_grid(); // populate grid[][] with TILE_GRASS for each cell
	call	_init_grid
;src/main.c:532: draw_grid();
	call	_draw_grid
;src/main.c:534: fadein();
	call	_fadein
;/Users/apple/gbdk/include/gb/gb.h:1475: SCX_REG+=x, SCY_REG+=y;
;src/main.c:537: SHOW_BKG;
	ldh	a, (_LCDC_REG + 0)
	or	a, #0x01
	ldh	(_LCDC_REG + 0), a
;src/main.c:538: SHOW_SPRITES;
	ldh	a, (_LCDC_REG + 0)
	or	a, #0x02
	ldh	(_LCDC_REG + 0), a
;src/main.c:542: init_overlay(); // set up cursor sprite (OAM slot 4, OBP1)
	call	_init_overlay
;src/main.c:543: draw_cursor();  // draw initial highlight at (0,0)
	call	_draw_cursor
;src/main.c:547: pointer_init(&ui_ptr, POINTER_TILE_BASE, POINTER_OAM_BASE);
	ld	a, #0x05
	push	af
	inc	sp
	ld	a, #0x5f
	ld	de, #_ui_ptr
	call	_pointer_init
;/Users/apple/gbdk/include/gb/gb.h:1739: WX_REG=x, WY_REG=y;
	ld	a, #0x07
	ldh	(_WX_REG + 0), a
	xor	a, a
	ldh	(_WY_REG + 0), a
;src/main.c:553: DISPLAY_ON;
	ldh	a, (_LCDC_REG + 0)
	or	a, #0x80
	ldh	(_LCDC_REG + 0), a
;src/main.c:555: while (1)
00163$:
;src/main.c:557: wait_vbl_done();
	call	_wait_vbl_done
;src/main.c:560: if (ui_anim == UI_ANIM_SHOWING) {
	ld	a, (#_ui_anim)
	dec	a
	jr	NZ, 00110$
;src/main.c:561: win_write_row(ui_anim_row++);
	ld	a, (_ui_anim_row)
	ld	c, a
	ld	hl, #_ui_anim_row
	inc	(hl)
	ld	a, c
	call	_win_write_row
;src/main.c:562: if (ui_anim_row >= UIHeight) {
	ld	a, (#_ui_anim_row)
	sub	a, #0x12
	jr	C, 00111$
;src/main.c:564: ui_write_text();
	call	_ui_write_text
;src/main.c:565: ui_visible  = 1u;
	ld	hl, #_ui_visible
	ld	(hl), #0x01
;src/main.c:566: ui_menu_idx = 0u;
	xor	a, a
	ld	(#_ui_menu_idx),a
;src/main.c:567: pointer_move(&ui_ptr, UI_MENU_X, UI_MENU_Y[0u]);
	ld	a, (#_UI_MENU_Y + 0)
	push	af
	inc	sp
	ld	a, #0x08
	ld	de, #_ui_ptr
	call	_pointer_move
;src/main.c:568: ui_anim = UI_ANIM_IDLE;
	xor	a, a
	ld	(#_ui_anim),a
	jr	00111$
00110$:
;src/main.c:570: } else if (ui_anim == UI_ANIM_HIDING) {
	ld	a, (#_ui_anim)
	sub	a, #0x02
	jr	NZ, 00111$
;src/main.c:571: win_clear_row(--ui_anim_row);
	ld	hl, #_ui_anim_row
	dec	(hl)
	ld	a, (hl)
	call	_win_clear_row
;src/main.c:572: if (ui_anim_row == 0u) {
	ld	a, (#_ui_anim_row)
	or	a, a
	jr	NZ, 00111$
;src/main.c:573: HIDE_WIN;
	ldh	a, (_LCDC_REG + 0)
	and	a, #0xdf
	ldh	(_LCDC_REG + 0), a
;src/main.c:577: player_grid_y * 8 + 16);
	ld	a, (_player_grid_y)
	add	a, a
	add	a, a
	add	a, a
	add	a, #0x10
	ld	b, a
;src/main.c:576: player_grid_x * 8 + 8,
	ld	a, (_player_grid_x)
	add	a, a
	add	a, a
	add	a, a
	add	a, #0x08
	ld	c, a
;src/main.c:575: movegamecharacter(&player,
	push	bc
	inc	sp
	ld	a, c
	ld	de, #_player
	call	_movegamecharacter
;src/main.c:578: draw_cursor();
	call	_draw_cursor
;src/main.c:579: ui_anim = UI_ANIM_IDLE;
	xor	a, a
	ld	(#_ui_anim),a
00111$:
;src/main.c:584: uint8_t keys = joypad();
	call	_joypad
	ldhl	sp,	#9
	ld	(hl), a
;src/main.c:587: if ((keys & J_SELECT) && !(prev_keys & J_SELECT) &&
	push	hl
	ldhl	sp,	#11
	bit	6, (hl)
	pop	hl
	jr	Z, 00116$
	ld	a, (_prev_keys)
	bit	6, a
	jr	NZ, 00116$
;src/main.c:588: ui_anim == UI_ANIM_IDLE)
	ld	a, (#_ui_anim)
	or	a, a
	jr	NZ, 00116$
;src/main.c:590: if (!ui_visible) {
	ld	a, (#_ui_visible)
	or	a, a
	jr	NZ, 00113$
;/Users/apple/gbdk/include/gb/gb.h:1973: OAM_item_t * itm = &shadow_OAM[nb];
	ld	hl, #_shadow_OAM
;/Users/apple/gbdk/include/gb/gb.h:1974: itm->y=y, itm->x=x;
	xor	a, a
	ld	(hl+), a
	ld	(hl), a
;/Users/apple/gbdk/include/gb/gb.h:1973: OAM_item_t * itm = &shadow_OAM[nb];
	ld	hl, #(_shadow_OAM + 4)
;/Users/apple/gbdk/include/gb/gb.h:1974: itm->y=y, itm->x=x;
	xor	a, a
	ld	(hl+), a
	ld	(hl), a
;/Users/apple/gbdk/include/gb/gb.h:1973: OAM_item_t * itm = &shadow_OAM[nb];
	ld	hl, #(_shadow_OAM + 8)
;/Users/apple/gbdk/include/gb/gb.h:1974: itm->y=y, itm->x=x;
	xor	a, a
	ld	(hl+), a
	ld	(hl), a
;/Users/apple/gbdk/include/gb/gb.h:1973: OAM_item_t * itm = &shadow_OAM[nb];
	ld	hl, #(_shadow_OAM + 12)
;/Users/apple/gbdk/include/gb/gb.h:1974: itm->y=y, itm->x=x;
	xor	a, a
	ld	(hl+), a
	ld	(hl), a
;/Users/apple/gbdk/include/gb/gb.h:1973: OAM_item_t * itm = &shadow_OAM[nb];
	ld	hl, #(_shadow_OAM + 16)
;/Users/apple/gbdk/include/gb/gb.h:1974: itm->y=y, itm->x=x;
	xor	a, a
	ld	(hl+), a
	ld	(hl), a
;src/main.c:598: SHOW_WIN;
	ldh	a, (_LCDC_REG + 0)
	or	a, #0x20
	ldh	(_LCDC_REG + 0), a
;src/main.c:599: ui_anim     = UI_ANIM_SHOWING;
	ld	hl, #_ui_anim
	ld	(hl), #0x01
;src/main.c:600: ui_anim_row = 0u;
	xor	a, a
	ld	(#_ui_anim_row),a
	jr	00116$
00113$:
;src/main.c:603: pointer_hide(&ui_ptr);
	ld	de, #_ui_ptr
	call	_pointer_hide
;src/main.c:604: ui_visible  = 0u;
	xor	a, a
	ld	(#_ui_visible),a
;src/main.c:605: ui_anim     = UI_ANIM_HIDING;
	ld	hl, #_ui_anim
	ld	(hl), #0x02
;src/main.c:606: ui_anim_row = UIHeight;
	ld	hl, #_ui_anim_row
	ld	(hl), #0x12
00116$:
;src/main.c:587: if ((keys & J_SELECT) && !(prev_keys & J_SELECT) &&
	ld	a, (_prev_keys)
	ld	c, a
;src/main.c:629: if ((keys & J_A) && !(prev_keys & J_A))
	ldhl	sp,	#9
	ld	a, (hl+)
	and	a, #0x10
	ld	(hl+), a
	ld	(hl), #0x00
;src/main.c:610: if (ui_visible)
	ld	hl, #_ui_visible
	ld	a, (hl)
	or	a, a
	jr	Z, 00143$
;src/main.c:547: pointer_init(&ui_ptr, POINTER_TILE_BASE, POINTER_OAM_BASE);
;src/main.c:613: if ((keys & J_UP) && !(prev_keys & J_UP))
	push	hl
	ldhl	sp,	#11
	bit	2, (hl)
	pop	hl
	jr	Z, 00122$
	bit	2, c
	jr	NZ, 00122$
;src/main.c:615: if (ui_menu_idx > 0)
	ld	hl, #_ui_menu_idx
	ld	a, (hl)
	or	a, a
	jr	Z, 00122$
;src/main.c:617: ui_menu_idx--;
	dec	(hl)
;src/main.c:618: pointer_move(&ui_ptr, UI_MENU_X, UI_MENU_Y[ui_menu_idx]);
	ld	a, #<(_UI_MENU_Y)
	add	a, (hl)
	ld	c, a
	ld	a, #>(_UI_MENU_Y)
	adc	a, #0x00
	ld	b, a
	ld	a, (bc)
	push	af
	inc	sp
	ld	a, #0x08
	ld	de, #_ui_ptr
	call	_pointer_move
00122$:
;src/main.c:621: if ((keys & J_DOWN) && !(prev_keys & J_DOWN))
	push	hl
	ldhl	sp,	#11
	bit	3, (hl)
	pop	hl
	jr	Z, 00127$
	ld	a, (_prev_keys)
	bit	3, a
	jr	NZ, 00127$
;src/main.c:623: if (ui_menu_idx < UI_MENU_COUNT - 1)
	ld	hl, #_ui_menu_idx
	ld	a, (hl)
	sub	a, #0x02
	jr	NC, 00127$
;src/main.c:625: ui_menu_idx++;
	inc	(hl)
;src/main.c:626: pointer_move(&ui_ptr, UI_MENU_X, UI_MENU_Y[ui_menu_idx]);
	ld	a, #<(_UI_MENU_Y)
	add	a, (hl)
	ld	c, a
	ld	a, #>(_UI_MENU_Y)
	adc	a, #0x00
	ld	b, a
	ld	a, (bc)
	push	af
	inc	sp
	ld	a, #0x08
	ld	de, #_ui_ptr
	call	_pointer_move
00127$:
;src/main.c:629: if ((keys & J_A) && !(prev_keys & J_A))
	xor	a, a
	ldhl	sp,	#10
	or	a, (hl)
	jr	Z, 00144$
	ld	a, (_prev_keys)
	bit	4, a
	jr	NZ, 00144$
;src/main.c:631: pointer_anim_select(&ui_ptr);
	ld	de, #_ui_ptr
	call	_pointer_anim_select
	jr	00144$
00143$:
;src/main.c:639: if ((keys & J_A) && !(prev_keys & J_A))
	xor	a, a
	ldhl	sp,	#10
	or	a, (hl)
	jr	Z, 00138$
	bit	4, c
	jr	NZ, 00138$
;src/main.c:642: if (move_path_len > 0u) clear_path_tiles();
	ld	a, (#_move_path_len)
	or	a, a
	jr	Z, 00133$
	call	_clear_path_tiles
00133$:
;src/main.c:644: uint8_t steps = astar_find(player_grid_x, player_grid_y,
	ld	de, #_move_path
	push	de
	ld	de, #_is_walkable
	push	de
	ld	a, (_cursor_y)
	ld	h, a
	ld	a, (_cursor_x)
	ld	l, a
	push	hl
	ld	a, (_player_grid_y)
	ld	e, a
	ld	a, (_player_grid_x)
	call	_astar_find
;src/main.c:647: if (steps > 1u)
	cp	a, #0x02
	jr	C, 00135$
;src/main.c:649: move_path_len  = steps;
	ld	(#_move_path_len),a
;src/main.c:650: move_path_step = 1u;
	ld	hl, #_move_path_step
	ld	(hl), #0x01
;src/main.c:651: move_timer     = 0u;
	xor	a, a
	ld	(#_move_timer),a
;src/main.c:652: draw_path_tiles();   // highlight the full route on BKG
	call	_draw_path_tiles
	jr	00138$
00135$:
;src/main.c:656: move_path_len = 0u;  // no path — nothing to highlight
	xor	a, a
	ld	(#_move_path_len),a
00138$:
;src/main.c:660: if (handle_input())
	call	_handle_input
	or	a, a
	jr	Z, 00144$
;src/main.c:662: clear_overlay();
	call	_clear_overlay
;src/main.c:663: draw_cursor();
	call	_draw_cursor
00144$:
;src/main.c:667: prev_keys = keys;
	ldhl	sp,	#9
	ld	a, (hl)
	ld	(#_prev_keys),a
;src/main.c:670: if (move_path_step < move_path_len)
	ld	a, (#_move_path_step)
	ld	hl, #_move_path_len
	sub	a, (hl)
	jp	NC, 00161$
;src/main.c:672: if (++move_timer >= MOVE_DELAY)
	ld	hl, #_move_timer
	inc	(hl)
	ld	a, (hl)
	sub	a, #0x0c
	jp	C, 00161$
;src/main.c:674: move_timer = 0;
	ld	(hl), #0x00
;src/main.c:675: uint8_t s = move_path_step;
	ld	a, (#_move_path_step)
	ldhl	sp,	#1
	ld	(hl), a
;src/main.c:680: if      (move_path[s].x > move_path[s - 1u].x) step_dir = DIR_RIGHT;
	ld	c, (hl)
	xor	a, a
	ld	b, a
	sla	c
	rl	b
	ld	hl, #_move_path
	add	hl, bc
	push	hl
	ld	a, l
	ldhl	sp,	#12
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#11
	ld	(hl-), a
	ld	a, (hl)
	ldhl	sp,	#2
	ld	(hl), a
	ldhl	sp,	#11
	ld	a, (hl)
	ldhl	sp,	#3
	ld	(hl-), a
	ld	a, (hl+)
	ld	e, a
	ld	a, (hl+)
	ld	d, a
	ld	a, (de)
	ld	(hl), a
	ldhl	sp,	#1
	ld	c, (hl)
	dec	c
	ld	b, #0x00
	sla	c
	rl	b
	ld	hl, #_move_path
	add	hl, bc
	ld	c, l
	ld	b, h
	ldhl	sp,	#5
	ld	a, c
	ld	(hl+), a
	ld	a, b
	ld	(hl-), a
	ld	a, (hl+)
	ld	e, a
	ld	a, (hl+)
	ld	d, a
	ld	a, (de)
	ld	(hl), a
;src/main.c:682: else if (move_path[s].y > move_path[s - 1u].y) step_dir = DIR_DOWN;
	ldhl	sp,#10
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	l, e
	ld	h, d
	inc	hl
	push	hl
	ld	a, l
	ldhl	sp,	#10
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#9
	ld	(hl+), a
	inc	bc
	ld	a, c
	ld	(hl+), a
	ld	(hl), b
;src/main.c:680: if      (move_path[s].x > move_path[s - 1u].x) step_dir = DIR_RIGHT;
	ldhl	sp,	#7
	ld	a, (hl)
	ldhl	sp,	#4
	sub	a, (hl)
	jr	NC, 00152$
	ld	c, #0x02
	jr	00153$
00152$:
;src/main.c:681: else if (move_path[s].x < move_path[s - 1u].x) step_dir = DIR_LEFT;
	ldhl	sp,	#4
	ld	a, (hl)
	ldhl	sp,	#7
	sub	a, (hl)
	jr	NC, 00149$
	ld	c, #0x01
	jr	00153$
00149$:
;src/main.c:682: else if (move_path[s].y > move_path[s - 1u].y) step_dir = DIR_DOWN;
	ldhl	sp,#8
	ld	a, (hl+)
	ld	e, a
	ld	a, (hl+)
	ld	d, a
	ld	a, (de)
	ld	c, a
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, (de)
	sub	a, c
	jr	NC, 00146$
	ld	c, #0x00
	jr	00153$
00146$:
;src/main.c:683: else                                            step_dir = DIR_UP;
	ld	c, #0x03
00153$:
;src/main.c:684: player_anim_set_dir(&player_anim, step_dir);
	ld	a, c
	ld	de, #_player_anim
	call	_player_anim_set_dir
;src/main.c:685: player_anim_set_state(&player_anim, ANIM_WALK);
	ld	a, #0x01
	ld	de, #_player_anim
	call	_player_anim_set_state
;src/main.c:686: player_anim_apply(&player_anim);
	ld	de, #_player_anim
	call	_player_anim_apply
;src/main.c:689: player_grid_x = move_path[s].x;
	ldhl	sp,#2
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, (de)
	ld	(#_player_grid_x),a
;src/main.c:690: player_grid_y = move_path[s].y;
	ldhl	sp,#8
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, (de)
	ld	hl, #_player_grid_y
	ld	(hl), a
;src/main.c:693: player_grid_y * 8 + 16);
	ld	a, (hl)
	add	a, a
	add	a, a
	add	a, a
	add	a, #0x10
	ld	b, a
;src/main.c:692: player_grid_x * 8 + 8,
	ld	a, (_player_grid_x)
	add	a, a
	add	a, a
	add	a, a
	add	a, #0x08
	ldhl	sp,	#7
	ld	(hl), a
;src/main.c:691: movegamecharacter(&player,
	push	bc
	inc	sp
	ld	a, (hl)
	ld	de, #_player
	call	_movegamecharacter
;src/main.c:696: if (s >= 2u) restore_bkg_tile(move_path[s - 1u].x,
	ldhl	sp,	#1
	ld	a, (hl)
	sub	a, #0x02
	jr	C, 00155$
;src/main.c:697: move_path[s - 1u].y);
	ldhl	sp,#10
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, (de)
	ld	(hl), a
;src/main.c:696: if (s >= 2u) restore_bkg_tile(move_path[s - 1u].x,
	ldhl	sp,#5
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, (de)
	ldhl	sp,	#11
	ld	e, (hl)
	call	_restore_bkg_tile
00155$:
;src/main.c:699: move_path_step++;
	ld	hl, #_move_path_step
	inc	(hl)
;src/main.c:702: if (move_path_step >= move_path_len) {
	ld	a, (hl)
	ld	hl, #_move_path_len
	sub	a, (hl)
	jr	C, 00161$
;src/main.c:703: restore_bkg_tile(move_path[s].x, move_path[s].y);
	ldhl	sp,#8
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, (de)
	ld	c, a
	ldhl	sp,#2
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ld	a, (de)
	ld	e, c
	call	_restore_bkg_tile
;src/main.c:704: player_anim_set_state(&player_anim, ANIM_IDLE);
	xor	a, a
	ld	de, #_player_anim
	call	_player_anim_set_state
;src/main.c:705: player_anim_apply(&player_anim);
	ld	de, #_player_anim
	call	_player_anim_apply
00161$:
;src/main.c:711: player_anim_tick(&player_anim);
	ld	de, #_player_anim
	call	_player_anim_tick
;src/main.c:713: gbt_update();
	call	_gbt_update
	jp	00163$
;src/main.c:715: }
	add	sp, #12
	ret
	.area _CODE
	.area _INITIALIZER
__xinit__Player:
	.db #0x07	; 7
	.db #0x07	; 7
	.db #0x0f	; 15
	.db #0x0f	; 15
	.db #0x0f	; 15
	.db #0x09	; 9
	.db #0x1f	; 31
	.db #0x19	; 25
	.db #0x1f	; 31
	.db #0x19	; 25
	.db #0x18	; 24
	.db #0x1f	; 31
	.db #0x0f	; 15
	.db #0x0e	; 14
	.db #0x7f	; 127
	.db #0x7a	; 122	'z'
	.db #0x87	; 135
	.db #0xfc	; 252
	.db #0x6b	; 107	'k'
	.db #0x7f	; 127
	.db #0xf0	; 240
	.db #0x9f	; 159
	.db #0xfc	; 252
	.db #0x9f	; 159
	.db #0x6b	; 107	'k'
	.db #0x6f	; 111	'o'
	.db #0x08	; 8
	.db #0x0f	; 15
	.db #0x04	; 4
	.db #0x07	; 7
	.db #0x0f	; 15
	.db #0x0f	; 15
	.db #0xe0	; 224
	.db #0xe0	; 224
	.db #0xf8	; 248
	.db #0xf8	; 248
	.db #0xfc	; 252
	.db #0xfc	; 252
	.db #0xf8	; 248
	.db #0xf8	; 248
	.db #0xfc	; 252
	.db #0xbc	; 188
	.db #0x98	; 152
	.db #0xf8	; 248
	.db #0xf0	; 240
	.db #0x70	; 112	'p'
	.db #0xf0	; 240
	.db #0x50	; 80	'P'
	.db #0xff	; 255
	.db #0x3f	; 63
	.db #0xf9	; 249
	.db #0xe7	; 231
	.db #0xbd	; 189
	.db #0xef	; 239
	.db #0x3d	; 61
	.db #0xef	; 239
	.db #0xfd	; 253
	.db #0xef	; 239
	.db #0x9a	; 154
	.db #0xf6	; 246
	.db #0xec	; 236
	.db #0xec	; 236
	.db #0xf0	; 240
	.db #0xf0	; 240
	.db #0x07	; 7
	.db #0x07	; 7
	.db #0x1f	; 31
	.db #0x1f	; 31
	.db #0x1f	; 31
	.db #0x1b	; 27
	.db #0x1b	; 27
	.db #0x1f	; 31
	.db #0x1f	; 31
	.db #0x19	; 25
	.db #0x6f	; 111	'o'
	.db #0x69	; 105	'i'
	.db #0xef	; 239
	.db #0xae	; 174
	.db #0xef	; 239
	.db #0xaa	; 170
	.db #0xff	; 255
	.db #0xb8	; 184
	.db #0xef	; 239
	.db #0xaf	; 175
	.db #0xec	; 236
	.db #0xaf	; 175
	.db #0xf9	; 249
	.db #0xbf	; 191
	.db #0xef	; 239
	.db #0xaf	; 175
	.db #0xe2	; 226
	.db #0xa3	; 163
	.db #0x64	; 100	'd'
	.db #0x67	; 103	'g'
	.db #0x07	; 7
	.db #0x07	; 7
	.db #0xe0	; 224
	.db #0xe0	; 224
	.db #0xf8	; 248
	.db #0xf8	; 248
	.db #0xfc	; 252
	.db #0xfc	; 252
	.db #0xf8	; 248
	.db #0x78	; 120	'x'
	.db #0xfe	; 254
	.db #0xbe	; 190
	.db #0xfc	; 252
	.db #0xfc	; 252
	.db #0xf8	; 248
	.db #0xb8	; 184
	.db #0xf0	; 240
	.db #0x30	; 48	'0'
	.db #0xf8	; 248
	.db #0xf8	; 248
	.db #0x7c	; 124
	.db #0xc4	; 196
	.db #0xf8	; 248
	.db #0x98	; 152
	.db #0xf8	; 248
	.db #0x18	; 24
	.db #0xe8	; 232
	.db #0x38	; 56	'8'
	.db #0xf0	; 240
	.db #0xf0	; 240
	.db #0x20	; 32
	.db #0xe0	; 224
	.db #0xe0	; 224
	.db #0xe0	; 224
	.db #0x07	; 7
	.db #0x07	; 7
	.db #0x1f	; 31
	.db #0x1f	; 31
	.db #0x3f	; 63
	.db #0x3f	; 63
	.db #0x1f	; 31
	.db #0x1f	; 31
	.db #0x3f	; 63
	.db #0x3f	; 63
	.db #0x1f	; 31
	.db #0x1f	; 31
	.db #0x0f	; 15
	.db #0x0f	; 15
	.db #0x7f	; 127
	.db #0x7b	; 123
	.db #0x87	; 135
	.db #0xfc	; 252
	.db #0xeb	; 235
	.db #0xff	; 255
	.db #0xf8	; 248
	.db #0xdf	; 223
	.db #0xfc	; 252
	.db #0xdf	; 223
	.db #0xfb	; 251
	.db #0xaf	; 175
	.db #0x78	; 120	'x'
	.db #0x4f	; 79	'O'
	.db #0x3c	; 60
	.db #0x3f	; 63
	.db #0x0f	; 15
	.db #0x0f	; 15
	.db #0xe0	; 224
	.db #0xe0	; 224
	.db #0xf0	; 240
	.db #0xb0	; 176
	.db #0xf0	; 240
	.db #0xd0	; 208
	.db #0xf8	; 248
	.db #0xf8	; 248
	.db #0xf8	; 248
	.db #0xf8	; 248
	.db #0xf0	; 240
	.db #0xf0	; 240
	.db #0xf0	; 240
	.db #0xf0	; 240
	.db #0xfe	; 254
	.db #0xde	; 222
	.db #0xe1	; 225
	.db #0x3f	; 63
	.db #0xd6	; 214
	.db #0xfe	; 254
	.db #0x1e	; 30
	.db #0xfa	; 250
	.db #0x3e	; 62
	.db #0xf2	; 242
	.db #0xdc	; 220
	.db #0xf4	; 244
	.db #0x98	; 152
	.db #0xf8	; 248
	.db #0xe0	; 224
	.db #0xe0	; 224
	.db #0xf0	; 240
	.db #0xf0	; 240
	.db #0x07	; 7
	.db #0x07	; 7
	.db #0x1f	; 31
	.db #0x1f	; 31
	.db #0x3f	; 63
	.db #0x3f	; 63
	.db #0x1f	; 31
	.db #0x1e	; 30
	.db #0x7f	; 127
	.db #0x7d	; 125
	.db #0x3f	; 63
	.db #0x3f	; 63
	.db #0x1f	; 31
	.db #0x1d	; 29
	.db #0x0f	; 15
	.db #0x0c	; 12
	.db #0x1f	; 31
	.db #0x1f	; 31
	.db #0x23	; 35
	.db #0x3e	; 62
	.db #0x1f	; 31
	.db #0x19	; 25
	.db #0x1f	; 31
	.db #0x18	; 24
	.db #0x17	; 23
	.db #0x1c	; 28
	.db #0x0f	; 15
	.db #0x0f	; 15
	.db #0x04	; 4
	.db #0x07	; 7
	.db #0x07	; 7
	.db #0x07	; 7
	.db #0xe0	; 224
	.db #0xe0	; 224
	.db #0xf8	; 248
	.db #0xf8	; 248
	.db #0xf8	; 248
	.db #0xd8	; 216
	.db #0xd8	; 216
	.db #0xf8	; 248
	.db #0xf8	; 248
	.db #0x98	; 152
	.db #0xf6	; 246
	.db #0x96	; 150
	.db #0xf5	; 245
	.db #0x77	; 119	'w'
	.db #0xf5	; 245
	.db #0x57	; 87	'W'
	.db #0xfd	; 253
	.db #0x1f	; 31
	.db #0xfd	; 253
	.db #0xf7	; 247
	.db #0x3d	; 61
	.db #0xf7	; 247
	.db #0x9d	; 157
	.db #0xff	; 255
	.db #0xf5	; 245
	.db #0xf7	; 247
	.db #0x45	; 69	'E'
	.db #0xc7	; 199
	.db #0x26	; 38
	.db #0xe6	; 230
	.db #0xe0	; 224
	.db #0xe0	; 224
__xinit__spritesize:
	.db #0x08	; 8
__xinit__cursor_x:
	.db #0x00	; 0
__xinit__cursor_y:
	.db #0x00	; 0
__xinit__input_timer:
	.db #0x00	; 0
__xinit__prev_keys:
	.db #0x00	; 0
__xinit__ui_visible:
	.db #0x00	; 0
__xinit__ui_menu_idx:
	.db #0x00	; 0
__xinit__ui_anim:
	.db #0x00	; 0
__xinit__ui_anim_row:
	.db #0x00	; 0
__xinit__move_path_len:
	.db #0x00	; 0
__xinit__move_path_step:
	.db #0x00	; 0
__xinit__move_timer:
	.db #0x00	; 0
__xinit__player_grid_x:
	.db #0x0c	; 12
__xinit__player_grid_y:
	.db #0x00	; 0
	.area _CABS (ABS)

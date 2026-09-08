;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.5.1 #15267 (Mac OS X ppc)
;--------------------------------------------------------
	.module astar
	
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _memset
	.globl _astar_find
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
	.area _HRAM
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	.area _DATA
_node_g:
	.ds 240
_node_flags:
	.ds 240
_node_par_x:
	.ds 240
_node_par_y:
	.ds 240
_heap:
	.ds 675
_heap_size:
	.ds 1
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
;src/pathfinding/astar.c:32: static void heap_push(uint8_t f, uint8_t x, uint8_t y) {
;	---------------------------------
; Function heap_push
; ---------------------------------
_heap_push:
	add	sp, #-6
	ld	b, a
	ld	c, e
;src/pathfinding/astar.c:33: uint8_t i = heap_size++;
	ld	a, (#_heap_size)
	ldhl	sp,	#5
	ld	(hl), a
	ld	hl, #_heap_size
	inc	(hl)
;src/pathfinding/astar.c:34: heap[i].f = f;
	ldhl	sp,	#5
	ld	e, (hl)
	ld	d, #0x00
	ld	l, e
	ld	h, d
	add	hl, hl
	add	hl, de
	ld	de, #_heap
	add	hl, de
	ld	(hl), b
;src/pathfinding/astar.c:35: heap[i].x = x;
	ld	e, l
	ld	d, h
;src/pathfinding/astar.c:36: heap[i].y = y;
	inc	hl
	inc	hl
	inc	de
	ld	a, c
	ld	(de), a
	ld	c, l
	ld	b, h
	ldhl	sp,	#8
	ld	a, (hl)
	ld	(bc), a
;src/pathfinding/astar.c:38: while (i > 0) {
00103$:
	ldhl	sp,	#5
	ld	a, (hl)
	or	a, a
	jr	Z, 00106$
;src/pathfinding/astar.c:39: uint8_t p = (i - 1u) >> 1;
	ld	a, (hl-)
	dec	hl
	ld	c, a
	ld	b, #0x00
	dec	bc
	srl	b
	rr	c
;src/pathfinding/astar.c:40: if (heap[p].f <= heap[i].f) break;
	ld	(hl),c
	ld	b, #0x00
	ld	l, c
	ld	h, b
	add	hl, hl
	add	hl, bc
	ld	a, l
	add	a, #<(_heap)
	ld	c, a
	ld	a, h
	adc	a, #>(_heap)
	ld	b, a
	ld	a, (bc)
	ldhl	sp,	#4
	ld	(hl+), a
	ld	e, (hl)
	ld	d, #0x00
	ld	l, e
	ld	h, d
	add	hl, hl
	add	hl, de
	ld	a, l
	add	a, #<(_heap)
	ld	e, a
	ld	a, h
	adc	a, #>(_heap)
	ld	d, a
	ld	a, (de)
	ldhl	sp,	#5
	ld	(hl), a
	ld	a, (hl-)
	sub	a, (hl)
	jr	NC, 00106$
;src/pathfinding/astar.c:41: HeapEntry tmp = heap[p]; heap[p] = heap[i]; heap[i] = tmp;
	ld	l, c
	ld	h, b
	push	hl
	push	de
	ld	bc, #0x0003
	push	bc
	ld	c, l
	ld	b, h
	push	hl
	ld	hl, #8
	add	hl, sp
	ld	e, l
	ld	d, h
	pop	hl
	call	___memcpy
	pop	de
	pop	hl
	push	de
	ld	bc, #0x0003
	push	bc
	ld	c, e
	ld	b, d
	ld	e, l
	ld	d, h
	call	___memcpy
	pop	de
	ld	bc, #0x0003
	push	bc
	ld	hl, #2
	add	hl, sp
	ld	c, l
	ld	b, h
	call	___memcpy
;src/pathfinding/astar.c:42: i = p;
	ldhl	sp,	#3
	ld	a, (hl+)
	inc	hl
	ld	(hl), a
	jr	00103$
00106$:
;src/pathfinding/astar.c:44: }
	add	sp, #6
	pop	hl
	inc	sp
	jp	(hl)
;src/pathfinding/astar.c:47: static void heap_pop(uint8_t *ox, uint8_t *oy) {
;	---------------------------------
; Function heap_pop
; ---------------------------------
_heap_pop:
	add	sp, #-10
;src/pathfinding/astar.c:48: *ox = heap[0].x;
	ld	a, (#_heap + 1)
	ld	(de), a
;src/pathfinding/astar.c:49: *oy = heap[0].y;
	ld	a, (#(_heap + 2) + 0)
	ld	(bc), a
;src/pathfinding/astar.c:50: heap[0] = heap[--heap_size];
	ld	hl, #_heap_size
	dec	(hl)
	ld	c, (hl)
	ld	b, #0x00
	ld	l, c
	ld	h, b
	add	hl, hl
	add	hl, bc
	ld	bc, #_heap
	add	hl, bc
	ld	c, l
	ld	b, h
	ld	de, #0x0003
	push	de
	ld	de, #_heap
	call	___memcpy
;src/pathfinding/astar.c:52: uint8_t i = 0;
	ld	c, #0x00
;src/pathfinding/astar.c:53: while (1) {
00110$:
;src/pathfinding/astar.c:54: uint8_t l = (i << 1) + 1u;
	ld	a, c
	add	a, a
;src/pathfinding/astar.c:55: uint8_t r = l + 1u;
	inc	a
	ld	b, a
	inc	a
	ldhl	sp,	#8
	ld	(hl), a
;src/pathfinding/astar.c:56: uint8_t s = i;
	ldhl	sp,	#3
	ld	(hl), c
;src/pathfinding/astar.c:57: if (l < heap_size && heap[l].f < heap[s].f) s = l;
	ld	e, c
	ld	d, #0x00
	ld	l, e
	ld	h, d
	add	hl, hl
	add	hl, de
	push	hl
	ld	a, l
	ldhl	sp,	#6
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#5
	ld	(hl), a
	ld	a, b
	ld	hl, #_heap_size
	sub	a, (hl)
	jr	NC, 00102$
	ld	e, b
	ld	d, #0x00
	ld	l, e
	ld	h, d
	add	hl, hl
	add	hl, de
	ld	de, #_heap
	add	hl, de
	ld	a, (hl)
	ldhl	sp,	#9
	ld	(hl), a
	ld	de, #_heap
	ldhl	sp,	#4
	ld	a,	(hl+)
	ld	h, (hl)
	ld	l, a
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, (de)
	ld	e, a
	ldhl	sp,	#9
	ld	a, (hl)
	sub	a, e
	jr	NC, 00102$
	ldhl	sp,	#3
	ld	(hl), b
00102$:
;src/pathfinding/astar.c:58: if (r < heap_size && heap[r].f < heap[s].f) s = r;
	ldhl	sp,	#8
	ld	a, (hl)
	ld	hl, #_heap_size
	sub	a, (hl)
	jr	NC, 00105$
	ldhl	sp,	#8
	ld	e, (hl)
	ld	d, #0x00
	ld	l, e
	ld	h, d
	add	hl, hl
	add	hl, de
	ld	de, #_heap
	add	hl, de
	ld	b, (hl)
	ldhl	sp,	#3
	ld	e, (hl)
	ld	d, #0x00
	ld	l, e
	ld	h, d
	add	hl, hl
	add	hl, de
	ld	de, #_heap
	add	hl, de
	ld	e, (hl)
	ld	a, b
	sub	a, e
	jr	NC, 00105$
	ldhl	sp,	#8
	ld	a, (hl)
	ldhl	sp,	#3
	ld	(hl), a
00105$:
;src/pathfinding/astar.c:59: if (s == i) break;
	ldhl	sp,	#3
	ld	a, (hl)
	sub	a, c
	jr	Z, 00112$
;src/pathfinding/astar.c:60: HeapEntry tmp = heap[s]; heap[s] = heap[i]; heap[i] = tmp;
	ldhl	sp,	#3
	ld	c, (hl)
	ld	b, #0x00
	ld	l, c
	ld	h, b
	add	hl, hl
	add	hl, bc
	push	hl
	ld	a, l
	ldhl	sp,	#8
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#7
	ld	(hl), a
	ld	de, #_heap
	ld	a, (hl-)
	ld	l, (hl)
	ld	h, a
	add	hl, de
	push	hl
	ld	a, l
	ldhl	sp,	#10
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#9
	ld	(hl-), a
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	push	de
	ld	bc, #0x0003
	push	bc
	ld	c, e
	ld	b, d
	ld	hl, #4
	add	hl, sp
	ld	e, l
	ld	d, h
	call	___memcpy
	ld	de, #_heap
	ldhl	sp,	#6
	ld	a,	(hl+)
	ld	h, (hl)
	ld	l, a
	add	hl, de
	pop	de
	push	hl
	ld	bc, #0x0003
	push	bc
	ld	c, l
	ld	b, h
	call	___memcpy
	pop	hl
	ld	de, #0x0003
	push	de
	push	hl
	ld	hl, #4
	add	hl, sp
	ld	c, l
	ld	b, h
	pop	de
	call	___memcpy
;src/pathfinding/astar.c:61: i = s;
	ldhl	sp,	#3
	ld	c, (hl)
	jp	00110$
00112$:
;src/pathfinding/astar.c:63: }
	add	sp, #10
	ret
;src/pathfinding/astar.c:66: static uint8_t manhattan(uint8_t ax, uint8_t ay, uint8_t bx, uint8_t by) {
;	---------------------------------
; Function manhattan
; ---------------------------------
_manhattan:
	ld	c, a
;src/pathfinding/astar.c:67: uint8_t dx = (ax > bx) ? (ax - bx) : (bx - ax);
	ldhl	sp,	#2
	ld	a, (hl)
	sub	a, c
	jr	NC, 00103$
	ld	a, c
	sub	a, (hl)
	jr	00104$
00103$:
	ldhl	sp,	#2
	ld	a, (hl)
	sub	a, c
00104$:
	ld	c, a
;src/pathfinding/astar.c:68: uint8_t dy = (ay > by) ? (ay - by) : (by - ay);
	ldhl	sp,	#3
	ld	a, (hl)
	sub	a, e
	jr	NC, 00105$
	ld	a, e
	sub	a, (hl)
	jr	00106$
00105$:
	ldhl	sp,	#3
	ld	a, (hl)
	sub	a, e
00106$:
;src/pathfinding/astar.c:69: return dx + dy;
	add	a, c
;src/pathfinding/astar.c:70: }
	pop	hl
	pop	bc
	jp	(hl)
;src/pathfinding/astar.c:76: uint8_t astar_find(uint8_t sx, uint8_t sy,
;	---------------------------------
; Function astar_find
; ---------------------------------
_astar_find::
	add	sp, #-10
	ld	c, a
	ld	b, e
;src/pathfinding/astar.c:82: memset(node_g,     0xFF, ASTAR_TOTAL);
	ld	de, #0x00f0
	push	de
	ld	de, #0x00ff
	push	de
	ld	de, #_node_g
	push	de
	call	_memset
	add	sp, #6
;src/pathfinding/astar.c:83: memset(node_flags, 0,    ASTAR_TOTAL);
	ld	de, #0x00f0
	push	de
	ld	de, #0x0000
	push	de
	ld	de, #_node_flags
	push	de
	call	_memset
	add	sp, #6
;src/pathfinding/astar.c:84: heap_size = 0;
	xor	a, a
	ld	(#_heap_size),a
;src/pathfinding/astar.c:86: uint8_t si = IDX(sx, sy);
	ld	a, b
	swap	a
	and	a, #0xf0
	or	a, c
	ld	e, a
;src/pathfinding/astar.c:87: node_g    [si] = 0;
	ld	hl, #_node_g
	ld	d, #0x00
	add	hl, de
	ld	(hl), #0x00
;src/pathfinding/astar.c:88: node_flags[si] = FLAG_OPEN;
	ld	hl, #_node_flags
	ld	d, #0x00
	add	hl, de
	ld	(hl), #0x01
;src/pathfinding/astar.c:89: node_par_x[si] = 0xFF;          /* sentinel: start tile has no parent */
	ld	hl, #_node_par_x
	ld	d, #0x00
	add	hl, de
	ld	(hl), #0xff
;src/pathfinding/astar.c:90: heap_push(manhattan(sx, sy, gx, gy), sx, sy);
	push	bc
	ldhl	sp,	#15
	ld	a, (hl-)
	ld	d, a
	ld	e, (hl)
	push	de
	ld	e, b
	ld	a, c
	call	_manhattan
	pop	bc
	push	bc
	inc	sp
	ld	e, c
	call	_heap_push
;src/pathfinding/astar.c:92: while (heap_size > 0) {
00129$:
	ld	a, (#_heap_size)
	or	a, a
	jp	Z, 00131$
;src/pathfinding/astar.c:94: heap_pop(&cx, &cy);
	ld	hl, #1
	add	hl, sp
	ld	c, l
	ld	b, h
	ld	hl, #0
	add	hl, sp
	ld	e, l
	ld	d, h
	call	_heap_pop
;src/pathfinding/astar.c:96: uint8_t ci = IDX(cx, cy);
	ldhl	sp,	#1
	ld	a, (hl-)
	swap	a
	and	a, #0xf0
	or	a, (hl)
	ldhl	sp,	#9
	ld	(hl), a
;src/pathfinding/astar.c:99: if (node_flags[ci] & FLAG_CLOSED) continue;
	ld	de, #_node_flags
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	ld	c, l
	ld	b, h
	ld	a, (bc)
	bit	1, a
	jr	NZ, 00129$
;src/pathfinding/astar.c:100: node_flags[ci] = FLAG_CLOSED;
	ld	a, #0x02
	ld	(bc), a
;src/pathfinding/astar.c:102: if (cx == gx && cy == gy) {
	ldhl	sp,	#0
	ld	a, (hl)
	ldhl	sp,	#12
	sub	a, (hl)
	jp	NZ, 00114$
	ldhl	sp,	#1
	ld	a, (hl)
	ldhl	sp,	#13
	sub	a, (hl)
	jp	NZ, 00114$
;src/pathfinding/astar.c:106: uint8_t tx = gx, ty = gy;
	ldhl	sp,	#12
	ld	a, (hl)
	ldhl	sp,	#7
	ld	(hl), a
	ldhl	sp,	#4
	ld	(hl), a
	ldhl	sp,	#13
	ld	a, (hl)
	ldhl	sp,	#8
	ld	(hl), a
	ld	a, (hl-)
	dec	hl
	ld	(hl), a
;src/pathfinding/astar.c:107: while (len < ASTAR_MAX_PATH) {
	ldhl	sp,	#9
	ld	(hl), #0x00
00105$:
	ldhl	sp,	#9
	ld	a, (hl)
	sub	a, #0x20
	jr	NC, 00155$
;src/pathfinding/astar.c:108: ++len;
	inc	(hl)
;src/pathfinding/astar.c:109: uint8_t px = node_par_x[IDX(tx, ty)];
	ldhl	sp,	#6
	ld	a, (hl-)
	ld	(hl+), a
	xor	a, a
	ld	(hl-), a
	ld	a, (hl-)
	ld	e, a
	ld	d, #0x00
	sla	e
	rl	d
	sla	e
	rl	d
	sla	e
	rl	d
	sla	e
	rl	d
	ld	c, (hl)
	ld	b, #0x00
	ld	a, e
	or	a, c
	ld	e, a
	ld	hl, #_node_par_x
	add	hl, de
	ld	c, (hl)
;src/pathfinding/astar.c:110: if (px == 0xFF) break;
	ld	a, c
	inc	a
	jr	Z, 00155$
;src/pathfinding/astar.c:111: uint8_t py = node_par_y[IDX(tx, ty)];
	ld	hl, #_node_par_y
	add	hl, de
	ld	a, (hl)
	ldhl	sp,	#6
	ld	(hl), a
;src/pathfinding/astar.c:112: tx = px; ty = py;
	ldhl	sp,	#4
	ld	(hl), c
	jr	00105$
00155$:
	ldhl	sp,	#9
	ld	a, (hl)
	ldhl	sp,	#2
	ld	(hl), a
;src/pathfinding/astar.c:116: tx = gx; ty = gy;
	ldhl	sp,	#7
	ld	a, (hl)
	ldhl	sp,	#3
	ld	(hl), a
	ldhl	sp,	#8
	ld	a, (hl)
	ldhl	sp,	#4
	ld	(hl), a
;src/pathfinding/astar.c:117: while (i > 0) {
00110$:
	ldhl	sp,	#9
	ld	a, (hl)
	or	a, a
	jr	Z, 00112$
;src/pathfinding/astar.c:118: --i;
	dec	(hl)
;src/pathfinding/astar.c:119: out_path[i].x = tx;
	ld	a, (hl-)
	dec	hl
	ld	(hl+), a
	xor	a, a
	ld	(hl-), a
	ld	a, (hl-)
	dec	hl
	ld	(hl+), a
	xor	a, a
	ld	(hl-), a
	sla	(hl)
	inc	hl
	rl	(hl)
	dec	hl
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ldhl	sp,	#16
	ld	a,	(hl+)
	ld	h, (hl)
	ld	l, a
	add	hl, de
	push	hl
	ld	a, l
	ldhl	sp,	#9
	ld	(hl), a
	pop	hl
	ld	a, h
	ldhl	sp,	#8
	ld	(hl-), a
	ld	a, (hl+)
	ld	e, a
	ld	d, (hl)
	ldhl	sp,	#3
	ld	a, (hl)
	ld	(de), a
;src/pathfinding/astar.c:120: out_path[i].y = ty;
	ldhl	sp,	#7
	ld	a, (hl+)
	ld	c, a
	ld	b, (hl)
	inc	bc
	ldhl	sp,	#4
	ld	a, (hl)
	ld	(bc), a
;src/pathfinding/astar.c:121: uint8_t px = node_par_x[IDX(tx, ty)];
	ld	a, (hl-)
	ld	d, #0x00
	add	a, a
	rl	d
	add	a, a
	rl	d
	add	a, a
	rl	d
	add	a, a
	rl	d
	ld	c, (hl)
	ld	b, #0x00
	or	a, c
	ld	e, a
	ld	hl, #_node_par_x
	add	hl, de
	ld	c, (hl)
;src/pathfinding/astar.c:122: if (px == 0xFF) break;
	ld	a, c
	inc	a
	jr	Z, 00112$
;src/pathfinding/astar.c:123: uint8_t py = node_par_y[IDX(tx, ty)];
	ld	hl, #_node_par_y
	add	hl, de
	ld	a, (hl)
	ldhl	sp,	#4
	ld	(hl), a
;src/pathfinding/astar.c:124: tx = px; ty = py;
	ldhl	sp,	#3
	ld	(hl), c
	jr	00110$
00112$:
;src/pathfinding/astar.c:126: return len;
	ldhl	sp,	#2
	ld	a, (hl)
	jp	00133$
00114$:
;src/pathfinding/astar.c:130: uint8_t cg  = node_g[ci];
	ld	de, #_node_g
	ldhl	sp,	#9
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	ld	c, l
	ld	b, h
	ld	a, (bc)
;src/pathfinding/astar.c:132: for (dir = 0; dir < 4; ++dir) {
	ld	c, a
	inc	c
	ld	b, #0x00
00132$:
;src/pathfinding/astar.c:133: int8_t nx = (int8_t)cx + DIR_DX[dir];
	ldhl	sp,	#0
	ld	e, (hl)
	ld	a, #<(_DIR_DX)
	add	a, b
	ld	l, a
	ld	a, #>(_DIR_DX)
	adc	a, #0x00
	ld	h, a
	ld	a, (hl)
	add	a, e
	ldhl	sp,	#8
	ld	(hl), a
;src/pathfinding/astar.c:134: int8_t ny = (int8_t)cy + DIR_DY[dir];
	ldhl	sp,	#1
	ld	e, (hl)
	ld	a, #<(_DIR_DY)
	add	a, b
	ld	l, a
	ld	a, #>(_DIR_DY)
	adc	a, #0x00
	ld	h, a
	ld	a, (hl)
	add	a, e
	ldhl	sp,	#9
;src/pathfinding/astar.c:135: if (nx < 0 || ny < 0 ||
	ld	(hl-), a
	bit	7, (hl)
	jp	NZ, 00127$
	inc	hl
	bit	7, (hl)
	jp	NZ, 00127$
;src/pathfinding/astar.c:136: nx >= (int8_t)ASTAR_GRID_W ||
	dec	hl
	ld	a, (hl)
	xor	a, #0x80
	sub	a, #0x8f
	jp	NC, 00127$
;src/pathfinding/astar.c:137: ny >= (int8_t)ASTAR_GRID_H)
	inc	hl
	ld	a, (hl)
	xor	a, #0x80
	sub	a, #0x8f
	jp	NC, 00127$
;src/pathfinding/astar.c:140: uint8_t ux = (uint8_t)nx;
	dec	hl
	ld	a, (hl-)
;src/pathfinding/astar.c:141: uint8_t uy = (uint8_t)ny;
	ld	(hl+), a
	inc	hl
	ld	a, (hl-)
;src/pathfinding/astar.c:142: uint8_t ni = IDX(ux, uy);
	ld	(hl-), a
	swap	a
	and	a, #0xf0
	or	a, (hl)
	inc	hl
	inc	hl
	ld	(hl), a
;src/pathfinding/astar.c:144: if (node_flags[ni] & FLAG_CLOSED) continue;
	ld	de, #_node_flags
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, (de)
	bit	1, a
	jr	NZ, 00127$
;src/pathfinding/astar.c:145: if (!walkable(ux, uy))            continue;
	push	bc
	ldhl	sp,	#10
	ld	a, (hl-)
	ld	e, a
	ld	a, (hl)
	push	af
	ldhl	sp,	#18
	ld	a, (hl+)
	ld	h, (hl)
	ld	l, a
	pop	af
	call	___sdcc_call_hl
	pop	bc
	or	a, a
	jr	Z, 00127$
;src/pathfinding/astar.c:148: if (ng < node_g[ni]) {
	ld	de, #_node_g
	ldhl	sp,	#9
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	ld	e, l
	ld	d, h
	ld	a, (de)
	ld	l, a
;src/pathfinding/astar.c:149: node_g    [ni] = ng;
	ld	a,c
	cp	a,l
	jr	NC, 00127$
	ld	(de), a
;src/pathfinding/astar.c:150: node_par_x[ni] = cx;
	ld	de, #_node_par_x
	ldhl	sp,	#9
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	ld	e, l
	ld	d, h
	ldhl	sp,	#0
	ld	a, (hl)
	ld	(de), a
;src/pathfinding/astar.c:151: node_par_y[ni] = cy;
	ld	de, #_node_par_y
	ldhl	sp,	#9
	ld	l, (hl)
	ld	h, #0x00
	add	hl, de
	ld	e, l
	ld	d, h
	ldhl	sp,	#1
	ld	a, (hl)
	ld	(de), a
;src/pathfinding/astar.c:153: heap_push(ng + manhattan(ux, uy, gx, gy), ux, uy);
	push	bc
	ldhl	sp,	#15
	ld	a, (hl-)
	ld	d, a
	ld	e, (hl)
	push	de
	ldhl	sp,	#12
	ld	a, (hl-)
	ld	e, a
	ld	a, (hl)
	call	_manhattan
	pop	bc
	add	a, c
	push	bc
	ldhl	sp,	#10
	ld	h, (hl)
	push	hl
	inc	sp
	ldhl	sp,	#10
	ld	e, (hl)
	call	_heap_push
	pop	bc
00127$:
;src/pathfinding/astar.c:132: for (dir = 0; dir < 4; ++dir) {
	inc	b
	ld	a, b
	sub	a, #0x04
	jp	C, 00132$
	jp	00129$
00131$:
;src/pathfinding/astar.c:158: return 0;   /* no path found */
	xor	a, a
00133$:
;src/pathfinding/astar.c:159: }
	add	sp, #10
	pop	hl
	add	sp, #6
	jp	(hl)
_DIR_DX:
	.db #0x00	;  0
	.db #0x00	;  0
	.db #0xff	; -1
	.db #0x01	;  1
_DIR_DY:
	.db #0xff	; -1
	.db #0x01	;  1
	.db #0x00	;  0
	.db #0x00	;  0
	.area _CODE
	.area _INITIALIZER
	.area _CABS (ABS)

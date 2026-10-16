// placeholder player character for meta sprite implementation
// (included from unit.h — guarded so several translation units can share it)

#ifndef PLAYER_CHARACTER_C
#define PLAYER_CHARACTER_C

#include <gb/gb.h>

// generical character structure: id, position, graphics

struct GameCharacter
{
    UBYTE spriteids[4];
    UINT8 x;
    UINT8 y;
    UINT8 width;
    UINT8 height;
};

#endif /* PLAYER_CHARACTER_C */

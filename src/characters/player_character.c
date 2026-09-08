// placeholder player character for meta sprite implementation

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

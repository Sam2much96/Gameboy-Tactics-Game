#ifndef MUSIC_H
#define MUSIC_H

#include <gb/gb.h>

/* gbt_update() for code that lives in a switchable ROM bank.

   gbt_update() pokes the MBC directly and can return with the song's bank
   (2) mapped at 0x4000, which would pull the floor out from under a caller
   in bank 1.  This bank-0 wrapper puts back whatever bank was current.
   Bank-0 code (the title screen) can keep calling gbt_update() directly. */
void music_update(void) NONBANKED;

#endif /* MUSIC_H */

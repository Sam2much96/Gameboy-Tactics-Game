#include "music.h"
#include "gbt_player.h"

void music_update(void) NONBANKED
{
    uint8_t bank = CURRENT_BANK;
    gbt_update();
    SWITCH_ROM(bank);
}

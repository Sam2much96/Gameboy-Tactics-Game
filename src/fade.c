#include "fade.h"

// ─────────────────────────────────────────────
// Fade in / out functions
// ─────────────────────────────────────────────

static const uint8_t FADE_STEPS[4] = { 0xE4, 0xF9, 0xFE, 0xFF };

void performantdelay(uint8_t numloops)
{
    uint8_t ii;
    for (ii = 0; ii < numloops; ii++)
    {
        wait_vbl_done();
    }
}

void fadeout(void)
{
    // uses pallette manipulation to trigger a fadeout effect
    // OBP0 fades in lockstep so unit sprites don't float over a white screen
    uint8_t i;
    for (i = 0; i < 4; i++)
    {
        BGP_REG  = FADE_STEPS[i];
        OBP0_REG = FADE_STEPS[i];
        performantdelay(10);
    }
}

void fadein(void)
{
    // uses pallette manipulation to trigger a fadein effect
    uint8_t i;
    for (i = 3; i > 0; i--)
    {
        BGP_REG  = FADE_STEPS[i - 1u];
        OBP0_REG = FADE_STEPS[i - 1u];
        performantdelay(10);
    }
}

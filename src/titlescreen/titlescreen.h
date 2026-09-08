#ifndef TITLESCREEN_H
#define TITLESCREEN_H

typedef enum {
    TITLE_START       = 0,
    TITLE_CONTINUE    = 1,
    TITLE_MULTIPLAYER = 2
} TitleResult;

/* Display the title screen with a navigable 3-option menu.
   Returns TITLE_START or TITLE_CONTINUE when A is pressed on those options.
   TITLE_MULTIPLAYER plays the selection animation but stays on the menu.
   Caller should call fadeout() after this returns. */
TitleResult run_titlescreen(void);

#endif /* TITLESCREEN_H */

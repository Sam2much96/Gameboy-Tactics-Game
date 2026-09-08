UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    GBDK_HOME = $(HOME)/gbdk
else
    GBDK_HOME = /opt/gbdk
endif

CC = $(GBDK_HOME)/bin/lcc
CFLAGS = -Wa-l -Wl-m -Wl-j -DUSE_SFR_FOR_REG -msm83:gb -O2
LFLAGS = -Wl-yt1 -Wl-yo4 -Wl-ya0

TARGET = my_game.gb

OBJS = src/main.o src/tileset.o src/levels/level1.o \
       src/UI/UI.o src/UI/ui_text.o src/UI/ui_pointer.o \
       src/pathfinding/astar.o \
       src/titlescreen/titlescreen.o \
       src/gbt_player.o src/gbt_player_bank1.o \
       output.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) $(LFLAGS) -o $@ $^

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: %.s
	$(CC) $(CFLAGS) -c -o $@ $<

src/main.o: src/main.c src/tileset.h src/levels/level1.h src/gbt_player.h \
            src/titlescreen/titlescreen.h \
            src/characters/player.c src/characters/player_character.c \
            src/characters/player_anim.c src/characters/player_anim.h
src/tileset.o: src/tileset.c src/tileset.h
src/levels/level1.o: src/levels/level1.c src/levels/level1.h
src/UI/UI.o: src/UI/UI.c src/UI/UI.h
src/UI/ui_text.o: src/UI/ui_text.c src/UI/ui_text.h \
                  src/UI/UI\ tiles/UI_tiles.c src/UI/UI\ tiles/UI_tiles.h \
                  src/UI/selector\ highlight\ tiles/selector.c \
                  src/UI/selector\ highlight\ tiles/selector.h
src/UI/ui_pointer.o: src/UI/ui_pointer.c src/UI/ui_pointer.h \
                     src/UI/pointer\ tiles/PointerSprites.c \
                     src/UI/pointer\ tiles/PointerSprites.h
src/pathfinding/astar.o: src/pathfinding/astar.c src/pathfinding/astar.h
src/titlescreen/titlescreen.o: src/titlescreen/titlescreen.c \
                               src/titlescreen/titlescreen.h \
                               src/titlescreen/titlescreen_data.c \
                               src/titlescreen/titlescreen_map.c \
                               src/UI/ui_pointer.h \
                               src/gbt_player.h
src/gbt_player.o: src/gbt_player.s
src/gbt_player_bank1.o: src/gbt_player_bank1.s
output.o: output.c

# ── Web build ────────────────────────────────────────────────────────────────
# `make web`                — copy the ROM into web/
# `make download-emulatorjs`— fetch the EmulatorJS bundle (run once)

EJS_DIR = web/emulatorjs
EJS_CDN = https://cdn.emulatorjs.org/stable/data

.PHONY: web download-emulatorjs

web: web/my_game.gb

web/my_game.gb: $(TARGET)
	cp $(TARGET) web/my_game.gb

# Downloads all files needed for Game Boy emulation using npm packages.
# Uses: @emulatorjs/emulatorjs (JS/CSS), @emulatorjs/core-gambatte (WASM core).
# Run once; re-run to update to the latest version.
download-emulatorjs:
	mkdir -p $(EJS_DIR)/cores/reports
	# Main emulator JS + CSS — must use stable to match the stable loader.js
	curl -L -o $(EJS_DIR)/emulator.min.js  $(EJS_CDN)/emulator.min.js
	curl -L -o $(EJS_DIR)/emulator.min.css $(EJS_CDN)/emulator.min.css
	# Loader, JS files, compression, localization via npm
	npm pack @emulatorjs/emulatorjs --pack-destination /tmp/
	tar -xzf /tmp/emulatorjs-emulatorjs-*.tgz -C /tmp/ \
	    package/data/loader.js \
	    package/data/version.json \
	    package/data/src/GameManager.js \
	    package/data/src/gamepad.js \
	    package/data/src/nipplejs.js \
	    package/data/src/compression.js \
	    package/data/src/shaders.js \
	    package/data/src/socket.io.min.js \
	    package/data/src/storage.js \
	    package/data/compression/ \
	    package/data/localization/ \
	    package/docs/favicon.ico
	cp /tmp/package/data/loader.js               $(EJS_DIR)/
	cp /tmp/package/data/version.json            $(EJS_DIR)/
	cp /tmp/package/data/src/GameManager.js      $(EJS_DIR)/
	cp /tmp/package/data/src/gamepad.js          $(EJS_DIR)/
	cp /tmp/package/data/src/nipplejs.js         $(EJS_DIR)/
	cp /tmp/package/data/src/compression.js      $(EJS_DIR)/
	cp /tmp/package/data/src/shaders.js          $(EJS_DIR)/
	cp /tmp/package/data/src/socket.io.min.js    $(EJS_DIR)/
	cp /tmp/package/data/src/storage.js          $(EJS_DIR)/
	mkdir -p $(EJS_DIR)/compression $(EJS_DIR)/localization
	cp /tmp/package/data/compression/*.js        $(EJS_DIR)/compression/
	cp /tmp/package/data/compression/*.wasm      $(EJS_DIR)/compression/
	cp /tmp/package/data/localization/*.json     $(EJS_DIR)/localization/
	cp /tmp/package/docs/favicon.ico             web/favicon.ico
	# Gambatte (Game Boy) core via npm — extracts the 7z .data archive
	npm pack @emulatorjs/core-gambatte --pack-destination /tmp/
	tar -xzf /tmp/emulatorjs-core-gambatte-*.tgz -C /tmp/ \
	    package/gambatte-wasm.data package/reports/gambatte.json
	7z e /tmp/package/gambatte-wasm.data \
	    gambatte_libretro.js gambatte_libretro.wasm -o$(EJS_DIR)/cores/ -y
	cp /tmp/package/reports/gambatte.json $(EJS_DIR)/cores/reports/
	# Clean up
	rm -rf /tmp/package /tmp/emulatorjs-*.tgz /tmp/emulatorjs-core-*.tgz

clean:
	rm -f web/my_game.gb
	rm -f $(TARGET)
	rm -f src/*.o src/*.lst src/*.sym src/*.map src/*.asm
	rm -f src/levels/*.o src/levels/*.lst src/levels/*.sym src/levels/*.map src/levels/*.asm
	rm -f src/UI/*.o src/UI/*.lst src/UI/*.sym src/UI/*.map src/UI/*.asm
	rm -f src/pathfinding/*.o src/pathfinding/*.lst src/pathfinding/*.sym src/pathfinding/*.map src/pathfinding/*.asm
	rm -f output.o output.c output.h output.lst output.sym

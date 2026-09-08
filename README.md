This game demo is a 4x style game engine built using gbdk

tools:
(1) png2asset
(2) gbdk

building:
$make

convert level to gameboy c file using png2asset
png2asset level1.png -c src/levels/level1.c -map -bpp 2 -max_palettes 1 -sw 16 -sh 16

#convert tileset

# Convert tileset

png2asset 16x16_gameboy_tileset_1.png -c src/tileset.c -map -bpp 2 -max_palettes 1

testing:

mgba-qt my_game.gb


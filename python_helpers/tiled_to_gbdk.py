import json
import sys

def convert(json_file, out_name):
    with open(json_file, "r") as f:
        data = json.load(f)

    width = data["width"]
    height = data["height"]

    # Get first layer (assumes tile layer)
    layer = None
    for l in data["layers"]:
        if l["type"] == "tilelayer":
            layer = l
            break

    if not layer:
        print("No tile layer found")
        return

    tiles = layer["data"]

    # Tiled uses 0 for empty tiles
    # We keep them as 0 for GB maps
    c_array = []

    for t in tiles:
        # Convert GID → tile index (simple case)
        if t == 0:
            c_array.append(0)
        else:
            c_array.append(t - 1)  # Tiled starts at 1

    # Write .c file
    c_file = f"{out_name}.c"
    h_file = f"{out_name}.h"

    with open(c_file, "w") as f:
        f.write(f"#include \"{out_name}.h\"\n\n")
        f.write(f"const unsigned char {out_name}_map[] = {{\n")

        for y in range(height):
            row = c_array[y * width:(y + 1) * width]
            f.write("    " + ", ".join(map(str, row)) + ",\n")

        f.write("};\n\n")
        f.write(f"const unsigned char {out_name}_width = {width};\n")
        f.write(f"const unsigned char {out_name}_height = {height};\n")

    # Write header
    with open(h_file, "w") as f:
        f.write(f"#ifndef {out_name.upper()}_H\n")
        f.write(f"#define {out_name.upper()}_H\n\n")

        f.write(f"extern const unsigned char {out_name}_map[];\n")
        f.write(f"extern const unsigned char {out_name}_width;\n")
        f.write(f"extern const unsigned char {out_name}_height;\n\n")

        f.write("#endif\n")

    print("Done:", c_file, h_file)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python tiled_to_gbdk.py level.json levelname")
    else:
        convert(sys.argv[1], sys.argv[2])
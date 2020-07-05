#!/usr/bin/env python3

from bdflib import reader

with open("cpufont", "rb") as f:
    font = reader.read_bdf(f)

print("static const unsigned char __font_bitmap__[] = {")
for idx in range(0, 256):
    print("// char 0x{:02x} {}".format(idx, idx))
    try:
        glyph = font[idx]
    except KeyError:
        print("// (undefined in font)")
        for i in range(0,8):
            print("    {},".format(hex_to_str(0xff)))
        continue

    (left, bottom, width, height) = glyph.get_bounding_box()

    reversed_data = [ ]
    for row in glyph.data:
        reversed_data.insert(0, row)

    grid = [ ]
    print("// {}".format(glyph.get_bounding_box()))
    for i in range(8 - (height + 2 + bottom)):
        grid.append(0x00)
    for row in reversed_data:
        new_row = row << (7 - width - left)
        grid.append(new_row)
    for i in range(2 + bottom):
        grid.append(0x00)

    for row in grid:
        print("    {},".format(hex_to_str(row)))
print("};")

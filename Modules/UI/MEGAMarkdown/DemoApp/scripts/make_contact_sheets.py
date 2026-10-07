#!/usr/bin/env python3
"""Puts capture screenshots on contact sheets, so a person can scan many files at once.

Usage: make_contact_sheets.py <capture folder>

Reads <capture folder>/index.json and writes <capture folder>/sheets/<folder>-NN.png.
Each sheet holds up to 8 screens of one top folder, with the file path above each screen.
"""

import json
import os
import shutil
import sys

from PIL import Image, ImageDraw, ImageFont

COLUMNS = 4
ROWS = 2
THUMB_WIDTH = 400
LABEL_HEIGHT = 44
GAP = 16


def main():
    folder = sys.argv[1]
    with open(os.path.join(folder, "index.json")) as f:
        records = json.load(f)
    sheets = os.path.join(folder, "sheets")
    shutil.rmtree(sheets, ignore_errors=True)
    os.makedirs(sheets)

    # One entry per screen, grouped by the top folder of the file.
    groups = {}
    for record in records:
        top = record["path"].split("/")[0] if "/" in record["path"] else "root"
        base = record["path"].replace("/", "__")
        for page in range(1, record["pages"] + 1):
            label = record["path"] + (f"  ({page}/{record['pages']})" if record["pages"] > 1 else "")
            groups.setdefault(top, []).append((label, os.path.join(folder, f"{base}.p{page}.png")))

    font = ImageFont.load_default(size=16)
    per_sheet = COLUMNS * ROWS
    count = 0
    for top, screens in groups.items():
        for start in range(0, len(screens), per_sheet):
            part = screens[start:start + per_sheet]
            thumbs = []
            for label, path in part:
                if not os.path.exists(path):
                    continue
                image = Image.open(path).convert("RGB")
                height = int(image.height * THUMB_WIDTH / image.width)
                thumbs.append((label, image.resize((THUMB_WIDTH, height))))
            if not thumbs:
                continue
            cell_height = max(t.height for _, t in thumbs) + LABEL_HEIGHT
            rows = (len(thumbs) + COLUMNS - 1) // COLUMNS
            sheet = Image.new("RGB", (COLUMNS * (THUMB_WIDTH + GAP) + GAP, rows * (cell_height + GAP) + GAP), "#d0d0d0")
            draw = ImageDraw.Draw(sheet)
            for index, (label, thumb) in enumerate(thumbs):
                x = GAP + (index % COLUMNS) * (THUMB_WIDTH + GAP)
                y = GAP + (index // COLUMNS) * (cell_height + GAP)
                # Long paths wrap onto a second line.
                draw.multiline_text((x, y), label[:44] + ("\n" + label[44:88] if len(label) > 44 else ""), fill="black", font=font)
                sheet.paste(thumb, (x, y + LABEL_HEIGHT))
            sheet.save(os.path.join(sheets, f"{top}-{start // per_sheet + 1:02d}.png"))
            count += 1
    print(f"{count} sheets in {sheets}")


if __name__ == "__main__":
    main()

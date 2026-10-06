"""Crops regions from screenshots and places them side by side.

Usage:
  python3 tool/side_by_side.py out.png a.png:x,y,w,h b.png:x,y,w,h [...]

Coordinates are in image pixels. Each crop is labeled with its file name.
Used for concept-vs-Flutter comparisons (KALITE §8).
"""
import os
import sys

from PIL import Image, ImageDraw


def crop(spec):
    path, box = spec.rsplit(':', 1)
    x, y, w, h = (int(v) for v in box.split(','))
    return os.path.basename(path), Image.open(path).convert('RGB').crop((x, y, x + w, y + h))


def main():
    out, specs = sys.argv[1], sys.argv[2:]
    parts = [crop(s) for s in specs]
    gap, label = 16, 24
    width = sum(img.width for _, img in parts) + gap * (len(parts) - 1)
    height = max(img.height for _, img in parts) + label
    sheet = Image.new('RGB', (width, height), 'white')
    draw = ImageDraw.Draw(sheet)
    x = 0
    for name, img in parts:
        draw.text((x + 4, 4), name, fill='black')
        sheet.paste(img, (x, label))
        x += img.width + gap
    sheet.save(out)
    print(out, sheet.size)


if __name__ == '__main__':
    main()

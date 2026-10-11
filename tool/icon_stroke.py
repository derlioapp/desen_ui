"""Finds icons whose openings close at Desen's 2-unit stroke.

Hugeicons draws its icons with a 1.5-unit stroke, Desen with 2. Where a
drawing's gaps are narrow (letters, rows of dots, dense patterns), the
heavier stroke fills an opening or joins strokes that are apart at 1.5.
Such an icon keeps the heaviest stroke that leaves its 1.5 drawing intact,
1.75 or 1.5, in its JSON's `stroke` (see import_icons.py). Icons that sit
side by side (the file types in a file list) form a family and share the
lightest stroke any of them needs.

  python3 tool/icon_stroke.py [name ...]           report
  python3 tool/icon_stroke.py --write [name ...]   also set `stroke`

Without names it checks every icon in tool/icons/. Each icon is rendered
at 96 px (rsvg-convert) and compared with itself at 1.5: the number of
separate strokes and of enclosed openings must match. Run it on new icons
after an import and review the result like any other change. Needs
rsvg-convert (librsvg), numpy and Pillow.
"""

import io
import json
import os
import re
import subprocess
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'tool', 'icons')
SIZE = 96
MIN_AREA = 6  # px at 96 px: smaller specks are antialiasing
STROKES = [2, 1.75, 1.5]

# Families that share one stroke, as full-name patterns.
FAMILIES = [
    r'file-(7z|css|csv|doc|gif|hdr|html|jpg|jsx|mp3|mp4|pdf|png|ppt|rar|raw'
    r'|svg|tiff|txt|wav|xls|xml|xsl|zip)(-boxed)?',
]


def render(svg, stroke):
    svg = re.sub(r'stroke-width="[^"]*"', f'stroke-width="{stroke:g}"', svg,
                 count=1)
    png = subprocess.run(
        ['rsvg-convert', '-w', str(SIZE), '-h', str(SIZE), '-b', 'white'],
        input=svg.encode(), capture_output=True, check=True).stdout
    return np.asarray(Image.open(io.BytesIO(png)).convert('L')) < 128


def labels(mask):
    """4-connected components of [mask], each labelled with its smallest
    pixel index; -1 outside the mask."""
    h, w = mask.shape
    none = h * w
    lab = np.where(mask, np.arange(none).reshape(h, w), none)
    while True:
        n = lab.copy()
        n[1:] = np.minimum(n[1:], lab[:-1])
        n[:-1] = np.minimum(n[:-1], lab[1:])
        n[:, 1:] = np.minimum(n[:, 1:], lab[:, :-1])
        n[:, :-1] = np.minimum(n[:, :-1], lab[:, 1:])
        n = np.where(mask, n, none)
        flat = np.append(n.ravel(), none)
        n = np.where(mask, flat[flat[n]], none)  # jump to the label's label
        if np.array_equal(n, lab):
            return np.where(mask, lab, -1)
        lab = n


def count(mask, enclosed):
    lab = labels(mask)
    ids, areas = np.unique(lab[lab >= 0], return_counts=True)
    edge = set(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]).tolist())
    return sum(1 for i, a in zip(ids, areas)
               if a >= MIN_AREA and not (enclosed and i in edge))


def topology(ink):
    """Separate strokes and enclosed openings."""
    return count(ink, False), count(~ink, True)


def stroke_for(svg):
    """The heaviest of [STROKES] that keeps the 1.5 drawing's topology."""
    want = topology(render(svg, 1.5))
    for stroke in STROKES:
        if stroke == 1.5 or topology(render(svg, stroke)) == want:
            return stroke


def main():
    args = sys.argv[1:]
    write = '--write' in args
    every = sorted(f[:-5] for f in os.listdir(SRC) if f.endswith('.json'))
    names = [a for a in args if a != '--write'] or every
    families = [[n for n in every if re.fullmatch(f, n)] for f in FAMILIES]
    for family in families:
        if set(family) & set(names):
            names += [n for n in family if n not in names]
    strokes = {}
    for i, name in enumerate(names):
        with open(os.path.join(SRC, name + '.svg')) as fh:
            strokes[name] = stroke_for(fh.read())
        if (i + 1) % 500 == 0:
            print(f'{i + 1} of {len(names)}', file=sys.stderr)
    for family in families:
        if set(family) <= set(strokes):
            lightest = min(strokes[n] for n in family)
            strokes.update((n, lightest) for n in family)
    changed = []
    for name in names:
        stroke = strokes[name]
        svg_path = os.path.join(SRC, name + '.svg')
        with open(svg_path) as fh:
            svg = fh.read()
        path = os.path.join(SRC, name + '.json')
        with open(path) as fh:
            meta = json.load(fh)
        if meta.get('stroke', 2) != stroke:
            changed.append(f'{name}: {meta.get("stroke", 2):g} -> {stroke:g}')
            if write:
                if stroke == 2:
                    meta.pop('stroke')
                else:
                    meta['stroke'] = stroke
                with open(path, 'w') as fh:
                    json.dump(meta, fh, indent=2, ensure_ascii=False)
                    fh.write('\n')
                # The same <svg> attribute import_icons.py writes.
                with open(svg_path, 'w') as fh:
                    fh.write(re.sub(r'stroke-width="[^"]*"',
                                    f'stroke-width="{stroke:g}"', svg, count=1))
    print(*changed, sep='\n')
    print(f'{len(names)} icons, {len(changed)} '
          f'{"changed" if write else "to change"}')
    return 0


if __name__ == '__main__':
    sys.exit(main())

"""Imports icon shapes from the free Hugeicons set into tool/icons/.

Desen keeps its own copy of the free Hugeicons icons (https://hugeicons.com,
MIT license, the stroke rounded style): tool/icons/ is the source of truth,
and tool/gen_icons.py turns it into Dart. This script copies a pinned release
of the npm package @hugeicons/core-free-icons into that folder. Run it again
with a newer version to take upstream changes, then review the diff: nothing
reaches the package unless it is committed.

  python3 tool/import_icons.py --hugeicons 4.3.5 [--cache DIR]

For each icon the folder holds its SVG and a JSON file with Desen's metadata:

  upstream   "hugeicons/<Name>", the upstream icon this one is drawn from;
             Desen names its icons itself, so a later import finds the file
             by this field, not by the file name
  also       other upstream icons with the same drawing; they are not
             imported again, and the site's search finds this icon by their
             names
  category   one of Desen's categories, which follow Lucide's
  tags       search words
  aliases    extra Dart names for the icon
  mirror     true if the icon points along the reading direction and flips in
             right-to-left text
  fill       false if the icon's filled form loses its details, so its docs
             say to use it outlined (optional)
  stroke     the stroke width when it is not 2: an icon whose openings close
             at 2 (letters, rows of dots) keeps the heaviest stroke that
             leaves them open, as tool/icon_stroke.py finds it (optional)

Everything except the shape is Desen's own and kept on import. The SVG is
normalized to the form tool/gen_icons.py reads: strokes in currentColor, the
stroke width (2 units unless the JSON says otherwise) with round caps and
joins set once on the <svg>, and transforms applied to the shapes.

An icon whose upstream is "desen/<name>" is Desen's own, derived from
upstream parts: its JSON holds the recipe under `derived`, and every import
rebuilds its SVG from the current upstream parts:

  derived    {"parts": [{"from": "<Name>", "keep": [element indexes],
                         "matrix": [a, b, c, d, e, f], "whole": true}, ...],
              "cut": [[cx, cy, r], ...], "paths": [extra path data],
              "transform": null | "mirror-x" | "mirror-y" | "rotate-90" |
              "rotate-180" | "rotate-270"}

             A part's `matrix` moves or scales it; `cut` removes everything
             inside the circles from every part not marked `whole` (the gap
             upstream leaves around a badge); `paths` and `transform` apply
             last.

It fills a gap upstream leaves (a plain clipboard, the stroke parts of an
icon whose body is a filled outline), and is reviewed like any other change.

Icons listed in tool/icons/excluded.txt are not imported (brand logos, and
icons with parts drawn as filled outlines, which cannot follow the stroke
weight). An upstream icon that is neither in the folder nor excluded is
added under its upstream name with category "new", for review: give it a
name, a category and tags before committing. An icon that upstream removed
stays here, reported, until it is deleted by hand.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import tarfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import icon_geometry as geometry  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'tool', 'icons')
PACKAGE = '@hugeicons/core-free-icons'

SVG_OPEN = ('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" '
            'viewBox="0 0 24 24" fill="none" stroke="currentColor" '
            'stroke-width="{stroke}" stroke-linecap="round" stroke-linejoin="round">')

# Presentation attributes that the <svg> sets once, or that Desen ignores:
# Hugeicons draws a 1.5-unit stroke, Desen's default is 2 for every path.
DROP = {'key', 'stroke', 'stroke-width', 'stroke-linecap', 'stroke-linejoin',
        'opacity', 'fill-rule', 'clip-rule', 'transform'}


def fetch(version, cache):
    """The package's dist/esm folder at [version], unpacked under [cache]."""
    folder = os.path.join(cache, f'hugeicons-{version}')
    esm = os.path.join(folder, 'package', 'dist', 'esm')
    if not os.path.isdir(esm):
        os.makedirs(folder, exist_ok=True)
        run = subprocess.run(
            ['npm', 'pack', f'{PACKAGE}@{version}', '--pack-destination', folder],
            check=True, capture_output=True, text=True)
        tgz = os.path.join(folder, run.stdout.strip().splitlines()[-1])
        with tarfile.open(tgz) as tar:
            tar.extractall(folder, filter='data')
    return esm


def kebab(camel):
    return re.sub(r'(?<=[a-z0-9])([A-Z])|(?<=[A-Z])([A-Z])(?=[a-z])',
                  lambda m: '-' + (m.group(1) or m.group(2)), camel).lower()


def num(v):
    s = ('%.4f' % v).rstrip('0').rstrip('.')
    return s if s not in ('-0', '') else '0'


def matrix(t):
    """The affine matrix (a, b, c, d, e, f) of an SVG transform attribute."""
    m = re.fullmatch(r'matrix\(([^)]*)\)', t.strip())
    if m:
        return [float(v) for v in re.split(r'[\s,]+', m.group(1).strip())]
    m = re.fullmatch(r'rotate\(\s*([-\d.]+)\s+([-\d.]+)\s+([-\d.]+)\s*\)', t.strip())
    if m:
        import math
        a, cx, cy = (float(v) for v in m.groups())
        r = math.radians(a)
        cos, sin = math.cos(r), math.sin(r)
        return [cos, sin, -sin, cos, cx - cx * cos + cy * sin,
                cy - cx * sin - cy * cos]
    raise SystemExit(f'unsupported transform: {t}')


def apply(m, x, y):
    a, b, c, d, e, f = m
    return a * x + c * y + e, b * x + d * y + f


def element(tag, attrs, name):
    """One SVG element with Desen's attributes, transforms applied."""
    t = attrs.get('transform')
    if t:
        m = matrix(t)
        if tag == 'circle':
            x, y = apply(m, float(attrs.get('cx', 0)), float(attrs.get('cy', 0)))
            attrs = {**attrs, 'cx': num(x), 'cy': num(y)}
        elif tag == 'rect':
            x0, y0 = float(attrs.get('x', 0)), float(attrs.get('y', 0))
            w, h = float(attrs['width']), float(attrs['height'])
            corners = [apply(m, x, y) for x in (x0, x0 + w) for y in (y0, y0 + h)]
            xs, ys = [p[0] for p in corners], [p[1] for p in corners]
            swap = abs(m[1]) > abs(m[0])  # a quarter turn swaps the radii
            rx, ry = attrs.get('rx'), attrs.get('ry', attrs.get('rx'))
            attrs = {**attrs, 'x': num(min(xs)), 'y': num(min(ys)),
                     'width': num(max(xs) - min(xs)),
                     'height': num(max(ys) - min(ys))}
            if rx is not None:
                attrs['rx'], attrs['ry'] = (ry, rx) if swap else (rx, ry)
        else:
            raise SystemExit(f'{name}: a transform on <{tag}> is not supported')
    if attrs.get('fill', 'none') != 'none':
        raise SystemExit(f'{name}: a filled <{tag}> cannot follow the stroke '
                         'weight; list the icon in excluded.txt')
    keep = ' '.join(f'{k}="{v}"' for k, v in attrs.items()
                    if k not in DROP and k != 'fill')
    return f'  <{tag} {keep} />'


def read_upstream(esm):
    """Upstream icons as {name: [(tag, attrs), ...]}, from the package's index."""
    with open(os.path.join(esm, 'index.js')) as fh:
        index = fh.read()
    names = sorted(set(re.findall(r"from '\./([A-Za-z0-9]+)Icon\.js'", index)))
    icons = {}
    for name in names:
        with open(os.path.join(esm, name + 'Icon.js')) as fh:
            src = fh.read()
        icons[name] = [
            (tag, {kebab(k): v for k, v in re.findall(r'(\w+): "([^"]*)"', body)})
            for tag, body in re.findall(r'\["(\w+)", \{([^}]*)\}\]', src)]
    return icons


def svg_text(lines, stroke=2):
    return '\n'.join([SVG_OPEN.format(stroke='%g' % stroke), *lines,
                      '</svg>']) + '\n'


# Whole-icon transforms of a derived icon, as affine matrices on the grid.
TRANSFORMS = {
    'mirror-x': [-1, 0, 0, 1, 24, 0],
    'mirror-y': [1, 0, 0, -1, 0, 24],
    'rotate-90': [0, 1, -1, 0, 24, 0],
    'rotate-180': [-1, 0, 0, -1, 24, 24],
    'rotate-270': [0, -1, 1, 0, 0, 24],
}

NUMBER = r'[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?'


def transform_path(d, m):
    """Path data [d] with the affine [m] applied (mirrors and quarter turns)."""
    tokens = re.findall(r'[A-Za-z]|' + NUMBER, d)
    a, b, c, dd, e, f = m
    flip = a * dd - b * c < 0
    out, i, cmd = [], 0, None
    def nums(n):
        nonlocal i
        vals = [float(t) for t in tokens[i:i + n]]
        i += n
        return vals
    def point(x, y, rel):
        return (a * x + c * y, b * x + dd * y) if rel else apply(m, x, y)
    cx = cy = 0.0
    while i < len(tokens):
        if re.fullmatch('[A-Za-z]', tokens[i]):
            cmd = tokens[i]
            i += 1
            if cmd in 'Zz':
                out.append('Z')
                continue
        rel = cmd.islower()
        up = cmd.upper()
        if up in 'ML T'.replace(' ', ''):
            x, y = point(*nums(2), rel)
            out.append(f'{cmd}{num(x)} {num(y)}')
        elif up == 'H' or up == 'V':
            v, = nums(1)
            # A line along one axis may run along the other after a turn.
            if rel:
                x, y = point(v, 0, True) if up == 'H' else point(0, v, True)
                out.append(f'l{num(x)} {num(y)}')
            else:
                raise SystemExit('absolute H/V in a derived path: use L')
        elif up in 'CSQ':
            n = {'C': 6, 'S': 4, 'Q': 4}[up]
            vals = nums(n)
            pts = [point(vals[k], vals[k + 1], rel) for k in range(0, n, 2)]
            out.append(cmd + ' '.join(f'{num(x)} {num(y)}' for x, y in pts))
        elif up == 'A':
            rx, ry, rot = nums(3)
            large, sweep = int(float(tokens[i])), int(float(tokens[i + 1]))
            i += 2
            x, y = point(*nums(2), rel)
            if abs(b) > abs(a):
                rx, ry = ry, rx
            if flip:
                sweep = 1 - sweep
            out.append(f'{cmd}{num(rx)} {num(ry)} {num(rot)} {large} {sweep} '
                       f'{num(x)} {num(y)}')
        else:
            raise SystemExit(f'unsupported path command {cmd}')
    return ''.join(out)


def transform_element(tag, attrs, m):
    attrs = dict(attrs)
    if tag == 'path':
        attrs['d'] = transform_path(absolute_hv(attrs['d']), m)
    elif tag in ('circle', 'ellipse'):
        x, y = apply(m, float(attrs.get('cx', 0)), float(attrs.get('cy', 0)))
        attrs['cx'], attrs['cy'] = num(x), num(y)
        if tag == 'ellipse' and abs(m[1]) > abs(m[0]):
            attrs['rx'], attrs['ry'] = attrs['ry'], attrs['rx']
    elif tag == 'rect':
        attrs['transform'] = 'matrix(%s)' % ' '.join(num(v) for v in m)
    else:
        raise SystemExit(f'cannot transform <{tag}>')
    return attrs


def absolute_hv(d):
    """[d] with every H and V written as an L, so a turn can move it."""
    tokens = re.findall(r'[A-Za-z]|' + NUMBER, d)
    out, i, cmd = [], 0, None
    x = y = sx = sy = 0.0
    def take():
        nonlocal i
        i += 1
        return float(tokens[i - 1])
    while i < len(tokens):
        if re.fullmatch('[A-Za-z]', tokens[i]):
            cmd = tokens[i]
            i += 1
            if cmd in 'Zz':
                out.append('Z')
                x, y = sx, sy
                continue
        up, rel = cmd.upper(), cmd.islower()
        if up in 'MLT':
            px, py = take(), take()
            x, y = (x + px, y + py) if rel else (px, py)
            if up == 'M':
                sx, sy = x, y
            out.append(f'{up}{num(x)} {num(y)}')
        elif up == 'H':
            v = take()
            x = x + v if rel else v
            out.append(f'L{num(x)} {num(y)}')
        elif up == 'V':
            v = take()
            y = y + v if rel else v
            out.append(f'L{num(x)} {num(y)}')
        elif up in 'CSQ':
            n = {'C': 6, 'S': 4, 'Q': 4}[up]
            vals = [take() for _ in range(n)]
            pts = [(vals[k] + (x if rel else 0), vals[k + 1] + (y if rel else 0))
                   for k in range(0, n, 2)]
            x, y = pts[-1]
            out.append(up + ' '.join(f'{num(px)} {num(py)}' for px, py in pts))
        elif up == 'A':
            rx, ry, rot = take(), take(), take()
            large, sweep = int(float(tokens[i])), int(float(tokens[i + 1]))
            i += 2
            px, py = take(), take()
            x, y = (x + px, y + py) if rel else (px, py)
            out.append(f'A{num(rx)} {num(ry)} {num(rot)} {large} {sweep} '
                       f'{num(x)} {num(y)}')
    return ''.join(out)


def derive(meta, upstream, name):
    """The SVG of a derived icon, built from current upstream parts."""
    recipe = meta['derived']
    circles = recipe.get('cut', [])
    parts = []
    for part in recipe['parts']:
        source = upstream.get(part['from'])
        if source is None:
            raise SystemExit(f'{name}: upstream {part["from"]} no longer exists')
        for i in part['keep']:
            tag, attrs = source[i]
            if attrs.get('fill', 'none') != 'none':
                raise SystemExit(f'{name}: {part["from"]} element {i} is filled')
            if attrs.get('transform'):
                line = element(tag, attrs, name)
                attrs = dict(re.findall(r'([\w-]+)="([^"]*)"', line))
            if part.get('matrix') or (circles and not part.get('whole')):
                # Moved, scaled or cut: rewritten as plain path data.
                shapes = geometry.shape(tag, attrs)
                if part.get('matrix'):
                    shapes = geometry.transform(shapes, part['matrix'])
                if circles and not part.get('whole'):
                    shapes = geometry.cut(shapes, circles)
                if not shapes:
                    continue
                tag, attrs = 'path', {'d': geometry.to_d(shapes)}
            parts.append((tag, attrs))
    parts += [('path', {'d': d}) for d in recipe.get('paths', [])]
    m = TRANSFORMS.get(recipe.get('transform'))
    lines = []
    for tag, attrs in parts:
        if m:
            attrs = transform_element(tag, attrs, m)
        lines.append(element(tag, attrs, name))
    return svg_text(lines, meta.get('stroke', 2))


def load_local():
    """Desen's current files keyed by upstream name, the `also` names, and
    the derived icons by file name."""
    local, also, derived = {}, {}, {}
    for f in sorted(os.listdir(OUT)):
        if not f.endswith('.json'):
            continue
        with open(os.path.join(OUT, f)) as fh:
            meta = json.load(fh)
        source, upstream = meta['upstream'].split('/', 1)
        if source == 'desen':
            derived[f[:-5]] = meta
            continue
        local[upstream] = (f[:-5], meta)
        for other in meta.get('also', []):
            also[other] = f[:-5]
    return local, also, derived


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--hugeicons', required=True,
                    help='version of @hugeicons/core-free-icons, e.g. 4.3.5')
    ap.add_argument('--cache', default=os.path.join(ROOT, '.dart_tool',
                                                     'icon_import'))
    args = ap.parse_args()

    os.makedirs(OUT, exist_ok=True)
    excluded = set()
    excluded_path = os.path.join(OUT, 'excluded.txt')
    if os.path.exists(excluded_path):
        with open(excluded_path) as fh:
            excluded = {l.split('#')[0].strip() for l in fh} - {''}

    local, also, derived = load_local()
    upstream = read_upstream(fetch(args.hugeicons, args.cache))
    added, updated = [], []

    def write(kebab_name, svg, known):
        svg_path = os.path.join(OUT, kebab_name + '.svg')
        before = open(svg_path).read() if os.path.exists(svg_path) else None
        if before != svg:
            with open(svg_path, 'w') as fh:
                fh.write(svg)
            if known:
                updated.append(kebab_name)

    for name, elements in upstream.items():
        if name in excluded or name in also:
            continue
        if name in local:
            kebab_name, meta = local[name]
        else:
            kebab_name = kebab(name)
            meta = {'upstream': f'hugeicons/{name}', 'also': [],
                    'category': 'new', 'tags': [], 'aliases': [],
                    'mirror': False}
            with open(os.path.join(OUT, kebab_name + '.json'), 'w') as fh:
                json.dump(meta, fh, indent=2, ensure_ascii=False)
                fh.write('\n')
            added.append(kebab_name)
        write(kebab_name, svg_text([element(t, a, name) for t, a in elements],
                                   meta.get('stroke', 2)),
              name in local)
    for kebab_name, meta in derived.items():
        write(kebab_name, derive(meta, upstream, kebab_name), True)

    gone = sorted(n for u, (n, _) in local.items() if u not in upstream)
    with open(os.path.join(OUT, 'SOURCE'), 'w') as fh:
        fh.write(f'hugeicons {args.hugeicons}\n')

    print(f'{len(upstream)} upstream icons: {len(added)} new, '
          f'{len(updated)} changed')
    if added:
        print('New (name, categorize and tag them):', ', '.join(added))
    if gone:
        print('No longer upstream (kept until deleted by hand):', ', '.join(gone))
    return 0


if __name__ == '__main__':
    sys.exit(main())

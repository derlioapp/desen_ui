"""Path geometry for derived icons (see import_icons.py).

A shape becomes a list of subpaths, each a list of segments: a line
('L', p0, p1) or a cubic Bézier ('C', p0, p1, p2, p3), with points as (x, y)
tuples. Arcs, quadratic curves, circles, ellipses and rounded rects become
cubics. On that form a derived icon can move or scale a part (an affine
matrix) and cut a gap into it (everything inside a circle goes, as upstream
icons do around a badge), and is written back as path data.
"""

import math
import re

NUMBER = r'[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?'
KAPPA = 0.5522847498  # cubic control distance for a quarter circle


def fmt(v):
    s = ('%.4f' % v).rstrip('0').rstrip('.')
    return s if s not in ('-0', '') else '0'


def _arc(p0, rx, ry, phi, large, sweep, p1):
    """Cubic segments for an SVG arc from p0 to p1 (endpoint form)."""
    if p0 == p1:
        return []
    if rx == 0 or ry == 0:
        return [('L', p0, p1)]
    rx, ry = abs(rx), abs(ry)
    cos, sin = math.cos(math.radians(phi)), math.sin(math.radians(phi))
    dx, dy = (p0[0] - p1[0]) / 2, (p0[1] - p1[1]) / 2
    x1, y1 = cos * dx + sin * dy, -sin * dx + cos * dy
    scale = x1 * x1 / (rx * rx) + y1 * y1 / (ry * ry)
    if scale > 1:
        rx, ry = rx * math.sqrt(scale), ry * math.sqrt(scale)
    num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
    den = rx * rx * y1 * y1 + ry * ry * x1 * x1
    co = math.sqrt(max(0, num / den)) * (-1 if large == sweep else 1)
    cx1, cy1 = co * rx * y1 / ry, -co * ry * x1 / rx
    cx = cos * cx1 - sin * cy1 + (p0[0] + p1[0]) / 2
    cy = sin * cx1 + cos * cy1 + (p0[1] + p1[1]) / 2

    def angle(ux, uy, vx, vy):
        a = math.atan2(ux * vy - uy * vx, ux * vx + uy * vy)
        return a

    t1 = angle(1, 0, (x1 - cx1) / rx, (y1 - cy1) / ry)
    dt = angle((x1 - cx1) / rx, (y1 - cy1) / ry, (-x1 - cx1) / rx, (-y1 - cy1) / ry)
    if not sweep and dt > 0:
        dt -= 2 * math.pi
    elif sweep and dt < 0:
        dt += 2 * math.pi
    n = max(1, math.ceil(abs(dt) / (math.pi / 2) - 1e-9))
    step = dt / n
    k = 4 / 3 * math.tan(step / 4)

    def point(t):
        x, y = rx * math.cos(t), ry * math.sin(t)
        return cos * x - sin * y + cx, sin * x + cos * y + cy

    def deriv(t):
        x, y = -rx * math.sin(t), ry * math.cos(t)
        return cos * x - sin * y, sin * x + cos * y

    segs, a, start = [], t1, p0
    for i in range(n):
        b = a + step
        end = p1 if i == n - 1 else point(b)
        da, db = deriv(a), deriv(b)
        segs.append(('C', start, (start[0] + k * da[0], start[1] + k * da[1]),
                     (end[0] - k * db[0], end[1] - k * db[1]), end))
        a, start = b, end
    return segs


def parse_path(d):
    """Subpaths of path data [d], as (segments, closed) pairs."""
    tokens = re.findall(r'[A-Za-z]|' + NUMBER, d)
    i, cmd = 0, None
    cur = start = (0.0, 0.0)
    last_ctrl = None
    subpaths, segs = [], []

    def take(n):
        nonlocal i
        vals = []
        while len(vals) < n:
            t = tokens[i]
            i += 1
            vals.append(float(t))
        return vals

    def flush(closed):
        nonlocal segs
        if segs:
            subpaths.append((segs, closed))
        segs = []

    while i < len(tokens):
        if re.fullmatch('[A-Za-z]', tokens[i]):
            cmd = tokens[i]
            i += 1
            if cmd in 'Zz':
                if cur != start:
                    segs.append(('L', cur, start))
                cur = start
                flush(True)
                last_ctrl = None
                continue
        rel = cmd.islower()
        up = cmd.upper()
        base = cur if rel else (0.0, 0.0)
        if up == 'M':
            x, y = take(2)
            flush(False)
            cur = start = (base[0] + x, base[1] + y)
            cmd = 'l' if rel else 'L'  # further pairs are lines
            last_ctrl = None
        elif up == 'L':
            x, y = take(2)
            p = (base[0] + x, base[1] + y)
            segs.append(('L', cur, p))
            cur, last_ctrl = p, None
        elif up in 'HV':
            v, = take(1)
            p = ((base[0] + v, cur[1]) if up == 'H' else (cur[0], base[1] + v))
            segs.append(('L', cur, p))
            cur, last_ctrl = p, None
        elif up == 'C':
            v = take(6)
            c1 = (base[0] + v[0], base[1] + v[1])
            c2 = (base[0] + v[2], base[1] + v[3])
            p = (base[0] + v[4], base[1] + v[5])
            segs.append(('C', cur, c1, c2, p))
            cur, last_ctrl = p, c2
        elif up == 'S':
            v = take(4)
            c1 = ((2 * cur[0] - last_ctrl[0], 2 * cur[1] - last_ctrl[1])
                  if last_ctrl else cur)
            c2 = (base[0] + v[0], base[1] + v[1])
            p = (base[0] + v[2], base[1] + v[3])
            segs.append(('C', cur, c1, c2, p))
            cur, last_ctrl = p, c2
        elif up in 'QT':
            if up == 'Q':
                v = take(4)
                q = (base[0] + v[0], base[1] + v[1])
                p = (base[0] + v[2], base[1] + v[3])
            else:
                v = take(2)
                q = ((2 * cur[0] - last_ctrl[0], 2 * cur[1] - last_ctrl[1])
                     if last_ctrl else cur)
                p = (base[0] + v[0], base[1] + v[1])
            c1 = (cur[0] + 2 / 3 * (q[0] - cur[0]), cur[1] + 2 / 3 * (q[1] - cur[1]))
            c2 = (p[0] + 2 / 3 * (q[0] - p[0]), p[1] + 2 / 3 * (q[1] - p[1]))
            segs.append(('C', cur, c1, c2, p))
            cur, last_ctrl = p, q
        elif up == 'A':
            rx, ry, phi = take(3)
            flags = []
            while len(flags) < 2:  # flags may be packed: "011"
                t = tokens[i]
                flags.append(int(t[0]))
                tokens[i] = t[1:]
                if not tokens[i]:
                    i += 1
            x, y = take(2)
            p = (base[0] + x, base[1] + y)
            segs += _arc(cur, rx, ry, phi, flags[0], flags[1], p)
            cur, last_ctrl = p, None
        else:
            raise SystemExit(f'unsupported path command {cmd}')
    flush(False)
    return subpaths


def _ellipse(cx, cy, rx, ry):
    k = KAPPA
    pts = [(cx + rx, cy), (cx, cy + ry), (cx - rx, cy), (cx, cy - ry)]
    segs = []
    for a, b in zip(pts, pts[1:] + pts[:1]):
        # Control points along the tangents at a and b.
        ta = (-(a[1] - cy) * rx / ry, (a[0] - cx) * ry / rx)
        tb = (-(b[1] - cy) * rx / ry, (b[0] - cx) * ry / rx)
        segs.append(('C', a, (a[0] + k * ta[0], a[1] + k * ta[1]),
                     (b[0] - k * tb[0], b[1] - k * tb[1]), b))
    return [(segs, True)]


def shape(tag, attrs):
    """Subpaths of one SVG element."""
    f = lambda k, d=0.0: float(attrs.get(k, d))
    if tag == 'path':
        return parse_path(attrs['d'])
    if tag == 'circle':
        return _ellipse(f('cx'), f('cy'), f('r'), f('r'))
    if tag == 'ellipse':
        return _ellipse(f('cx'), f('cy'), f('rx'), f('ry'))
    if tag == 'line':
        return [([('L', (f('x1'), f('y1')), (f('x2'), f('y2')))], False)]
    if tag == 'rect':
        x, y, w, h = f('x'), f('y'), f('width'), f('height')
        rx = min(float(attrs.get('rx', attrs.get('ry', 0))), w / 2)
        ry = min(float(attrs.get('ry', attrs.get('rx', 0))), h / 2)
        if not rx or not ry:
            d = f'M{x} {y}H{x + w}V{y + h}H{x}Z'
        else:
            d = (f'M{x + rx} {y}H{x + w - rx}A{rx} {ry} 0 0 1 {x + w} {y + ry}'
                 f'V{y + h - ry}A{rx} {ry} 0 0 1 {x + w - rx} {y + h}H{x + rx}'
                 f'A{rx} {ry} 0 0 1 {x} {y + h - ry}V{y + ry}'
                 f'A{rx} {ry} 0 0 1 {x + rx} {y}Z')
        return parse_path(d)
    raise SystemExit(f'cannot convert <{tag}> to a path')


def transform(subpaths, m):
    a, b, c, d, e, f = m
    tp = lambda p: (a * p[0] + c * p[1] + e, b * p[0] + d * p[1] + f)
    return [([(s[0], *map(tp, s[1:])) for s in segs], closed)
            for segs, closed in subpaths]


def _at(s, t):
    if s[0] == 'L':
        (x0, y0), (x1, y1) = s[1], s[2]
        return x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
    p0, p1, p2, p3 = s[1:]
    u = 1 - t
    return tuple(u ** 3 * p0[k] + 3 * u * u * t * p1[k] + 3 * u * t * t * p2[k]
                 + t ** 3 * p3[k] for k in (0, 1))


def _split(s, t):
    """[s] split at parameter t into two segments."""
    if s[0] == 'L':
        m = _at(s, t)
        return ('L', s[1], m), ('L', m, s[2])
    p0, p1, p2, p3 = s[1:]
    lerp = lambda a, b: (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)
    a, b, c = lerp(p0, p1), lerp(p1, p2), lerp(p2, p3)
    d, e = lerp(a, b), lerp(b, c)
    m = lerp(d, e)
    return ('C', p0, a, d, m), ('C', m, e, c, p3)


def _crossings(s, circles):
    """Parameters where [s] crosses a circle's edge."""
    ts = []
    for cx, cy, r in circles:
        g = lambda t: math.hypot(_at(s, t)[0] - cx, _at(s, t)[1] - cy) - r
        n = 96
        prev = g(0)
        for k in range(1, n + 1):
            t = k / n
            cur = g(t)
            if (prev < 0) != (cur < 0):
                lo, hi = (k - 1) / n, t
                for _ in range(40):
                    mid = (lo + hi) / 2
                    if (g(lo) < 0) == (g(mid) < 0):
                        lo = mid
                    else:
                        hi = mid
                ts.append((lo + hi) / 2)
            prev = cur
    return sorted(t for t in ts if 1e-6 < t < 1 - 1e-6)


def cut(subpaths, circles):
    """[subpaths] without whatever lies inside any of [circles]."""
    inside = lambda p: any(math.hypot(p[0] - cx, p[1] - cy) < r
                           for cx, cy, r in circles)
    out = []
    for segs, closed in subpaths:
        pieces = []  # (segment, kept)
        for s in segs:
            rest, done = s, 0.0
            for t in _crossings(s, circles):
                left, rest = _split(rest, (t - done) / (1 - done))
                pieces.append(left)
                done = t
            pieces.append(rest)
        kept = [(p, not inside(_at(p, .5))) for p in pieces]
        if all(k for _, k in kept):
            out.append((segs, closed))
            continue
        runs, run = [], []
        for p, k in kept:
            if k:
                run.append(p)
            elif run:
                runs.append(run)
                run = []
        if run:
            runs.append(run)
        # A closed outline cut open: its last run continues into the first.
        if closed and len(runs) > 1 and kept[0][1] and kept[-1][1]:
            runs[0] = runs.pop() + runs[0]
        out += [(r, False) for r in runs]
    return out


def to_d(subpaths):
    parts = []
    for segs, closed in subpaths:
        p0 = segs[0][1]
        d = f'M{fmt(p0[0])} {fmt(p0[1])}'
        for s in segs:
            pts = s[2:] if s[0] == 'L' else s[2:]
            d += s[0] + ' '.join(f'{fmt(x)} {fmt(y)}' for x, y in pts)
        parts.append(d + ('Z' if closed else ''))
    return ''.join(parts)

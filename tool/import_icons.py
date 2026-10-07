"""Imports icon shapes from Lucide into tool/icons/.

Desen keeps its own copy of the Lucide icons (https://lucide.dev, ISC
license): tool/icons/ is the source of truth, and tool/gen_icons.py turns it
into Dart. This script copies a pinned upstream release into that folder. Run
it again with newer refs to take upstream changes, then review the diff:
nothing reaches the package unless it is committed.

  python3 tool/import_icons.py --lucide 1.52.0 --lab <commit> [--cache DIR]

For each upstream icon the folder holds its SVG, unchanged, and a JSON file
with Desen's metadata:

  upstream   "lucide/<name>" or "lucide-lab/<name>"; an icon renamed here
             keeps its upstream name, so a later import updates the right file
  category   the first upstream category, folded into the file groups
             (Desen's own once imported, kept on later imports)
  tags       upstream search tags
  aliases    extra Dart names for the icon (Desen's own, kept on import)
  mirror     true if the icon points along the reading direction and flips in
             right-to-left text (Desen's own, kept on import)
  fill       false if the icon's filled form loses its details, so its docs
             say to use it outlined (Desen's own, optional, kept on import)

Icons listed in tool/icons/excluded.txt are not imported. When the same name
exists in both sets, the main set wins (Lab icons move there when they
graduate). An icon that upstream removed stays here, reported, until it is
deleted by hand.
"""

import argparse
import json
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'tool', 'icons')

SOURCES = {
    'lucide': 'https://github.com/lucide-icons/lucide',
    'lucide-lab': 'https://github.com/lucide-icons/lucide-lab',
}

# Upstream categories with only a handful of icons join a larger group, so
# each generated file has a useful size.
FOLD = {
    'money': 'finance',
    'currency': 'finance',
    'sustainability': 'nature',
    'maps': 'navigation',
    'people': 'account',
    'furniture': 'home',
    'cursors': 'arrows',
    'communication': 'social',
    'emoji': 'social',
}


def fetch(source, ref, cache):
    """A sparse checkout of the upstream icons/ folder at [ref]."""
    path = os.path.join(cache, source)
    if not os.path.isdir(os.path.join(path, '.git')):
        subprocess.run(['git', 'clone', '-q', '--filter=blob:none', '--sparse',
                        '--no-checkout', SOURCES[source], path], check=True)
        subprocess.run(['git', '-C', path, 'sparse-checkout', 'set', 'icons'],
                       check=True)
    subprocess.run(['git', '-C', path, 'fetch', '-q', '--filter=blob:none',
                    'origin', ref], check=True)
    subprocess.run(['git', '-C', path, '-c', 'advice.detachedHead=false',
                    'checkout', '-q', 'FETCH_HEAD'], check=True)
    sha = subprocess.run(['git', '-C', path, 'rev-parse', 'HEAD'], check=True,
                         capture_output=True, text=True).stdout.strip()
    return os.path.join(path, 'icons'), sha


def read_upstream(folder):
    icons = {}
    for f in sorted(os.listdir(folder)):
        if not f.endswith('.json'):
            continue
        name = f[:-5]
        with open(os.path.join(folder, f)) as fh:
            meta = json.load(fh)
        with open(os.path.join(folder, name + '.svg')) as fh:
            svg = fh.read()
        icons[name] = (meta, svg)
    return icons


def load_local():
    """Desen's current files, keyed by upstream id."""
    local = {}
    if not os.path.isdir(OUT):
        return local
    for f in sorted(os.listdir(OUT)):
        if f.endswith('.json'):
            with open(os.path.join(OUT, f)) as fh:
                meta = json.load(fh)
            local[meta['upstream']] = (f[:-5], meta)
    return local


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--lucide', required=True, help='lucide tag, e.g. 1.52.0')
    ap.add_argument('--lab', required=True, help='lucide-lab commit')
    ap.add_argument('--cache', default=os.path.join(ROOT, '.dart_tool',
                                                     'icon_import'))
    args = ap.parse_args()

    os.makedirs(OUT, exist_ok=True)
    excluded_path = os.path.join(OUT, 'excluded.txt')
    excluded = set()
    if os.path.exists(excluded_path):
        with open(excluded_path) as fh:
            excluded = {l.strip() for l in fh
                        if l.strip() and not l.startswith('#')}

    refs = {'lucide': args.lucide, 'lucide-lab': args.lab}
    pinned = {}
    upstream = {}
    for source in ('lucide', 'lucide-lab'):
        folder, sha = fetch(source, refs[source], args.cache)
        pinned[source] = refs[source] if source == 'lucide' else sha
        for name, entry in read_upstream(folder).items():
            uid = f'{source}/{name}'
            if uid in excluded or entry[0].get('deprecated'):
                continue
            if source == 'lucide-lab' and f'lucide/{name}' in upstream:
                continue  # graduated to the main set
            upstream[uid] = entry

    local = load_local()
    added, updated = [], []
    for uid, (meta, svg) in sorted(upstream.items()):
        name, old = local.get(uid, (uid.split('/', 1)[1], None))
        category = (meta.get('categories') or ['other'])[0]
        record = {
            'upstream': uid,
            'category': old['category'] if old else FOLD.get(category, category),
            'tags': meta.get('tags', []),
            'aliases': old['aliases'] if old else [],
            'mirror': old['mirror'] if old else False,
        }
        if old and 'fill' in old:
            record['fill'] = old['fill']
        svg_path = os.path.join(OUT, name + '.svg')
        before = open(svg_path).read() if os.path.exists(svg_path) else None
        with open(svg_path, 'w') as fh:
            fh.write(svg)
        with open(os.path.join(OUT, name + '.json'), 'w') as fh:
            json.dump(record, fh, indent=2, ensure_ascii=False)
            fh.write('\n')
        if old is None:
            added.append(name)
        elif before != svg:
            updated.append(name)

    gone = sorted(n for uid, (n, _) in local.items() if uid not in upstream)
    with open(os.path.join(OUT, 'SOURCE'), 'w') as fh:
        fh.write(f'lucide {pinned["lucide"]}\nlucide-lab {pinned["lucide-lab"]}\n')

    print(f'{len(upstream)} icons: {len(added)} new, {len(updated)} changed')
    if gone:
        print('No longer upstream (kept until deleted by hand):', ', '.join(gone))
    return 0


if __name__ == '__main__':
    sys.exit(main())

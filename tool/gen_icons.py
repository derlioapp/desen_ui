"""Generates lib/src/icons/icons.dart from Lucide-style primitives.

Lucide (https://lucide.dev) is ISC licensed. Shapes are 24x24, stroke 2,
round caps and joins.
"""
import sys

def f(v):
    s = ('%.3f' % v).rstrip('0').rstrip('.')
    return s if s != '-0' else '0'

def circle(cx, cy, r):
    return f"M{f(cx-r)} {f(cy)}a{f(r)} {f(r)} 0 1 0 {f(2*r)} 0a{f(r)} {f(r)} 0 1 0 {f(-2*r)} 0"

def rect(x, y, w, h, r=0):
    if r == 0:
        return f"M{f(x)} {f(y)}h{f(w)}v{f(h)}h{f(-w)}z"
    return (f"M{f(x+r)} {f(y)}h{f(w-2*r)}a{f(r)} {f(r)} 0 0 1 {f(r)} {f(r)}v{f(h-2*r)}"
            f"a{f(r)} {f(r)} 0 0 1 {f(-r)} {f(r)}h{f(-(w-2*r))}a{f(r)} {f(r)} 0 0 1 {f(-r)} {f(-r)}"
            f"v{f(-(h-2*r))}a{f(r)} {f(r)} 0 0 1 {f(r)} {f(-r)}z")

def line(x1, y1, x2, y2):
    return f"M{f(x1)} {f(y1)}L{f(x2)} {f(y2)}"

# Icons that point along the reading direction mirror in RTL.
directional = {'chevronLeft', 'chevronRight', 'logOut'}

icons = {
  'plus': ('Plus.', ["M5 12h14", "M12 5v14"]),
  'minus': ('Minus.', ["M5 12h14"]),
  'check': ('Check mark.', ["M20 6 9 17l-5-5"]),
  'x': ('Close / clear.', ["M18 6 6 18", "m6 6 12 12"]),
  'chevronDown': ('Chevron pointing down.', ["m6 9 6 6 6-6"]),
  'chevronUp': ('Chevron pointing up.', ["m18 15-6-6-6 6"]),
  'chevronLeft': ('Chevron pointing left.', ["m15 18-6-6 6-6"]),
  'chevronRight': ('Chevron pointing right.', ["m9 18 6-6-6-6"]),
  'ellipsis': ('Horizontal ellipsis (more).', [circle(12,12,1), circle(19,12,1), circle(5,12,1)]),
  'search': ('Magnifier.', [circle(11,11,8), "m21 21-4.3-4.3"]),
  'circleAlert': ('Error.', [circle(12,12,10), line(12,8,12,12), line(12,16,12.01,16)]),
  'circleCheck': ('Success.', [circle(12,12,10), "m9 12 2 2 4-4"]),
  'info': ('Information.', [circle(12,12,10), "M12 16v-4", "M12 8h.01"]),
  'triangleAlert': ('Warning.', ["m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3", "M12 9v4", "M12 17h.01"]),
  'mail': ('Envelope.', [rect(2,4,20,16,2), "m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"]),
  'calendar': ('Calendar.', ["M8 2v4", "M16 2v4", rect(3,4,18,18,2), "M3 10h18"]),
  'layoutGrid': ('Grid layout.', [rect(3,3,7,7,1), rect(14,3,7,7,1), rect(14,14,7,7,1), rect(3,14,7,7,1)]),
  'list': ('List layout.', ["M3 12h.01", "M3 18h.01", "M3 6h.01", "M8 12h13", "M8 18h13", "M8 6h13"]),
  'bold': ('Bold text.', ["M6 12h9a4 4 0 0 1 0 8H7a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1h7a4 4 0 0 1 0 8"]),
  'italic': ('Italic text.', [line(19,4,10,4), line(14,20,5,20), line(15,4,9,20)]),
  'underline': ('Underlined text.', ["M6 4v6a6 6 0 0 0 12 0V4", line(4,20,20,20)]),
  'bell': ('Notifications.', ["M10.268 21a2 2 0 0 0 3.464 0", "M3.262 15.326A1 1 0 0 0 4 17h16a1 1 0 0 0 .74-1.673C19.41 13.956 18 12.499 18 8A6 6 0 0 0 6 8c0 4.499-1.411 5.956-2.738 7.326"]),
  'inbox': ('Inbox.', ["M22 12h-6l-2 3h-4l-2-3H2", "M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"]),
  'user': ('Person.', ["M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2", circle(12,7,4)]),
  'arrowUpRight': ('External link.', ["M7 7h10v10", "M7 17 17 7"]),
  'volumeLow': ('Volume, low.', ["M11 4.702a.705.705 0 0 0-1.203-.498L6.413 7.587A1.4 1.4 0 0 1 5.416 8H3a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1h2.416a1.4 1.4 0 0 1 .997.413l3.383 3.384A.705.705 0 0 0 11 19.298z", "M16 9a5 5 0 0 1 0 6"]),
  'volumeHigh': ('Volume, high.', ["M11 4.702a.705.705 0 0 0-1.203-.498L6.413 7.587A1.4 1.4 0 0 1 5.416 8H3a1 1 0 0 0-1 1v6a1 1 0 0 0 1 1h2.416a1.4 1.4 0 0 1 .997.413l3.383 3.384A.705.705 0 0 0 11 19.298z", "M16 9a5 5 0 0 1 0 6", "M19.364 18.364a9 9 0 0 0 0-12.728"]),
  'chevronsUpDown': ('Two chevrons: a switcher or sort.', ["m7 15 5 5 5-5", "m7 9 5-5 5 5"]),
  'sun': ('Light appearance.', [circle(12,12,4), "M12 2v2", "M12 20v2", "m4.93 4.93 1.41 1.41", "m17.66 17.66 1.41 1.41", "M2 12h2", "M20 12h2", "m6.34 17.66-1.41 1.41", "m19.07 4.93-1.41 1.41"]),
  'moon': ('Dark appearance.', ["M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"]),
  'menu': ('Menu (navigation).', ["M4 12h16", "M4 6h16", "M4 18h16"]),
  'folder': ('Folder.', ["M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z"]),
  'house': ('Home.', ["M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8", "M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"]),
  'globe': ('Language or web.', [circle(12,12,10), "M12 2a14.5 14.5 0 0 0 0 20 14.5 14.5 0 0 0 0-20", "M2 12h20"]),
  'logOut': ('Sign out.', ["m16 17 5-5-5-5", "M21 12H9", "M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"]),
  'share': ('Share.', ["M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8", "m16 6-4-4-4 4", line(12,2,12,15)]),
  'link': ('Link.', ["M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71", "M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"]),
  'copy': ('Copy.', [rect(8,8,14,14,2), "M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"]),
  'trash': ('Delete.', ["M3 6h18", "M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6", "M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2", line(10,11,10,17), line(14,11,14,17)]),
  'slidersHorizontal': ('Filters.', [line(21,4,14,4), line(10,4,3,4), line(21,12,12,12), line(8,12,3,12), line(21,20,16,20), line(12,20,3,20), line(14,2,14,6), line(8,10,8,14), line(16,18,16,22)]),
  'eye': ('Visible: shows hidden text, e.g. a password.', ["M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0", circle(12,12,3)]),
  'eyeOff': ('Hidden: hides revealed text again.', ["M10.733 5.076a10.744 10.744 0 0 1 11.205 6.575 1 1 0 0 1 0 .696 10.747 10.747 0 0 1-1.444 2.49", "M14.084 14.158a3 3 0 0 1-4.242-4.242", "M17.479 17.499a10.75 10.75 0 0 1-15.417-5.151 1 1 0 0 1 0-.696 10.75 10.75 0 0 1 4.446-5.143", "m2 2 20 20"]),
  # Keyboard keys, for shortcut hints: the bundled fonts have no ⌘ ⌥ ⇧ ⌫ ⏎
  # glyphs, and platform fallback is not guaranteed (visual M4).
  'command': ('Command key (⌘).', ["M15 6v12a3 3 0 1 0 3-3H6a3 3 0 1 0 3 3V6a3 3 0 1 0-3 3h12a3 3 0 1 0-3-3"]),
  'option': ('Option key (⌥).', ["M3 3h6l6 18h6", "M14 3h7"]),
  'shift': ('Shift key (⇧).', ["M9 18v-6H5l7-7 7 7h-4v6H9z"]),
  'backspace': ('Backspace / delete key (⌫).', ["M10 5a2 2 0 0 0-1.344.519l-6.328 5.74a1 1 0 0 0 0 1.481l6.328 5.741A2 2 0 0 0 10 19h10a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2z", "m12 9 6 6", "m18 9-6 6"]),
  'enter': ('Return key (⏎).', ["M20 4v7a4 4 0 0 1-4 4H4", "m9 10-5 5 5 5"]),
  'upload': ('Upload (tray with an arrow up).', ['M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4', 'M17 8l-5-5-5 5', 'M12 3v12']),
  'fileText': ('File with text lines.', ['M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z', 'M14 2v4a2 2 0 0 0 2 2h4', 'M10 9H8', 'M16 13H8', 'M16 17H8']),
  'clock': ('Clock.', ['M12 6v6l4 2', 'M2 12a10 10 0 1 0 20 0a10 10 0 1 0 -20 0z']),
  'arrowUp': ('Arrow up, e.g. ascending sort.', ['m5 12 7-7 7 7', 'M12 19V5']),
  'arrowDown': ('Arrow down, e.g. descending sort.', ['M12 5v14', 'm19 12-7 7-7-7']),
  'searchX': ('Magnifier with a cross: nothing found.', ['m13.5 8.5-5 5', 'm8.5 8.5 5 5', 'M3 11a8 8 0 1 0 16 0a8 8 0 1 0 -16 0', 'm21 21-4.3-4.3']),
  'imageOff': ('Crossed-out picture: an image that cannot be shown.', [line(2,2,22,22), 'M10.41 10.41a2 2 0 1 1-2.83-2.83', line(13.5,13.5,6,21), line(18,12,21,15), 'M3.59 3.59A1.99 1.99 0 0 0 3 5v14a2 2 0 0 0 2 2h14c.55 0 1.052-.22 1.41-.59', 'M21 15V5a2 2 0 0 0-2-2H9']),
  'settings': ('Settings (gear).', ["M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z", circle(12,12,3)]),
}

out = ['// GENERATED by tool/gen_icons.py. Do not edit by hand.',
       '// Shapes from Lucide (https://lucide.dev), ISC license.', '',
       "import 'icon.dart';", '',
       '/// The built-in icon set: Lucide-style 24×24 stroke icons.',
       '///',
       '/// Desen uses these internally (chevrons, checks, alerts). Components take',
       '/// icons as widgets, so any icon set works in your own UI.',
       'abstract final class DsIcons {']
for name, (doc, paths) in icons.items():
    out.append(f'  /// {doc}')
    joined = ', '.join(f"'{p}'" for p in paths)
    extra = ', matchTextDirection: true' if name in directional else ''
    out.append(f'  static const {name} = DsIconData([{joined}]{extra});')
    out.append('')
out.append('  /// Every icon above by its name, in this order (e.g. for an icon')
out.append('  /// picker or a search).')
out.append('  static const all = <String, DsIconData>{')
for name in icons:
    out.append(f"    '{name}': {name},")
out.append('  };')
out.append('}')
open(sys.argv[1], 'w').write('\n'.join(out) + '\n')
print(len(icons), 'icons')

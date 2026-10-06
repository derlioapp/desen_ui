## Unreleased

- Skeleton blocks are easier to see: new color roles `skeleton` and
  `skeletonStrong` (about 1.27:1 on the card, the page and the sidebar in
  light mode). In dark mode a strong skeleton line no longer vanishes on a
  floating layer.
- Dashed outlines (`DsDashedBorder`, a dashed `DsCard`, the
  `DsFileUpload` drop zone) space their dashes evenly on continuous
  corners too. Dashes were laid out with the engine's path measure, which
  runs unevenly along a superellipse curve, so dashes and gaps on the
  corners were up to 7% and 11% off. The outline is now measured along a
  flattened copy, and the dashes are built once per size and shape rather
  than on every repaint.
- The dark-mode warning tint (`colors.warning.tint`, with its hover and
  press) is a deep orange instead of a brown: amber this dark reads as
  brown or olive. Its hue turns to the nearest clean one at the same
  luminance, so the warning text on it keeps its contrast (about 7.7:1).
  The other status tints were clean already and are unchanged.

## 0.1.0-alpha.2

- LICENSE holds the MIT License alone, so pub.dev recognizes it. The
  licenses of the bundled fonts (SIL OFL 1.1) and the Lucide icon shapes
  (ISC) move to NOTICES, which Flutter adds to an app's license page.
- The package links to its docs site: https://derlioapp.github.io/desen_ui/

## 0.1.0-alpha.1

First public pre-release. The API may still change before 1.0; see
[VERSIONING.md](VERSIONING.md) for what an alpha promises.

Requires Dart 3.13 and Flutter 3.47 or later. Built on the widgets layer
only: no Material or Cupertino dependency.

### Breaking

- The fonts are part of `desen_ui`: the separate `desen_ui_fonts` package
  is gone, and nothing needs to be added for Desen's typefaces.
  `DsTypography`'s `package` and `monoPackage` default to `'desen_ui'`
  (still applied only to Schibsted Grotesk and Geist Mono). The unused
  Schibsted Grotesk ExtraBold (800) is no longer shipped.

  | Before | After |
  |---|---|
  | `desen_ui_fonts` in the app's `pubspec.yaml` | Remove it |
  | `DsTypography.fontsPackage`, `DsFonts.package` | `'desen_ui'` |
  | `DsFonts.text`, `DsFonts.mono` | `'SchibstedGrotesk'`, `'GeistMono'` |
  | `fontFamily: 'packages/desen_ui_fonts/…'` | `'packages/desen_ui/…'` |
  | `FontWeight.w800` in Schibsted Grotesk | `FontWeight.w700` |

### Theme

- One brand color (`DsSeed`) generates every color role in OKLCH, in light
  and dark mode, with a contrast budget checked over every preset and
  random seeds: body text at least 4.5:1, control boundaries and focus
  rings at least 3:1 (WCAG 2.2 AA) at the `standard` contrast level.
- End-user settings: light, dark or system; contrast `soft` (iOS-like) or
  `standard`; corner style (sharp, standard, soft, pill) with continuous
  corners; density `compact` or `touch`, following the platform unless set.
- Typography: Schibsted Grotesk and Geist Mono bundled in the package
  (SIL Open Font License 1.1, see `fonts/`), the system font (San
  Francisco) in iOS and macOS apps, tabular figures on numbers.
- Customization at every level: adjust generated tokens (`adjustColors`,
  `adjustRadii`, …), component defaults for an app or a section
  (`DsComponentThemes`), per-instance styles, theme extensions, and
  headless behavior (`DsPressable`) for building your own controls.

### Components

Button, badge, count, status dot, avatar, image, card, divider, alert,
progress, spinner, skeleton, link, breadcrumb, checkbox, radio, radio card,
switch, segmented control, slider, chip, choice chips, tabs, accordion,
stepper, list, sidebar, bottom navigation, pane header, empty state,
pagination, toolbar, popover, tooltip, menu and context menu, submenu,
dialog, panel and sheet, toast, select, text field (single and
multi-line), search field, autocomplete, multi-select, number field, table,
scrollbar, calendar, date and date range picker, time picker, file upload,
text magnifier; `Form` integration (`DsFormField`, typed form fields,
`DsValidators`).

### Behavior and accessibility

- Keyboard support following the WAI-ARIA patterns; focus rings for
  keyboard users only; focus kept inside layers and returned to the
  control that opened them.
- Screen reader names, roles, states and announcements, tested per
  component.
- Large text up to 200% without clipped labels, 44px touch targets on
  phones, reduced motion, haptics on touch platforms.
- Strings for 13 languages (Arabic, Chinese, English, French, German,
  Hindi, Italian, Japanese, Korean, Portuguese, Russian, Spanish, Turkish)
  and 2 regional variants (Portuguese (Portugal), Traditional Chinese),
  with right-to-left layout.

### Known limitations

See [Known limitations](README.md#known-limitations) in the README.

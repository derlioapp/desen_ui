## 0.1.0-alpha.1

First public pre-release. The API may still change before 1.0; see
[VERSIONING.md](VERSIONING.md) for what an alpha promises.

Requires Dart 3.13 and Flutter 3.47 or later. Built on the widgets layer
only: no Material or Cupertino dependency.

### Theme

- One brand color (`DsSeed`) generates every color role in OKLCH, in light
  and dark mode, with a contrast budget checked over every preset and
  random seeds: body text at least 4.5:1, control boundaries and focus
  rings at least 3:1 (WCAG 2.2 AA) at the `standard` contrast level.
- End-user settings: light, dark or system; contrast `soft` (iOS-like) or
  `standard`; corner style (sharp, standard, soft, pill) with continuous
  corners; density `compact` or `touch`, following the platform unless set.
- Typography: Schibsted Grotesk and Geist Mono through the optional
  `desen_ui_fonts` package, the system font (San Francisco) in iOS and
  macOS apps, tabular figures on numbers.
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
- Strings for 15 languages (Arabic, Chinese (Simplified and Traditional),
  English, French, German, Hindi, Italian, Japanese, Korean, Portuguese
  (Brazil and Portugal), Russian, Spanish, Turkish), with right-to-left
  layout.

### Known limitations

See [Known limitations](README.md#known-limitations) in the README.

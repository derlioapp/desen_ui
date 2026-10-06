# Desen UI

Web-grade UI components for Flutter, built on the widgets layer only. No Material, no Cupertino.

**Docs and live examples:** https://derlioapp.github.io/desen_ui/

> Status: alpha (`0.1.0-alpha.2`). The API may still change before 1.0 ([VERSIONING.md](VERSIONING.md)). Requires Dart 3.13 and Flutter 3.47 or later.
>
> Foundation, overlay engine, localization (13 languages, plus Portuguese (Portugal) and Traditional Chinese) and 50 components plus form fields: button, badge, count, status dot, avatar, image, card, divider, alert, progress, spinner, skeleton, link, breadcrumb, checkbox, radio, radio card, switch, segmented control, slider, range slider, chip, choice chips, tabs, accordion, stepper, list, sidebar, bottom navigation, pane header, empty state, pagination, toolbar, popover, tooltip, menu and context menu, dialog, panel and sheet, toast, select, form field, text field (single and multi-line), search field, autocomplete, multi-select, number field, table, scrollbar, calendar, date and date range picker, time picker, file upload, submenu, text magnifier; `Form` integration (`DsFormField` and typed form fields, `DsValidators`).

## Principles

- **Widgets layer only.** `lib/` never imports `material.dart`, `cupertino.dart`, `material_ui` or `cupertino_ui` (enforced by a test).
- **No app wrapper required.** `DsApp` is optional; `DsScope` works under any root, including `MaterialApp`. Without either, components fall back to a default theme. Layers (menus, selects, comboboxes, popovers, pickers, dialogs, toasts) need an `Overlay`, and dialogs and panels a `Navigator`: any `WidgetsApp`, `MaterialApp` or `DsApp` provides both. A tooltip without an `Overlay` simply shows its control.
- **One seed, every role.** Colors and shadows are generated in OKLCH from a single brand color, with a clash rule that keeps selection distinct from danger and success.
- **End-user settings built in:** contrast (soft / standard), corner style (sharp / standard / soft / pill), density (compact / touch), light / dark / system.
- **Phones:** density follows the platform unless you pin it: iOS and Android get `DsDensity.touch` (44px tap areas while the visuals stay small, taller rows, body text 16/22), desktop and desktop browsers `DsDensity.compact` (24px targets per WCAG 2.5.8, body 14).
- **Keyboard focus** shows only for keyboard users (`:focus-visible`), as one line: fields turn their edge into a 2px focus edge (text fields on every focus, as browsers do for inputs), bordered controls swap their border for a 2px ring, filled controls get a ring with a small gap.

## Quick start

```yaml
dependencies:
  desen_ui: ^0.1.0-alpha.2
```

```dart
import 'package:desen_ui/desen_ui.dart';

void main() => runApp(
  DsApp(
    theme: DsThemeData(seed: DsSeed.navy),
    home: const HomePage(),
  ),
);
```

Inside an existing app:

```dart
DsScope(
  theme: DsThemeData(seed: DsSeed.color(const Color(0xFF2D4D8B))),
  child: child,
)
```

Buttons:

```dart
DsButton(onPressed: save, child: const Text('Save'))
DsButton(variant: .secondary, size: .sm, leading: const DsIcon(DsIcons.plus), onPressed: add, child: const Text('New task'))
DsButton.icon(icon: const DsIcon(DsIcons.ellipsis), semanticLabel: 'More', onPressed: openMenu)

// Customize one instance, a subtree, or build a new look on the same behavior:
DsButton(style: const DsButtonStyle(borderColor: brand), …)
DsButtonTheme(data: const DsButtonThemeData(size: .sm), child: …)
DsPressable(onPressed: …, builder: (context, states, _) => …)
```

Customizing generated tokens (survives dark mode, contrast, corner and density switches):

```dart
DsThemeData(
  seed: DsSeed.color(brand),
  adjustColors: (k, brightness) => k.copyWith(link: …),
  adjustRadii: (r, style) => r.copyWith(card: r.card + 4),
)
```

Component defaults for the whole app or one section (every component, one mechanism):

```dart
DsComponentThemes(
  themes: const [
    DsButtonThemeData(size: .sm),
    DsChipThemeData(style: DsChipStyle(height: 28)),
  ],
  child: app,
)
```

Floating layers are opaque. To make them frosted glass, give them a translucent fill and a backdrop filter. Keep the fill dense enough that text on it still reads over any content; the contrast budget assumes opaque layers.

```dart
import 'dart:ui' show ImageFilter;

final glass = ImageFilter.blur(sigmaX: 24, sigmaY: 24);
final fill = colors.overlay.withValues(alpha: .8);

DsComponentThemes(
  themes: [
    DsMenuThemeData(style: DsMenuStyle(background: fill, backdropFilter: glass)),
    DsPopoverThemeData(style: DsPopoverStyle(background: fill, backdropFilter: glass)),
    DsBottomNavThemeData(style: DsBottomNavStyle(background: fill, backdropFilter: glass)),
    // also DsDialog, DsPanel, DsToast, DsToolbar, DsTooltip, DsTextSelectionToolbar
  ],
  child: app,
)
```

`DsSurface` draws the same kind of box for your own floating layers.

Reading tokens:

```dart
final colors = DsTheme.colorsOf(context); // rebuilds only when colors change
final t = DsTheme.of(context);            // everything
```

## Fonts and icons

Desen bundles [Schibsted Grotesk](https://github.com/schibsted/schibsted-grotesk) for text and [Geist Mono](https://github.com/vercel/geist-font) for code, so they need no setup (SIL Open Font License 1.1, see [License](#license)). iOS and macOS apps set text in the system font (San Francisco) by default; pass a `family` to `DsTypography` to use another face there too. Built-in icons (`DsIcons`) are drawn from [Lucide](https://lucide.dev) shapes (ISC). Components take icons as widgets, so any icon set works.

## Testing your app

Keyboard focus visibility is global state, like the browser's `:focus-visible`. Desen resets it when the test binding resets between tests; to pin the starting value (for example, to test focus rings as a desktop user sees them first), call:

```dart
setUp(() => DsFocusVisibility.debugReset(keyboard: true));
```

## Known limitations

- `DsToolbar` has no "⋯" overflow menu: items that don't fit scroll with a faded edge. The touch text selection toolbar pages its actions with arrows, as iOS does.
- The time picker's hour column doesn't wrap from 23 to 00, and has no seconds or minimum and maximum time.
- Screen readers aren't told which menu item opens a submenu (needs a role Flutter doesn't expose yet).
- Screen readers announce the select as a button with its expanded state, and the number field as an adjustable text field: Flutter doesn't support the combobox and spin button roles yet.
- Plain `FormState.validate()` announces errors through Flutter's own unnamed announcement. `formKey.currentState!.validateAndFocus()` (from `DsFormValidation`) focuses the first invalid field and announces it once, with its name.
- VoiceOver users who turned hints off don't hear a field's description or error, which are attached as hints.
- Visual references (golden images) are rendered on macOS and checked by hand on the web and macOS; iOS and Android have not yet been checked on physical devices.

## Layout

| Path | Contents |
|---|---|
| `lib/src/foundation/` | OKLCH conversion, contrast helpers, SVG path parser |
| `lib/src/icons/` | `DsIcon`, `DsIcons` |
| `lib/src/painting/` | `DsShadow` (with inset), `DsBoxDecoration`, `DsSurface` |
| `lib/src/theme/` | Palette engine, color roles, shadows, radii, sizes, motion, typography, `DsTheme`, `DsScope` |
| `lib/src/app/` | `DsApp`, `DsPageRoute`, `DsScrollBehavior` |
| `lib/src/behavior/` | Headless behavior (`DsPressable`, `DsMinTapTarget`, `DsFocusVisibility`) |
| `lib/src/overlay/` | Anchored layers (`DsAnchoredOverlay`, placement), modal route |
| `lib/src/l10n/` | `DsLocalizations` (13 languages and 2 regional variants, generated) |
| `lib/src/components/` | Styled components |
| `fonts/` | Schibsted Grotesk and Geist Mono, with their licenses (SIL OFL 1.1) |
| `VERSIONING.md` | What counts as a breaking change, pre-1.0 rules, deprecation |
| `example/` | The docs site (`example/lib/site/`, English, built with Desen): every component with live examples and code, foundations, guides and app examples |

## Development

Main stays green: `flutter analyze`, the format check and the full `flutter test` run before every commit (about 40 seconds). A new test must fail without its fix. Goldens are re-baselined only after reviewing the diff images, in a commit of their own.

```sh
flutter test                                  # everything
flutter test --tags golden                    # visual regression only
flutter test --update-goldens --tags golden   # after an intended visual change; review the PNGs
tool/native_snapshot.sh /tmp dark             # native macOS (Impeller) render of the example
python3 tool/gen_colors.py lib/src/theme/colors.dart  # regenerate DsColors
python3 tool/gen_icons.py lib/src/icons/icons.dart     # regenerate DsIcons
python3 tool/gen_styles.py                            # regenerate component styles/themes
python3 tool/gen_l10n.py                              # regenerate DsLocalizations
```

## License

The code is under the MIT License ([LICENSE](LICENSE)). The font files in `fonts/` are not: they are under the SIL Open Font License 1.1, which allows bundling and embedding them in any app, free or commercial. Its text is in `fonts/` and in [NOTICES](NOTICES), which Flutter adds to your app's license page (`showLicensePage`, `LicenseRegistry`) on its own.

- Schibsted Grotesk: Copyright 2023 The Schibsted-Grotesk Project Authors; license text in `fonts/OFL-SchibstedGrotesk.txt`.
- Geist Mono: Copyright 2024 The Geist Project Authors; license text in `fonts/OFL-GeistMono.txt`.

The icon shapes are from [Lucide](https://lucide.dev) (ISC License, included in [NOTICES](NOTICES)).

# Desen UI

Web-grade UI components for Flutter, built on the widgets layer only. No Material, no Cupertino.

> Status: early development (0.1.0-dev). Foundation, overlay engine, localization (13 languages) and 49 components plus form fields are in place: button, badge, count, status dot, avatar, image, card, divider, alert, progress, spinner, skeleton, link, breadcrumb, checkbox, radio, radio card, switch, segmented control, slider, chip, choice chips, tabs, accordion, stepper, list, sidebar, bottom navigation, pane header, empty state, pagination, toolbar, popover, tooltip, menu and context menu, dialog, panel and sheet, toast, select, form field, text field (single and multi-line), search field, autocomplete, multi-select, number field, table, scrollbar, calendar, date and date range picker, time picker, file upload, submenu, text magnifier; `Form` integration (`DsFormField` and typed form fields, `DsValidators`).

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
  desen_ui: ...
  desen_ui_fonts: ...   # optional: Desen's typefaces (Schibsted Grotesk, Geist Mono)
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
DsButton(onPressed: save, child: const Text('Kaydet'))
DsButton(variant: .secondary, size: .sm, leading: const DsIcon(DsIcons.plus), onPressed: add, child: const Text('Yeni görev'))
DsButton.icon(icon: const DsIcon(DsIcons.ellipsis), semanticLabel: 'Daha fazla', onPressed: openMenu)

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

The optional `desen_ui_fonts` package bundles [Schibsted Grotesk](https://github.com/schibsted/schibsted-grotesk) and [Geist Mono](https://github.com/vercel/geist-font), both under the SIL Open Font License 1.1 (see `desen_ui_fonts/fonts/OFL-*.txt`). Without it, text uses the platform font. iOS and macOS apps set text in the system font (San Francisco) by default either way; pass a `family` to `DsTypography` to use another face there too. Built-in icons (`DsIcons`) are drawn from [Lucide](https://lucide.dev) shapes (ISC). Components take icons as widgets, so any icon set works.

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
| `lib/src/l10n/` | `DsLocalizations` (13 languages, generated) |
| `lib/src/components/` | Styled components |
| `desen_ui_fonts/` | Optional font package |
| `VERSIONING.md` | What counts as a breaking change, pre-1.0 rules, deprecation |
| `example/` | The docs site (`example/lib/site/`, English, built with Desen): every component with live examples and code, foundations, guides and app examples |

## Development

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

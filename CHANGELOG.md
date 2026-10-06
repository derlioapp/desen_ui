## Unreleased · Independent audit fixes

### Breaking

- `DsTypography`'s default `desen_ui_fonts` package applies only to the
  faces it bundles; a family of your own is looked up in your app (it was
  silently looked up in the fonts package). New `monoPackage` and
  `DsTypography.fontsPackage`.
- `DsBottomNav` destinations are buttons, the current one selected, with
  their position ("2 of 4", new `DsLocalizations.positionOf`) read on every
  platform; they were tabs in a tab bar, which misused the role inside a
  navigation landmark.
- `DsChip` is announced as a checkbox, checked or not (it was a selected
  button, which the web read as "current").
- `DsNumberFormat.tryParse` returns a number only when the text reads one
  way; misplaced or ambiguous grouping now returns null instead of being
  stripped.

### Added

- `DsTextField`, `.multiline` and `DsTextFormField`: `autocorrect`,
  `enableSuggestions`, `textCapitalization`, `textAlign`,
  `onEditingComplete`. Email, URL and password fields no longer autocorrect
  or suggest by default.
- `DsApp` and `DsApp.router`: `localeResolutionCallback`,
  `localeListResolutionCallback`, `scrollBehavior`,
  `followPlatformContrast`, `animateChanges`.
- `DsThemeData.densityFollowsPlatform`: a theme without an explicit density
  derives it again on `copyWith(platform:)`.
- `DsFocusVisibility.debugReset({bool? keyboard})` for widget tests.
- `DsMenuItem.checkRole` (`DsMenuCheckRole.radio` or `.checkbox`).
- `DsShortcut.spokenLabel`: shortcut hints are read by localized key name
  ("Command E"). New strings `keyCommand`, `keyOption`, `keyShift`,
  `keyControl`, `keyBackspace`, `keyEnter`.
- `DsTab.countSemanticLabel` and `DsSidebarItem.countSemanticLabel` say what
  a count counts ("4 unread").
- `DsNumberFormat.readings` and `DsNumberFormat.maxDecimals` (20); new
  string `numberAmbiguous`.
- `DsProgressBarStyle.width` (default 160) under an unbounded width.

### Changed

- Dialogs, panels and popovers opened without an `autofocus` control move
  focus to their first control (WAI-ARIA dialog pattern).
- Tab no longer interleaves a sidebar, toolbar, pagination, breadcrumb,
  accordion or table with the content beside it; `DsSidebar` is a
  navigation landmark named by `semanticLabel` or the localized
  "Navigation".
- Fields with their own buttons (clear, show password, date and time
  pickers, autocomplete, multi-select, file upload) carry their description
  or error on the input for screen readers; every field reads its message
  after its name and state, and checkbox, radio, radio card and switch
  descriptions are read as hints. `validateAndFocus` is heard once, on the
  focused field with its name.
- `DsTheme` and component themes are `InheritedTheme`s (carried into
  Flutter's own dialogs and third-party sheets); `DsComponentThemes` keeps
  its subtree's state when its list changes; a change to theme extensions
  alone no longer rebuilds components; without `DsScope` or `DsApp` the
  fallback theme follows reduce motion.
- Numeric text keeps tabular figures on digits only; separators keep the
  face's own spacing, so "12.480,00" no longer reads like a typewriter.
- Tabs answer taps across their cell, up to half the gap on each side; on
  touch, short tabs are widened to a 44px cell, and the segmented control
  and table sort headers answer taps across 44px without growing.
- Large text: segmented-control labels wrap between words, then the
  segments stack; bottom-nav labels wrap to two lines between words, and a
  label that still doesn't fit shows whole in a tooltip; table flex columns
  keep the text they showed at 1.0 and the table scrolls sideways.
- `DsToolbar` scrolls its items with a faded edge when they don't fit;
  `DsCalendar(months: n)` stacks its months when they are too narrow;
  multi-select tags wrap long labels; a single-line text field fades the
  edge that hides an overflowing value while it is not being edited; the
  touch text selection toolbar pages its actions with chevrons.
- Dark mode: the date range band (`accentTint`) stands 1.3:1 or more off
  the card. A checked control whose accent fill stands under 3:1 off the
  page or card at rest (a deep red) wears a faint light `accentEdge`,
  strong enough for its hovered and pressed states too; in a field well and
  on the floating layer the check mark carries the state, so no rim is
  drawn there. Dark accent text (`accentText`, `link`, `focus`) is a touch
  lighter, so today's number reads 4.5:1 on the range band.
- Warm and bright brand colors no longer produce muddy marks. In light mode
  a yellow or amber brand's progress and slider fill, tab underline, caret
  and focus outline turn to a vivid deep orange at the same contrast,
  instead of mustard or olive; in dark mode they stay a clear yellow. The
  date range band is a pale butter in light mode and a neutral wash in dark
  mode for warm brands. Avatar tones skip olive, khaki and brown hues.
- Calendar: the chosen day and range ends use a checked control's accent
  colors (`accent`, `onAccent`, `accentHover`, `accentPress`,
  `accentEdge`) instead of `selectionStrong`; pressed now steps to
  `accentPress`.
- Table Shift range selection keeps its anchor, so moving back shrinks it.

### Fixed

- Floating layers whose trigger is kept alive off screen in a lazy list
  (a focused field, a table's active row) close and return focus instead
  of painting at a NaN position and staying open; `validateAndFocus()` no
  longer throws in that case.
- `DsTabs` revealing its selected tab scrolled the whole page; only the
  strip scrolls now.
- `DsTooltip` no longer pops up during a touch scroll that starts on its
  trigger.
- Keyboard focus visibility no longer leaks between an app's widget tests.
- A keypad "." in a locale where "." groups thousands is the decimal point
  where it can't be a group ("12.5" is 12.5, not 125); text that reads two
  ways is flagged instead of guessed. A grouped paste into an ungrouped
  field keeps its digits; typed integers past what a double holds exactly
  are flagged instead of changed. `format` shows infinities as ∞ and NaN as
  empty text.
- Slider divisions report exact grid values (0.3, not 0.30000000000000004).
- Progress bar and ring: NaN is indeterminate (it was drawn and announced
  as 100%).
- `DsStepper`: `max: double.infinity` means no limit (the int stepper threw
  in build); a fractional `step` on an int stepper is rounded to a whole
  one; in too little room the value scales down instead of overflowing.
- `DsProgressBar`, `DsAlert` and `DsAccordion` no longer throw under an
  unbounded width; the dialog's actions support dry layout.

## Unreleased · Parity with the old library

### Breaking

- `DsSidebar` and `DsSidebarItem` are generic (`T extends Object`) for the
  value API; untyped calls infer `Object` and keep compiling.
- `DsStepper` is generic, `DsStepper<T extends num>`, inferred from
  `value`, so existing int steppers compile unchanged; `find.byType` must
  name the type argument (`DsStepper<int>`).
- A `DsThemeData` without a `density` follows the platform: `touch` on iOS
  and Android (their browsers included), `compact` on desktop. Pass
  `density: DsDensity.compact` to keep the old default on phones.
- `DsShadows.field` is removed: no component drew it (fields draw their
  edge from their style's `borderColor`, which is `borderField`). Change
  the edge with `adjustColors` (`borderField`) or `DsTextFieldTheme`.
- `DsTypography.package` is now the package of `family` only; the mono
  family has its own `monoPackage`. In iOS and macOS apps (not on the web),
  `DsTypography()` without a `family` sets text in the system font (San
  Francisco) instead of Schibsted Grotesk; pass
  `family: 'SchibstedGrotesk'` to keep it. `DsTypography.raw` takes
  `monoPackage`, `displayFamily`, `displayPackage` and `density`.
- `defaultStyle(...).borderRadius` is now `null` for `DsToolbar`,
  `DsToolbarToggle` and the floating `DsBottomNav` and its items, as are
  `DsAutocomplete.defaultStyle(...).tagBorderRadius` and
  `tagRemoveStyle.borderRadius`: these corners resolve at build time.
- The `defaultStyle(...).borderRadius` of controls rounded by height is now
  `null`: the control applies `DsRadii.controlCorners` to the height it
  resolves to (see Changed).

### Added

- Sidebar: `collapsed` narrows `DsSidebar` to an icon rail. Labels show as
  tooltips on hover and keyboard focus, counts as dots, section labels as
  lines. The width moves with the theme's move spring and jumps under
  reduced motion. Labels, counts and the current page stay announced. New
  `DsSidebarStyle.collapsedWidth`, `dividerColor`, `dividerPadding`,
  `DsSidebarItemStyle.dotSize`, and `DsSidebar.collapsedOf`.
- Sidebar: value API. `DsSidebar.value` / `onChanged` select items by
  `DsSidebarItem.value`; `selected` / `onPressed` keep working.
- List row: `DsListRow.selected` for master-detail lists. It takes the
  theme's selection style, keeps a visible hover, and is announced as
  selected. New `DsListRowStyle.borderColor` and `selected` state.
- Tooltip: `DsTooltip.excludeFromSemantics`, for a message that repeats the
  control's own label.
- Haptics: `DsThemeData.haptics` (`DsHaptics.none` / `subtle` / `full`;
  null follows the platform: subtle on iOS and Android, none on the web and
  desktop) and `DsHapticFeedback.play`. `DsPressable.haptic` takes a
  `DsHapticEvent` (`command` by default; null for silence). Toggles,
  choices, tabs, segments, steppers, number-field steps, stepped-slider
  detents, calendar days, time-picker values and select/autocomplete
  options tick under `subtle`; buttons and other commands play only under
  `full`. Only touch and pointer changes tick; keyboard changes are silent,
  as on iOS.
- The touch text magnifier `DsTextMagnifier`: text fields show it on iOS
  and Android while a handle is dragged or a long press selects. Style it
  with `DsTextMagnifierTheme` / `DsTextMagnifierStyle`.
- `DsImage` and `DsImage.network`: a reserved box (a size or an aspect
  ratio is required), a skeleton while loading, a short fade-in and an
  "Image unavailable" state, with continuous theme corners; decodes at the
  box size. New `DsIcons.imageOff` and the `imageUnavailable` string.
- App tokens: `DsThemeExtension`, `DsThemeData(extensions:)`,
  `extension<T>()` and `DsTheme.extensionOf<T>()`. Extensions resolve
  against the theme (mode, contrast, density), interpolate in animated
  theme changes and count in equality.
- `scrim: DsScrim.clear` on `showDsModal` and `showDsPanel` for
  live-preview sheets: a transparent barrier that still dismisses.
- `animate: false` on `DsProgressBar` and `DsProgressRing` for scroll- or
  gesture-driven values.
- `DsScrollbar` with `DsScrollbarStyle` and `DsScrollbarTheme`
  (`alwaysVisible`); `DsScrollBehavior` uses it on desktop.
- `DsThemeData.warningOverride`, calibrated like the danger and success
  overrides.
- `DsSpace.s32`, `s40`, `s48` and `s64` for layout.
- `DsBreadcrumbItem.icon`, with `DsBreadcrumbStyle.iconSize` / `iconGap`.
- `DsChoiceChips<T>` and `DsChipOption<T>`: a single-choice chip row (a
  radio group) that looks like `DsChip`. One Tab stop, arrows mirrored in
  RTL, Home/End; it scrolls when it overflows and keeps the selected chip
  in view.
- `DsRadioCard<T>`, `DsRadioCardStyle` and `DsRadioCardTheme`: a radio
  option drawn as a card inside `DsRadioGroup`, following the theme's
  selection style.
- `description` on `DsCheckbox` and `DsRadio`; `DsCheckboxStyle` and
  `DsRadioStyle` gain `descriptionStyle` and `textGap`.
- `DsStepper` takes decimal values: `min`, `max` and `step` are `num`,
  with `format: DsNumberFormat?`, `unit` and `prefix` (shown smaller,
  mirrored in RTL, read with the value); `DsStepperStyle` gains
  `unitStyle` and `unitGap`.
- `DsRadioGroup`: Home and End select the first and last enabled option;
  Left and Right mirror in RTL. Applies to radios and radio cards.
- Typography: a touch type ramp. `DsTypography(density:)` and
  `forDensity`; `DsThemeData` sets its typography for its density (touch:
  body 16 on a 22px line, every role a step up). Roles replaced with
  `copyWith` keep their values at every density.
- Typography: `displayFamily` / `displayPackage` set `display` and `title`
  in another face, e.g. a serif; `numeric()` keeps titles in it.
- Typography: `controlLabel(DsSize)`, the label style buttons use;
  `DsTypography.systemFamily` / `systemDisplayFamily`.
- Button: `neutral` variant, an ink fill (near-black in light mode, soft
  white in dark mode) with the label in the inverse ink; and `inverse` for
  accent grounds: the accent's label color as fill, an accent label, and a
  focus ring that shows on the accent.
- `DsPressEffect`: turns the press scale of a subtree off (or back on);
  buttons and stepper buttons follow it, reduced motion still wins.
- `DsFocusRing`: the theme's keyboard focus ring around a control of your
  own, with given corners, without changing layout.
- `DsFieldSurface`: the bare text field box (fill, edge, corners by height,
  focus, error, read-only and disabled looks) for field-like controls; it
  follows the text field theme. Text field, select and autocomplete now
  draw their well through one shared painter (no visual change).
- Bottom nav: `DsBottomNavItem.enabled`; a disabled destination is dimmed,
  skipped by taps, Tab and the arrow keys, and announced as disabled. New
  `DsBottomNavItemStyle.disabled`.
- Bottom nav: the bar is one Tab stop (the current destination). Left and
  Right (mirrored in RTL), Home and End move focus; Enter or Space chooses
  (manual activation, since each destination swaps the whole screen).
- Bottom nav: a navigation landmark named by `semanticLabel` or the new
  localized `DsLocalizations.navigation`; destinations are tabs in a tab
  bar.
- Tabs and bottom nav: on iOS and Android each tab also announces its
  position ("Tab 2 of 4", new `DsLocalizations.tabOf`); on the web the tab
  role does.
- Card: `DsCard(dashed: true)`, an empty slot or drop target with a dashed
  outline in the form boundary color (3:1) along the card corners, filling
  and darkening on hover when pressable. New `DsCardStyle.dashed`,
  `borderColor`, `borderWidth`, `dashLength`, `dashGap`.
- `showDsDialog(scrim:)`, as on `showDsModal` and `showDsPanel`.
- `DsTextMagnifier.controller`: the loupe fades out (and shrinks unless
  motion is reduced) instead of vanishing.
- `DsDensity.forPlatform`, the density a theme takes when none is given.
- `DsRadii.controlCorners` and `DsRadii.nestedCorners`.
- `VERSIONING.md`: what counts as breaking, the pre-1.0 rules, deprecation,
  and how `desen_ui_fonts` is versioned.
- A CI workflow (`.github/workflows/ci.yml`), and a corner benchmark in the
  example (`--dart-define=DS_BENCH=true`, `tool/corner_bench.sh`);
  `--dart-define=DS_PLAIN_CORNERS=true` draws plain rounded rectangles to
  compare against.

### Changed

- Continuous corners raster as fast as plain rounded rectangles: a box
  whose pieces all sit on or under an opaque fill draws with the engine's
  direct superellipse instead of a path, and blurred shadows take a
  rounded rectangle (the blur hides the curve). A box with a see-through
  fill or a gapped ring keeps paths so its pieces still meet exactly. On
  the dense benchmark (300 cards, macOS, 120 Hz) mean raster time fell from
  3.0 to 1.0 ms and frames over budget from 118 to 2. Pixels move only at
  corner edges.
- The toolbar's corner follows its toggles' resolved size and padding, and
  the floating bottom nav's its items' resolved height; toggles, toolbar
  buttons, nav items, multi-select tags and their remove buttons stay
  concentric. A radius set in `DsButtonTheme` wins for toolbar buttons.
- A bottom nav with `onChanged: null` shows the disabled look.
- The file drop zone's dashed edge uses the form boundary color (3:1) and
  darkens on hover and press, like the dashed card.
- At touch density, text in button, chip, badge, alert, breadcrumb,
  segmented control, checkbox, radio, switch, radio card, tooltip shortcut
  and file upload follows the touch ramp. Compact density looks the same.
- In iOS and macOS apps the system font uses Apple's tracking for each
  size, and its display cut for titles.
- Control corners follow the height a control ends up with: a style that
  sets only a height keeps the proportion and stays a capsule in the pill
  style; an explicit `borderRadius` wins. Covers buttons, text, number,
  date, time and search fields, select, autocomplete, chip, tooltip,
  pagination, sidebar item, calendar day, empty-state and dialog icon
  boxes, segmented control, stepper and the flat bottom-nav item. The
  segmented thumb, stepper buttons and search shortcut cap stay concentric
  with their container's resolved corners, an explicit one included.

### Fixed

- The text selection toolbar's buttons no longer stretch to the window's
  height on touch platforms, where they covered the selection handles.


## Unreleased · Continuous corners and hairlines

### Breaking

| Before | After |
|---|---|
| `DsContrast.high` | removed; `standard` (WCAG AA, 1.4.11 included) is the strongest level |

### Added

- `DsShadow(hairline: true)` (also on `ring`, `innerRing`, `topLine`,
  `bottomLine`): lengths in device pixels, color strengthened to carry the
  same ink as the logical-pixel line. `DsShadow.resolve(dpr)` and
  `DsShadow.hairlineColor`.
- `DsLine`: a separator, a hairline in a one-pixel slot.
- `DsShapeClip`: clips to the outline `DsBoxDecoration` paints.
- `DsContrast.soft`: the iOS look. Text and focus as at standard; the text
  field, checkbox and radio edge at about 1.5:1, the switch's off track and
  the slider track as light fills, lighter chip and button edges. Knowingly
  below WCAG 1.4.11 for those control boundaries.
- `DsThemeData.fillsSelection`: whether selected items are filled (the
  strong selection style).
- `DsScope` follows the browser's `prefers-contrast: more` on the web, as it
  follows `MediaQueryData.highContrast` elsewhere.

### Changed

- Dark mode: `channelThumb` (the selected segment, stepper buttons) is a
  translucent white layer instead of a fixed gray, so it stands off its
  channel the same on every layer; on a floating layer it had all but
  vanished.
- `DsSegmentedControl` no longer cuts a label while there is room for all
  of them: when equal segments do not fit, each takes its own width plus
  an equal share of the rest; only narrower still do labels ellipsize.
- Contrast has two levels, soft and standard. The high level is gone: it
  made every screen busier. Following the platform's contrast (iOS
  "Increase contrast", Android high-contrast text, Windows contrast themes,
  the browser's `prefers-contrast: more`) now lifts a soft theme to
  standard; a standard theme stays as it is.
- `DsThemeData.selectedEdge` is only the edge a bright filled selection
  needs off a light card.

- Corners are continuous (rounded superellipse) everywhere `DsBoxDecoration`
  draws, clips or hit tests, and in the components' own clips. Capsules and
  circles keep true half-circle ends. Every golden changed.
- Decorative lines are one device pixel wide: card, layer, sidebar and
  segmented-thumb edges, and the separators of lists, menus, toolbars, tabs,
  tables, accordions, pane headers, the bottom bar, the time picker and the
  text selection toolbar. Functional edges (fields, checkbox, radio, switch,
  buttons, chips, focus rings) keep their widths.

### Corner rules (breaking)

Corners follow three rules instead of a list of per-component radii, and a
corner style only changes their numbers:

1. Controls are rounded by their height: `radii.control(height)` is
   `height × controlFactor` (sharp 0.1, standard 0.25, soft 0.375, pill
   0.5). Every button size, text and search fields, select and picker
   triggers, number field, chips, segmented control, stepper, toolbar,
   tooltips, calendar days, icon boxes, pagination items, sidebar items and
   the floating bottom navigation follow it. A field and a button of the
   same height match; in the pill style every control is a capsule, text
   fields included.
2. Containers have one radius: `card` for cards, list sections, tables,
   alerts, accordions, file upload; `overlay` for menus, popovers, dialogs,
   panels and sheets, toasts, the text selection toolbar (sharp 4,
   standard 14, soft 21, pill 14). Dialogs and panels now read `overlay`.
3. Nested pieces derive from what holds them: `radii.nested(outer, inset)`
   is `outer − inset`, at least `nestedMin` (sharp 2, standard 4, soft 6,
   pill 4), at most `outer`. Segmented thumb, stepper buttons, toolbar
   toggles, menu, list, time picker and text selection rows, floating
   bottom-navigation items, multi-select tags and their remove button,
   the search field's shortcut key cap and skeleton blocks follow it.

The checkbox rounds by its size, `radii.checkbox(size)` (sharp 0.1,
standard 0.28, soft and pill a third), and never past
`DsRadii.maxCheckboxFactor` (1/3), so it never becomes a circle. Focus
rings around a line of text (links, breadcrumbs, tab labels) take
`control(20)`; the table header's ring `control(headerHeight)`.

| Before | After |
|---|---|
| `DsRadii.control` (a number) | `DsRadii.control(height)` (a method), from `controlFactor` |
| `DsRadii.field`, `day`, `tooltip`, `iconBox`, `bottomNav` | `control(height)` of the component's height |
| `DsRadii.controlInner`, `channelThumb`, `item`, `cardInner`, `bottomNavItem` | `nested(outer, inset)` |
| `DsRadii.checkbox` (a number) | `DsRadii.checkbox(size)` (a method), from `checkboxFactor` |
| `DsRadii.card`, `overlay` | unchanged |
| `DsRadii.pill` | unchanged: a radius for shapes round in every style (progress, badges, slider track, grabber) |
| `DsRadii(...)` with 14 radii | `DsRadii(controlFactor:, card:, overlay:, checkboxFactor:, nestedMin:)` |
| `copyWith`, `lerp`, `==` over the 14 radii | over the five values |
| — | `DsRadii.maxCheckboxFactor` |

Visible changes at the default style: extra-small buttons 7 (was 10),
small buttons, chips and pagination items 8 (was 10), large buttons 12; the segmented channel and stepper track 9.5 (their 38px
height) with 6.5 inside; list rows 9 (was 8); time picker and text
selection rows 10 (was 8); dialog icon box 10 (was 12); floating bottom
navigation 15 with 10 items (was 18 and 13); toolbar 10.5 with 5.5
toggles (was 10 and 10); multi-select tags 4 (was 7); skeleton blocks 4
(was 8); search shortcut key cap 4 (was 6). Every golden showing these
changed; `corner_styles_light.png` shows all four styles side by side.

## Unreleased (0.1.0-dev.11) · API review

A review of the whole public API before it settles. Every change below is
breaking; there are no deprecated aliases. Rename as the table says.

### Components

| Before | After |
|---|---|
| `DsCalendar.range(value:, onChanged:)` | `DsRangeCalendar(value:, onChanged:)` with a typed `DsDateRange?` |
| `DsMenuItem(selected:)` | removed; use `checked:` |
| `DsAvatar(contentInsetEnd:)` | removed (internal to `DsAvatarGroup`) |
| `DsSidebarItem(icon:)` | `leading:` |
| `DsListRow(value:)`, `DsListRowStyle.valueStyle` | `detail:`, `detailStyle` |
| `DsSelectOption(hint:)` | `detail:` |
| `DsFileUpload(hint:)`, `DsFileUploadStyle.hintStyle` | `description:`, `descriptionStyle` |
| `DsSearchField(shortcutHint:)` | `shortcut:` |
| `onInvalid` (number field, date, date range and time pickers) | `onInputIssueChanged` |
| `showDsConfirm(message:)` | `description:` |
| `DsPopover(content:)` | `contentBuilder:` |
| `DsButton(expanded:)` | `semanticExpanded:` |
| `DsToolbarSeparator`, `separatorColor`, `separatorHeight` | `DsToolbarDivider`, `dividerColor`, `dividerHeight` |
| `DsTable(rowMenuBuilder: (item) => …)` | `(context, item) => …` |
| `DsTable(controller:)` | `scrollController:` |
| `onCustom` (autocomplete, multi-select and their form fields) | `onCreate` |
| `DsBreadcrumbItem('Label', …)` | `DsBreadcrumbItem(label: 'Label', …)` |
| `DsShortcut(style:)` | `textStyle:` |
| `DsTableStyle.messageStyle` | `emptyStateStyle` |
| `DsNumberFieldStyle.field` | `fieldStyle` |
| `DsSwitchStyle.padding` | `inset` |
| `X.defaultStyle(theme, variant, size)` and other positional extras | named: `defaultStyle(theme, variant: …, size: …)` (button, text field, alert, badge, status dot, count, avatar, bottom nav) |
| `DsFieldHooks` (a `ChangeNotifier`) | `final class` with `setMessageEnd`, `setInputIssue`, `separateNodes`, `inputIssue` |
| `DsFieldScope.labelled` | `isLabelled` |
| `AnimatedDsTheme` | `DsAnimatedTheme` |
| `DsPagination.slots`, `DsFocusVisibility.initialFor`, `.reset`, `DsSizes.isTouchPlatform`, `DsMergeable`, `DsColorTween`, `DsThemeAspect` | no longer public |

### Tokens

| Before | After |
|---|---|
| `DsColors.focusRing`, `DsShadows.focus` | removed (focus is one line; use `focusOffset`, `focusTight`) |
| `DsShadows.content`, `contentRaised`, `floating`, `primary` | `surface`, `surfaceRaised`, `overlay`, `accent` |
| `DsColors.track`, `trackStrong`, `thumb`; `DsShadows.track`, `thumb` | `channel`, `channelStrong`, `channelThumb` |
| `DsRadii.inner` | `channelThumb` |
| `DsMotion.fast`, `fastCurve`, `movement`, `spring`, `noticeDuration` | `toneDuration`, `toneCurve`, `moveDuration`, `moveCurve`, `toastDuration` |
| `DsMotion.fade` | removed (same as `toneDuration`) |
| `DsSelectionStyle.fill` | `DsSelectionStyle.strong` |
| `DsSurface(filter:)` | `backdropFilter:` |
| `static DsSizes.iconSize(size)` | instance `sizes.iconSize(size)`, with `iconXs`…`iconLg` adjustable through `adjustSizes` |

### Added

* The theme can default `DsAvatar` and `DsAvatarGroup` sizes and the
  `DsBottomNav` variant (`DsAvatarThemeData.size`,
  `DsBottomNavThemeData.variant` and `variants`).
* `DsDivider` and `DsDivider.vertical`: a line in the `border` color with
  insets that follow the text direction, styled with `DsDividerStyle` and
  `DsDividerTheme`. Decorative for screen readers.
* `DsButtonVariant.tinted`: accent text on a light wash of the accent (15%
  in light mode, 18% in dark mode), deeper on hover and press, with an
  edge in its text color at high contrast. The label keeps 4.5:1 on every
  layer.
* Localization keys `delete`, `scanText`, `editAction` and `pageCounter`
  in all 13 languages and their variants. Classes that implement
  `DsLocalizations` directly need them; ones extending
  `DsLocalizationsEn` get the English text.
* `DsStatusColors.signal`: a vivid status color, like iOS's system colors,
  for marks with no text on them. Status dots, the avatar status dot, alert
  and toast icons and the file item's icons use it. It stands 3:1 off the
  page, surfaces and floating layers. Hand-built `DsStatusColors` need it.

### Changed

* Clearer colors. The blue preset is the most vivid blue that carries a
  white label at AA (`oklch(.565 .20 257)`, #0170E8). In dark mode a
  white-label accent keeps the light chroma, so the dark accent is as vivid
  as the light one. Danger is a clean red in both modes, and dark warning
  is a clear amber.
* Light status tints are opaque, so they read the same on the page and on
  a card (warning no longer turns khaki). Dark status tints are a little
  lighter and more saturated, with vivid status text on them.
* In dark mode `DsAlert` is a neutral raised block with a vivid icon and a
  title in the status color, not a deep status tint.
  `DsAlert.iconColor(status, background)` now takes the alert's opaque
  background.
* Light text tiers sit further apart: secondary text about 6.4:1 on a
  card, tertiary about 5.2:1.

* Dark mode tertiary text (`textSubtle`) sits a clear step below secondary
  text, as in light mode (about 6.3:1 on a card). Menu shortcuts and select
  option details use secondary text, so they stay readable on a
  highlighted row.
* API docs no longer cite internal rule or audit numbers. Building token
  classes by hand and implementing `DsLocalizations` directly are outside
  the compatibility promise; customize through `DsThemeData(adjust…)` and
  by extending `DsLocalizationsEn`.
* The touch edit toolbar names Delete and Live Text ("Scan text") in the
  app's language, and an app's own action without a label reads "Action"
  instead of showing an empty button.
* The slider thumb loses its grey outline at standard contrast: it is the
  switch's knob, white with a soft shadow. High contrast keeps the
  outline.
* The compact pager's "3 / 10" comes from `pageCounter`.

## Unreleased (0.1.0-dev.10) · Docs site and clearer colors

### Added

* The example app is now the documentation site: every component with live
  examples and the code that runs them, foundations, guides and three app
  screens. `cd example && flutter run -d chrome`.
* `DsLink(inline: true)` for links inside running text.
* `DsWidgetsLocalizations`: `DsApp` lays right-to-left languages out RTL
  without `flutter_localizations`.
* `DsIcons.all`; icons `moon` and `menu`.
* `DsAutocomplete`/`DsMultiSelect` `emptyText` and `loadingText`; with
  `onCustom` an empty list offers the typed text.
* `DsBreadcrumb(overflow:)` with a collapsing "…" menu.
* `DsTable.showRowMenuButton`; `DsSkeleton.block`; `affixGap` on text field
  styles; `DsAvatar.statusLabel`.

### Changed

* Neutrals (page, surfaces, text, borders, channels, shadows) no longer take
  the brand color's hue; every brand shares one cool slate gray.
* Dark mode keeps vivid accents: at least 85% of the seed's chroma (up to
  0.21) instead of a fixed 0.148 cap.
* Dark mode soft selection: cool brands keep their color, warm brands
  select in gray with the brand in the text. Status tints are deep opaque
  colors.
* Light mode channel, neutral soft fill and disabled fill are translucent
  and lighter.
* Links and breadcrumb levels activate on Enter only.
* A checked menu item draws a leading check; the select's check moved there
  too.
* Counts cap at "99+" everywhere; avatar status is announced.
* Table cards sort from one "Sort by" menu button, so the bar above the
  cards keeps one line at any width.
* Dates follow CLDR by language and region: the 24-hour clock in fr_CA and
  other regions, day-first medium and full dates outside the US (en_GB
  "4 Mar 2026"), spelled months in Japanese and Korean medium dates.
  `DsDateLocale` gains `mediumDatePattern` and `fullDatePattern`.

### Fixed

* `dismissible: false` dialogs and panels ignore the system back gesture.
* A required date, time or number field shows its own parse message.
* Two-month calendars line up; breadcrumb chevrons never start a line; a
  control with a two-line label sits on the first line; select and text
  field line up on touch platforms; numeric table headers line up with
  their values.
* On touch, a collapsed breadcrumb's "…" keeps the same gaps as other
  levels and still takes taps across 44px.
* Trailing text in a field (".desen.app", "kg") sits as close to the value
  as leading text.

## Unreleased (0.1.0-dev.9) · Polish round

### Added

* Floating layers (menu, popover, dialog, panel, toast, toolbar, tooltip,
  edit toolbar, bottom nav) take a `backdropFilter` style field: with a
  translucent `background` they become frosted glass. They stay opaque by
  default. `DsSurface` draws the same box for your own layers.
* `DsShadows.focusTight`, `DsTextFieldStyle.readOnly`,
  `DsTextFieldStyle.errorIconColor`, `DsSelectStyle.readOnly`,
  `DsCalendarStyle.todayBorderColor`, `DsAutocompleteStyle.selected` (the
  active tag).
* Multi-select: Left (Right in RTL) at the start of the text walks the tags;
  Backspace or Delete removes the active one.
* `DsMultiSelect(collapseTags: true)`: without focus the tags stay on one
  line followed by a "+N" chip.

### Changed

* Focus is one line: fields turn their edge into a 2px focus edge with no
  ring around it; secondary buttons and unselected chips draw a 2px ring in
  place of their border; filled controls keep the ring with a gap.
* Read-only fields look like a value on the page (no fill, a faint
  hairline, full-contrast text) instead of like disabled ones, and drop the
  buttons that would edit them (clear, steps, picker buttons, chevrons).
* Calendar: the chosen day and range ends are always a solid fill, whatever
  the selection style; today gets a thin ring.
* Multi-select tags are smaller neutral chips; only the active tag uses the
  accent. Disabled tags keep their shape. Empty text no longer takes a row
  of its own.
* Bottom nav: the full-width bar fills the whole selected item like the
  floating one; the icon-only capsule is gone by default (`capsuleSize`
  brings it back).
* Pagination buttons keep their size in a tall parent.
* Dark mode: secondary text is a step quieter (9.2:1 → 8.4:1 on the
  surface).
* High contrast: disabled text reads at 4.5:1 or more.
* `DsTypography.display` is 700 (was 800) and `title` 600 (was 700), with
  −0.02em tracking.
* `DsSearchField.shortcutHint` is hidden on touch platforms.

## Unreleased (0.1.0-dev.8) · Open items

### Changed

* `DsScope` cross-fades a snapshot of the old frame over the new theme
  (colors and shadows): every themed widget rebuilds once instead of on each
  of ~20 frames. Something moving during the 150ms fade leaves a brief trace;
  `animateChanges: false` switches at once.
* Menus and selects with more than 100 entries build only the rows on screen
  (a 5,000-option select opens in ~50ms instead of ~2s); their labels stay
  on one line.

### Fixed

* The date range band has a 3:1 edge at high contrast
  (`DsCalendarStyle.rangeEdgeColor`).
* Text, number, password, date and time fields no longer overflow when
  narrow: clear, unit and step buttons hide in turn, keys and screen reader
  actions remain.

### Removed

* `DsDatePickerStyle.buttonWidth` and `DsTimePickerStyle.buttonWidth` (they
  had no effect).

## Unreleased (0.1.0-dev.7) · Audit 2 and API normalization

A second independent audit, its fixes, and a one-time pre-1.0 API
normalization. Breaking changes are listed with their migration.

### Breaking: API normalization

| Before | After |
|---|---|
| `DsChip(onSelected:)` | `DsChip(onChanged:)` |
| `DsMenuItem(onSelected:)`, `DsListRow(onTap:)`, `DsSidebarItem(onTap:)` | `onPressed:` |
| `DsTable(onRowTap:, empty:, error:)` | `DsTable(onRowPressed:, emptyView:, errorView:)` |
| `DsBottomNav(selectedIndex:, onChanged: (int))` | `DsBottomNav<T>(value:, onChanged:)`; items take `value:` |
| `DsAccordion(open:, initiallyOpen:, onOpenChanged:)` | `DsAccordion(value:, initialValue:, onChanged:)` |
| `DsCalendar.range(range:, onRangeChanged:)` | `DsCalendar.range(value:, onChanged:)` |
| `DsMultiSelect(values:)` | `DsMultiSelect(value:)` |
| `DsSelect.onChanged: ValueChanged<T>` | `ValueChanged<T?>`; new `clearable` |
| `DsField(error:)` (message) | `DsField(errorText:)` |
| `DsFileItem(error:)` | `DsFileItem(message:)` |
| `showDsConfirm(context, …)`, `showDsToast(context, …)` | `context:` by name; `useRootNavigator` on dialogs and panels |
| `DsSegmented{Style,ThemeData,Theme}` | `DsSegmentedControl…` |
| `DsTextToolbar{Style,ThemeData,Theme}` | `DsTextSelectionToolbar…` |
| `DsAvatar(tone:, backgroundColor:, foregroundColor:, ringColor:)` | `DsAvatar(toneIndex:, style: DsAvatarStyle(…))` |
| `DsProgressBar(height:)`, `DsProgressRing(size:, strokeWidth:)`, `DsSpinner(size:, color:, strokeWidth:)`, `DsSkeleton(radius:)`, `DsCount(ringColor:)`, `DsAvatarGroup(ringColor:)` | the same values through `style:` |
| `DsSkeleton.line(…)`, `dsAvatarDiameter` | removed (`DsSkeleton(…)`, `DsAvatarStyle.diameter`) |
| `DsFocusIndicator`, `DsThemeData.focusIndicator` | removed: keyboard focus always draws the ring |
| `DsMenuAnchor`/`DsPopover(controller:)` required | optional; new `builder:` gets the controller |
| exported `RenderDsIcon`, `DsPlacement`, `dsPlace`, `dsParseSvgPath`, `DsPalette`, `dsContextMenuLabel`, `dsEditShortcut` | internal |

### Added

* Forms: `DsFormField<T>` (a `FormField` drawing a `DsField`: the
  validator's message is the field's error text) and typed form fields
  `DsTextFormField` (+ `.multiline`), `DsNumberFormField`,
  `DsSelectFormField`, `DsAutocompleteFormField`, `DsMultiSelectFormField`,
  `DsDateFormField`, `DsDateRangeFormField`, `DsTimeFormField`,
  `DsCheckboxFormField`, `DsSwitchFormField`, `DsRadioGroupFormField`.
  Validate and save commit pending typed text (no stale values); invalid
  typed input fails validation with a localized message; `restorationId`
  restores text and values; `FormState.validateAndFocus()` focuses the first
  invalid field; `DsValidators` (`required`, `minLength`, `maxLength`,
  `email`, `all`).
* `focusNode`, `autofocus` and `semanticLabel` on every interactive widget;
  `error` on `DsSwitch`, `DsRadioGroup`, `DsSearchField`; `readOnly` on
  select, autocomplete, multi-select, date, range and time pickers.
* Styles and themes for `DsLink`, `DsBreadcrumb`, `DsAvatar`,
  `DsAvatarGroup`, `DsCount`, `DsStatusDot`, `DsProgressBar`,
  `DsProgressRing`, `DsSpinner`, `DsSkeleton`.
* `DsButton.expanded`; menu, popover, select, combobox, date and time
  triggers announce open/closed.
* `onInvalid(DsInputIssue)` on date, range, time and number fields, with
  built-in localized messages shown in `DsField`.
* `DsTable.rowsVersion`, `DsTableLayout` (rows, cards, auto below 480px),
  `DsCollationKey`.
* `accentEdge` color role; `DsChip.showCheck`; `DsTypography.numeric`.

### Fixed

* Table: no re-sort on parent rebuilds with inline columns (10k rows: 0.55s
  per click before), stale rows after in-place edits (`rowsVersion`), mixed
  value types, two selection events in one frame, row checkbox names, badge
  colors on selected rows; Turkish collation ~10× faster per sort.
* Date and time fields: huge years and hours no longer throw; years below
  1000 are kept; no change reported without an edit; time of day kept;
  numeric date conventions follow the app locale for every language (pl,
  nl, sv… no longer read as US); the popup fits small windows and phones.
* Number field rounds before clamping (`max: 2.5` no longer yields 3).
* Layers: close when their trigger leaves the window or the tree; system
  back closes the newest layer first; Escape on a tooltip no longer closes
  the dialog behind it; a tooltip without an `Overlay` shows only its
  control; dialogs and toasts follow theme and language changes when
  `DsScope` sits below the navigator; toast overlay entries are disposed.
* Autocomplete: keys are left to the input method while composing; a typed
  label chooses its option even with `onCustom`; Escape never clears a chosen
  value.
* Tabs and segmented control expose the selected item to screen readers.
* Bright accents (yellow, lime) keep the outline of checked controls; high
  contrast draws 3:1 slider and progress tracks; list rows and menu options
  wrap to two lines; toasts stay on screen at 2× text; progress and shimmer
  repaint only themselves.
* `DsThemeData.copyWith` keeps a hand-built theme's tokens; `DsScope` keeps a
  hand-built theme in dark mode with a debug warning.

### Changed

* Numbers use the text family with tabular figures where they line up
  (tables, calendar, counters, pagination); typed fields use proportional
  figures. Mono is left for code-like content.
* Filled buttons are flat (no colored glow); every button label is 600.

## Unreleased (0.1.0-dev.6) · Phase 8

### Added

* `DsTable<T>` (concept 28): sortable headers (ascending → descending →
  unsorted, controlled, optional stable local sort), keyed multi-selection
  with a tri-state "select all" and Shift ranges, row-mode keyboard
  navigation with one Tab stop, `onRowTap` and a row menu, loading skeleton,
  empty and error slots, sticky header, lazy fixed-height rows (10,000+),
  horizontal scroll, RTL, table / row / cell semantics. `DsTableColumn`,
  `DsTableColumnWidth`, `DsTableSort`, `DsTableSortDirection`,
  `DsTableCellAlignment`, `DsTableStyle`, `DsTableTheme`.
* `DsCalendar` and `DsCalendar.range`: WAI-ARIA date grid, first day of the
  week by region, range band with preview, disabled days, one or two months,
  a sliding month turn.
* `DsDatePicker`, `DsDateRangePicker`: typeable date fields (lenient, locale
  pattern) with a popup calendar.
* `DsTimePicker` and `DsTime`: a typeable time field with hour, minute and
  AM/PM columns, `minuteStep`, 12/24-hour clock by region.
* `DsDateFormat`, `DsDateLocale`, `dsFirstDayOfWeek`, `dsUses24HourClock`:
  date and time formatting and parsing without `intl`.
* `dsCompareText`: dictionary order for sorting (Turkish ç ğ ı ö ş ü after
  their base letters; accents with their base letter elsewhere). `DsTable`
  sorts strings in the app's language.
* `DsMenuItem.submenu`: nested menus (end side, flips, RTL; safe triangle;
  APG keys; type-ahead per level). `DsMotion.submenuDelay` (150ms).
* `DsFileUpload`, `DsFileItem`, `DsFileStatus` (concept 34): a plugin-free
  drop zone and file rows (uploading, done, error with retry);
  `DsDashedBorder`, `dsFormatFileSize`, `dsFormatFileProgress`.
* Styles and themes: calendar, date picker, time picker, file upload, file
  item.
* Icons `DsIcons.upload`, `fileText`, `clock`, `arrowUp`, `arrowDown`,
  `searchX`.
* l10n: table, date/time (month and weekday names, patterns, AM/PM) and
  upload strings in all languages.

## Unreleased (0.1.0-dev.5) · Phase 7b

### Added

* `DsAutocomplete<T>`: an editable combobox that filters as you type
  (Turkish-aware case folding), draws matched letters bold, takes async
  options (`optionsBuilder`, with a loading state), free text (`onCustom`),
  a clear button and `DsField`. Focus stays in the field; the active option
  is a highlight (an inset ring is added only in high contrast).
* `DsMultiSelect<T>`: several values as tags inside the field; the popup
  stays open with checks; Backspace removes the last tag; the field grows
  as tags wrap.
* `DsNumberField`: mono digits, unit prefix or suffix, −/+ buttons with
  press-and-hold repeat, WAI-ARIA spinbutton keys and semantics (the unit is
  read with the value), `DsField`, read-only and disabled.
* `DsNumberFormat` (fixed decimals, grouping, locale separators,
  `inputFormatter`) and `dsNumberSeparators(Locale)`; no `intl` dependency.
* `DsAutocompleteStyle`, `DsAutocompleteTheme`, `DsNumberFieldStyle`,
  `DsNumberFieldTheme`, `DsOptionsBuilder`, `DsOptionFilter`.
* l10n keys `remove(label)` and `removed(label)`; `selectResultCount` is
  now announced.

## Unreleased (0.1.0-dev.4) · Phase 7a

Text editing.

### Added

* `DsTextField` on the widgets-layer editing core: platform selection
  gestures, Desen selection handles (`DsTextSelectionControls`), an edit menu
  (native on iOS via `SystemContextMenu`, `DsTextSelectionToolbar` on touch,
  `DsTextContextMenu` at the pointer or caret on desktop; the browser's own
  menu on the web unless the app disables it), IME composing underline,
  autofill, `DsFieldScope` error and required, full semantics. Works without
  `DsApp` (adds the text editing shortcuts when none are present).
* `DsTextField` `leading`, `trailing`, `clearable`, `revealable`
  (show / hide password), a mono character counter with `maxLength`
  (`maxLengthEnforcement`; a soft limit shows the error look), and
  `DsTextField.multiline` (grows from 3 to 8 lines, then scrolls).
* `DsSearchField`: magnifier, clear, Escape clears first, optional
  `shortcutHint` (e.g. ⌘K).
* `DsTextFieldStyle`, `DsTextFieldTheme`, `DsTextFieldVariant`,
  `DsTextToolbarStyle`, `DsTextToolbarTheme`; `DsSelectStyle.borderWidth`.
* `DsFieldHooks`, `DsFieldScope.hooks`, `DsFieldScope.labelText`; a field's
  message row can carry a control's counter.
* `DsLocalizations.supportedLocales`; l10n keys `cut`, `copy`, `paste`,
  `selectAll`, `lookUp`, `share`, `searchWeb`, `showPassword`,
  `hidePassword`, `characterCount`, `characterCountLabel`,
  `charactersRemaining`, `charactersOver`. Icons `DsIcons.eye`, `eyeOff`.

### Changed

* `DsApp.supportedLocales` defaults to every bundled locale, so `locale`
  alone selects Desen's strings (it used to fall back to English).
* Text selection everywhere uses the `selection` color (was `focusRing`).
* `DsSelect`, `DsCheckbox` and `DsRadio` take the error from `DsFieldScope`;
  a select labelled by its field is not named by its placeholder.
* `DsSelect` keeps a faint edge when disabled and has a 2px error edge.

## Unreleased (0.1.0-dev.3)

Owner decisions after the audit, and the remaining items.

### Breaking

* `DsFocusIndicator.auto` is removed. Keyboard focus draws the ring by
  default (`DsFocusIndicator.ring`); pass `DsFocusIndicator.subtle` for the
  hover look. High contrast always draws the ring. Pointer and touch users
  never see it (`DsFocusVisibility`).
* `DsShadows.knobOn` and the color roles `accentPress`, `controlPress`,
  `DsStatusColors.fillPress` / `tintPress` are new required fields for code
  that constructs `DsShadows`, `DsColors` or `DsStatusColors` by hand.
* On iOS and Android every small control takes a 44px layout box (an
  invisible tap area; visuals unchanged). Pin `DsThemeData(platform:)` for
  platform-independent layouts.
* `onAccent` and `onSelectionStrong` are no longer always white (bright
  accent below).

### Added

* `DsField`, `DsFieldScope`, `DsFieldStyle`, `DsFieldTheme`: label,
  description, error message and required mark around a control or a group.
* `DsPageRoute`: iOS edge back swipe and Android predictive back.
* `DsThemeData(platform:)`, `DsSizes.compactOnTouchPlatform`,
  `DsSizes.forDensity(density, platform:)`, `DsSizes.isTouchPlatform`.
* `DsCoverImage`, `DsCoverImageKey`, `DsAvatar.resizeImage`: avatar photos
  decode at the size they cover, not at full resolution.
* `DsLocalizations.resolve` and `lookupKeys`; Traditional Chinese
  (`zh_Hant`, also for zh_TW, zh_HK, zh_MO) and European Portuguese
  (`pt_PT`). `pt` is Brazilian, `zh` Simplified.

### Changed

* Bright accent: light brand seeds (yellow, amber, orange, lime, mint, cyan)
  keep their own fill with a dark label in both modes instead of being
  darkened to mustard or olive. Progress, focus and accent text stay
  darkened; the switch knob gets a dark edge on the bright track. The tabs
  underline and the text caret use `indicator`.
* Pressed buttons are one step deeper than hover. The light warning fill
  lightens on hover (its label is dark).
* Danger toasts are announced assertively where the platform supports it.
* List rows and sidebar items draw the focus ring inside their edge.
* Golden comparisons run only on macOS; elsewhere they are skipped with a
  message.

### Fixed

* `DsAccordion` no longer throws when opened under reduced motion.

### License

* MIT. The fonts package carries the SIL Open Font License texts.

## Unreleased (0.1.0-dev.2)

Independent quality audit fixes ("denetim-1"). Pre-1.0: breaking changes are
listed here without `fix_data.yaml` migrations.

### Breaking

* `parseSvgPath` is now `dsParseSvgPath`.
* `DsAccordion` is generic: `DsAccordion<T>` with `DsAccordionItem(value:)`.
  `open`, `initiallyOpen` and `onOpenChanged` take sets of values, not indices.
* `DsStatusDot.label` is required: status is never told by color alone.
* `DsPressable` and `DsButton` with only `onLongPress` are enabled.
* `DsButton.loading` keeps focus and enabled semantics and announces
  "loading"; without a leading icon the spinner covers the label, so the
  width never changes.
* `DsSegmentedControl`: a value that matches no segment selects none.
* `DsModalRoute.theme` and `direction` are optional pins; modals follow the
  live theme above the navigator and capture the opener's subtree themes
  (`DsCapturedThemes`).
* `DsPanel.showClose` is `bool?`; null follows `dismissible`.
* `DsSelect` semantics: label and value are separate properties.
* Button decorations always keep the border ring at `shadows[0]`.

### Added

* Overlays: `DsOverlayTab` / `DsAnchoredOverlay.tab` (Tab closes menus and
  selects and moves on; flows through popovers), `DsCapturedThemes`,
  `DsModalRoute.captured`.
* `DsShortcut`: shortcut hints draw ⌘ ⌥ ⇧ ⌫ ⏎ as icons. New icons
  `DsIcons.command`, `option`, `shift`, `backspace`, `enter`.
* Menus: `DsMenuItem.checked` (radio items), `DsMenuItemStyle.focusShadows`
  (inset ring in ring mode); Shift+F10 and the context-menu key open a
  `DsContextMenuRegion`.
* `DsDialog.semanticLabel`, `DsPanel.semanticLabel`; dialogs and panels are
  named by their title.
* Toasts: F8 focuses the toast, Escape dismisses it; with a screen reader a
  toast with an action does not time out.
* `DsPressable.busy`, `DsPressable.validationResult`; `DsSwitch.offHover`.
* Style fields: `DsSliderStyle.width`, `DsCheckboxStyle.borderWidth`,
  `DsRadioStyle.borderWidth`, `DsBadgeStyle.borderColor`,
  `DsAlertStyle.borderColor`, `DsBottomNavItemStyle.borderColor`,
  `DsSidebarItemStyle.borderColor`, `DsPaginationStyle.borderColor`.
  Also `DsSwitchStyle.labelStyle`/`descriptionStyle`/`textGap`,
  `DsSliderStyle.tickSize`, `DsBadgeStyle.iconSize`, `DsAlertStyle.textGap`,
  `DsDialogStyle.iconSize`, `DsPanelStyle.grabberSize`/`sheetMaxWidth`,
  `DsToastStyle.closeIconSize`/`textGap`.
* Color roles `selectionHover`, `selectionStrongHover`;
  `DsThemeData.selectedHoverFill`, `DsThemeData.selectedEdge`;
  `DsOklch.inGamut`, `DsOklch.fitted`.
* 24 localization keys in all 13 languages (`loading`, `percent`, `page`,
  `pageOf`, `currentPage`, `moreCount`, status names and more).

### Fixed

* Two toasts in one frame no longer strand the first.
* Open dialogs, panels and toasts follow theme switches.
* `DsScope` keeps a raw theme's tokens under reduced motion and high contrast.
* `DsShadows ==` compares `contentRaised`.
* Dialog body scrolls and actions stack on small screens and at 200% text.
* Non-dismissible sheets cannot be dragged away; the drag threshold uses the
  sheet's height. Sheets, toasts and layers stay above the soft keyboard.
* Select: unbounded width, empty `fieldError` shadows, type-ahead with no
  value, disabled while open, error shown with an icon and announced.
* Menus: order and type-ahead follow changed items; layers no longer trap Tab;
  focus returns to the trigger after a pointer open; closing layers take no
  taps.
* Slider: unbounded width, NaN, `min == max`, stale `onChangeEnd`, double
  `onChangeStart`, disabled mid-drag.
* Overflows at phone width and large text: bottom navigation, segmented
  control, pagination (collapses to "6 / 24"), list row value, `DsLink`
  (wraps), stepper.
* Tabs scroll the selected tab into view and fade clipped edges.
* Avatar falls back to initials when the image fails; groups keep labels and
  status; `max: 0` works. Cards and list rows keep their child's state when
  `onPressed` toggles.
* Spinner and indeterminate ring stop turning under reduced motion.
* `DsPageRoute` and `DsModalRoute` use theme springs and dispose their curves.
* `DsButtonStyle.lerp` blends in premultiplied alpha.
* Zero-duration springs no longer crash.

### Changed

* High contrast raises every edge to 3:1 and outlines soft fills; backgrounds
  and fills stay as they are.
* Keyboard focus on selected items is visible in the default (subtle) mode.
* Palette: light status tints are cleaner, the neutral badge is visible, the
  light scrim dims, dark selection and secondary text are a step lighter,
  darkened brand seeds keep their hue.
* The sharp corner style is sharper (×0.3).
* Checkbox and radio errors use a 2px edge, and a danger fill when checked.
  Disabled controls keep their enabled shape.
* Toolbar: arrow keys, Home and End move between items.
* Focus visibility starts hidden on iOS and Android.

## 0.1.0-dev.1

* Foundation: OKLCH color engine, design tokens, `DsTheme`, `DsScope`, `DsApp`.

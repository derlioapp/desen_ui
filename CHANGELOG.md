## Unreleased

### Added

- `DsIcon` follows the icon theme's `weight`, as the weight axis of a
  variable icon font does: 400 draws the icon's own stroke, other weights
  scale it (350 draws a 2-unit stroke at 1.75). Set it once in
  `DsApp.builder` and it reaches the icons inside components and layers;
  `DsIcon.strokeWidth` still wins. Without a weight nothing changes.

## 0.2.3

The same code as 0.2.2. The archives of 0.2.0, 0.2.1 and 0.2.2 included
local files that were not meant to be published; those versions are
retracted. Update to this release: `^0.2.0` picks it up.

## 0.2.2

Additions and fixes, nothing breaking: `^0.2.0` picks this release up.

### Added

- `DsToastStyle.actionStyle` and `closeStyle`, and `DsPanelStyle.closeStyle`:
  the toast's action and close buttons and the panel's close button can be
  styled, like the inner buttons of other components. The app's button
  theme still does not reach them.

### Deprecated

- `DsToastStyle.closeIconSize`: use
  `closeStyle: DsButtonStyle(iconSize: …)`. It still works until it is
  removed in 0.3.0; a `closeStyle` that sets its own `iconSize` wins over
  it.

### Fixed

- `DsTabs` and `DsChoiceChips` on a page that is covered from its first
  frame (a deep link that opens a stack of pages at once) no longer fail
  an assertion; they bring the selected item into view once the page is
  laid out.

## 0.2.1

New components and fixes, nothing breaking: `^0.2.0` picks this release up.
From this release on, additions and changes of the default look come in
patch releases before 1.0, breaking changes in minor ones (see
[VERSIONING.md](VERSIONING.md)).

### Added

- `DsSectionIndex`: a column of section letters beside a long sorted list
  (contacts, stations, countries). Tap a letter or drag along the column to
  jump; a bubble shows the letter under the finger, letters that do not fit
  give way to dots, and it ticks once per section. Keyboard (arrows,
  Home/End, typing a letter) and screen readers (one adjustable control)
  step through the sections. `DsLocalizations.sectionIndex` names it.
- `DsEdgeFadeScrollView` and `DsEdgeFade`: a horizontal row of your own
  items (tags, filter chips) that scrolls when it does not fit and fades
  the edge that hides items, as the toolbar and text fields already do.
  `DsEdgeFade` fades a horizontal scrollable you already have.
- `DsImage.fallback`: your own stand-in (initials, a placeholder cover)
  shown in the image's box and corners when the picture fails, announced
  by the image's `semanticLabel`. `DsImage.image` may be null when there is
  no picture: the fallback, or the unavailable state, shows at once.
- `DsReorderableList`: a list people put in their own order (favorites,
  playlists). Drag an item by its grip handle, or long-press it on iOS and
  Android; the lifted item floats over the others, which make room. The
  handle moves its item with the arrow keys and Home/End, Alt+arrows move
  it from a focused row, and screen readers get "Move up", "Move down",
  "Move to the start" and "Move to the end". `onReorder(from, to)` counts
  `to` after the move.
- `DsWidgetsLocalizations` gives Flutter's reorderable lists their screen
  reader actions in the app's language (13 languages), not only English.
- `DsToastInset`: marks bottom chrome of your own (a mini player, a docked
  media bar) that toasts keep clear of while it shows. It measures the
  chrome after every frame, so toasts follow it as it slides in or out.

### Changed

- A `DsChoiceChips` row too narrow for its chips fades the edge that hides
  chips instead of cutting one in half, and brings the selected chip into
  view clear of the fade.

### Fixed

- Toasts no longer cover a `DsBottomNav`: they sit above it while it shows.

## 0.2.0

The first release without the `alpha` tag. Desen is still before 1.0:
breaking changes come in minor releases (0.3.0), never in patches, and
each is listed here with how to update (see [VERSIONING.md](VERSIONING.md)).

### Breaking

| Before (0.1.0-alpha.2) | Now | What to do |
|---|---|---|
| `DsIcons` held 56 icons | `DsIcons` is the full Lucide set, 2225 icons, in camel case (`triangle-alert` is `DsIcons.triangleAlert`) | Most names are the same. Look up others on the [icon page](https://derlioapp.github.io/desen_ui/#/foundations/icons), which also searches the 94 aliases (`home`, `close`, `volumeUp`) |
| `DsIcons.shift` | `DsIcons.arrowBigUp` | Rename |
| `DsIcons.all` | Removed: an app's own icon picker should list the icons it offers | Keep your own list of `DsIconData` |
| `DsIcons.chevronLeft` and `chevronRight` mirrored in right-to-left text | 67 icons that point along the reading direction mirror (below) | If you flipped any of them yourself, stop; to keep one fixed, use `DsIcons.logOut.copyWith(matchTextDirection: false)` |
| `DsApp.supportedLocales` defaulted to all 13 Desen locales | It defaults to `locale`, else English, as Flutter's app widgets do | To follow the device's language, pass the locales your app is translated into, or `supportedLocales: DsLocalizations.supportedLocales` |
| `DsToolbar` items that did not fit scrolled sideways | They move into a "More actions" (⋯) menu (`overflow: DsToolbarOverflow.menu`) | Pass `overflow: DsToolbarOverflow.scroll` to keep scrolling; wrap custom children in `DsToolbarItem` to let them collapse |
| Text fields did not check spelling | `DsTextField.spellCheck` is on by default on iOS and Android for plain and multi-line text (off for email, URL, password, number, name and address fields, search fields and autocompletes) | Pass `spellCheck: false` to turn it off |
| `DsColors` had no skeleton roles | New required roles `skeleton` and `skeletonStrong` | Only hand-built `DsColors` (for `DsThemeData.raw`) need them; generated themes have them |
| `showDsPanel` drew a surface around whatever its builder returned | `DsPanel` draws its own surface (so `DsPanel.style` applies) | Return a `DsPanel` from the builder, or draw your own surface |
| `showDsToast` took an `actionLabel` without `onAction` | It asserts that they come together | Pass both, or neither |
| `DsPagination` asserted `page <= pageCount` | It shows the last page, without calling `onChanged` | Nothing; remove workarounds |

The 67 mirrored icons: `arrowBigLeft`, `arrowBigLeftDash`, `arrowBigRight`,
`arrowBigRightDash`, `arrowLeft`, `arrowLeftFromLine`, `arrowLeftToLine`,
`arrowRight`, `arrowRightFromLine`, `arrowRightToLine`, `chevronFirst`,
`chevronLast`, `chevronLeft`, `chevronRight`, `chevronsLeft`,
`chevronsRight`, `circleArrowLeft`, `circleArrowRight`, `circleChevronLeft`,
`circleChevronRight`, `cornerDownLeft`, `cornerDownRight`, `cornerLeftDown`,
`cornerLeftUp`, `cornerRightDown`, `cornerRightUp`, `cornerUpLeft`,
`cornerUpRight`, `forward`, `list`, `listChecks`, `listClock`, `listFilter`,
`listFilterPlus`, `listIndentDecrease`, `listIndentIncrease`, `listMinus`,
`listMusic`, `listOrdered`, `listPlus`, `listRestart`, `listTodo`,
`listTree`, `listVideo`, `listX`, `logIn`, `logOut`, `messageCircleReply`,
`messageSquareReply`, `redo`, `redo2`, `redoDot`, `reply`, `replyAll`,
`send`, `sendHorizontal`, `squareArrowLeft`, `squareArrowRight`,
`squareArrowRightEnter`, `squareArrowRightExit`, `squareChevronLeft`,
`squareChevronRight`, `tableOfContents`, `textQuote`, `undo`, `undo2`,
`undoDot`.

### Added

- **Icons:** the full Lucide set (Lucide 1.52.0 and Lucide Lab), kept in
  the package and updated only after review; unused icons add nothing to
  an app's size. Icons can be solid: `DsIconData.fill` and `DsIcon.fill`
  fill each closed shape, cut a mark inside out (the "!" in an alert) and
  leave open strokes as strokes. `DsIcon` also follows the icon theme's
  `fill`, as an `Icon` from a font with a fill axis does.
  `DsIconData.copyWith`.
- **`DsBottomNav`** draws the selected destination's icon solid, as iOS
  tab bars and Android navigation bars do;
  `DsBottomNavItemStyle(fillIcon: false)` keeps it outlined.
- **`DsRangeSlider`** picks a range with two thumbs (`DsRangeValues`),
  sharing `DsSlider`'s look and theme. The thumbs never cross and can keep
  a `minDistance`. Each thumb is its own focus stop and its own slider for
  screen readers ("Minimum", "Maximum"), also inside a `DsField`.
- **`DsParagraph` and `DsLinkSpan`:** links inside running text that wrap
  with the sentence, with everything a `DsLink` has (hover, Tab and Enter,
  a focus ring around each line, link semantics). The paragraph takes
  `maxLines`, `overflow` and `WidgetSpan`s; `DsLinkSpan.external` ends a
  link with the up-right arrow.
- **Time picker:** the columns wrap like iOS and Android wheels.
  `firstTime` and `lastTime` bound the times that can be chosen or typed,
  also across midnight (a night shift from 22:00 to 06:00). `showSeconds`
  and `secondStep` add a seconds column; `DsTime` takes seconds.
- **Spell check** in text fields on iOS and Android, with
  `DsSpellCheckSuggestionsToolbar` (`DsTextField.spellCheck`,
  `DsTextFieldStyle.misspelledStyle`).
- **`DsToolbar` overflow menu** ("More actions") and `DsToolbarItem`.
- **Layers:** `routeSettings` on `showDsDialog`, `showDsPanel` and
  `showDsModal`; `DsToastController.closed` with a `DsToastClosedReason`,
  for undo flows; `DsPanel(scrollable: false)` for a child that scrolls
  itself (a `ListView`); `showDsPanel` with `DsPanelPresentation.auto`
  follows the window while open; long content in a dialog, panel or toast
  scrolls from the keyboard (Page Up/Down, arrows, Home, End).
- **Lists and fields:** `DsListRow.description`; `DsTextField.textDirection`
  (an IBAN in a right-to-left app) and `enableIMEPersonalizedLearning` (an
  incognito keyboard); `DsAutocomplete.labelOf` and `DsMultiSelect.labelOf`
  for values not among the options; `DsRadioGroup.semanticLabel`;
  `DsTextSelectionToolbar.semanticLabel`.
- **Colors:** `skeleton` and `skeletonStrong` roles.
- **Strings** in every language: `seconds`, `unavailable`, `timeTooEarly`,
  `timeTooLate`, `timeOutsideRange`, `rangeMinimum`, `rangeMaximum`,
  `moreActions`, `spellingSuggestions`, `noSpellingSuggestions`,
  `showMenu`, `opensExternally`.

### Changed

The default look moved in these places (apps with golden tests will see
them):

- Numbers in tables, counts, the stepper and the pagination set their
  separators at the font's own width; only the digits are tabular
  ("12.480,00" no longer reads like a typewriter).
- Avatar tones are a fixed set of clean hues, the same for every brand and
  in both modes, so a person keeps their color when the mode changes.
- Red and green brands (and the `oxblood` and `forest` presets) draw the
  strong selection, focus outline and links in their own red or green in
  light mode instead of maroon or bottle green. Yellow, amber and orange
  brands write accent text and links in a clean tone instead of olive,
  mustard or khaki.
- Yellow, amber and light orange brands select in gray in light mode too,
  as warm brands do in dark mode, with the brand in the text: a cream
  selection swallowed a warning badge or alert on a selected row. The
  warning color is unchanged.
- A light `DsAlert` whose tint barely stands off the page gets a quiet
  1px edge in its status color; its icon stays centered on the title's
  first line with large text.
- Buttons, chips, segmented controls, the select's trigger and tabs grow
  with large text, so their labels keep clear of the edges; at the regular
  size nothing moves.
- A `DsSwitch` label is in the body weight, as a checkbox's and a radio's.
- A `DsStepper` button that cannot step stays visible, flat, with a muted
  glyph.
- The dark-mode warning tint is a deep orange instead of a brown.
- Skeleton blocks are easier to see; dashed outlines space their dashes
  evenly on continuous corners.
- `DsApp` keeps the device's region once its language is supported, so a
  British device reads and writes dd/MM/y dates.

To empty a number, date or time field that holds invalid text from
outside (a "Clear" button), give it a new key or reset its form: it has
already reported null, so `value: null` again cannot change it. Their docs
now say so.

### Fixed

- **Screen readers:**
  - Inside a `DsField`, a segmented control, choice chips, tabs and a
    radio group were heard as one item, so their options could not be
    chosen one by one; the field's label now names the group, and its
    description or error is the group's hint.
  - A `DsContextMenuRegion` added a nameless node whose tap did nothing;
    the row's own node now opens the menu (long press, "Show menu").
  - A bottom sheet and a toast offered a scroll action that dismissed
    them.
  - An anchored badge was read apart from its anchor ("Notifications",
    then "5"); progress was read twice on a valued `DsProgressRing` and an
    uploading `DsFileItem`.
  - The autocomplete's active option is said from a live region where the
    platform has no announcements (Android).
  - An external link says it leaves the app.
- **Keyboard and focus:**
  - A select, menu or popover reopened while fading out kept stale focus,
    so Enter could undo a typed choice.
  - A context or row menu opened from the keyboard closed at once at the
    window's edge (a full-width `DsTable`'s row menu never showed).
  - An open menu took Ctrl, Command and Alt shortcuts as type-ahead.
  - Slider key and screen-reader steps now call `onChangeStart` and
    `onChangeEnd`, Page Up and Page Down always move at least one step,
    and a slider disabled mid-drag ends its change.
  - A disabled `DsCalendar` or `DsPagination` stayed a Tab stop; a table
    focused while loading kept focus once rows arrived; a pagination
    focused after it narrowed focused nothing.
- **Behavior:**
  - On touch, long-pressing a control to read its tooltip also pressed it.
  - `DsAutocomplete` threw when focus left with an option's label typed;
    chose a stale option on Enter while async results loaded; moved the
    highlight to another option when its options changed; and showed
    `toString()` for a value not among its options.
  - `DsNumberField` steps stalled or skipped (step 0.5 in whole numbers,
    cents past a billion, Page Up and Down); a `DsNumberFormat` could use
    the same character for both separators; a new value with a new format
    was ignored while the text had an issue.
  - Typed fields did not commit when focus left through a swapped
    `focusNode`; `FormState.reset()` kept a `DsTextFormField`'s edited
    text.
  - `DsPanel.style` was mostly ignored; `DsPanel` threw with a
    `ListView` child; a bottom sheet whose content refused to close stayed
    dragged off screen.
  - An app-wide `DsButtonTheme` reached the buttons that are parts of
    other components (clear buttons, month arrows, pagination arrows,
    picker buttons, close buttons).
  - Calendars with `months` above 1 turned two pages for an outside day; a
    new value from the app did not call `onMonthChanged`; `DsDateRange`
    failed for a one-day range with a UTC end west of UTC.
  - `DsBreadcrumb(items: [])` threw, and a collapsed breadcrumb overflowed
    on touch; `DsTableColumnWidth.flex(0)` laid out NaN widths; a
    right-to-left `DsListSection` divider took the wrong inset; menus with
    more than 100 entries squashed tall leadings and lost focus when they
    grew; a `DsSelect` in a `Row` kept its old width when its options
    changed in place; the edit toolbar's page chevrons pointed backwards
    in right-to-left text.
  - On the web, the browser's context menu stayed off for the whole app
    after a table row or context menu region was removed under the
    pointer.
  - A time column opened scrolled had no top fade.

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

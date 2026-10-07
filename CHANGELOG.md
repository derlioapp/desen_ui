## Unreleased

- Fixed (web): the browser's own context menu stayed off for the whole
  app after a `DsTable` row with a row menu was removed under the pointer
  (deleted from its own menu), and moving between rows turned it on and
  off again. It is off while the pointer is over such rows and back on
  after; an app that turned it off for good keeps it off.
- `DsTextField.textDirection` sets the direction of the text itself (an
  IBAN or an email address in a right-to-left app) while the field's
  layout keeps the ambient direction, and
  `DsTextField.enableIMEPersonalizedLearning` asks for an incognito
  keyboard.
- `DsListRow.description`: a muted line under the title, such as a
  setting's explanation or a message's preview, read after the title
  (new style fields `descriptionStyle` and `textGap`).
- Fixed: an app-wide `DsButtonTheme` reached the buttons that are parts
  of other components: a wide padding made a text field's clear button
  62px wide, and a height or background changed the calendar's month
  arrows, the pagination arrows, the picker buttons, a file item's cancel
  and retry, the table's row menu and sort buttons and the toast's buttons.
  Those parts keep their component's look now; the app's own buttons
  (including dialog actions and toolbar items) still take the theme.
- Fixed: a `DsAutocomplete` threw when focus left it with an option's
  label typed out in full while its popup was open (focus moved away, or
  the app switched windows on desktop and web). The option is still
  chosen.
- Fixed: a `DsAutocomplete` with an `optionsBuilder` chose an option of
  the previous query on Enter or Tab while the new results were loading.
  No option is active until they arrive.
- Fixed: when a `DsAutocomplete`'s `options` changed while its popup was
  open, the highlight stayed at the same row and so moved to another
  option. It now stays on the same option.
- Fixed: a bottom sheet dragged down past the dismiss point stayed off
  screen, its scrim blocking the page, when its content refused to close
  (a `PopScope` with `canPop: false`). It now goes back in place.
- Fixed: an open `DsMenu`, or a `DsSelect`'s menu, took Control, Command
  and Alt shortcuts (Ctrl+S) as type-ahead, and kept letters no item
  starts with. Both now reach the app.
- Fixed: in menus and selects with more than 100 entries, a leading taller
  than the text (an avatar) was squashed to the row height, and a menu
  that grew past 100 entries while open lost the item with focus. Rows
  are now as tall as their leading, and the focused item keeps focus.
- Fixed: a `DsSelect` kept its height at large text sizes, so its label
  touched its edges (at 200%, 3 px of room). It now grows with its label,
  as a text field does; at the regular size its height is unchanged.
- Buttons, chips and segmented controls grow with large text, as text
  fields do, so their labels keep clear of their edges (at 200% a chip's
  label touched its outline). At the regular text size their heights are
  unchanged.
- A `DsSwitch` label is set in the body weight, as a checkbox's and a
  radio's are (it was semibold), so the three read alike side by side.
- A `DsStepper` button that cannot step (at its limit, or in a disabled
  stepper) keeps its shape, flat and with a muted glyph, instead of
  vanishing into the track.
- A `DsAvatar`'s tone keeps its color when the app switches between light
  and dark mode (a person shown purple in light mode was teal in dark).
  The tones are a fixed set of clean hues, blue-green through blue and
  violet to pink, spread evenly and kept off the brand's own hue, the same
  for every brand; in dark mode they are as vivid for a warm brand as for
  a blue one.
- Fixed: a `DsParagraph` threw when a link's `semanticLabel` (or a span's
  `semanticsLabel`) was shorter than its text, and drew the underline in
  the wrong place when it was longer.
- Fixed: a `DsSelect` in an unbounded width (a `Row`) kept its old width
  when its `options` list was changed in place, cutting a longer label.
  It now measures again whenever the labels change.
- Fixed: `DsNumberField`, `DsDatePicker` and `DsTimePicker` did not commit
  their text when focus left through a new `focusNode` given while
  focused, so typed text stayed unformatted and unreported. It is now
  committed as on any other blur.
- Fixed: `DsNumberField` steps could stall or skip. With a step the
  format cannot show (0.5 in whole numbers) Down from 2 stayed at 2; with
  a cents step, Up did nothing past a billion; and Page Up and Page Down
  rounded to the nearest tenth step (60 from 8 with a step of 5). A step
  now rounds on in its direction, holds at any size, and Page Up and Page
  Down land where ten steps do (55).
- Fixed: a new `value` given to a `DsNumberField` together with a new
  `format` was ignored while the text held an issue; it is now shown.
- Fixed: a `DsNumberFormat` with one separator set could take the same
  character from the locale for the other: a `,` decimal separator with
  grouping showed 1234.5 as "1,234,50" in English and could not read it
  back. The locale's other separator is now taken in that case ("1.234,50"),
  and setting both to the same character fails an assertion.
- Fixed: `FormState.reset()` kept the edited text of a `DsTextFormField`
  with a `controller` when the parent rebuilt on each change. Reset now
  goes back to the controller's text when the field was created, as
  Flutter's `TextFormField` does.
- Fixed: a `DsSlider` or `DsRangeSlider` disabled mid-drag never called
  `onChangeEnd` after `onChangeStart`. It now ends the change with the
  last value.
- Fixed: in right-to-left text, a `DsListSection` divider took its start
  inset from the rows' end padding, so with uneven row padding it did not
  line up with the row text.
- Fixed: a `DsTable` focused while `loading` (with `autofocus` or its
  `focusNode`) kept focus on itself once the rows arrived, so the arrow
  keys did nothing. It now hands focus to the active row.
- Fixed: `DsTableColumnWidth.flex(0)` laid the table out with NaN widths;
  a flex column now asserts a flex above 0.
- Fixed: a `DsCalendar` or `DsRangeCalendar` with `onChanged: null` kept
  its days a Tab stop, and Page Up or Page Down still turned the month
  and called `onMonthChanged`. Its days are now no Tab stop and its keys
  do nothing.
- Fixed: with `months` above 1, choosing an outside day after the last
  shown month turned two pages instead of one.
- Fixed: a new `value` from the app that moved a calendar to another
  month did not call `onMonthChanged`.
- Fixed: `DsDateRange` failed an assert for a one-day range with a UTC
  end west of UTC, and turned a UTC range into a local one. Its ends are
  compared by date only, and a UTC `start` now keeps the range in UTC
  (the end takes the day its date reads), as `DsDatePicker` keeps a UTC
  value.
- Fixed: a `DsPagination` with `onChanged: null` kept its current page a
  Tab stop that screen readers announced as enabled.
- Fixed: focusing a `DsPagination` (its `focusNode` or `autofocus`) after
  it narrowed to "‹ 6 / 24 ›" focused nothing; it now focuses the arrow
  that can move.
- Fixed: a `DsPagination` whose `page` is past `pageCount` (a filter left
  fewer pages) failed an assert. It now shows the last page, without
  calling `onChanged`.
- Fixed: `DsBreadcrumb(items: [])` threw a `RangeError`; it now builds
  empty.
- Fixed: on touch, a collapsed `DsBreadcrumb` of short levels could
  overflow its width: it measured the levels without their 44 px tap
  targets.
- Fixed: a context or row menu opened from the keyboard (Shift+F10 or the
  Menu key) closed at once when its control touched the window's edge, so
  the row menu of a full-width `DsTable` never showed.
- Fixed: on touch, long-pressing a control inside a `DsTooltip` to read
  its tooltip also pressed the control when the finger lifted. The long
  press that shows the tooltip now cancels the press.
- Fixed: dates followed the language but not the region of the app's
  locale when an app listed language-only `supportedLocales` (as
  `DsLocalizations.supportedLocales`): a British device resolved to `en`
  and read "05/10/2026" as 10 May. `DsApp` now keeps the device's region
  and script once its language is supported, unless the app sets its own
  resolution callback.
- **Breaking:** `DsApp.supportedLocales` defaults to `locale` when one is
  given, else to English, as Flutter's own app widgets do. It used to
  default to all 13 of Desen's locales, so an untranslated English app
  resolved to Arabic on an Arabic device and was mirrored right to left.
  To follow the device's language, pass the locales the app is
  translated into, or `supportedLocales: DsLocalizations.supportedLocales`.
- Fixed: a `DsRangeSlider` inside a `DsField` merged its two thumbs into
  one screen-reader node, so the maximum could not be adjusted with a
  screen reader. The thumbs now stay two sliders, each named by the
  field's label and its end ("Price, Minimum"), with the field's
  description or error as its hint.
- Fixed: `DsSlider` and `DsRangeSlider` called `onChangeStart` and
  `onChangeEnd` only for taps and drags, so an app that saves in
  `onChangeEnd` lost every change made with the keyboard or a screen
  reader. Each key step or screen-reader increase or decrease that changes
  the value now has its own start and end; each repeat of a held key is
  one step.
- Fixed: Page Up and Page Down could do nothing on a slider with only a
  few steps (a tenth of the range rounded back to the same step). They now
  move a tenth of the range in whole steps, at least one, on `DsSlider`
  and `DsRangeSlider`.
- Fixed: `DsTabs` cut its labels at very large text. A tab now grows
  taller with its label; `DsTabsStyle.height` is its minimum height, so
  the bar looks the same at usual sizes.
- A `DsRadio` or `DsRadioCard` whose value type differs from its
  `DsRadioGroup`'s (`DsRadio<Plan?>` in a `DsRadioGroup<Plan>`) could never
  be selected, without a word; debug builds now stop with a message that
  names both types.
- Fixed: inside a `DsField`, screen readers heard a `DsSegmentedControl`,
  `DsChoiceChips` or `DsTabs` as one item with one action, so the options
  could not be chosen one by one. Each option is its own item again; the
  field's label names the group, and its description or error is the
  group's hint.
- `DsRadioGroup` takes a `semanticLabel`, and a `DsField` names the radio
  group with its label, its description or error as the group's hint: a
  screen reader user who tabs into the group hears the question and the
  error, not only the first option.
- Fixed: `DsPanel.style` now sizes and paints the panel. Its `width`,
  `sheetMaxWidth`, `margin`, `background`, `borderRadius`, `shadows` and
  `backdropFilter` were ignored; only the theme's applied. The `DsPanel`
  now draws the panel's surface itself, so other content given to
  `showDsPanel` draws its own.
- `DsPanel(scrollable: false)` leaves scrolling to a child that scrolls
  itself, such as a `ListView`: it gets a bounded height instead of
  throwing for an unbounded one.
- Long content in a `DsDialog`, a `DsPanel` and a toast scrolls from the
  keyboard: with focus on a button, Page Up, Page Down, Arrow Up, Arrow
  Down, Home and End scroll it. A focused text field keeps these keys.
- `showDsDialog`, `showDsPanel` and `showDsModal` take `routeSettings`, for
  navigator observers, analytics and route arguments.
- `DsToastController.closed` completes when the toast goes, with a
  `DsToastClosedReason`: `action`, `dismissed`, `timeout` or `replaced`. An
  undo flow commits there unless the action was pressed; an action pressed
  while the toast is already leaving no longer runs. `showDsToast` asserts
  that `actionLabel` and `onAction` come together.
- A bottom sheet and a toast no longer offer screen readers a scroll
  action that dismissed them; the close button, the scrim and Escape
  still do.
- `showDsPanel` with `DsPanelPresentation.auto` follows the window while
  the panel is open: resizing it or turning a tablet across the breakpoint
  switches between side panel and bottom sheet, keeping the panel's state
  and focus.

- An external `DsLink` or `DsLinkSpan` tells screen readers it leaves the
  app, as its arrow shows: a localized "Opens outside the app" hint.
- Fixed: a `DsAnchoredBadge` was a node of its own, so an icon button
  with a count read "Notifications, button" and then a bare "5". The
  badge is now read with its anchor, in one node ("Notifications, 5");
  a `DsCount.semanticLabel` still names the count.
- `DsAutocomplete` and `DsMultiSelect` take `labelOf`, which labels a
  value that is not among the options, e.g. a saved record's customer
  when the options come from a server. Fixed: such a value showed (and
  screen readers read) its `toString()`, "Instance of 'Customer'"; without
  `labelOf` it now shows no text. The labels of options a search returned
  are no longer all kept: only the chosen ones.
- Fixed: where the platform has no announcements (Android), screen
  readers did not hear which `DsAutocomplete` or `DsMultiSelect` option
  the arrow keys made active. The popup now says it from a polite live
  region.
- Fixed: progress was read twice. A `DsProgressRing` with a value no
  longer reads its child ("50") before its value ("50%"); name it with
  `semanticLabel`. An uploading `DsFileItem` is one node, the progress bar
  with the percentage as its value, instead of the row and then a
  separate bar; with unknown progress it says "Uploading" once.
- Fixed: in right-to-left text the edit toolbar's page chevrons pointed
  against the reading direction; "next" now points left.
- Fixed: a `DsContextMenuRegion` added a nameless node around its row or
  card whose tap did nothing, and screen reader users could not find the
  menu. The row's or card's own node now opens it, with a long press and
  with a localized "Show menu" action.
- **Breaking:** `DsIcons` is now the full Lucide set, 2225 icons (Lucide
  1.52.0 and Lucide Lab), in place of the 56 picked before. Names follow
  Lucide's in camel case (`triangle-alert` is `DsIcons.triangleAlert`), and
  94 icons also have a more common alias (`volumeUp` for `volume2`, `home`
  for `house`, `close` for `x`). Icons an app does not use add nothing to
  its size. `DsIcons.shift` is now `DsIcons.arrowBigUp`; `volumeLow`,
  `volumeHigh`, `backspace` and `enter` keep working as aliases.
  `DsIcons.all` is gone. The calendar, settings and search shapes follow
  Lucide's current drawings. 67 icons that point along the reading
  direction (back and forward arrows, undo and redo, lists) mirror in
  right-to-left text.
- Icons can be solid: `DsIconData.fill` and `DsIcon.fill` fill each closed
  shape of an icon, at the same size as the outlined one. A mark inside a
  filled shape (the "!" in an alert, an envelope's flap) is cut out so it
  stays visible; open strokes (arrows, a chart's axes) stay strokes. A play
  button, pause bars or a selected tab's icon can be drawn solid.
- Fixed: numbers in tables, counts, the stepper and the pagination drew
  their separators (`.`, `,`, `:`, `/`) a digit wide, so "12.480,00" read
  like a typewriter. Only the digits are tabular now; the separators
  keep the font's own spacing, and the digits still line up.
- Red and green brands (and the `oxblood` and `forest` presets) draw the
  strong selection, focus outline and links in their own red or green in
  light mode, a step darker than the fills, instead of maroon or bottle
  green.
- Yellow, amber and orange brands write accent text and links in a clean
  tone: in light mode the deep orange (or a lemon brand's deep lime) of
  their progress bars instead of olive or mustard, in dark mode a vivid
  yellow or amber instead of khaki.
- In light mode a `DsAlert` whose status tint barely stands off the page
  (1.01–1.06:1 on the default gray page) gets a quiet 1px edge in its
  status color, so the block keeps its shape for people who see little
  hue difference. On a white page, and in dark mode, there is none.
- A `DsAlert`'s icon stays centered on the title's first line with large
  text; before, it kept to the top and sat up to 7px above the line.
- `DsParagraph` takes `maxLines` and `overflow` (a link cut off entirely
  leaves the Tab order and the semantics) and `WidgetSpan`s, which screen
  readers read in their place in the text. `DsLinkSpan.external` ends a
  link with the up-right arrow, as on a `DsLink`.
- `DsTimePicker` takes a range across midnight: a `firstTime` after
  `lastTime` (a night shift from 22:00 to 06:00). The hour column runs 22,
  23, 00 to 06, Home and End give the range's first and last time, and a
  typed time outside it gets the new localized message
  `timeOutsideRange` ("Enter a time from 10:00 PM to 6:00 AM.").
- `DsBottomNav` draws the selected destination's icon solid, as iOS tab
  bars and Android navigation bars do. It sets the icon theme's `fill`,
  which `DsIcon` now follows (as an `Icon` from a font with a fill axis
  does). `DsBottomNavItemStyle(fillIcon: false)` keeps it outlined.
- Skeleton blocks are easier to see: new color roles `skeleton` and
  `skeletonStrong` (about 1.27:1 on the card, the page and the sidebar in
  light mode). In dark mode a strong skeleton line no longer vanishes on a
  floating layer.
- Text fields check spelling on iOS and Android with the platform's spell
  checker. A misspelled word gets a danger-colored underline (dotted on
  iOS, wavy on Android), and tapping it opens
  `DsSpellCheckSuggestionsToolbar`, built from the touch edit toolbar, with
  up to three replacements; Android adds Delete, and iOS shows "No
  replacements found" when there are none. `DsTextField.spellCheck`
  (also on `DsTextFormField`) is on by default for plain and multi-line
  text, and off for email, URL, password, number, phone, date, name and
  address fields, search fields, autocompletes and fields with
  `autocorrect: false`; desktop and the web have no checker. The look is
  `DsTextFieldStyle.misspelledStyle` and `misspelledSelectionColor`. New
  strings: `spellingSuggestions`, `noSpellingSuggestions`.
- `DsTextSelectionToolbar.semanticLabel` names the toolbar for screen
  readers.
- `DsRangeSlider` picks a range with two thumbs, such as a price filter,
  with `DsRangeValues` for its start and end. It shares `DsSlider`'s
  track, thumbs, step marks, `DsSliderStyle` and `DsSliderTheme`. The
  thumbs never cross and can keep a `minDistance`; pressing the track
  moves the nearer thumb, and on a shared spot the drag direction picks
  one. Each thumb is its own focus stop and its own slider for screen
  readers, named "Minimum" or "Maximum" in all 13 languages (new
  `DsLocalizations.rangeMinimum` and `rangeMaximum`).
- `DsParagraph` and `DsLinkSpan`: links inside running text. The label is
  part of the paragraph's text, so a long one wraps with the sentence, as
  an `<a>` in a `<p>` does on the web, where a `DsLink` in a `WidgetSpan`
  wraps inside its own box. Each link keeps what `DsLink` offers: the
  theme's link color and underline, hover and pressed styles, Tab and
  Enter with a focus ring around each line of the label for keyboard users
  only, and link semantics (label, address, enabled and focus state,
  activation). The paragraph owns each link's tap recognizer and focus
  node and disposes them.
- Time picker: the hour, minute and second columns wrap like the iOS and
  Android wheels. Down on 23 gives 00 (keys, screen reader increase and
  decrease), and a column longer than it shows scrolls round. A wrapping
  minute stays in its hour. On a 12-hour clock the hours step through the
  day, so Down on 11 AM gives 12 PM.
- Time picker: `firstTime` and `lastTime` bound the times that can be
  chosen or typed, like the date picker's `firstDate` and `lastDate`:

  ```dart
  DsTimePicker(
    value: meeting,
    firstTime: const DsTime(9, 0),
    lastTime: const DsTime(18, 0),
    onChanged: (t) => setState(() => meeting = t),
  )
  ```

  Hours and minutes out of range are struck through (the new
  `DsTimePickerStyle.disabled` look) and can't be chosen. The columns stop
  at the edge of the range instead of wrapping, and a chosen value out of
  range reads as "Unavailable". A typed time out of range gets the field
  error ("Enter a time at or after 9:00 AM.", `DsInputIssueKind.belowMin`
  and `aboveMax`).
- Time picker: `showSeconds` adds a seconds column (`secondStep` sets its
  steps), and the field shows and reads seconds (`14:30:05`). `DsTime`
  takes an optional `second` (`DsTime(0, 4, 30)`), with `inSeconds` and
  `DsTime.fromSeconds`. `DsDateFormat` reads and writes seconds (`s`,
  `ss`), and `DsDateLocale.timeFormat` takes `seconds: true`.
- New strings in every language: `seconds`, `unavailable`,
  `timeTooEarly`, `timeTooLate`.
- Fixed: a time column that opened scrolled had no fade at its top until
  it was focused (the minute column always did). A column that ends (one
  kept from wrapping by its limits) no longer fades over a last item when
  nothing lies beyond it, and that item now rests whole at the end in a
  short window.
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
- `DsToolbar` items that do not fit no longer scroll out of reach: from
  the end, they move into a menu that a "More actions" (⋯) button at the
  bar's end opens, and they come back when there is room (also at large
  text sizes and in right-to-left layouts). Toggles become checkbox items,
  buttons items named by their text or `semanticLabel`, a tooltip's
  `shortcut` shows beside the item, and dividers at the cut are dropped.
  The button is a Tab stop like the other items, its menu has the
  `DsMenu` keyboard, and focus returns to it when the menu closes. Its
  label is the new `DsLocalizations.moreActions`, in every bundled
  language.
  - **Behavior change:** this is the new default,
    `overflow: DsToolbarOverflow.menu`. Pass `DsToolbarOverflow.scroll` to
    keep the sideways scrolling.
  - A bar with a child that has no menu form (anything but a toggle, a
    button, a divider or a tooltip around a toggle or button) keeps
    scrolling as before, with every child in it. Wrap custom children in
    the new `DsToolbarItem` to let them collapse: its `menuItems` give the
    child's menu form, or an empty list for an item that only shows
    something, such as a "3 selected" label.

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

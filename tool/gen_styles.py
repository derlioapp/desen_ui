"""Generates component style and theme classes.

Every component follows the model proven on DsButton:

- `DsXStyle`: every field optional; `merge` lays one style over another;
  state styles (`hovered`, `selected`, ...) nest like CSS blocks.
- `resolve(states)` applies interaction states first (focused, hovered,
  pressed), then structural ones (selected, error, disabled). Structural
  styles resolve recursively, so `selected: DsXStyle(hovered: ...)` is the
  selected-and-hovered look and beats the plain `hovered` one, like CSS
  specificity.
- Layers (defaults, theme style, theme variant, widget style) are each
  resolved for the current states, then laid over each other: a value you
  set wins over a library state value.
- `DsXThemeData` + `DsXTheme` scope defaults to a subtree (merging with
  outer ones); `DsComponentThemes` applies several at once.
- `flags` (optional) are states that `WidgetState` has no value for,
  such as `readOnly`: a nested style like a state one, passed to
  `resolve` as a named bool. They apply after the interaction states and
  before the structural ones, which pass them on, so
  `error: DsXStyle(readOnly: …)` is the error-and-read-only look.
- `defaults` (optional) are widget parameters the theme data can default,
  such as a size or variant: `(name, type, doc)`, nullable on the theme
  data, laid over like any other value (an inner theme's wins).

Usage: python3 tool/gen_styles.py   (writes every spec below)
"""
import os

ROOT = os.path.join(os.path.dirname(__file__), '..', 'lib', 'src', 'components')

INTERACTION = ['focused', 'hovered', 'pressed']
STRUCTURAL = ['selected', 'error', 'disabled']

COMMON = {
    'cursor': ('MouseCursor', 'Mouse cursor.'),
    'focusShadows': ('List<DsShadow>', 'Added while focused from the keyboard: the focus ring.'),
}

SPECS = [
    dict(
        name='Checkbox', dir='selection', file='checkbox_style.dart',
        doc='The look of a `DsCheckbox`.',
        states=['focused', 'hovered', 'pressed', 'selected', 'error', 'disabled'],
        fields=[
            ('size', 'double', 'Box width and height.'),
            ('background', 'Color', 'Box fill.'),
            ('borderColor', 'Color', 'Inner outline of the box.'),
            ('borderWidth', 'double', 'Width of the inner outline; 2 for errors.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Box corners.'),
            ('markColor', 'Color', 'Check or dash color.'),
            ('markSize', 'double', 'Check or dash size.'),
            ('shadows', 'List<DsShadow>', 'Extra shadows on the box.'),
            ('focusShadows', None, None),
            ('labelStyle', 'TextStyle', 'Label text style, merged.'),
            ('descriptionStyle', 'TextStyle', 'Description text style (under the label), merged.'),
            ('textGap', 'double', 'Space between label and description.'),
            ('gap', 'double', 'Space between box and label.'),
            ('cursor', None, None),
        ],
    ),
    dict(
        name='Radio', dir='selection', file='radio_style.dart',
        doc='The look of a `DsRadio`.',
        states=['focused', 'hovered', 'pressed', 'selected', 'error', 'disabled'],
        fields=[
            ('size', 'double', 'Circle diameter.'),
            ('background', 'Color', 'Circle fill.'),
            ('borderColor', 'Color', 'Inner outline of the circle.'),
            ('borderWidth', 'double', 'Width of the inner outline; 2 for errors.'),
            ('dotColor', 'Color', 'Center dot color when selected.'),
            ('dotSize', 'double', 'Center dot diameter.'),
            ('focusShadows', None, None),
            ('labelStyle', 'TextStyle', 'Label text style, merged.'),
            ('descriptionStyle', 'TextStyle', 'Description text style (under the label), merged.'),
            ('textGap', 'double', 'Space between label and description.'),
            ('gap', 'double', 'Space between circle and label.'),
            ('cursor', None, None),
        ],
    ),
    dict(
        name='RadioCard', dir='selection', file='radio_card_style.dart',
        doc='The look of a `DsRadioCard`.',
        states=['focused', 'hovered', 'pressed', 'selected', 'error', 'disabled'],
        imports=['radio_style.dart'],
        fields=[
            ('padding', 'EdgeInsetsGeometry', 'Inner padding.'),
            ('background', 'Color', 'Card fill.'),
            ('shadows', 'List<DsShadow>', 'Card edge and lift.'),
            ('borderColor', 'Color', 'Inner outline over the edge; transparent for none.'),
            ('borderWidth', 'double', 'Width of the inner outline; 2 for errors.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Card corners.'),
            ('labelStyle', 'TextStyle', 'Label text style, merged.'),
            ('descriptionStyle', 'TextStyle', 'Description text style, merged.'),
            ('textGap', 'double', 'Space between label and description.'),
            ('contentGap', 'double', 'Space between the text and the extra content under it.'),
            ('gap', 'double', 'Space between the radio circle and the text.'),
            ('showRadio', 'bool', 'Whether the card shows a radio circle before its text, so the selection does not rest on the fill alone (WCAG 1.4.1).'),
            ('radioStyle', 'DsRadioStyle', 'The radio circle, laid over the radio theme and resolved with the card states (focus draws its ring around the card instead).'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
    ),
    dict(
        name='Switch', dir='selection', file='switch_style.dart',
        doc='The look of a `DsSwitch`.',
        states=['focused', 'hovered', 'pressed', 'selected', 'error', 'disabled'],
        fields=[
            ('width', 'double', 'Track width.'),
            ('height', 'double', 'Track height.'),
            ('inset', 'double', 'Space between the track edge and the knob.'),
            ('trackColor', 'Color', 'Track fill.'),
            ('trackShadows', 'List<DsShadow>', 'Track edge or inner shadow.'),
            ('knobColor', 'Color', 'Knob fill.'),
            ('knobShadows', 'List<DsShadow>', 'Knob shadow.'),
            ('labelStyle', 'TextStyle', 'Label text style; the color follows the state.'),
            ('descriptionStyle', 'TextStyle', 'Description text style; the color follows the state.'),
            ('textGap', 'double', 'Space between label and description.'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
    ),
    dict(
        name='Chip', dir='chip', file='chip_style.dart',
        doc='The look of a `DsChip`.',
        states=['focused', 'hovered', 'pressed', 'selected', 'disabled'],
        fields=[
            ('height', 'double', 'Minimum height; grows with large text.'),
            ('padding', 'EdgeInsetsGeometry', 'Inner padding.'),
            ('background', 'Color', 'Fill.'),
            ('foreground', 'Color', 'Label and icon color.'),
            ('borderColor', 'Color', 'Inner 1px outline.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners. When no layer sets them, rounded as a control of `height` (`DsRadii.controlCorners`), so a style that changes only the height keeps them in proportion.'),
            ('textStyle', 'TextStyle', 'Label text style, merged.'),
            ('gap', 'double', 'Space between icon and label.'),
            ('iconSize', 'double', 'Leading icon size.'),
            ('showCheck', 'bool', 'Whether a selected chip shows a check before its label, in place of its leading icon, so the selection does not rest on color (WCAG 1.4.1).'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
    ),
    dict(
        name='SegmentedControl', dir='segmented', file='segmented_control_style.dart',
        doc='The look of a `DsSegmentedControl`. Channel and thumb fields are read unresolved; item fields resolve per segment.',
        states=['focused', 'hovered', 'pressed', 'selected', 'disabled'],
        fields=[
            ('height', 'double', 'Segment height.'),
            ('inset', 'double', 'Space between channel edge and segments.'),
            ('gap', 'double', 'Space between segments.'),
            ('trackColor', 'Color', 'Channel fill.'),
            ('trackShadows', 'List<DsShadow>', 'Channel edge.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Channel corners. When no layer sets them, the channel is rounded as a control of its height (`height` plus `inset` on each side, `DsRadii.controlCorners`), so a style that changes only the height or the inset keeps them in proportion.'),
            ('thumbColor', 'Color', 'Sliding indicator fill.'),
            ('thumbShadows', 'List<DsShadow>', 'Sliding indicator shadow.'),
            ('thumbRadius', 'BorderRadiusGeometry', 'Indicator and segment corners. When no layer sets them, concentric with the channel corners (`DsRadii.nestedCorners` by `inset`).'),
            ('foreground', 'Color', 'Segment label and icon color.'),
            ('textStyle', 'TextStyle', 'Segment label style, merged.'),
            ('itemPadding', 'EdgeInsetsGeometry', 'Space around each label.'),
            ('iconSize', 'double', 'Icon size.'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
    ),
    dict(
        name='Slider', dir='slider', file='slider_style.dart',
        doc='The look of a `DsSlider`.',
        states=['focused', 'hovered', 'pressed', 'disabled'],
        fields=[
            ('width', 'double', 'Width when the parent leaves it unbounded (e.g. in a Row); otherwise the slider fills the width.'),
            ('height', 'double', 'Height of the touch area.'),
            ('trackHeight', 'double', 'Track thickness.'),
            ('trackColor', 'Color', 'Unfilled track.'),
            ('trackShadows', 'List<DsShadow>', 'Unfilled track edge, e.g. an inner line (`DsShadows.channel`, empty by default). The fill covers it.'),
            ('fillColor', 'Color', 'Filled track.'),
            ('thumbSize', 'double', 'Thumb diameter.'),
            ('thumbColor', 'Color', 'Thumb fill.'),
            ('thumbBorderColor', 'Color', 'Thumb outline; by default only while hovered.'),
            ('thumbShadows', 'List<DsShadow>', 'Thumb shadow.'),
            ('tickColor', 'Color', 'Step mark on the unfilled track.'),
            ('tickFilledColor', 'Color', 'Step mark on the filled track.'),
            ('tickSize', 'double', 'Step mark diameter.'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
    ),
    dict(
        name='Card', dir='card', file='card_style.dart',
        doc='The look of a `DsCard`.',
        states=['focused', 'hovered', 'pressed', 'disabled'],
        flags=[('dashed', 'Laid over the base for a dashed card (`DsCard.dashed`): an empty slot or a drop target.')],
        fields=[
            ('background', 'Color', 'Fill.'),
            ('shadows', 'List<DsShadow>', 'Edge and elevation.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners.'),
            ('padding', 'EdgeInsetsGeometry', 'Space around the content.'),
            ('borderColor', 'Color', 'Color of the dashed outline of a dashed card.'),
            ('borderWidth', 'double', 'Width of the dashed outline of a dashed card.'),
            ('dashLength', 'double', 'Length of one dash of a dashed card\'s outline.'),
            ('dashGap', 'double', 'Space between the dashes of a dashed card\'s outline.'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
    ),
    dict(
        name='Badge', dir='badge', file='badge_style.dart',
        doc='The look of a `DsBadge`.',
        states=[],
        variants=('DsStatus', '../../theme/status.dart', 'statuses'),
        fields=[
            ('height', 'double', 'Minimum height; grows with large text.'),
            ('padding', 'EdgeInsetsGeometry', 'Inner padding.'),
            ('background', 'Color', 'Fill.'),
            ('foreground', 'Color', 'Text color, and the dot\'s when [dotColor] is null.'),
            ('dotColor', 'Color', 'Leading dot color.'),
            ('borderColor', 'Color', 'Inner 1px outline; none by default.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners.'),
            ('textStyle', 'TextStyle', 'Text style, merged.'),
            ('dotSize', 'double', 'Leading dot diameter.'),
            ('iconSize', 'double', 'Leading icon size.'),
            ('gap', 'double', 'Space between dot and text.'),
        ],
    ),
    dict(
        name='Count', dir='badge', file='count_style.dart',
        doc='The look of a `DsCount`.',
        states=[],
        variants=('DsCountTone', 'badge.dart', 'tones', 'tone'),
        fields=[
            ('minSize', 'double', 'Minimum width and height; the bubble grows with the number and with large text.'),
            ('padding', 'EdgeInsetsGeometry', 'Inner padding.'),
            ('background', 'Color', 'Fill.'),
            ('foreground', 'Color', 'Number color.'),
            ('borderColor', 'Color', 'Inner 1px outline; none by default.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners.'),
            ('ringColor', 'Color', 'Ring separating the bubble from what it sits on. Set the real background when it is not the surface, or transparent to drop the ring.'),
            ('ringWidth', 'double', 'Width of that ring.'),
            ('textStyle', 'TextStyle', 'Number text style, merged (tabular figures).'),
        ],
    ),
    dict(
        name='StatusDot', dir='badge', file='status_dot_style.dart',
        doc='The look of a `DsStatusDot`.',
        states=[],
        variants=('DsStatus', '../../theme/status.dart', 'statuses'),
        fields=[
            ('dotSize', 'double', 'Dot diameter.'),
            ('dotColor', 'Color', 'Dot fill.'),
            ('haloColor', 'Color', 'Soft ring around the dot.'),
            ('haloWidth', 'double', 'Width of that ring.'),
            ('gap', 'double', 'Space between dot and label.'),
            ('labelStyle', 'TextStyle', 'Label text style, merged.'),
        ],
    ),
    dict(
        name='Avatar', dir='avatar', file='avatar_style.dart',
        doc='The look of a `DsAvatar`.',
        states=[],
        variants=('DsSize', '../../theme/sizes.dart', 'sizes', 'size'),
        defaults=[('size', 'DsSize', 'Size for avatars that do not set one; `DsSize.md` when null.')],
        fields=[
            ('diameter', 'double', 'Circle diameter.'),
            ('background', 'Color', 'Fill behind initials or the icon. When no layer sets it, the tone picks it (`DsAvatar.toneIndex`).'),
            ('foreground', 'Color', 'Initials and icon color. When no layer sets it, the tone picks it.'),
            ('textStyle', 'TextStyle', 'Initials text style, merged.'),
            ('iconSize', 'double', 'Person icon size.'),
            ('statusSize', 'double', 'Status dot diameter.'),
            ('ringColor', 'Color', 'Ring around the status dot. Set the real background when it is not the surface.'),
            ('ringWidth', 'double', 'Width of that ring.'),
        ],
    ),
    dict(
        name='AvatarGroup', dir='avatar', file='avatar_group_style.dart',
        doc='The look of a `DsAvatarGroup`. The avatars themselves follow `DsAvatarStyle`.',
        states=[],
        defaults=[('size', 'DsSize', 'Size for groups that do not set one; `DsSize.sm` when null.')],
        imports=['../../theme/sizes.dart'],
        fields=[
            ('ringColor', 'Color', 'Ring that separates overlapping avatars, also used around their status dots. Set the real background when it is not the surface.'),
            ('ringWidth', 'double', 'Width of that ring.'),
            ('overlap', 'double', 'How much of each avatar the next one covers, as a fraction of the diameter.'),
            ('overflowSurface', 'Color', 'Opaque fill under the `+N` bubble, so its tint does not show what lies beneath.'),
            ('overflowBackground', 'Color', '`+N` bubble fill.'),
            ('overflowForeground', 'Color', '`+N` text color.'),
            ('overflowTextStyle', 'TextStyle', '`+N` text style, merged (tabular figures).'),
        ],
    ),
    dict(
        name='Link', dir='link', file='link_style.dart',
        doc='The look of a `DsLink`.',
        states=['focused', 'hovered', 'pressed', 'disabled'],
        fields=[
            ('foreground', 'Color', 'Text, underline and arrow color.'),
            ('textStyle', 'TextStyle', 'Text style, merged over the surrounding one.'),
            ('underlineWidth', 'double', 'Underline thickness.'),
            ('iconSize', 'double', 'Size of the external-link arrow.'),
            ('iconGap', 'double', 'Space before the external-link arrow.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners of the focus ring.'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
    ),
    dict(
        name='Breadcrumb', dir='link', file='breadcrumb_style.dart',
        doc='The look of a `DsBreadcrumb`. Level fields resolve per level; the current page resolves as selected.',
        states=['focused', 'hovered', 'pressed', 'selected'],
        fields=[
            ('padding', 'EdgeInsetsGeometry', 'Space around each level\'s label.'),
            ('background', 'Color', 'Fill behind a level, e.g. on hover.'),
            ('foreground', 'Color', 'Label color.'),
            ('textStyle', 'TextStyle', 'Label text style, merged.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners of a level\'s fill and focus ring.'),
            ('separatorColor', 'Color', 'Chevron color between levels.'),
            ('separatorSize', 'double', 'Chevron size.'),
            ('gap', 'double', 'Space between levels and chevrons, and between wrapped lines.'),
            ('iconSize', 'double', 'Size of a level\'s leading icon.'),
            ('iconGap', 'double', 'Space between a level\'s icon and its label.'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
    ),
    dict(
        name='ProgressBar', dir='progress', file='progress_bar_style.dart',
        doc='The look of a `DsProgressBar`.',
        states=[],
        fields=[
            ('width', 'double', 'Width when the parent leaves it unbounded (e.g. in a Row); otherwise the bar fills the width.'),
            ('height', 'double', 'Track thickness.'),
            ('trackColor', 'Color', 'Unfilled track.'),
            ('trackShadows', 'List<DsShadow>', 'Track edge, e.g. an inner line (`DsShadows.channel`, empty by default). The fill covers it.'),
            ('fillColor', 'Color', 'Filled part.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners of track and fill.'),
        ],
    ),
    dict(
        name='ProgressRing', dir='progress', file='progress_ring_style.dart',
        doc='The look of a `DsProgressRing`.',
        states=[],
        fields=[
            ('size', 'double', 'Diameter.'),
            ('strokeWidth', 'double', 'Ring thickness.'),
            ('trackColor', 'Color', 'Unfilled ring.'),
            ('trackEdgeColor', 'Color', 'Hairlines along both edges of the ring, from `DsShadows.channel`; transparent for none (the default).'),
            ('fillColor', 'Color', 'Filled arc.'),
            ('foreground', 'Color', 'Text color of the centered content.'),
        ],
    ),
    dict(
        name='Spinner', dir='spinner', file='spinner_style.dart',
        doc='The look of a `DsSpinner`.',
        states=[],
        fields=[
            ('size', 'double', 'Diameter. When no layer sets it, 7/8 of the ambient icon size (14 without one).'),
            ('color', 'Color', 'Ring color. When no layer sets it, the ambient icon color.'),
            ('strokeWidth', 'double', 'Ring thickness.'),
        ],
    ),
    dict(
        name='Skeleton', dir='skeleton', file='skeleton_style.dart',
        doc='The look of a `DsSkeleton`.',
        states=[],
        fields=[
            ('height', 'double', 'Height of a skeleton that does not set its own.'),
            ('color', 'Color', 'Fill.'),
            ('strongColor', 'Color', 'Fill of a `strong` skeleton, e.g. a title line.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners. When no layer sets them, a line is fully rounded and a block takes the radius of media inside a card (`DsRadii.nested` of the card radius and its padding).'),
        ],
    ),
    dict(
        name='Image', dir='image', file='image_style.dart',
        doc='The look of a `DsImage`. While loading it shows a `DsSkeleton`, which follows `DsSkeletonStyle`.',
        states=[],
        fields=[
            ('borderRadius', 'BorderRadiusGeometry', 'Corners, the same in every state. When no layer sets them, the radius of media inside a card (`DsRadii.nested` of the card radius and its padding).'),
            ('errorBackground', 'Color', 'Fill of the box when the image cannot be shown.'),
            ('errorIconColor', 'Color', 'Color of the icon that marks a missing image.'),
            ('errorIconSize', 'double', 'Size of that icon.'),
        ],
    ),
    dict(
        name='Scrollbar', dir='scrollbar', file='scrollbar_style.dart',
        doc='The look of a `DsScrollbar`. Hovered is the pointer over the thumb, pressed a drag of the thumb.',
        states=['hovered', 'pressed'],
        defaults=[('alwaysVisible', 'bool', 'Whether thumbs of scrollbars that do not set it stay visible while the content is at rest; `false` (shown while scrolling) when null.')],
        fields=[
            ('thumbColor', 'Color', 'Thumb fill.'),
            ('thickness', 'double', 'Thumb width across the scroll direction. The thumb is fully rounded.'),
            ('crossAxisMargin', 'double', 'Space between the thumb and the edge it runs along.'),
            ('mainAxisMargin', 'double', 'Space before the start and after the end of the thumb\'s run.'),
            ('minThumbLength', 'double', 'Shortest the thumb gets on long content.'),
        ],
    ),
    dict(
        name='Divider', dir='divider', file='divider_style.dart',
        doc='The look of a `DsDivider`.',
        states=[],
        fields=[
            ('thickness', 'double', 'Line thickness: its height when horizontal, its width when vertical.'),
            ('color', 'Color', 'Line color.'),
            ('indent', 'double', 'Inset at the start: the leading edge of a horizontal line (the right one in right-to-left text), the top of a vertical one.'),
            ('endIndent', 'double', 'Inset at the end: the trailing edge of a horizontal line, the bottom of a vertical one.'),
        ],
    ),
    dict(
        name='Alert', dir='alert', file='alert_style.dart',
        doc='The look of a `DsAlert`.',
        states=[],
        variants=('DsStatus', '../../theme/status.dart', 'statuses'),
        fields=[
            ('padding', 'EdgeInsetsGeometry', 'Inner padding.'),
            ('background', 'Color', 'Fill.'),
            ('borderColor', 'Color', 'Inner 1px outline; none by default.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners.'),
            ('iconColor', 'Color', 'Status icon color.'),
            ('iconSize', 'double', 'Status icon size.'),
            ('titleStyle', 'TextStyle', 'Title style, merged.'),
            ('descriptionStyle', 'TextStyle', 'Description style, merged.'),
            ('gap', 'double', 'Space between icon and text.'),
            ('textGap', 'double', 'Space between title and description.'),
        ],
    ),
    dict(
        name='Tabs', dir='tabs', file='tabs_style.dart',
        doc='The look of a `DsTabs` bar and its tabs. States apply per tab.',
        states=['focused', 'hovered', 'pressed', 'selected', 'disabled'],
        fields=[
            ('height', 'double', 'Tab height.'),
            ('gap', 'double', 'Space between tabs.'),
            ('padding', 'EdgeInsetsGeometry', 'Padding of the bar.'),
            ('foreground', 'Color', 'Label color.'),
            ('textStyle', 'TextStyle', 'Label style, merged. Keep the weight the same in every state so labels do not shift.'),
            ('indicatorColor', 'Color', 'Underline of the selected tab.'),
            ('indicatorHeight', 'double', 'Underline thickness.'),
            ('dividerColor', 'Color', 'Hairline under the whole bar.'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
    ),
    dict(
        name='Accordion', dir='accordion', file='accordion_style.dart',
        doc='The look of a `DsAccordion`. States apply per section header.',
        states=['focused', 'hovered', 'pressed', 'disabled'],
        fields=[
            ('background', 'Color', 'Container fill.'),
            ('shadows', 'List<DsShadow>', 'Container edge and elevation.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Container corners.'),
            ('dividerColor', 'Color', 'Line between sections.'),
            ('headerHeight', 'double', 'Minimum header height.'),
            ('headerPadding', 'EdgeInsetsGeometry', 'Header padding.'),
            ('headerBackground', 'Color', 'Header fill (e.g. on hover).'),
            ('titleStyle', 'TextStyle', 'Header title style, merged.'),
            ('iconColor', 'Color', 'Chevron color.'),
            ('iconSize', 'double', 'Chevron size.'),
            ('bodyPadding', 'EdgeInsetsGeometry', 'Padding around an open section.'),
            ('bodyStyle', 'TextStyle', 'Default text style of an open section.'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
    ),
    dict(
        name='Stepper', dir='stepper', file='stepper_style.dart',
        doc='The look of a `DsStepper`. `disabled` also styles a button at its limit.',
        states=['focused', 'hovered', 'pressed', 'disabled'],
        fields=[
            ('height', 'double', 'Button height.'),
            ('inset', 'double', 'Space between the track edge and the buttons.'),
            ('trackColor', 'Color', 'Track fill.'),
            ('trackShadows', 'List<DsShadow>', 'Track edge.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Track corners. When no layer sets them, the track is rounded as a control of its height (`height` plus `inset` on each side, `DsRadii.controlCorners`), so a style that changes only the height or the inset keeps them in proportion.'),
            ('buttonWidth', 'double', 'Width of the minus and plus buttons.'),
            ('buttonColor', 'Color', 'Button fill.'),
            ('buttonShadows', 'List<DsShadow>', 'Button edge and lift.'),
            ('buttonRadius', 'BorderRadiusGeometry', 'Button corners. When no layer sets them, concentric with the track corners (`DsRadii.nestedCorners` by `inset`).'),
            ('foreground', 'Color', 'Icon and value color.'),
            ('iconSize', 'double', 'Minus and plus icon size.'),
            ('valueWidth', 'double', 'Fixed width of the value, so the control does not jump.'),
            ('valueStyle', 'TextStyle', 'Value style, merged (tabular figures).'),
            ('unitStyle', 'TextStyle', 'Unit and prefix text, merged.'),
            ('unitGap', 'double', 'Space between the number and its unit or prefix.'),
            ('pressScale', 'double', 'Button scale while pressed; `DsPressEffect` can turn it off.'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
    ),
    dict(
        name='ListSection', dir='list', file='list_section_style.dart',
        doc='The look of a `DsListSection`: a card holding list rows.',
        states=[],
        fields=[
            ('background', 'Color', 'Card fill.'),
            ('shadows', 'List<DsShadow>', 'Card edge.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Card corners.'),
            ('padding', 'EdgeInsetsGeometry', 'Inset between the card edge and the rows.'),
            ('headerStyle', 'TextStyle', 'Section header style, merged.'),
            ('headerPadding', 'EdgeInsetsGeometry', 'Padding around the header.'),
            ('dividerColor', 'Color', 'Line between rows.'),
            ('dividerEndIndent', 'double', 'Space between the line end and the card edge.'),
        ],
    ),
    dict(
        name='ListRow', dir='list', file='list_row_style.dart',
        doc='The look of a `DsListRow`.',
        states=['focused', 'hovered', 'pressed', 'selected', 'disabled'],
        fields=[
            ('height', 'double', 'Minimum row height.'),
            ('padding', 'EdgeInsetsGeometry', 'Row padding.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Row corners (visible on hover and selection).'),
            ('background', 'Color', 'Row fill.'),
            ('borderColor', 'Color', 'Inner 1px outline, e.g. the edge a bright filled selection needs off a light card.'),
            ('foreground', 'Color', 'Title color.'),
            ('iconColor', 'Color', 'Leading icon color.'),
            ('iconSize', 'double', 'Leading icon size.'),
            ('titleStyle', 'TextStyle', 'Title style, merged.'),
            ('detailStyle', 'TextStyle', 'Trailing detail style, merged.'),
            ('maxLines', 'int', 'Lines the title and the detail may each take before they ellipsize.'),
            ('chevronColor', 'Color', 'Disclosure chevron color.'),
            ('gap', 'double', 'Space between parts.'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
    ),
    dict(
        name='Sidebar', dir='sidebar', file='sidebar_style.dart',
        doc='The look of a `DsSidebar`.',
        states=[],
        fields=[
            ('width', 'double', 'Sidebar width.'),
            ('collapsedWidth', 'double', 'Width when collapsed to a rail of icons. The default centers an item\'s icon, which stays where it was in the full sidebar.'),
            ('background', 'Color', 'Fill.'),
            ('shadows', 'List<DsShadow>', 'Edge toward the content.'),
            ('padding', 'EdgeInsetsGeometry', 'Inner padding.'),
            ('gap', 'double', 'Space between items.'),
            ('sectionStyle', 'TextStyle', 'Section label style, merged.'),
            ('sectionPadding', 'EdgeInsetsGeometry', 'Padding around a section label.'),
            ('dividerColor', 'Color', 'The line a section label becomes when collapsed.'),
            ('dividerPadding', 'EdgeInsetsGeometry', 'Inset of that line in the place of the label, which keeps its height so the items do not move.'),
        ],
    ),
    dict(
        name='SidebarItem', dir='sidebar', file='sidebar_item_style.dart',
        doc='The look of a `DsSidebarItem`.',
        states=['focused', 'hovered', 'pressed', 'selected', 'disabled'],
        fields=[
            ('height', 'double', 'Minimum item height.'),
            ('padding', 'EdgeInsetsGeometry', 'Item padding.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Item corners. When no layer sets them, rounded as a control of `height` (`DsRadii.controlCorners`), so a style that changes only the height keeps them in proportion.'),
            ('background', 'Color', 'Item fill.'),
            ('borderColor', 'Color', 'Inner 1px outline, e.g. the edge a bright filled selection needs off a light sidebar.'),
            ('foreground', 'Color', 'Icon and label color.'),
            ('iconSize', 'double', 'Icon size.'),
            ('textStyle', 'TextStyle', 'Label style, merged.'),
            ('countStyle', 'TextStyle', 'Trailing count style, merged.'),
            ('dotSize', 'double', 'Diameter of the dot that stands for the count when the sidebar is collapsed; drawn in the count color.'),
            ('gap', 'double', 'Space between icon and label.'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
    ),
    dict(
        name='BottomNav', dir='bottom_nav', file='bottom_nav_style.dart',
        doc='The look of a `DsBottomNav` container.',
        states=[],
        variants=('DsBottomNavVariant', 'bottom_nav.dart', 'variants', 'variant'),
        defaults=[('variant', 'DsBottomNavVariant', 'Variant for bottom navs that do not set one; `DsBottomNavVariant.floating` when null.')],
        fields=[
            ('background', 'Color', 'Fill.'),
            ('backdropFilter', 'ImageFilter', 'Filter for what shows through a translucent fill, e.g. `ImageFilter.blur` for a frosted layer; null filters nothing. Opaque by default.'),
            ('shadows', 'List<DsShadow>', 'Edge, top line or floating shadow.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners. When no layer sets them, the floating bar is rounded as a control as tall as its items plus its padding (`DsRadii.controlCorners`), so an item height set in a style keeps the bar concentric with its items; the flat bar is square.'),
            ('padding', 'EdgeInsetsGeometry', 'Inner padding.'),
            ('gap', 'double', 'Space between items.'),
        ],
    ),
    dict(
        name='BottomNavItem', dir='bottom_nav', file='bottom_nav_item_style.dart',
        doc='The look of a `DsBottomNav` item.',
        states=['focused', 'hovered', 'pressed', 'selected', 'disabled'],
        variants=('DsBottomNavVariant', 'bottom_nav.dart', 'variants', 'variant'),
        fields=[
            ('width', 'double', 'Item width (floating bar); the full-width bar shares space.'),
            ('height', 'double', 'Item height.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners of the selected fill. When no layer sets them, concentric with the floating bar (`DsRadii.nestedCorners` by its padding), and on the flat bar rounded as a control of `height` (`DsRadii.controlCorners`).'),
            ('background', 'Color', 'Selected fill: the whole item, or the capsule when `capsuleSize` is set.'),
            ('borderColor', 'Color', 'Inner 1px outline of the selected fill, e.g. the edge a bright filled selection needs.'),
            ('foreground', 'Color', 'Icon and label color.'),
            ('iconSize', 'double', 'Icon size.'),
            ('labelStyle', 'TextStyle', 'Label style, merged.'),
            ('capsuleSize', 'Size', 'Size of a capsule behind the icon that takes the selected fill instead of the whole item; null (the default) fills the item.'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
    ),
    dict(
        name='PaneHeader', dir='pane_header', file='pane_header_style.dart',
        doc='The look of a `DsPaneHeader`.',
        states=[],
        fields=[
            ('height', 'double', 'Minimum height.'),
            ('padding', 'EdgeInsetsGeometry', 'Inner padding.'),
            ('background', 'Color', 'Fill; transparent by default.'),
            ('dividerColor', 'Color', 'Line between the header and the content.'),
            ('gap', 'double', 'Space between title and actions.'),
        ],
    ),
    dict(
        name='EmptyState', dir='empty_state', file='empty_state_style.dart',
        doc='The look of a `DsEmptyState`.',
        states=[],
        fields=[
            ('padding', 'EdgeInsetsGeometry', 'Inner padding.'),
            ('iconBoxSize', 'double', 'Tone disk size.'),
            ('iconBoxColor', 'Color', 'Tone disk fill.'),
            ('iconBoxRadius', 'BorderRadiusGeometry', 'Tone disk corners. When no layer sets them, rounded as a control of `iconBoxSize` (`DsRadii.controlCorners`), so a style that changes only the size keeps them in proportion.'),
            ('iconColor', 'Color', 'Icon color.'),
            ('iconSize', 'double', 'Icon size.'),
            ('titleStyle', 'TextStyle', 'Title style, merged.'),
            ('descriptionStyle', 'TextStyle', 'Description style, merged.'),
            ('descriptionMaxWidth', 'double', 'Description wraps at this width.'),
            ('gap', 'double', 'Space between disk, text and actions.'),
        ],
    ),
    dict(
        name='Pagination', dir='pagination', file='pagination_style.dart',
        doc='The look of a `DsPagination`. States apply per page button.',
        states=['focused', 'hovered', 'pressed', 'selected', 'disabled'],
        fields=[
            ('itemSize', 'double', 'Height and minimum width of a page button.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Page button corners. When no layer sets them, rounded as a control of `itemSize` (`DsRadii.controlCorners`), so a style that changes only the size keeps them in proportion.'),
            ('background', 'Color', 'Page button fill.'),
            ('borderColor', 'Color', 'Inner 1px outline, e.g. the edge a bright filled selection needs.'),
            ('foreground', 'Color', 'Page number color.'),
            ('textStyle', 'TextStyle', 'Page number style, merged (tabular figures).'),
            ('ellipsisColor', 'Color', 'Color of the gap marker.'),
            ('gap', 'double', 'Space between buttons.'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
    ),
    dict(
        name='Toolbar', dir='toolbar', file='toolbar_style.dart',
        doc='The look of a `DsToolbar` container.',
        states=[],
        fields=[
            ('background', 'Color', 'Fill.'),
            ('backdropFilter', 'ImageFilter', 'Filter for what shows through a translucent fill, e.g. `ImageFilter.blur` for a frosted layer; null filters nothing. Opaque by default.'),
            ('shadows', 'List<DsShadow>', 'Floating edge and shadow.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners. When no layer sets them, the bar is rounded as a control as tall as its toggles (their size from the toggle theme) plus its padding (`DsRadii.controlCorners`), so a theme that resizes the toggles keeps the bar concentric with them.'),
            ('padding', 'EdgeInsetsGeometry', 'Inner padding.'),
            ('gap', 'double', 'Space between items.'),
            ('dividerColor', 'Color', 'Divider line.'),
            ('dividerHeight', 'double', 'Divider length.'),
        ],
    ),
    dict(
        name='ToolbarToggle', dir='toolbar', file='toolbar_toggle_style.dart',
        doc='The look of a `DsToolbarToggle`.',
        states=['focused', 'hovered', 'pressed', 'selected', 'disabled'],
        fields=[
            ('size', 'double', 'Width and height.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners. When no layer sets them, concentric with the bar inside a `DsToolbar` (`DsRadii.nestedCorners` by its padding), otherwise rounded as a control of `size` (`DsRadii.controlCorners`).'),
            ('background', 'Color', 'Fill.'),
            ('shadows', 'List<DsShadow>', 'Edge (e.g. the soft selection lift).'),
            ('foreground', 'Color', 'Icon color.'),
            ('iconSize', 'double', 'Icon size.'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
    ),
    dict(
        name='Popover', dir='popover', file='popover_style.dart',
        doc='The look of a `DsPopover` panel.',
        states=[],
        fields=[
            ('background', 'Color', 'Fill.'),
            ('backdropFilter', 'ImageFilter', 'Filter for what shows through a translucent fill, e.g. `ImageFilter.blur` for a frosted layer; null filters nothing. Opaque by default.'),
            ('shadows', 'List<DsShadow>', 'Floating edge and shadow.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners.'),
            ('padding', 'EdgeInsetsGeometry', 'Inner padding.'),
            ('width', 'double', 'Fixed width; null sizes to the content.'),
            ('maxWidth', 'double', 'Largest width when sized to the content.'),
        ],
    ),
    dict(
        name='Tooltip', dir='tooltip', file='tooltip_style.dart',
        doc='The look of a `DsTooltip`.',
        states=[],
        fields=[
            ('height', 'double', 'Minimum height.'),
            ('padding', 'EdgeInsetsGeometry', 'Inner padding.'),
            ('background', 'Color', 'Fill.'),
            ('backdropFilter', 'ImageFilter', 'Filter for what shows through a translucent fill, e.g. `ImageFilter.blur` for a frosted layer; null filters nothing. Opaque by default.'),
            ('shadows', 'List<DsShadow>', 'Shadow.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners. When no layer sets them, rounded as a control of `height` (`DsRadii.controlCorners`), so a style that changes only the height keeps them in proportion.'),
            ('textStyle', 'TextStyle', 'Message style, merged.'),
            ('shortcutStyle', 'TextStyle', 'Shortcut style, merged.'),
            ('gap', 'double', 'Space between message and shortcut.'),
            ('maxWidth', 'double', 'Messages wrap at this width.'),
        ],
    ),
    dict(
        name='Menu', dir='menu', file='menu_style.dart',
        doc='The look of a `DsMenu` panel.',
        states=[],
        fields=[
            ('background', 'Color', 'Fill.'),
            ('backdropFilter', 'ImageFilter', 'Filter for what shows through a translucent fill, e.g. `ImageFilter.blur` for a frosted layer; null filters nothing. Opaque by default.'),
            ('shadows', 'List<DsShadow>', 'Floating edge and shadow.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners.'),
            ('padding', 'EdgeInsetsGeometry', 'Inner padding.'),
            ('minWidth', 'double', 'Minimum width.'),
            ('gap', 'double', 'Space between items.'),
            ('dividerColor', 'Color', 'Line between groups.'),
            ('dividerMargin', 'EdgeInsetsGeometry', 'Space around a divider.'),
        ],
    ),
    dict(
        name='MenuItem', dir='menu', file='menu_item_style.dart',
        doc='The look of a `DsMenuItem`. Hover and keyboard focus are the same active look.',
        states=['focused', 'hovered', 'pressed', 'disabled'],
        fields=[
            ('height', 'double', 'Minimum height.'),
            ('padding', 'EdgeInsetsGeometry', 'Item padding.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners of the active fill.'),
            ('background', 'Color', 'Fill.'),
            ('foreground', 'Color', 'Label and icon color.'),
            ('textStyle', 'TextStyle', 'Label style, merged.'),
            ('shortcutStyle', 'TextStyle', 'Shortcut style, merged.'),
            ('iconSize', 'double', 'Icon size.'),
            ('gap', 'double', 'Space between parts.'),
            ('focusShadows', 'List<DsShadow>', 'Added while focused from the keyboard: an inset ring.'),
            ('cursor', None, None),
        ],
    ),
    dict(
        name='Dialog', dir='dialog', file='dialog_style.dart',
        doc='The look of a `DsDialog`.',
        states=[],
        fields=[
            ('background', 'Color', 'Fill.'),
            ('backdropFilter', 'ImageFilter', 'Filter for what shows through a translucent fill, e.g. `ImageFilter.blur` for a frosted layer; null filters nothing. Opaque by default.'),
            ('shadows', 'List<DsShadow>', 'Floating edge and shadow.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners.'),
            ('padding', 'EdgeInsetsGeometry', 'Inner padding.'),
            ('width', 'double', 'Preferred width; narrower screens shrink it.'),
            ('gap', 'double', 'Space between icon, text and actions.'),
            ('iconBoxSize', 'double', 'Tone disk size.'),
            ('iconBoxColor', 'Color', 'Tone disk fill.'),
            ('iconBoxRadius', 'BorderRadiusGeometry', 'Tone disk corners. When no layer sets them, rounded as a control of `iconBoxSize` (`DsRadii.controlCorners`), so a style that changes only the size keeps them in proportion.'),
            ('iconColor', 'Color', 'Icon color.'),
            ('iconSize', 'double', 'Icon size inside the tone disk.'),
            ('titleStyle', 'TextStyle', 'Title style, merged.'),
            ('descriptionStyle', 'TextStyle', 'Description style, merged.'),
        ],
    ),
    dict(
        name='Panel', dir='panel', file='panel_style.dart',
        doc='The look of a `DsPanel` (side panel or bottom sheet).',
        states=[],
        fields=[
            ('background', 'Color', 'Fill.'),
            ('backdropFilter', 'ImageFilter', 'Filter for what shows through a translucent fill, e.g. `ImageFilter.blur` for a frosted layer; null filters nothing. Opaque by default.'),
            ('shadows', 'List<DsShadow>', 'Floating edge and shadow.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners.'),
            ('padding', 'EdgeInsetsGeometry', 'Inner padding.'),
            ('margin', 'EdgeInsetsGeometry', 'Space between the panel and the screen edges.'),
            ('width', 'double', 'Side panel width.'),
            ('gap', 'double', 'Space between header, body and footer.'),
            ('titleStyle', 'TextStyle', 'Title style, merged.'),
            ('grabberColor', 'Color', 'Drag handle of a bottom sheet.'),
            ('grabberSize', 'Size', 'Drag handle size.'),
            ('sheetMaxWidth', 'double', 'Largest width of a bottom sheet.'),
        ],
    ),
    dict(
        name='Toast', dir='toast', file='toast_style.dart',
        doc='The look of a `DsToast`.',
        states=[],
        fields=[
            ('background', 'Color', 'Fill.'),
            ('backdropFilter', 'ImageFilter', 'Filter for what shows through a translucent fill, e.g. `ImageFilter.blur` for a frosted layer; null filters nothing. Opaque by default.'),
            ('shadows', 'List<DsShadow>', 'Floating edge and shadow.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners.'),
            ('padding', 'EdgeInsetsGeometry', 'Inner padding.'),
            ('maxWidth', 'double', 'Largest width.'),
            ('gap', 'double', 'Space between parts.'),
            ('iconSize', 'double', 'Status icon size.'),
            ('closeIconSize', 'double', 'Dismiss button icon size.'),
            ('titleStyle', 'TextStyle', 'Title style, merged.'),
            ('descriptionStyle', 'TextStyle', 'Description style, merged.'),
            ('textGap', 'double', 'Space between title and description.'),
        ],
    ),
    dict(
        name='Select', dir='select', file='select_style.dart',
        doc='The look of a `DsSelect` trigger.',
        states=['focused', 'hovered', 'pressed', 'error', 'disabled'],
        flags=[('readOnly', 'Laid over the base while the select is read-only: it shows a value that cannot be changed.')],
        fields=[
            ('height', 'double', 'Minimum height.'),
            ('padding', 'EdgeInsetsGeometry', 'Inner padding.'),
            ('background', 'Color', 'Fill.'),
            ('borderColor', 'Color', 'Inner outline.'),
            ('borderWidth', 'double', 'Width of the inner outline.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners. When no layer sets them, rounded as a control of `height` (`DsRadii.controlCorners`), so a style that changes only the height keeps them in proportion.'),
            ('foreground', 'Color', 'Value color.'),
            ('placeholderColor', 'Color', 'Placeholder color.'),
            ('iconColor', 'Color', 'Leading icon and chevron color.'),
            ('errorIconColor', 'Color', 'Error icon color; the error edge color when null.'),
            ('iconSize', 'double', 'Icon size.'),
            ('textStyle', 'TextStyle', 'Value style, merged.'),
            ('gap', 'double', 'Space between parts.'),
            ('clearStyle', 'DsButtonStyle', 'The clear button of a clearable select, laid over a ghost extra-small icon button.'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
        imports=['../button/button_style.dart'],
    ),
    dict(
        name='Autocomplete', dir='autocomplete', file='autocomplete_style.dart',
        doc='The look of a `DsAutocomplete` and a `DsMultiSelect`: the field, its tags and the popup list. Nested styles lay over the text field, menu and menu item themes. `selected` styles the tag that the arrow keys made active (the one Backspace removes next); `disabled` styles the tags of a disabled field.',
        states=['selected', 'disabled'],
        fields=[
            ('fieldStyle', 'DsTextFieldStyle', 'The well and its text, laid over the text field theme and resolved with the field states (hovered, focused, error, disabled).'),
            ('tagsPadding', 'EdgeInsetsGeometry', 'Padding of the well while it holds tags; the field padding applies otherwise. Its top and bottom center a line of tags in the field height.'),
            ('tagGap', 'double', 'Space between tags, along a line and between lines.'),
            ('inputGap', 'double', 'Extra space before the text after the last tag.'),
            ('inputMinWidth', 'double', 'Narrowest the typed text may get after the tags on a line, at text scale 1 (it scales with the text); with less room it moves to a line of its own. Empty text only needs room for the caret, so it never takes a line of its own.'),
            ('tagHeight', 'double', 'Minimum tag height; grows with large text.'),
            ('tagPadding', 'EdgeInsetsGeometry', 'Tag padding.'),
            ('tagBackground', 'Color', 'Tag fill.'),
            ('tagForeground', 'Color', 'Tag label color; the remove icon takes its color from `tagRemoveStyle`.'),
            ('tagBorderColor', 'Color', 'Inner 1px tag outline: by default only on an active tag whose bright fill needs one.'),
            ('tagBorderRadius', 'BorderRadiusGeometry', 'Tag corners. When no layer sets them, concentric with the field corners (`DsRadii.nestedCorners` by the top of `tagsPadding`), so a field height set in a style or theme keeps the tags concentric with it.'),
            ('tagTextStyle', 'TextStyle', 'Tag label style, merged.'),
            ('tagGapInside', 'double', 'Space between a tag label and its remove button.'),
            ('tagRemoveStyle', 'DsButtonStyle', 'The remove button of a tag, laid over a ghost extra-small icon button. When it sets no corners, the button is concentric with the tag.'),
            ('panelStyle', 'DsMenuStyle', 'The popup panel, laid over the menu theme. Its `backdropFilter` frosts the popup like a menu.'),
            ('optionStyle', 'DsMenuItemStyle', 'Option rows, laid over the menu item theme.'),
            ('matchStyle', 'TextStyle', 'Laid over the letters of an option that match the typed text.'),
            ('checkColor', 'Color', 'Check mark of a chosen option.'),
            ('maxHeight', 'double', 'Tallest the popup list grows before it scrolls.'),
            ('messageStyle', 'TextStyle', '"No results" and "Loading" text style, merged.'),
        ],
        imports=[
            '../button/button_style.dart',
            '../menu/menu_item_style.dart',
            '../menu/menu_style.dart',
            '../text_field/text_field_style.dart',
        ],
    ),
    dict(
        name='TextField', dir='text_field', file='text_field_style.dart',
        doc='The look of a `DsTextField`: the well and its edge, the text, the caret, the selection and its touch handles.',
        states=['focused', 'hovered', 'error', 'disabled'],
        flags=[('readOnly', 'Laid over the base while the field is read-only: its text can be selected and copied but not changed.')],
        fields=[
            ('height', 'double', 'Minimum height of the field.'),
            ('width', 'double', 'Width when the parent leaves it unbounded (a Row), like an HTML input\'s default size.'),
            ('padding', 'EdgeInsetsGeometry', 'Inner padding around the text.'),
            ('background', 'Color', 'Fill: the well.'),
            ('borderColor', 'Color', 'Inner outline.'),
            ('borderWidth', 'double', 'Width of the inner outline.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners. When no layer sets them, rounded as a control of `height` (`DsRadii.controlCorners`), so a style that changes only the height keeps them in proportion.'),
            ('foreground', 'Color', 'Text color.'),
            ('placeholderColor', 'Color', 'Placeholder color.'),
            ('iconColor', 'Color', 'Color of the leading and trailing icons.'),
            ('errorIconColor', 'Color', 'Error icon color; the edge color when null.'),
            ('iconSize', 'double', 'Icon size.'),
            ('textStyle', 'TextStyle', 'Text style, merged.'),
            ('gap', 'double', 'Space between the text and icons.'),
            ('affixGap', 'double', 'Space between the text and a text affix in the leading or trailing slot (a unit, "https://").'),
            ('caretColor', 'Color', 'Caret (text cursor) color.'),
            ('caretWidth', 'double', 'Caret width; its ends are rounded.'),
            ('selectionColor', 'Color', 'Highlight behind selected text.'),
            ('handleColor', 'Color', 'Selection handles on touch screens.'),
            ('handleSize', 'double', "Diameter of a selection handle's knob."),
            ('composingStyle', 'TextStyle', 'Text an input method (IME) is still composing, merged: an underline.'),
            ('misspelledStyle', 'TextStyle', 'A word the spell checker flags, merged: a dotted underline on Apple platforms, a wavy one elsewhere.'),
            ('misspelledSelectionColor', 'Color', 'Highlight behind a flagged word while its spelling suggestions show (iOS selects the word).'),
            ('shadows', 'List<DsShadow>', 'Elevation around the edge, e.g. a search field drawn as a control.'),
            ('counterStyle', 'TextStyle', 'Character counter ("12 / 100") style, merged.'),
            ('counterOverStyle', 'TextStyle', 'Laid over the counter style while the text is over the limit.'),
            ('counterGap', 'double', 'Space between the field and the counter below it.'),
            ('clearStyle', 'DsButtonStyle', 'The clear button, laid over a ghost extra-small icon button.'),
            ('revealStyle', 'DsButtonStyle', 'The show-password button, laid over a ghost extra-small icon button.'),
            ('shortcutStyle', 'TextStyle', "A search field's shortcut hint (\u2318K) text, merged."),
            ('shortcutBackground', 'Color', 'Fill behind the shortcut hint.'),
            ('shortcutPadding', 'EdgeInsetsGeometry', 'Padding around the shortcut hint.'),
            ('shortcutBorderRadius', 'BorderRadiusGeometry', 'Corners of the shortcut hint. When no layer sets them, concentric with the field corners (`DsRadii.nestedCorners` by the end padding).'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
        variants=('DsTextFieldVariant', 'text_field_variant.dart', 'variants', 'variant'),
        imports=['../button/button_style.dart'],
    ),
    dict(
        name='NumberField', dir='number_field', file='number_field_style.dart',
        doc='The look of a `DsNumberField`: its text field, the unit, and the decrease and increase buttons. `hovered`, `pressed` and `disabled` style a button; `disabled` also one at a limit.',
        states=['hovered', 'pressed', 'disabled'],
        fields=[
            ('fieldStyle', 'DsTextFieldStyle', 'The text field, laid over its own defaults and theme: a narrower default width.'),
            ('unitStyle', 'TextStyle', 'Unit and prefix text, merged; the color comes from the field (its placeholder color).'),
            ('buttonWidth', 'double', 'Drawn width of each button; never less than the minimum tap target.'),
            ('buttonColor', 'Color', 'Button fill.'),
            ('foreground', 'Color', 'Button icon color.'),
            ('iconSize', 'double', 'Minus and plus icon size, scaled with the text.'),
            ('dividerColor', 'Color', 'Hairline before and between the buttons.'),
            ('dividerWidth', 'double', 'Width of the hairlines.'),
            ('cursor', None, None),
        ],
        imports=['../text_field/text_field_style.dart'],
    ),
    dict(
        name='TextSelectionToolbar', dir='text_field', file='text_selection_toolbar_style.dart',
        doc='The look of the floating edit toolbar (Cut, Copy, Paste) on touch screens. `pressed` and `disabled` style its buttons.',
        states=['pressed', 'disabled'],
        fields=[
            ('height', 'double', 'Height of each button, the tap height.'),
            ('padding', 'EdgeInsetsGeometry', 'Inner padding of the pill.'),
            ('background', 'Color', 'Fill of the pill.'),
            ('backdropFilter', 'ImageFilter', 'Filter for what shows through a translucent fill, e.g. `ImageFilter.blur` for a frosted layer; null filters nothing. Opaque by default.'),
            ('shadows', 'List<DsShadow>', 'Elevation and edge of the pill.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners of the pill.'),
            ('itemPadding', 'EdgeInsetsGeometry', 'Padding of each button.'),
            ('itemBackground', 'Color', 'Fill of a button, e.g. while pressed.'),
            ('itemBorderRadius', 'BorderRadiusGeometry', 'Corners of a button fill.'),
            ('foreground', 'Color', 'Button label color.'),
            ('textStyle', 'TextStyle', 'Button label style, merged.'),
            ('dividerColor', 'Color', 'Line between buttons.'),
            ('margin', 'double', 'Distance kept from the selection and the window edges.'),
        ],
    ),
    dict(
        name='TextMagnifier', dir='text_field', file='text_magnifier_style.dart',
        doc='The look of the loupe that enlarges the text under the finger while a touch user drags a selection handle or long-presses to select.',
        states=[],
        fields=[
            ('width', 'double', 'Width of the loupe.'),
            ('height', 'double', 'Height of the loupe.'),
            ('magnification', 'double', 'How much the text under the finger is enlarged; 1 shows it as it is.'),
            ('lift', 'double', 'Distance from the middle of the line to the bottom of the loupe, so the finger does not cover it.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Corners of the loupe.'),
            ('shadows', 'List<DsShadow>', 'Elevation and edge of the loupe, drawn around the enlarged text (inset ones over it).'),
        ],
    ),
    dict(
        name='Field', dir='field', file='field_style.dart',
        doc='The look of a `DsField`: its label, required mark and message. `error` styles the field while it shows an error.',
        states=['error'],
        fields=[
            ('labelStyle', 'TextStyle', 'Label style, merged.'),
            ('requiredColor', 'Color', 'Color of the required mark after the label.'),
            ('messageStyle', 'TextStyle', 'Description and error message style, merged.'),
            ('iconColor', 'Color', 'Error icon color.'),
            ('iconSize', 'double', 'Error icon size.'),
            ('labelGap', 'double', 'Space between the label and the control.'),
            ('messageGap', 'double', 'Space between the control and the message.'),
            ('gap', 'double', 'Space between the label and the required mark, and between the error icon and the message.'),
        ],
    ),
    # File upload.
    dict(
        name='FileUpload', dir='file_upload', file='file_upload_style.dart',
        doc='The look of a `DsFileUpload` drop zone. `selected` styles it while files are dragged over it (`DsFileUpload.dragging`); `error` while it shows an error.',
        states=['focused', 'hovered', 'pressed', 'selected', 'error', 'disabled'],
        fields=[
            ('width', 'double', 'Width in an unbounded width (a Row); otherwise it fills the width it gets.'),
            ('height', 'double', 'Minimum height of the zone.'),
            ('padding', 'EdgeInsetsGeometry', 'Space inside the zone.'),
            ('background', 'Color', 'Zone fill.'),
            ('borderColor', 'Color', 'Color of the dashed edge.'),
            ('borderWidth', 'double', 'Width of the dashed edge.'),
            ('dashLength', 'double', 'Length of one dash.'),
            ('dashGap', 'double', 'Space between dashes.'),
            ('borderRadius', 'BorderRadius', 'Zone corners.'),
            ('iconColor', 'Color', 'Upload icon color.'),
            ('iconSize', 'double', 'Upload icon size.'),
            ('titleStyle', 'TextStyle', 'Prompt style, merged.'),
            ('actionStyle', 'TextStyle', 'The "browse" word in the prompt, merged over the title style.'),
            ('descriptionStyle', 'TextStyle', 'Description style (types, size limit), merged.'),
            ('gap', 'double', 'Space between the icon, the prompt and the description.'),
            ('listGap', 'double', 'Space between the zone and the file rows, and between rows.'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
    ),
    dict(
        name='FileItem', dir='file_upload', file='file_item_style.dart',
        doc='The look of a `DsFileItem` row. `error` styles a row whose upload failed.',
        states=['error'],
        imports=['../button/button_style.dart'],
        fields=[
            ('padding', 'EdgeInsetsGeometry', 'Space inside the row.'),
            ('background', 'Color', 'Row fill.'),
            ('shadows', 'List<DsShadow>', 'Edge and elevation; the error edge in the error state.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Row corners.'),
            ('iconColor', 'Color', 'File icon color while uploading.'),
            ('successColor', 'Color', 'Icon color of a finished upload.'),
            ('errorColor', 'Color', 'Icon color of a failed upload.'),
            ('iconSize', 'double', 'Status icon size.'),
            ('nameStyle', 'TextStyle', 'File name style, merged.'),
            ('metaStyle', 'TextStyle', 'Size and percentage style, merged.'),
            ('messageStyle', 'TextStyle', 'Error message style, merged.'),
            ('progressHeight', 'double', 'Thickness of the progress bar.'),
            ('gap', 'double', 'Space between the icon, the text and the buttons.'),
            ('textGap', 'double', 'Space between the name line and the progress bar or message.'),
            ('iconButtonStyle', 'DsButtonStyle', 'Cancel and remove buttons, laid over a ghost extra-small icon button.'),
            ('textButtonStyle', 'DsButtonStyle', 'The retry button, laid over a ghost extra-small text button.'),
        ],
    ),
    # 8a table
    dict(
        name='Table', dir='table', file='table_style.dart',
        doc='The look of a `DsTable`. Container, header and message fields are read unresolved; row fields resolve per row with its states (focused, hovered, pressed, selected).',
        states=['focused', 'hovered', 'pressed', 'selected'],
        fields=[
            ('background', 'Color', 'Container fill.'),
            ('shadows', 'List<DsShadow>', 'Container edge and elevation.'),
            ('borderRadius', 'BorderRadiusGeometry', 'Container corners; rows are clipped to them.'),
            ('headerHeight', 'double', 'Minimum header height; grows with large text.'),
            ('headerStyle', 'TextStyle', 'Column header text style, merged.'),
            ('headerActiveColor', 'Color', 'Header label and sort arrow color of the sorted column, and of a sortable column while hovered or focused.'),
            ('sortIconSize', 'double', 'Sort arrow size.'),
            ('rowHeight', 'double', 'Minimum row height; grows with large text or taller cells.'),
            ('rowBackground', 'Color', 'Row fill.'),
            ('rowBorderColor', 'Color', 'Inner 1px row outline; none by default.'),
            ('textStyle', 'TextStyle', 'Cell text style, merged.'),
            ('numericStyle', 'TextStyle', 'Laid over the cell text style in numeric columns: tabular figures.'),
            ('padding', 'EdgeInsetsGeometry', 'Row and header padding. With a selection column, the column takes the place of the start padding.'),
            ('columnGap', 'double', 'Space between columns.'),
            ('minColumnWidth', 'double', 'Narrowest a flexible column gets when it sets no minimum, before the table scrolls sideways.'),
            ('selectionColumnWidth', 'double', 'Width of the checkbox column.'),
            ('dividerColor', 'Color', 'Line under the header and between rows.'),
            ('emptyStateStyle', 'DsEmptyStateStyle', 'Empty and error states, laid over the empty state theme: compact, without the tone disk.'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
        imports=['../empty_state/empty_state_style.dart'],
    ),
    # 8b date/time
    dict(
        name='Calendar', dir='date', file='calendar_style.dart',
        doc='The look of a `DsCalendar` or `DsRangeCalendar`: the month header, the weekday row and the days. States resolve per day; `selected` is a chosen day or an end of a chosen range (Desen draws it as a solid accent fill whatever the selection style), `disabled` a day that cannot be chosen. Header and grid fields are read unresolved.',
        states=['focused', 'hovered', 'pressed', 'selected', 'disabled'],
        fields=[
            ('daySize', 'double', 'Drawn width and height of a day; grows with large text.'),
            ('dayRadius', 'BorderRadiusGeometry', 'Corners of a day. When no layer sets them, rounded as a control of `daySize` (`DsRadii.controlCorners`), so a style that changes only the size keeps them in proportion.'),
            ('dayBackground', 'Color', 'Fill of a day; under `selected`, the solid fill of the chosen day and of both range ends.'),
            ('dayForeground', 'Color', 'Number color of a day.'),
            ('dayBorderColor', 'Color', 'Inner 1px outline of a day, e.g. the edge of a bright accent fill that melts into the card.'),
            ('dayTextStyle', 'TextStyle', 'Number style, merged (tabular figures).'),
            ('todayForeground', 'Color', "Today's number while it is not selected: the accent text color."),
            ('todayTextStyle', 'TextStyle', 'Laid over the number style for today: bold.'),
            ('todayBorderColor', 'Color', "Inner 1px ring of today while it is not selected, so today is not marked by color alone; Desen uses the accent text color (3:1 off the card, the popup and the range band). A selected today drops it: the fill marks the day."),
            ('outsideForeground', 'Color', 'Number color of a shown day of the month before or after.'),
            ('rangeColor', 'Color', 'Band behind the days of a chosen range, joined from end to end.'),
            ('rangeEdgeColor', 'Color', 'Inner 1px line along the top and bottom of the range band, following its rounded ends, and around the filled range ends the band joins, so the outline runs unbroken; none by default.'),
            ('columnGap', 'double', 'Space between days in a week; the tap areas fill it.'),
            ('rowGap', 'double', 'Space between weeks; the tap areas fill it.'),
            ('headerStyle', 'TextStyle', 'Month and year title style, merged.'),
            ('headerPadding', 'EdgeInsetsGeometry', 'Padding around the month header.'),
            ('weekdayStyle', 'TextStyle', 'Weekday column header style, merged.'),
            ('gap', 'double', 'Space between the header, the weekday row and the days.'),
            ('monthGap', 'double', 'Space between two months shown side by side.'),
            ('navButtonStyle', 'DsButtonStyle', 'The previous and next month buttons, laid over a ghost small icon button.'),
            ('slideOffset', 'double', 'How far a month slides in when it changes (not under reduced motion).'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
        imports=['../button/button_style.dart'],
    ),
    dict(
        name='DatePicker', dir='date', file='date_picker_style.dart',
        doc='The look of a `DsDatePicker` and a `DsDateRangePicker`: the field, its calendar button and the popup calendar. Nested styles lay over the text field, button, popover and calendar themes.',
        states=[],
        fields=[
            ('fieldStyle', 'DsTextFieldStyle', 'The text field, laid over its own defaults and theme: a default width.'),
            ('rangeWidth', 'double', "Width of a range picker's field when the parent leaves it unbounded (a Row)."),
            ('buttonStyle', 'DsButtonStyle', 'The calendar button, laid over a ghost extra-small icon button.'),
            ('panelStyle', 'DsPopoverStyle', 'The popup panel, laid over the popover theme.'),
            ('calendarStyle', 'DsCalendarStyle', 'The calendar in the popup, laid over the calendar theme.'),
            ('wideBreakpoint', 'double', 'Window width from which a range picker shows two months side by side.'),
        ],
        imports=[
            '../button/button_style.dart',
            '../popover/popover_style.dart',
            '../text_field/text_field_style.dart',
            'calendar_style.dart',
        ],
    ),
    dict(
        name='TimePicker', dir='time', file='time_picker_style.dart',
        doc='The look of a `DsTimePicker`: the field, its clock button and the popup columns. States resolve per column item; `focused` is the keyboard-focused column\'s chosen item. Field, button and panel styles lay over their themes; column fields are read unresolved.',
        states=['focused', 'hovered', 'pressed', 'selected'],
        fields=[
            ('fieldStyle', 'DsTextFieldStyle', 'The text field, laid over its own defaults and theme: a default width.'),
            ('buttonStyle', 'DsButtonStyle', 'The clock button, laid over a ghost extra-small icon button.'),
            ('panelStyle', 'DsPopoverStyle', 'The popup panel, laid over the popover theme.'),
            ('columnWidth', 'double', 'Width of a column.'),
            ('columnGap', 'double', 'Space between columns; the divider sits in it.'),
            ('dividerColor', 'Color', 'Line between columns.'),
            ('visibleItems', 'double', 'How many items a column shows before it scrolls.'),
            ('itemHeight', 'double', 'Minimum item height; grows with large text.'),
            ('itemGap', 'double', 'Space between items.'),
            ('itemRadius', 'BorderRadiusGeometry', 'Item corners.'),
            ('itemBackground', 'Color', 'Item fill.'),
            ('itemForeground', 'Color', 'Item text color.'),
            ('itemBorderColor', 'Color', 'Inner 1px item outline, e.g. the edge a bright filled selection needs.'),
            ('itemTextStyle', 'TextStyle', 'Item text style, merged (tabular digits).'),
            ('focusShadows', None, None),
            ('cursor', None, None),
        ],
        imports=[
            '../button/button_style.dart',
            '../popover/popover_style.dart',
            '../text_field/text_field_style.dart',
        ],
    ),
]


def gen(spec):
    name = spec['name']
    S = f'Ds{name}Style'
    TD = f'Ds{name}ThemeData'
    TW = f'Ds{name}Theme'
    states = spec['states']
    flags = spec.get('flags', [])
    flag_names = [f for f, _ in flags]
    flag_params = ''.join(f', bool {f} = false' for f in flag_names)
    flag_sig = f', {{{flag_params[2:]}}}' if flags else ''
    flag_pass = ''.join(f', {f}: {f}' for f in flag_names)
    fields = []
    for fname, ftype, fdoc in spec['fields']:
        if ftype is None:
            ftype, fdoc = COMMON[fname]
        fields.append((fname, ftype, fdoc))
    variants = spec.get('variants')
    defaults = spec.get('defaults', [])

    o = []
    w = o.append
    w('// GENERATED by tool/gen_styles.py. Do not edit by hand.')
    w('')
    if any(t == 'ImageFilter' for _, t, _ in fields):
        w("import 'dart:ui' show ImageFilter;")
        w('')
    w("import 'package:flutter/foundation.dart';")
    w("import 'package:flutter/widgets.dart';")
    w('')
    w("import '../../foundation/component_theme.dart';")
    if any(t == 'List<DsShadow>' for _, t, _ in fields):
        w("import '../../painting/shadow.dart';")
    for imp in spec.get('imports', []):
        w(f"import '{imp}';")
    if variants:
        w(f"import '{variants[1]}';")
    w('')
    w(f'/// {spec["doc"]}')
    w('///')
    w('/// Every field is optional; null means "keep the layer below". To remove')
    w('/// something, pass an empty value (`const []`, a transparent color).')
    if states:
        w('///')
        w('/// State styles lay over the base like CSS blocks. Interaction states')
        w('/// (focused, hovered, pressed) apply first; structural ones (selected,')
        w('/// error, disabled) apply after and resolve their own nested states, so')
        w(f'/// `selected: {S}(hovered: …)` is the selected-and-hovered look.')
    for fl in flag_names:
        w('///')
        w(f'/// [{fl}] is a state too, passed to [resolve] as a flag: it applies')
        w('/// after the interaction states and before the structural ones, so')
        w(f'/// `error: {S}({fl}: …)` styles an error while [{fl}] is set.')
    w('@immutable')
    w(f'class {S} with Diagnosticable {{')
    w('  /// Creates a style.')
    w(f'  const {S}({{')
    for f, _, _ in fields:
        w(f'    this.{f},')
    for st in states + flag_names:
        w(f'    this.{st},')
    w('  });')
    w('')
    for f, t, d in fields:
        w(f'  /// {d}')
        w(f'  final {t}? {f};')
        w('')
    for st in states:
        w(f'  /// Laid over the base while {st}.')
        w(f'  final {S}? {st};')
        w('')
    for fl, fdoc in flags:
        w(f'  /// {fdoc}')
        w(f'  final {S}? {fl};')
        w('')
    # merge
    w('  /// Lays [other] over this: its set fields win; state styles merge.')
    w(f'  {S} merge({S}? other) {{')
    w('    if (other == null) return this;')
    w(f'    return {S}(')
    for f, t, _ in fields:
        # Text styles and nested component styles merge field by field.
        if t == 'TextStyle' or (t.startswith('Ds') and t.endswith('Style')):
            w(f'      {f}: {f}?.merge(other.{f}) ?? other.{f},')
        else:
            w(f'      {f}: other.{f} ?? {f},')
    for st in states + flag_names:
        w(f'      {st}: {st} == null ? other.{st} : {st}!.merge(other.{st}),')
    w('    );')
    w('  }')
    w('')
    # base & resolve
    if states:
        w(f'  {S} get _base => {S}(')
        for f, _, _ in fields:
            w(f'    {f}: {f},')
        w('  );')
        w('')
        w('  /// This style flattened for [states] (see the class docs for the order).')
        w(f'  {S} resolve(Set<WidgetState> states{flag_sig}) {{')
        w('    var s = _base;')
        for st in INTERACTION:
            if st in states:
                w(f'    if (states.contains(WidgetState.{st}) && {st} != null) {{')
                w(f'      s = s.merge({st}!._base);')
                w('    }')
        for fl in flag_names:
            w(f'    if ({fl} && this.{fl} != null) {{')
            w(f'      s = s.merge(this.{fl}!.resolve(states));')
            w('    }')
        for st in STRUCTURAL:
            if st in states:
                w(f'    if (states.contains(WidgetState.{st}) && {st} != null) {{')
                w(f'      s = s.merge({st}!.resolve({{...states}}..remove(WidgetState.{st}){flag_pass}));')
                w('    }')
        w('    return s;')
        w('  }')
    else:
        w('  /// This style; it has no state styles.')
        w(f'  {S} resolve(Set<WidgetState> states) => this;')
    w('')
    w('  /// Resolves each layer for [states] and lays them over each other,')
    w('  /// weakest first.')
    w(f'  static {S} resolveLayers(Iterable<{S}?> layers, Set<WidgetState> states{flag_sig}) {{')
    w(f'    var result = const {S}();')
    w('    for (final layer in layers) {')
    if flags:
        w('      if (layer != null) {')
        w(f'        result = result.merge(layer.resolve(states{flag_pass}));')
        w('      }')
    else:
        w('      if (layer != null) result = result.merge(layer.resolve(states));')
    w('    }')
    w('    return result;')
    w('  }')
    w('')
    allf = [f for f, _, _ in fields] + states + flag_names
    w('  List<Object?> get _fields => [')
    for f in allf:
        w(f'    {f},')
    w('  ];')
    w('')
    w('  @override')
    w('  bool operator ==(Object other) {')
    w('    if (identical(this, other)) return true;')
    w(f'    if (other is! {S}) return false;')
    w('    final a = _fields, b = other._fields;')
    w('    for (var i = 0; i < a.length; i++) {')
    w('      final x = a[i], y = b[i];')
    w('      if (x is List && y is List ? !listEquals(x, y) : x != y) return false;')
    w('    }')
    w('    return true;')
    w('  }')
    w('')
    w('  @override')
    w('  int get hashCode =>')
    w('      Object.hashAll(_fields.map((f) => f is List ? Object.hashAll(f) : f));')
    w('')
    w('  @override')
    w('  void debugFillProperties(DiagnosticPropertiesBuilder properties) {')
    w('    super.debugFillProperties(properties);')
    for f, t, _ in fields:
        if t == 'Color':
            w(f"    properties.add(ColorProperty('{f}', {f}, defaultValue: null));")
        elif t == 'double':
            w(f"    properties.add(DoubleProperty('{f}', {f}, defaultValue: null));")
        else:
            w(f"    properties.add(DiagnosticsProperty('{f}', {f}, defaultValue: null));")
    for st in states + flag_names:
        w(f"    properties.add(DiagnosticsProperty('{st}', {st}, defaultValue: null));")
    w('  }')
    w('}')
    w('')
    # Theme data
    w(f'/// Defaults for every `Ds{name}` in a subtree; see [{TW}].')
    w(f'class {TD} extends DsComponentThemeData<{TD}> {{')
    w('  /// Creates defaults.')
    params = ''.join(f'this.{d}, ' for d, _, _ in defaults) + 'this.style'
    if variants:
        params += f', this.{variants[2]} = const {{}}'
    w(f'  const {TD}({{{params}}});')
    w('')
    for d, dtype, ddoc in defaults:
        w(f'  /// {ddoc}')
        w(f'  final {dtype}? {d};')
        w('')
    noun = (variants[3] if len(variants) > 3 else 'status') if variants else ''
    w(f'  /// Laid over Desen\'s defaults{" for every " + noun if variants else ""}.')
    w(f'  final {S}? style;')
    w('')
    if variants:
        w(f'  /// Laid over [style] for one {variants[0]} each.')
        w(f'  final Map<{variants[0]}, {S}> {variants[2]};')
        w('')
    w('  @override')
    w(f'  {TD} merge({TD}? other) {{')
    w('    if (other == null) return this;')
    w(f'    return {TD}(')
    for d, _, _ in defaults:
        w(f'      {d}: other.{d} ?? {d},')
    w('      style: style?.merge(other.style) ?? other.style,')
    if variants:
        v = variants[2]
        w(f'      {v}: {{')
        w(f'        for (final k in {{...{v}.keys, ...other.{v}.keys}})')
        w(f'          k: {v}[k]?.merge(other.{v}[k]) ?? other.{v}[k]!,')
        w('      },')
    w('    );')
    w('  }')
    w('')
    w('  @override')
    same = ''.join(f' && other.{d} == {d}' for d, _, _ in defaults)
    hashed = ''.join(f'    {d},\n' for d, _, _ in defaults)
    if variants:
        v = variants[2]
        w(f'  bool operator ==(Object other) =>')
        w(f'      other is {TD}{same} && other.style == style && mapEquals(other.{v}, {v});')
        w('')
        w('  @override')
        w(f'  int get hashCode => Object.hash(')
        if hashed:
            w(hashed.rstrip('\n'))
        w('    style,')
        w(f'    Object.hashAllUnordered({v}.entries.map((e) => Object.hash(e.key, e.value))),')
        w('  );')
    elif defaults:
        w(f'  bool operator ==(Object other) => other is {TD}{same} && other.style == style;')
        w('')
        w('  @override')
        w(f'  int get hashCode => Object.hash({", ".join(d for d, _, _ in defaults)}, style);')
    else:
        w(f'  bool operator ==(Object other) => other is {TD} && other.style == style;')
        w('')
        w('  @override')
        w('  int get hashCode => style.hashCode;')
    w('')
    w('  @override')
    w('  void debugFillProperties(DiagnosticPropertiesBuilder properties) {')
    w('    super.debugFillProperties(properties);')
    for d, dtype, _ in defaults:
        if dtype == 'bool':
            w(f"    properties.add(FlagProperty('{d}', value: {d}, ifTrue: '{d}', ifFalse: 'not {d}'));")
        else:
            w(f"    properties.add(EnumProperty('{d}', {d}, defaultValue: null));")
    w("    properties.add(DiagnosticsProperty('style', style, defaultValue: null));")
    w('  }')
    w('}')
    w('')
    w(f'/// Applies [{TD}] to a subtree, merged over any outer one.')
    w(f'class {TW} extends DsComponentTheme<{TD}> {{')
    w('  /// Applies [data] to [child].')
    w(f'  const {TW}({{super.key, required super.data, required super.child}});')
    w('')
    w('  /// The merged defaults for [context]; empty when there are none.')
    w(f'  static {TD} of(BuildContext context) =>')
    w(f'      DsComponentTheme.maybeOf<{TD}>(context) ?? const {TD}();')
    w('}')
    path = os.path.join(ROOT, spec['dir'], spec['file'])
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'w').write('\n'.join(o) + '\n')
    return path


if __name__ == '__main__':
    for spec in SPECS:
        print(gen(spec))

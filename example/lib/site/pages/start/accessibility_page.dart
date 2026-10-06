import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';
import '../foundations/common.dart';

/// Contrast, contrast levels, focus, screen readers, targets, motion, RTL
/// and text scaling.
class AccessibilityPage extends StatelessWidget {
  const AccessibilityPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Get started',
    title: 'Accessibility',
    lead:
        'Desen meets WCAG 2.2 AA by default: readable contrast in every '
        'theme, full keyboard use, screen reader semantics, real tap areas, '
        'reduced motion, right-to-left layout and large text. This page '
        'lists what the library does, so you know what is left to you.',
    sections: [
      DocSection(
        title: 'Contrast',
        children: [
          const DocText(
            'WCAG sets only minimums. Desen aims for AA without harshness: '
            'each role has a minimum and, where too much contrast hurts, a '
            'maximum. Dark mode never uses pure white text, and decorative '
            'edges stay quiet so the content stands out. The budget holds '
            'for any seed, not only the presets.',
          ),
          DocTable(
            columns: const ['Role', 'Against', 'Target'],
            flex: const [5, 4, 2],
            rows: [
              for (final (role, against, target) in _budget)
                [DocText(role), DocText(against), DocText(target)],
            ],
          ),
          const DocText(
            'Tests check the budget for the six presets in both modes at '
            'every contrast level, and for 22 real brand colors and 300 '
            'random seeds. [Colors](/foundations/colors) shows the ratios of '
            'the current theme, computed live.',
          ),
        ],
      ),
      const DocSection(
        title: 'Contrast levels',
        children: [
          DocText(
            '`DsThemeData.contrast` has two levels. Pages, cards, controls '
            'and floating layers keep their colors at both, text stays at '
            '4.5:1 or more and the focus ring at 3:1; they differ only in '
            'control boundaries.',
          ),
          DocList([
            '**Soft** is the iOS look. Text and focus are as at standard, but '
                'control boundaries are as faint as iOS draws them: the text '
                'field, checkbox and radio edge at about 1.5:1, the off '
                'switch and the slider track as light fills, lighter chip and '
                'button edges. Controls are told by fill, shape and shadow. '
                'This knowingly falls below WCAG 1.4.11, which asks 3:1 for '
                'the boundary of a control; choose it where that is accepted.',
            '**Standard**, the default, meets WCAG 2.2 AA throughout, '
                '1.4.11 (non-text contrast) included: every form control '
                'boundary (field, checkbox, radio, switch track) stands 3:1 '
                'off its surface, while decorative lines stay quiet.',
          ]),
          DocText(
            'Standard is the strongest level. `DsScope` (and `DsApp`) lift '
            'a soft theme to standard when the platform asks for more '
            'contrast: "Increase contrast" on iOS, high-contrast text on '
            'Android, contrast themes on Windows, and `prefers-contrast: '
            'more` in the browser. Turn that off with '
            '`followPlatformContrast: false`, and offer the levels as a '
            'setting, like the menu at the top of this site.',
          ),
          Board(child: _ContrastCompare()),
        ],
      ),
      DocSection(
        title: 'Keyboard focus',
        children: [
          const DocText(
            'Focus shows only for people using the keyboard, like CSS '
            '`:focus-visible`. A click or tap hides it and any key other than '
            'a lone modifier brings it back. Clicking a button does not move '
            'focus to it, as in Safari and macOS. Text fields are the '
            'exception: they show focus on every focus, because the caret is '
            'there. Click below, then press Tab.',
          ),
          Example(
            snippet: 'a11y-focus',
            padding: const EdgeInsets.all(24),
            child: const _FocusDemo(),
          ),
          const DocText(
            'Every focus indicator is one 2px line that reaches 3:1, drawn '
            'by the kind of control:',
          ),
          const DocList([
            '**Fields** (text, search, number, select, date, time) turn their '
                'edge into the focus color, inside the box.',
            '**Bordered controls** (secondary button, unselected chip) draw '
                'the ring in place of their 1px border.',
            '**Filled controls** (primary and danger buttons, selected chip, '
                'checkbox, radio, switch, segmented control) draw the ring '
                'with a 2px gap.',
            '**Full-width rows** (menu, list, sidebar, accordion) draw the '
                'ring inside the row.',
          ]),
          const DocText(
            'Every interactive component follows the WAI-ARIA pattern for '
            'its keys: arrows inside groups, Home and End, Escape to close, '
            'typeahead in menus and selects. Buttons take Enter and Space; '
            'links and breadcrumb levels take Enter only, as in browsers, so '
            'Space can scroll the page. Each component page has a keyboard '
            'table, as on [Button](/components/button).',
          ),
        ],
      ),
      const DocSection(
        title: 'Screen readers',
        children: [
          DocList([
            'Controls announce their role (button, link, checkbox, switch, '
                'radio, tab, slider…) and their state: selected, checked, '
                'mixed, expanded, disabled.',
            'A busy button stays focusable and announces "loading" while it '
                'ignores presses, so keyboard focus is not lost mid-task.',
            'Icon-only buttons need a `semanticLabel`. Icons are decorative '
                'unless you label them.',
            'A link with a `url` is a real link on the web, so the browser '
                'can open it in a new tab.',
            'State is never told by color alone: an error has a red edge, an '
                'icon and a message; a badge has a dot and a word.',
            'Toasts are live regions. A danger toast is announced '
                'assertively where the platform supports it.',
            'Every built-in string, including what screen readers hear, is '
                'translated into 13 languages; see '
                '[Localization](/localization).',
          ]),
        ],
      ),
      const DocSection(
        title: 'Touch targets',
        children: [
          DocText(
            'Every control can be hit across at least 24px with a mouse '
            '(WCAG 2.5.8) and 44px on iOS and Android, where small controls '
            'get an invisible tap area and keep their look. Rows are their '
            'own target. See [Spacing and sizes](/foundations/spacing).',
          ),
        ],
      ),
      const DocSection(
        title: 'Reduced motion',
        children: [
          DocText(
            'When the platform asks for reduced motion, nothing slides, '
            'scales or bounces; only fades remain. Spinners stop turning and '
            'pulse instead, and the skeleton shimmer and the caret stop. See '
            '[Motion](/foundations/motion).',
          ),
        ],
      ),
      DocSection(
        title: 'Right to left',
        children: [
          const DocText(
            'Components lay out from `Directionality`. Paddings, alignments '
            'and the order of icons and labels flip, and arrows that point '
            'somewhere (chevrons) mirror. Code stays left to right. To see '
            'every example on this site in Arabic, choose it as the preview '
            'language in the settings.',
          ),
          Example(
            snippet: 'a11y-rtl',
            padding: const EdgeInsets.all(24),
            child: const _RtlDemo(),
          ),
        ],
      ),
      DocSection(
        title: 'Text scaling',
        children: [
          const DocText(
            'Text follows the platform\'s text size. Controls grow taller '
            'with their text instead of clipping it; heights are minimums. '
            'Components are tested at twice the default size, and stay '
            'usable at three times.',
          ),
          Example(
            snippet: 'a11y-scale',
            padding: const EdgeInsets.all(24),
            alignment: AlignmentDirectional.topCenter,
            child: const _ScaleDemo(),
          ),
        ],
      ),
    ],
  );
}

const _budget = [
  ('Primary text', 'Surface', '7:1'),
  (
    'Secondary and tertiary text',
    'Page, surface, control, floating layer',
    '4.5:1',
  ),
  ('Links', 'Page, surface, floating layer', '4.5:1'),
  ('Accent text', 'Page, surface', '4.5:1'),
  (
    'Labels on accent, selection and danger fills, hover included',
    'Their fill',
    '4.5:1',
  ),
  ('Icons and bold labels on success, warning, info', 'Their fill', '3:1'),
  (
    'Form control edges: field, unchecked checkbox, switch rail',
    'Field, surface, page',
    '3:1',
  ),
  ('Focus ring', 'Page, surface, floating layer, sidebar', '3:1'),
  ('Progress and slider fill', 'The rest of the track', '3:1'),
  ('Channels: segmented control, skeleton', 'Surface, page', '1.15:1'),
  ('Disabled text', 'Disabled background', '3–4.5:1'),
  (
    'Decorative edges: dividers, cards, chips',
    'Surface or control',
    '1.2–1.8:1',
  ),
  ('Primary text in dark mode', 'Surface', 'at most 13:1'),
];

class _ContrastCompare extends StatelessWidget {
  const _ContrastCompare();

  @override
  Widget build(BuildContext context) {
    final site = DsTheme.of(context);
    final y = site.typography;
    return TokenGrid(
      minWidth: 300,
      spacing: 20,
      children: [
        for (final level in DsContrast.values)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Text(
                level.name,
                style: y.mono(y.caption).copyWith(color: site.colors.textMuted),
              ),
              ThemePreview(
                theme: site.copyWith(contrast: level),
                followContrast: false,
                child: const _ContrastSample(),
              ),
            ],
          ),
      ],
    );
  }
}

class _ContrastSample extends StatelessWidget {
  const _ContrastSample();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    return DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text(
            'Weekly report',
            style: t.typography.heading.copyWith(color: k.text),
          ),
          Text(
            'Sent every Monday at 9:00',
            style: t.typography.small.copyWith(color: k.textMuted),
          ),
          const DsField(
            label: Text('Recipients'),
            child: DsTextField(initialValue: 'team@northwind.dev'),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DsChip(
                label: const Text('PDF'),
                selected: true,
                onChanged: (_) {},
              ),
              DsChip(
                label: const Text('CSV'),
                selected: false,
                onChanged: (_) {},
              ),
            ],
          ),
          Row(
            spacing: 12,
            children: [
              DsCheckbox(
                value: false,
                semanticLabel: 'Attach charts',
                onChanged: (_) {},
              ),
              DsSwitch(
                value: false,
                semanticLabel: 'Paused',
                onChanged: (_) {},
              ),
              const Expanded(child: DsProgressBar(value: .6)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FocusDemo extends StatefulWidget {
  const _FocusDemo();

  @override
  State<_FocusDemo> createState() => _FocusDemoState();
}

class _FocusDemoState extends State<_FocusDemo> {
  bool _agree = false;
  bool _remember = true;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    // #region a11y-focus
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        const DsField(
          label: Text('Team name'),
          child: DsTextField(placeholder: 'Design systems'),
        ),
        DsCheckbox(
          value: _agree,
          onChanged: (v) => setState(() => _agree = v ?? false),
          label: const Text('I agree to the workspace rules'),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DsChip(
              label: const Text('Remember me'),
              selected: _remember,
              onChanged: (v) => setState(() => _remember = v),
            ),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            DsButton(
              variant: .secondary,
              onPressed: () {},
              child: const Text('Back'),
            ),
            DsButton(onPressed: () {}, child: const Text('Create team')),
          ],
        ),
      ],
    ),
    // #endregion
  );
}

class _RtlDemo extends StatelessWidget {
  const _RtlDemo();

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 340),
    // #region a11y-rtl
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          DsListSection(
            children: [
              DsListRow(
                leading: const DsIcon(DsIcons.user),
                title: const Text('الملف الشخصي'),
                showChevron: true,
                onPressed: () {},
              ),
              DsListRow(
                leading: const DsIcon(DsIcons.globe),
                title: const Text('اللغة'),
                detail: const Text('العربية'),
                showChevron: true,
                onPressed: () {},
              ),
            ],
          ),
          DsButton(onPressed: () {}, child: const Text('حفظ')),
        ],
      ),
    ),
    // #endregion
  );
}

class _ScaleDemo extends StatefulWidget {
  const _ScaleDemo();

  @override
  State<_ScaleDemo> createState() => _ScaleDemoState();
}

class _ScaleDemoState extends State<_ScaleDemo> {
  double _scale = 1.5;
  bool _alerts = true;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        DsField(
          label: Text('Text size ${_scale.toStringAsFixed(1)}×'),
          child: DsSlider(
            value: _scale,
            min: 1,
            max: 2,
            divisions: 4,
            onChanged: (v) => setState(() => _scale = v),
            semanticLabel: 'Text size',
          ),
        ),
        // #region a11y-scale
        MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(_scale)),
          child: DsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                DsSwitch(
                  value: _alerts,
                  onChanged: (v) => setState(() => _alerts = v),
                  label: const Text('Price alerts'),
                ),
                DsButton(onPressed: () {}, child: const Text('Save')),
              ],
            ),
          ),
        ),
        // #endregion
      ],
    ),
  );
}

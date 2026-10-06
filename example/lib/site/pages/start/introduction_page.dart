import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';
import '../../links.dart';

/// The home page: what Desen is, a live sample and where to go next.
class IntroductionPage extends StatelessWidget {
  const IntroductionPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    title: 'Desen UI',
    lead:
        'Web-grade components for Flutter, built on the widgets layer only. '
        'No Material, no Cupertino. Calm, legible, accessible by default, '
        'and themed from a single brand color.',
    sections: [
      DocSection(
        title: 'At a glance',
        children: [
          Example(
            snippet: 'intro-sample',
            padding: const EdgeInsets.all(24),
            child: const _Sample(),
          ),
          const DocText(
            'Everything on this site is Desen. Change the tone, appearance, '
            'contrast, corners or density from the settings button at the '
            'top, and the examples\' language from the same place.',
          ),
        ],
      ),
      const DocSection(
        title: 'Principles',
        children: [
          DocList([
            '**Widgets layer only.** `desen_ui` never imports `material.dart` '
                'or `cupertino.dart`; it works under `DsApp`, `WidgetsApp` or '
                'even `MaterialApp`.',
            '**One seed, every role.** Colors are generated in OKLCH from one '
                'brand color, with rules that keep selection apart from danger '
                'and success and keep every label readable.',
            '**AA, never harsh.** Text and controls meet WCAG AA in every '
                'tone and both modes; a soft level draws control edges as '
                'faintly as iOS.',
            '**Keyboard first.** Every component follows the WAI-ARIA '
                'pattern for its keys; focus shows only for keyboard users.',
            '**Built for the web, at home on phones.** Desktop density with '
                '24px targets; 44px tap areas on iOS and Android.',
            '**13 languages, right to left included.** Built-in strings, '
                'dates and numbers follow the locale.',
          ]),
        ],
      ),
      DocSection(
        title: 'Next steps',
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _NextCard(
                path: '/getting-started',
                title: 'Getting started',
                body: 'Install the package and build your first screen.',
              ),
              _NextCard(
                path: '/theming',
                title: 'Theming',
                body: 'Brand color, contrast, corners, density and tokens.',
              ),
              _NextCard(
                path: '/components/button',
                title: 'Components',
                body: 'Every component, with live examples and code.',
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _Sample extends StatefulWidget {
  const _Sample();

  @override
  State<_Sample> createState() => _SampleState();
}

class _SampleState extends State<_Sample> {
  String _plan = 'team';
  bool _notify = true;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    // #region intro-sample
    child: DsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          const DsField(
            label: Text('Workspace name'),
            child: DsTextField(initialValue: 'Northwind'),
          ),
          DsField(
            label: const Text('Plan'),
            child: DsSegmentedControl<String>(
              value: _plan,
              onChanged: (v) => setState(() => _plan = v),
              segments: const [
                DsSegment(value: 'solo', label: Text('Solo')),
                DsSegment(value: 'team', label: Text('Team')),
                DsSegment(value: 'org', label: Text('Organization')),
              ],
            ),
          ),
          DsSwitch(
            value: _notify,
            onChanged: (v) => setState(() => _notify = v),
            label: const Text('Email me about activity'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              DsButton(
                variant: .ghost,
                onPressed: () {},
                child: const Text('Cancel'),
              ),
              DsButton(onPressed: () {}, child: const Text('Create workspace')),
            ],
          ),
        ],
      ),
    ),
    // #endregion
  );
}

class _NextCard extends StatelessWidget {
  const _NextCard({
    required this.path,
    required this.title,
    required this.body,
  });

  final String path, title, body;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return SizedBox(
      width: 260,
      child: DsCard(
        onPressed: () => SiteLinks.of(context).go(path),
        semanticLabel: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: t.typography.heading.copyWith(color: t.colors.text),
                  ),
                ),
                DsIcon(DsIcons.chevronRight, color: t.colors.textSubtle),
              ],
            ),
            Text(
              body,
              style: t.typography.small.copyWith(color: t.colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

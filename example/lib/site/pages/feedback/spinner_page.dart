import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

class SpinnerPage extends StatelessWidget {
  const SpinnerPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Feedback',
    title: 'Spinner',
    lead:
        'A small turning ring for a short wait with nothing to measure: '
        'saving, syncing, fetching a preview. When you know how far along '
        'the work is, show a [Progress](/components/progress) bar. When the '
        'layout of what is coming is known, a [Skeleton](/components/skeleton) '
        'keeps the page steady.',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(
            snippet: 'spinner-overview',
            child: Builder(
              builder: (context) {
                final t = DsTheme.of(context);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    // #region spinner-overview
                    const DsSpinner(),
                    // #endregion
                    Text(
                      'Syncing changes…',
                      style: t.typography.small.copyWith(
                        color: t.colors.textMuted,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Size and color',
        children: [
          const DocText(
            'The spinner takes its size and color from the surrounding icon '
            'theme, at 14/16 of the icon size, so beside a 16px icon it is '
            '14px and in a button it matches the label. Set them directly '
            'with a `DsSpinnerStyle`.',
          ),
          Example(
            snippet: 'spinner-sizes',
            child: Builder(
              builder: (context) {
                // #region spinner-sizes
                // Theme colors:
                final k = DsTheme.colorsOf(context);
                return Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const DsSpinner(),
                    DsSpinner(
                      style: DsSpinnerStyle(size: 20, color: k.accentText),
                    ),
                    DsSpinner(
                      style: DsSpinnerStyle(
                        size: 32,
                        strokeWidth: 3,
                        color: k.textMuted,
                      ),
                    ),
                  ],
                );
                // #endregion
              },
            ),
          ),
        ],
      ),
      DocSection(
        title: 'In buttons',
        children: [
          const DocText(
            'Do not put a spinner in a button yourself. Set the button\'s '
            '`loading` instead: it shows a spinner in the label color, keeps '
            'its size and focus, and ignores presses. See '
            '[Button](/components/button).',
          ),
          Example(
            snippet: 'spinner-button',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                // #region spinner-button
                DsButton(
                  loading: true,
                  onPressed: () {},
                  child: const Text('Save'),
                ),
                DsButton(
                  variant: .secondary,
                  loading: true,
                  onPressed: () {},
                  child: const Text('Export'),
                ),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Announcing',
        children: [
          const DocText(
            'Without `semanticLabel` the spinner is decorative: use that when '
            'nearby text already says what is happening. With a label, it '
            'becomes a live region and screen readers say the label when the '
            'spinner appears.',
          ),
          Example(
            snippet: 'spinner-label',
            child: Builder(
              builder: (context) {
                final t = DsTheme.of(context);
                return DsCard(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 12,
                    children: [
                      // #region spinner-label
                      const DsSpinner(semanticLabel: 'Loading preview'),
                      // #endregion
                      Text(
                        'Q4 report.pdf',
                        style: t.typography.body.copyWith(color: t.colors.text),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'Set the stroke, size or color for every spinner below a point '
            'with `DsSpinnerTheme`.',
          ),
          Example(
            snippet: 'spinner-custom',
            // #region spinner-custom
            child: const DsSpinnerTheme(
              data: DsSpinnerThemeData(
                style: DsSpinnerStyle(strokeWidth: 1.5, size: 18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 24,
                children: [DsSpinner(), DsSpinner(), DsSpinner()],
              ),
            ),
            // #endregion
          ),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'Hidden from screen readers unless it has a `semanticLabel`; '
                'then it is a live region that reads the label.',
            'When the system asks to reduce motion, the ring stops turning '
                'and slowly pulses its opacity, so it still reads as '
                'working.',
            'The spinner is not focusable and takes no input.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            (
              'semanticLabel',
              'String?',
              'Read aloud when shown. Null keeps it decorative.',
            ),
            (
              'style',
              'DsSpinnerStyle?',
              '`size`, `color` and `strokeWidth` (default 2).',
            ),
          ]),
        ],
      ),
    ],
  );
}

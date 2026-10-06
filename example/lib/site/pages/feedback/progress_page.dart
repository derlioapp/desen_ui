import 'dart:async';

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../doc.dart';

/// Bars read best at a form's width.
Widget _measure(Widget child) => ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 420),
  child: child,
);

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Feedback',
    title: 'Progress',
    lead:
        'Shows how far a task has come. `DsProgressBar` suits uploads, '
        'quotas and steps in a row of text; `DsProgressRing` fits a small '
        'square, such as a card corner or a dashboard tile. When the amount '
        'is unknown, both show indeterminate motion. For a short wait with '
        'no progress to report, use a [Spinner](/components/spinner).',
    sections: [
      DocSection(
        title: 'Overview',
        children: [
          Example(
            snippet: 'progress-overview',
            child: _measure(const _UploadDemo()),
          ),
        ],
      ),
      DocSection(
        title: 'Progress bar',
        children: [
          const DocText(
            '`value` runs from 0 to 1 and is clamped. Changes animate '
            'briefly. The bar is 6px tall on a recessed track and fills '
            'the width it is given. Pair it with a label and, when it helps, '
            'the figure in tabular digits.',
          ),
          Example(
            snippet: 'progress-bar',
            child: _measure(
              Builder(
                builder: (context) {
                  final t = DsTheme.of(context);
                  final label = t.typography.small.copyWith(
                    color: t.colors.textMuted,
                  );
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 8,
                    children: [
                      Text('Storage: 7.2 of 10 GB', style: label),
                      // #region progress-bar
                      const DsProgressBar(value: .72, semanticLabel: 'Storage'),
                      // #endregion
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Progress ring',
        children: [
          const DocText(
            'A 46px ring that fills clockwise from the top. `child` sits in '
            'the middle: a percentage in tabular figures, or an icon.',
          ),
          Example(
            snippet: 'progress-ring',
            child: Builder(
              builder: (context) {
                final t = DsTheme.of(context);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 16,
                  children: [
                    // #region progress-ring
                    // t = DsTheme.of(context)
                    DsProgressRing(
                      value: .72,
                      semanticLabel: 'Sprint 14',
                      child: Text(
                        '72',
                        style: t.typography.numeric(t.typography.labelStrong),
                      ),
                    ),
                    // #endregion
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(
                          'Sprint 14',
                          style: t.typography.bodyStrong.copyWith(
                            color: t.colors.text,
                          ),
                        ),
                        Text(
                          '18 of 25 tasks · 4 days left',
                          style: t.typography.small.copyWith(
                            color: t.colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Indeterminate',
        children: [
          const DocText(
            'A null `value` means the amount is unknown. The bar sweeps a '
            'segment across the track; the ring turns a quarter arc. When '
            'the system asks to reduce motion, the bar shows a still '
            'segment and the ring stays still and pulses slowly. Screen '
            'readers hear "Loading" unless you set `semanticLabel`.',
          ),
          Example(
            snippet: 'progress-indeterminate',
            child: _measure(
              const Row(
                spacing: 24,
                children: [
                  // #region progress-indeterminate
                  Expanded(
                    child: DsProgressBar(semanticLabel: 'Preparing export'),
                  ),
                  DsProgressRing(semanticLabel: 'Preparing export'),
                  // #endregion
                ],
              ),
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Following a scroll',
        children: [
          const DocText(
            'A value that changes every frame, such as reading progress or '
            'a pull distance, would trail behind if each change moved into '
            'place. `animate: false` draws each value as given. Scroll the '
            'box below.',
          ),
          Example(
            snippet: 'progress-scroll',
            child: _measure(const _ReadingDemo()),
          ),
        ],
      ),
      DocSection(
        title: 'Customizing',
        children: [
          const DocText(
            'Change one bar or ring with `style`, or every one below a point '
            'with `DsProgressBarTheme` and `DsProgressRingTheme`. The fill '
            'defaults to the theme\'s indicator color; a status fill makes '
            'a quota bar warn as it fills.',
          ),
          Example(
            snippet: 'progress-custom',
            child: _measure(
              Builder(
                builder: (context) {
                  // #region progress-custom
                  // Theme colors:
                  final k = DsTheme.colorsOf(context);
                  return Row(
                    spacing: 24,
                    children: [
                      Expanded(
                        child: DsProgressBar(
                          value: .94,
                          semanticLabel: 'Seats used',
                          style: DsProgressBarStyle(
                            height: 4,
                            fillColor: k.warning.fill,
                          ),
                        ),
                      ),
                      DsProgressRing(
                        value: .4,
                        semanticLabel: 'Profile complete',
                        style: DsProgressRingStyle(
                          size: 28,
                          strokeWidth: 3,
                          fillColor: k.success.fill,
                        ),
                      ),
                    ],
                  );
                  // #endregion
                },
              ),
            ),
          ),
        ],
      ),
      const DocSection(
        title: 'Accessibility',
        children: [
          DocList([
            'A determinate bar or ring is a progress bar for screen '
                'readers, with its percent and a 0 to 100 range. Name it '
                'with `semanticLabel`.',
            'An indeterminate one is a loading indicator, announced as '
                '"Loading" or its `semanticLabel`.',
            'The fill stands 3:1 off the track at every contrast level; the '
                'track is a fill, with no outline.',
            'Indeterminate motion stops or slows to a pulse when the '
                'system asks to reduce motion.',
          ]),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          DocHeading('DsProgressBar'),
          ApiTable([
            ('value', 'double?', '0 to 1. Null is indeterminate.'),
            (
              'animate',
              'bool',
              'Whether a new value moves into place. Defaults to true; '
                  'false for a value that follows a gesture or a scroll.',
            ),
            ('semanticLabel', 'String?', 'What is progressing.'),
            (
              'style',
              'DsProgressBarStyle?',
              'Height, track, fill and corners.',
            ),
          ]),
          DocHeading('DsProgressRing'),
          ApiTable([
            ('value', 'double?', '0 to 1. Null is indeterminate.'),
            ('animate', 'bool', 'As on the bar. Defaults to true.'),
            ('child', 'Widget?', 'Centered content, such as a percentage.'),
            ('semanticLabel', 'String?', 'What is progressing.'),
            ('style', 'DsProgressRingStyle?', 'Size, stroke, track and fill.'),
          ]),
        ],
      ),
    ],
  );
}

class _ReadingDemo extends StatefulWidget {
  const _ReadingDemo();

  @override
  State<_ReadingDemo> createState() => _ReadingDemoState();
}

class _ReadingDemoState extends State<_ReadingDemo> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        ListenableBuilder(
          listenable: _scroll,
          builder: (context, _) {
            final p =
                _scroll.hasClients && _scroll.position.hasContentDimensions
                ? _scroll.position
                : null;
            final read = p == null || p.maxScrollExtent <= 0
                ? 0.0
                : p.pixels / p.maxScrollExtent;
            // #region progress-scroll
            return DsProgressBar(
              value: read,
              animate: false,
              semanticLabel: 'Read',
            );
            // #endregion
          },
        ),
        SizedBox(
          height: 160,
          child: SingleChildScrollView(
            controller: _scroll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                for (var i = 1; i <= 8; i++)
                  Text(
                    'Paragraph $i. The bar above follows the scroll position '
                    'exactly, with no lag behind the content.',
                    style: t.typography.body.copyWith(color: t.colors.text),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadDemo extends StatefulWidget {
  const _UploadDemo();

  @override
  State<_UploadDemo> createState() => _UploadDemoState();
}

class _UploadDemoState extends State<_UploadDemo> {
  double _progress = .35;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _upload() {
    _timer?.cancel();
    setState(() => _progress = 0);
    _timer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!mounted) return;
      setState(() => _progress = (_progress + .04).clamp(0, 1));
      if (_progress >= 1) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final done = _progress >= 1;
    final percent = (_progress * 100).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: Text(
                done ? 'brand-guide.pdf uploaded' : 'Uploading brand-guide.pdf',
                style: t.typography.labelStrong.copyWith(color: t.colors.text),
              ),
            ),
            Text(
              '$percent%',
              style: t.typography
                  .numeric(t.typography.small)
                  .copyWith(color: t.colors.textMuted),
            ),
          ],
        ),
        // #region progress-overview
        DsProgressBar(
          value: _progress,
          semanticLabel: 'Uploading brand-guide.pdf',
        ),
        // #endregion
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: DsButton(
            variant: .secondary,
            size: .sm,
            leading: const DsIcon(DsIcons.upload),
            onPressed: _upload,
            child: Text(done ? 'Upload again' : 'Upload'),
          ),
        ),
      ],
    );
  }
}

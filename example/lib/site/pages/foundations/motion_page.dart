import 'dart:math' as math;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';

import '../../code.dart';
import '../../doc.dart';
import 'common.dart';

/// Springs, what moves and what does not, and reduced motion.
class MotionPage extends StatelessWidget {
  const MotionPage({super.key});

  @override
  Widget build(BuildContext context) => DocPage(
    eyebrow: 'Foundations',
    title: 'Motion',
    lead:
        'Every animation is a spring. Color and opacity settle without '
        'bounce; position, size and scale bounce a little. When the system '
        'asks for reduced motion, movement stops and only fades remain.',
    sections: [
      const DocSection(
        title: 'Two springs',
        children: [
          DocText(
            'A `DsSpring` is described the way iOS describes one: a '
            'perceptual `duration` and a `bounce` from 0 (no overshoot) to '
            'below 1. `DsMotion` holds two of them. `toneSpring` drives '
            'color, opacity and shadow changes; an overshooting color would '
            'flash, so it never bounces. `moveSpring` drives position, size '
            'and scale with a slight overshoot.',
          ),
          Board(child: _SpringPlot()),
        ],
      ),
      DocSection(
        title: 'Movement',
        children: [
          const DocText(
            'Click quickly several times. `DsSpringValue` keeps the current '
            'velocity when its target changes mid-flight, so repeated '
            'toggles flow on instead of restarting from rest. The switch '
            'knob, the segmented control\'s thumb, the checkmark and the '
            'press scale of buttons move this way.',
          ),
          Example(snippet: 'motion-move', child: const _MoveDemo()),
        ],
      ),
      DocSection(
        title: 'Tone',
        children: [
          const DocText(
            'For implicit animations, `motion.toneDuration` and '
            '`motion.toneCurve` give the tone spring as a duration and a '
            'curve. Colors mix in '
            'premultiplied alpha, as in CSS, so a fill fading in from '
            'transparent never dips through gray.',
          ),
          Example(snippet: 'motion-tone', child: const _ToneDemo()),
        ],
      ),
      const DocSection(
        title: 'What moves',
        children: [
          DocList([
            '**Bounces a little:** switch knob, segment thumb, tab underline, '
                'checkmark, press scale (0.97 for small controls, 0.955 for '
                'larger ones), menus and popovers opening (6px and a 0.97 '
                'scale), page transitions.',
            '**Never bounces:** hover and press colors, focus rings, fades, '
                'the progress bar (overshooting would show a wrong value) and '
                'the accordion\'s height (it would shake the content below).',
            '**Loops at a fixed period:** the spinner (0.8s per turn), the '
                'skeleton shimmer (1.6s) and the indeterminate progress bar '
                '(1.4s).',
            '**Exits are quicker:** 0.7 of the enter duration.',
            '**Delays:** a tooltip waits 0.5s and lingers 0.12s; a submenu '
                'opens after 0.15s; a toast stays 6s, twice as long with an '
                'action, and pauses while hovered or focused.',
          ]),
        ],
      ),
      DocSection(
        title: 'Press motion',
        children: [
          const DocText(
            'Filled buttons and stepper buttons shrink a little while '
            'pressed. `DsPressEffect(enabled: false)` turns that off for a '
            'whole subtree, whatever the buttons\' styles say: hover and '
            'press colors, focus rings and haptics stay. A nested '
            '`DsPressEffect(enabled: true)` turns it back on; reduced motion '
            'still wins. Press both rows to compare.',
          ),
          Example(
            snippet: 'motion-press-effect',
            child: Column(
              spacing: 16,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [
                    DsButton(onPressed: () {}, child: const Text('Moves')),
                    DsStepper(value: 3, onChanged: (_) {}),
                  ],
                ),
                // #region motion-press-effect
                DsPressEffect(
                  enabled: false,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 12,
                    children: [
                      DsButton(onPressed: () {}, child: const Text('Still')),
                      DsStepper(value: 3, onChanged: (_) {}),
                    ],
                  ),
                ),
                // #endregion
              ],
            ),
          ),
        ],
      ),
      DocSection(
        title: 'Reduced motion',
        children: [
          const DocText(
            'When the platform asks for reduced motion, `DsScope` sets '
            '`DsMotion.reduced`. Movement then jumps: `moveDuration` is zero '
            'and `moveSpringOrNull` is null. Fades stay, because they do not '
            'move anything. The spinner stops turning and pulses its opacity '
            'slowly, the skeleton shimmer stops and the caret stops '
            'blinking.',
          ),
          Example(
            snippet: 'motion-reduced',
            padding: const EdgeInsets.all(24),
            child: const _ReducedDemo(),
          ),
          const DocText(
            'In your own animations, ask the theme instead of reading '
            '`moveSpring` directly:',
          ),
          const CodeBlock(
            'final motion = DsTheme.motionOf(context);\n'
            '\n'
            '// Implicit: zero when reduced.\n'
            'AnimatedAlign(\n'
            '  duration: motion.moveDuration,\n'
            '  curve: motion.moveCurve,\n'
            '  alignment: open ? Alignment.centerRight : Alignment.centerLeft,\n'
            '  child: knob,\n'
            ')\n'
            '\n'
            '// Physics: null when reduced, and the value jumps.\n'
            'DsSpringValue(\n'
            '  value: open ? 1 : 0,\n'
            '  spring: motion.moveSpringOrNull,\n'
            '  builder: (context, t, child) => …,\n'
            ')',
          ),
        ],
      ),
      DocSection(
        title: 'Haptics',
        children: [
          const DocText(
            'On iOS and Android, controls answer a touch through the '
            'haptic engine the way the platform\'s own controls do: a '
            'light tick when state changes, nothing for a plain command. '
            'Only touches play: a change made with the keyboard is silent, '
            'as on iOS. Desktop has no haptic engine and stays silent, and '
            'so does the web unless you set `haptics` yourself.',
          ),
          const DocList([
            '**`DsHaptics.subtle`** (the default on iOS and Android): '
                'state changes tick. A switch or checkbox flipping, a chip '
                'or toolbar toggle, a radio, segment, tab, bottom bar or '
                'sidebar item becoming the selected one, a stepped slider '
                'crossing a step, a stepper or number field stepping, an '
                'option, day or time being picked.',
            '**`DsHaptics.full`**: every press also plays a light impact, '
                'buttons and menu items included.',
            '**`DsHaptics.none`** (the default on the web and desktop): '
                'silence.',
          ]),
          Example(
            snippet: 'motion-haptics',
            padding: const EdgeInsets.all(24),
            child: const _HapticsDemo(),
          ),
          const DocText(
            'The setting lives on the theme, so one line covers the whole '
            'app; `null` follows the platform. A control of your own built '
            'on `DsPressable` says what its press means with `haptic:`, and '
            'one with its own gestures calls `DsHapticFeedback.play` when '
            'its state changes:',
          ),
          const CodeBlock(
            'DsThemeData(haptics: DsHaptics.none)\n'
            '\n'
            '// A toggle of your own: ticks under subtle and full.\n'
            'DsPressable(\n'
            '  onPressed: toggle,\n'
            '  haptic: DsHapticEvent.selection,\n'
            '  builder: …,\n'
            ')\n'
            '\n'
            '// Own gestures: play before reporting the change.\n'
            'DsHapticFeedback.play(context, DsHapticEvent.selection);\n'
            'onChanged(next);',
          ),
        ],
      ),
      const DocSection(
        title: 'Customizing',
        children: [
          DocText(
            'Pass your own `DsMotion` to the theme. Reduced motion still '
            'applies on top of it.',
          ),
          CodeBlock(
            'DsThemeData(\n'
            '  motion: const DsMotion(\n'
            '    moveSpring: DsSpring(\n'
            '      duration: Duration(milliseconds: 320),\n'
            '      bounce: .15,\n'
            '    ),\n'
            '    hoverDelay: Duration(milliseconds: 300),\n'
            '  ),\n'
            ')',
          ),
        ],
      ),
      const DocSection(
        title: 'API',
        children: [
          ApiTable([
            (
              'DsSpring',
              'class',
              '`duration` and `bounce`. `simulate` drives a controller; '
                  '`curve` and `settleDuration` serve implicit animations.',
            ),
            ('toneSpring', 'DsSpring', '200ms, no bounce.'),
            ('moveSpring', 'DsSpring', '380ms, bounce 0.28.'),
            (
              'toneDuration / toneCurve',
              'Duration / Curve',
              'The tone spring.',
            ),
            (
              'moveDuration / moveCurve',
              'Duration / Curve',
              'The move spring; `moveDuration` is zero when reduced.',
            ),
            (
              'moveSpringOrNull',
              'DsSpring?',
              'The move spring, or null when reduced.',
            ),
            ('reduced', 'bool', 'Set by `DsScope` from the platform.'),
            (
              'DsPressEffect',
              'widget',
              '`enabled` turns the press scale of a subtree off or back on; '
                  '`scaleOf(context, scale)` for controls of your own.',
            ),
            (
              'DsThemeData.haptics',
              'DsHaptics?',
              '`none`, `subtle` or `full`; null follows the platform '
                  '(`effectiveHaptics`).',
            ),
            (
              'DsPressable.haptic',
              'DsHapticEvent?',
              '`command` (default), `selection`, or null for silence.',
            ),
            (
              'DsHapticFeedback.play',
              'method',
              'Plays an event through the theme\'s setting.',
            ),
            (
              'DsSpringValue',
              'widget',
              'Animates a number with spring physics, keeping velocity.',
            ),
          ]),
        ],
      ),
    ],
  );
}

class _SpringPlot extends StatelessWidget {
  const _SpringPlot();

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final m = t.motion;
    final k = t.colors;
    Widget legend(Color color, String name, DsSpring s) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: DsBoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Flexible(
          child: Caption(
            '$name · ${s.duration.inMilliseconds}ms, bounce ${s.bounce == 0 ? 0 : s.bounce} · '
            'settles in ${s.settleDuration.inMilliseconds}ms',
            color: k.text,
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        SizedBox(
          height: 180,
          child: CustomPaint(
            painter: _PlotPainter(
              tone: m.toneSpring,
              move: m.moveSpring,
              toneColor: k.textMuted,
              moveColor: k.indicator,
              grid: k.border,
            ),
          ),
        ),
        Wrap(
          spacing: 24,
          runSpacing: 6,
          children: [
            legend(k.textMuted, 'toneSpring', m.toneSpring),
            legend(k.indicator, 'moveSpring', m.moveSpring),
          ],
        ),
        Caption(
          'Progress from 0 to 1 over time. The dashed line is the target.',
          color: k.textSubtle,
        ),
      ],
    );
  }
}

class _PlotPainter extends CustomPainter {
  _PlotPainter({
    required this.tone,
    required this.move,
    required this.toneColor,
    required this.moveColor,
    required this.grid,
  });

  final DsSpring tone, move;
  final Color toneColor, moveColor, grid;

  @override
  void paint(Canvas canvas, Size size) {
    final end = math.max(
      tone.settleDuration.inMilliseconds,
      move.settleDuration.inMilliseconds,
    );
    const top = 1.15, bottom = -0.05;
    double y(double v) => size.height * (top - v) / (top - bottom);
    final line = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, y(0)), Offset(size.width, y(0)), line);
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, y(1)), Offset(x + 4, y(1)), line);
    }
    void curve(DsSpring s, Color color) {
      final sim = s.simulate();
      final path = Path();
      for (var i = 0; i <= 200; i++) {
        final ms = end * i / 200;
        final v = sim.x(ms / 1000);
        final p = Offset(size.width * i / 200, y(v));
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
      );
    }

    curve(tone, toneColor);
    curve(move, moveColor);
  }

  @override
  bool shouldRepaint(_PlotPainter old) =>
      old.tone != tone ||
      old.move != move ||
      old.toneColor != toneColor ||
      old.moveColor != moveColor ||
      old.grid != grid;
}

class _MoveDemo extends StatefulWidget {
  const _MoveDemo();

  @override
  State<_MoveDemo> createState() => _MoveDemoState();
}

class _MoveDemoState extends State<_MoveDemo> {
  bool _end = false;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    return Column(
      spacing: 24,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Container(
            height: 40,
            padding: const EdgeInsets.all(DsSpace.s4),
            decoration: DsBoxDecoration(
              color: k.channel,
              borderRadius: BorderRadius.circular(t.radii.control(40)),
              shadows: t.shadows.channel,
            ),
            // #region motion-move
            child: DsSpringValue(
              value: _end ? 1 : 0,
              spring: t.motion.moveSpringOrNull,
              builder: (context, v, child) =>
                  Align(alignment: Alignment(v * 2 - 1, 0), child: child),
              child: Container(
                width: 64,
                decoration: DsBoxDecoration(
                  color: k.accent,
                  borderRadius: BorderRadius.circular(
                    t.radii.nested(t.radii.control(40), DsSpace.s4),
                  ),
                  shadows: t.shadows.channelThumb,
                ),
              ),
            ),
            // #endregion
          ),
        ),
        DsButton(
          variant: .secondary,
          onPressed: () => setState(() => _end = !_end),
          child: const Text('Move'),
        ),
      ],
    );
  }
}

class _ToneDemo extends StatefulWidget {
  const _ToneDemo();

  @override
  State<_ToneDemo> createState() => _ToneDemoState();
}

class _ToneDemoState extends State<_ToneDemo> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    return Column(
      spacing: 24,
      children: [
        // #region motion-tone
        AnimatedContainer(
          duration: t.motion.toneDuration,
          curve: t.motion.toneCurve,
          width: 160,
          height: 48,
          alignment: Alignment.center,
          decoration: DsBoxDecoration(
            color: _on ? k.accent : k.accent.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(t.radii.control(48)),
            shadows: [DsShadow.innerRing(_on ? k.accent : k.borderControl)],
          ),
          child: Text(
            _on ? 'Following' : 'Follow',
            style: t.typography.label.copyWith(
              color: _on ? k.onAccent : k.text,
            ),
          ),
        ),
        // #endregion
        DsButton(
          variant: .secondary,
          onPressed: () => setState(() => _on = !_on),
          child: const Text('Toggle'),
        ),
      ],
    );
  }
}

class _ReducedDemo extends StatefulWidget {
  const _ReducedDemo();

  @override
  State<_ReducedDemo> createState() => _ReducedDemoState();
}

class _ReducedDemoState extends State<_ReducedDemo> {
  bool _reduced = true;
  bool _wifi = true;
  String _range = 'week';

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          DsSwitch(
            value: _reduced,
            onChanged: (v) => setState(() => _reduced = v),
            label: const Text('Reduce motion'),
          ),
          Container(height: 1, color: k.border),
          // #region motion-reduced
          DsTheme(
            data: t.copyWith(motion: t.motion.copyWith(reduced: _reduced)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                DsSwitch(
                  value: _wifi,
                  onChanged: (v) => setState(() => _wifi = v),
                  label: const Text('Wi-Fi'),
                ),
                Row(
                  children: [
                    DsSegmentedControl<String>(
                      value: _range,
                      onChanged: (v) => setState(() => _range = v),
                      segments: const [
                        DsSegment(value: 'day', label: Text('Day')),
                        DsSegment(value: 'week', label: Text('Week')),
                        DsSegment(value: 'month', label: Text('Month')),
                      ],
                    ),
                    const Spacer(),
                    const DsSpinner(semanticLabel: 'Syncing'),
                  ],
                ),
              ],
            ),
          ),
          // #endregion
        ],
      ),
    );
  }
}

class _HapticsDemo extends StatefulWidget {
  const _HapticsDemo();

  @override
  State<_HapticsDemo> createState() => _HapticsDemoState();
}

class _HapticsDemoState extends State<_HapticsDemo> {
  DsHaptics _haptics = DsHaptics.subtle;
  bool _wifi = true;
  double _volume = 0.5;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final k = t.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          DsSegmentedControl<DsHaptics>(
            value: _haptics,
            onChanged: (v) => setState(() => _haptics = v),
            segments: const [
              DsSegment(value: DsHaptics.none, label: Text('None')),
              DsSegment(value: DsHaptics.subtle, label: Text('Subtle')),
              DsSegment(value: DsHaptics.full, label: Text('Full')),
            ],
          ),
          Container(height: 1, color: k.border),
          // #region motion-haptics
          DsTheme(
            data: t.copyWith(haptics: () => _haptics),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                DsSwitch(
                  value: _wifi,
                  onChanged: (v) => setState(() => _wifi = v),
                  label: const Text('Wi-Fi'),
                ),
                DsSlider(
                  value: _volume,
                  divisions: 10,
                  onChanged: (v) => setState(() => _volume = v),
                  semanticLabel: 'Volume',
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: DsButton(onPressed: () {}, child: const Text('Save')),
                ),
              ],
            ),
          ),
          // #endregion
        ],
      ),
    );
  }
}

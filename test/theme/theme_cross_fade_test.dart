import 'dart:ui' as ui;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts builds per kind of theme read.
final _builds = <String, int>{};

class _Reader extends StatelessWidget {
  const _Reader(this.kind);

  final String kind;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case 'of':
        DsTheme.of(context);
      case 'colors':
        DsTheme.colorsOf(context);
      case 'sizes':
        DsTheme.sizesOf(context);
      case 'radii':
        DsTheme.radiiOf(context);
      case 'text':
        DefaultTextStyle.of(context);
    }
    _builds[kind] = (_builds[kind] ?? 0) + 1;
    return const SizedBox(width: 1, height: 1);
  }
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int value = 0;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// A [DsScope] whose inputs a test changes through [_HostState].
class _Host extends StatefulWidget {
  const _Host({required this.child});

  final Widget child;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  DsThemeMode mode = DsThemeMode.light;
  DsDensity density = DsDensity.compact;
  bool animate = true;

  void set(VoidCallback change) => setState(change);

  @override
  Widget build(BuildContext context) => DsScope(
    themeMode: mode,
    animateChanges: animate,
    theme: DsThemeData(density: density),
    child: widget.child,
  );
}

final _shot = GlobalKey();

Future<_HostState> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: _shot,
        child: _Host(child: child),
      ),
    ),
  );
  return tester.state<_HostState>(find.byType(_Host));
}

void main() {
  setUp(_builds.clear);

  testWidgets('a dark switch rebuilds each theme reader at most once, and '
      'readers of sizes or radii not at all', (tester) async {
    final host = await _pump(
      tester,
      Wrap(
        children: [
          for (final kind in ['of', 'colors', 'sizes', 'radii', 'text'])
            for (var i = 0; i < 100; i++) _Reader(kind),
        ],
      ),
    );
    _builds.clear();
    host.set(() => host.mode = DsThemeMode.dark);
    await tester.pump();
    // It still fades after the one rebuild.
    expect(tester.hasRunningAnimations, isTrue);
    var frames = 0;
    while (tester.hasRunningAnimations && frames < 200) {
      await tester.pump(const Duration(milliseconds: 16));
      frames++;
    }
    expect(frames, greaterThan(2));
    expect(_builds, {'of': 100, 'colors': 100, 'text': 100});
  });

  testWidgets('the fade blends finished pixels: no frame leaves the range '
      'between the light and the dark canvas', (tester) async {
    tester.view
      ..physicalSize = const Size(40, 40)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final host = await _pump(
      tester,
      Builder(
        builder: (context) =>
            ColoredBox(color: DsTheme.colorsOf(context).canvas),
      ),
    );
    Future<Color> pixel() async {
      final boundary =
          _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData();
        image.dispose();
        return data!;
      });
      final at = (20 * 40 + 20) * 4;
      return Color.fromARGB(
        bytes!.getUint8(at + 3),
        bytes.getUint8(at),
        bytes.getUint8(at + 1),
        bytes.getUint8(at + 2),
      );
    }

    final light = await pixel();
    host.set(() => host.mode = DsThemeMode.dark);
    final seen = <Color>[];
    await tester.pump();
    seen.add(await pixel());
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      seen.add(await pixel());
    }
    await tester.pumpAndSettle();
    final dark = await pixel();
    expect(light, isNot(dark));
    // The first frame still shows the old colors; later ones move on.
    expect(seen.first, light);
    expect(seen.toSet().length, greaterThan(2));
    bool between(double v, double a, double b) =>
        v >= (a < b ? a : b) - 1 / 255 && v <= (a < b ? b : a) + 1 / 255;
    for (final c in seen) {
      expect(c.a, 1);
      expect(between(c.r, light.r, dark.r), isTrue, reason: '$c');
      expect(between(c.g, light.g, dark.g), isTrue, reason: '$c');
      expect(between(c.b, light.b, dark.b), isTrue, reason: '$c');
    }
  });

  testWidgets('a layout change (density) switches at once', (tester) async {
    final host = await _pump(tester, const _Reader('sizes'));
    _builds.clear();
    host.set(() => host.density = DsDensity.touch);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(_builds, {'sizes': 1});
  });

  testWidgets('animateChanges: false switches in one frame, and turning it '
      'off keeps the subtree state', (tester) async {
    final host = await _pump(tester, const _Counter());
    tester.state<_CounterState>(find.byType(_Counter)).value = 7;
    host.set(() => host.animate = false);
    await tester.pump();
    host.set(() => host.mode = DsThemeMode.dark);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.state<_CounterState>(find.byType(_Counter)).value, 7);
  });

  testWidgets('switching back mid-fade fades again from what is on screen', (
    tester,
  ) async {
    final host = await _pump(tester, const _Reader('colors'));
    host.set(() => host.mode = DsThemeMode.dark);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    host.set(() => host.mode = DsThemeMode.light);
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      DsTheme.of(tester.element(find.byType(_Reader))).brightness,
      ui.Brightness.light,
    );
  });
}

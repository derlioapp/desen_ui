import 'dart:convert';
import 'dart:math' as math;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Corner benchmark: scrolls a dense screen of controls (a card per row
/// with buttons, an icon button, a chip and a text field) and reports the
/// frame build and raster times, to measure what continuous corners
/// (`Path.addRSuperellipse`) cost against plain rounded rectangles.
///
/// Run it in profile mode, once as is and once with plain corners, and
/// compare the `DS_BENCH` lines it prints:
///
/// ```sh
/// cd example
/// flutter run --profile -d macos --dart-define=DS_BENCH=true
/// flutter run --profile -d macos --dart-define=DS_BENCH=true \
///   --dart-define=DS_PLAIN_CORNERS=true
/// ```
///
/// `DS_BENCH_ROWS` (default 300) sets the number of rows.
class CornerBenchApp extends StatelessWidget {
  const CornerBenchApp({super.key});

  @override
  Widget build(BuildContext context) => DsApp(
    title: 'Corner benchmark',
    theme: DsThemeData(),
    themeMode: DsThemeMode.light,
    debugShowCheckedModeBanner: false,
    home: const _Bench(),
  );
}

const _rows = int.fromEnvironment('DS_BENCH_ROWS', defaultValue: 300);
const _plain = bool.fromEnvironment('DS_PLAIN_CORNERS');

/// One scroll from top to bottom, or back.
const _sweep = Duration(seconds: 8);

/// Recorded round trips, after one unrecorded warm-up.
const _passes = 2;

class _Bench extends StatefulWidget {
  const _Bench();

  @override
  State<_Bench> createState() => _BenchState();
}

class _BenchState extends State<_Bench> {
  final _scroll = ScrollController();
  final _timings = <FrameTiming>[];
  String _status = 'Warming up…';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_timings.addAll);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _roundTrip() async {
    await _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: _sweep,
      curve: Curves.linear,
    );
    await _scroll.animateTo(0, duration: _sweep, curve: Curves.linear);
  }

  Future<void> _run() async {
    // Fonts settle; the first pass warms glyph and shader caches and is
    // not recorded.
    await Future<void>.delayed(const Duration(seconds: 1));
    await _roundTrip();
    if (!mounted) return;
    setState(() => _status = 'Recording…');
    SchedulerBinding.instance.addTimingsCallback(_timings.addAll);
    for (var i = 0; i < _passes; i++) {
      await _roundTrip();
    }
    // Timings arrive in batches, up to a second late.
    await Future<void>.delayed(const Duration(seconds: 2));
    SchedulerBinding.instance.removeTimingsCallback(_timings.addAll);
    if (!mounted) return;
    final refresh = View.of(context).display.refreshRate;
    final report = _report(_timings, budgetMs: 1000 / refresh);
    // ignore: avoid_print
    print('DS_BENCH ${jsonEncode(report)}');
    setState(
      () => _status = const JsonEncoder.withIndent('  ').convert(report),
    );
  }

  @override
  Widget build(BuildContext context) {
    final k = DsTheme.colorsOf(context);
    return ColoredBox(
      color: k.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: k.text, fontSize: 13),
              child: Text(
                '${_plain ? 'Plain' : 'Continuous'} corners · $_rows rows\n'
                '$_status',
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _rows,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _Row(index: i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) => DsCard(
    child: Row(
      spacing: 8,
      children: [
        DsButton(onPressed: () {}, child: const Text('Save')),
        DsButton(
          variant: .secondary,
          onPressed: () {},
          child: const Text('Cancel'),
        ),
        DsButton.icon(
          variant: .secondary,
          icon: const DsIcon(DsIcons.plus),
          semanticLabel: 'Add',
          onPressed: () {},
        ),
        DsChip(
          label: Text('Tag $index'),
          selected: index.isEven,
          onChanged: (_) {},
        ),
        Expanded(child: DsTextField(placeholder: 'Row $index')),
      ],
    ),
  );
}

/// Build and raster times in milliseconds: mean, percentiles and worst,
/// and how many frames missed the [budgetMs] of one refresh.
Map<String, Object> _report(
  List<FrameTiming> timings, {
  required double budgetMs,
}) {
  double ms(Duration d) => d.inMicroseconds / 1000;
  Map<String, double> stats(List<double> values) {
    final sorted = [...values]..sort();
    double at(double p) => sorted.isEmpty
        ? 0
        : sorted[math.min(sorted.length - 1, (p * sorted.length).floor())];
    double round(double v) => (v * 100).roundToDouble() / 100;
    final mean = sorted.isEmpty
        ? 0.0
        : sorted.reduce((a, b) => a + b) / sorted.length;
    return {
      'mean': round(mean),
      'p50': round(at(.5)),
      'p90': round(at(.9)),
      'p99': round(at(.99)),
      'max': round(sorted.isEmpty ? 0 : sorted.last),
    };
  }

  final build = [for (final t in timings) ms(t.buildDuration)];
  final raster = [for (final t in timings) ms(t.rasterDuration)];
  return {
    'corners': _plain ? 'plain' : 'continuous',
    'rows': _rows,
    'frames': timings.length,
    'budgetMs': (budgetMs * 100).roundToDouble() / 100,
    'buildMs': stats(build),
    'rasterMs': stats(raster),
    'overBudget': {
      'build': build.where((v) => v > budgetMs).length,
      'raster': raster.where((v) => v > budgetMs).length,
    },
  };
}

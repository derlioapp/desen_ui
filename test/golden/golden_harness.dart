import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared setup for golden tests.
///
/// Goldens are generated on macOS with the real bundled fonts (see
/// test/flutter_test_config.dart). Regenerate after an intended visual
/// change with:
///
/// ```sh
/// flutter test --update-goldens --tags golden
/// ```
///
/// and review every changed PNG before accepting it.

/// The platform every golden theme is generated for. `flutter test` runs as
/// Android, where themes default to 44px tap areas; goldens pin a
/// desktop platform so they keep the compact 24px layout they were drawn
/// with. Phone layouts get their own golden with `TargetPlatform.iOS`.
const goldenPlatform = TargetPlatform.macOS;

/// A labeled grid: a header row of column labels, then one row per entry.
class GoldenGrid extends StatelessWidget {
  const GoldenGrid({
    super.key,
    required this.columns,
    required this.rows,
    this.cellWidth = 132,
    this.cellHeight = 56,
    this.labelWidth = 104,
  });

  final List<String> columns;
  final List<(String, List<Widget>)> rows;
  final double cellWidth, cellHeight, labelWidth;

  @override
  Widget build(BuildContext context) {
    final t = DsTheme.of(context);
    final label = t.typography
        .mono(t.typography.caption)
        .copyWith(color: t.colors.textSubtle, fontSize: 11);
    Widget cell(Widget child) => SizedBox(
      width: cellWidth,
      height: cellHeight,
      child: Center(child: child),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: labelWidth),
            for (final c in columns) cell(Text(c, style: label)),
          ],
        ),
        for (final (name, cells) in rows)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: labelWidth,
                child: Text(name, style: label),
              ),
              for (final c in cells) cell(c),
            ],
          ),
      ],
    );
  }
}

/// Marks the region a golden captures; see [goldenFinder].
final goldenKey = GlobalKey(debugLabel: 'golden');

/// Compares the golden region with [path] at the view's device pixel
/// ratio (`matchesGoldenFile` on a finder would capture at 1x only).
Future<void> expectGolden(WidgetTester tester, String path) async {
  final boundary =
      goldenKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await tester.runAsync(
    () => boundary.toImage(pixelRatio: tester.view.devicePixelRatio),
  );
  await expectLater(image, matchesGoldenFile(path));
  image!.dispose();
}

/// Pumps [child] on the theme's canvas, sized to its content, at [dpr].
Future<void> pumpGolden(
  WidgetTester tester,
  Widget child, {
  required DsThemeData theme,
  double dpr = 2,
  // Generous: the golden captures only the grid, not the whole canvas.
  Size size = const Size(1200, 900),
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
}) async {
  tester.view
    ..devicePixelRatio = dpr
    ..physicalSize = size * dpr;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        devicePixelRatio: dpr,
        textScaler: TextScaler.linear(textScale),
      ),
      child: Directionality(
        textDirection: direction,
        child: DsTheme(
          data: theme,
          child: ColoredBox(
            color: theme.colors.canvas,
            child: Align(
              alignment: Alignment.topLeft,
              // The golden captures exactly this boundary: the content plus
              // a margin wide enough for focus rings and shadows.
              child: RepaintBoundary(
                key: goldenKey,
                child: ColoredBox(
                  color: theme.colors.canvas,
                  // The same text and icon defaults DsScope provides, for
                  // components that inherit the surrounding text style.
                  child: DefaultTextStyle(
                    style: theme.typography.body.copyWith(
                      color: theme.colors.text,
                    ),
                    child: IconTheme(
                      data: IconThemeData(color: theme.colors.text, size: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  // Settle state animations without waiting on endless ones (spinners).
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Light and dark themes for [seed], named for file names.
Map<String, DsThemeData> themesFor(
  DsSeed seed, {
  DsContrast contrast = DsContrast.standard,
}) => {
  'light': DsThemeData(
    seed: seed,
    contrast: contrast,
    platform: goldenPlatform,
  ),
  'dark': DsThemeData(
    seed: seed,
    contrast: contrast,
    brightness: Brightness.dark,
    platform: goldenPlatform,
  ),
};

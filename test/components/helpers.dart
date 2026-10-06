import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal root: MediaQuery from the test view and Directionality. No
/// DsScope unless [theme] is given, so tests also prove components work
/// without one.
Widget host(
  Widget child, {
  DsThemeData? theme,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
}) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQueryData.fromView(View.of(context))
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: Directionality(
      textDirection: direction,
      child: theme == null
          ? Center(child: child)
          : DsTheme(
              data: theme,
              child: Center(child: child),
            ),
    ),
  ),
);

/// The decoration currently painted for the [index]th button.
DsBoxDecoration buttonDecoration(WidgetTester tester, [int index = 0]) =>
    tester
            .widget<AnimatedContainer>(
              find
                  .descendant(
                    of: find.byType(DsButton),
                    matching: find.byType(AnimatedContainer),
                  )
                  .at(index),
            )
            .decoration!
        as DsBoxDecoration;

/// The size of the visible button box (not the hit area).
Size buttonBoxSize(WidgetTester tester, [int index = 0]) => tester.getSize(
  find
      .descendant(
        of: find.byType(DsButton),
        matching: find.byType(AnimatedContainer),
      )
      .at(index),
);

/// Shows focus and hover highlights as with a keyboard and mouse.
void useTraditionalHighlights() {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

/// Moves a mouse over [finder].
Future<TestGesture> hover(WidgetTester tester, Finder finder) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(tester.getCenter(finder));
  await tester.pumpAndSettle();
  return gesture;
}

/// The shadows of [d] that paint: a button keeps a transparent ring slot
/// first so its transitions pair shadows by role (eng L8).
List<DsShadow> visibleShadows(DsBoxDecoration d) => [
  for (final s in d.shadows)
    if (s.color.a > 0) s,
];

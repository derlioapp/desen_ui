import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Without DsScope or DsApp, the fallback theme still follows the
/// platform's reduce-motion setting (and its brightness), as DsScope does.
void main() {
  Widget bare({required bool reduce, required Widget child}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduce, highContrast: true),
    child: Directionality(textDirection: TextDirection.ltr, child: child),
  );

  testWidgets('reduce motion reaches the fallback theme', (tester) async {
    late DsThemeData seen;
    final probe = Builder(
      builder: (context) {
        seen = DsTheme.of(context);
        return const SizedBox();
      },
    );
    await tester.pumpWidget(bare(reduce: true, child: probe));
    expect(seen.motion.reduced, isTrue);
    // The strongest contrast level: nothing to lift for more contrast.
    expect(seen.contrast, DsContrast.standard);
    // A change of the setting rebuilds the reader.
    await tester.pumpWidget(bare(reduce: false, child: probe));
    expect(seen.motion.reduced, isFalse);
    expect(
      DsTheme.motionOf(tester.element(find.byWidget(probe))).reduced,
      isFalse,
    );
  });

  testWidgets('a spinner without a scope stops turning under reduce motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      bare(reduce: true, child: const Center(child: DsSpinner())),
    );
    expect(
      find.descendant(
        of: find.byType(DsSpinner),
        matching: find.byType(RotationTransition),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(DsSpinner),
        matching: find.byType(FadeTransition),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the fallback is shared while the settings stay', (tester) async {
    final seen = <DsThemeData>[];
    Widget probe() => Builder(
      builder: (context) {
        seen.add(DsTheme.of(context));
        return const SizedBox();
      },
    );
    await tester.pumpWidget(
      bare(reduce: true, child: Column(children: [probe(), probe()])),
    );
    expect(seen, hasLength(2));
    expect(seen.first, same(seen.last));
  });
}

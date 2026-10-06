import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Regressions from the blind audit (phase B): toolbar keys, edges on soft
/// fills, status semantics, reduced motion.
void main() {
  DsBoxDecoration decoOf(WidgetTester tester, Finder of) =>
      tester
              .widget<Container>(
                find.descendant(of: of, matching: find.byType(Container)).first,
              )
              .decoration!
          as DsBoxDecoration;

  testWidgets('toolbar arrows, Home and End move focus (ux V21, S-27)', (
    tester,
  ) async {
    useTraditionalHighlights();
    final nodes = [for (var i = 0; i < 3; i++) FocusNode()];
    addTearDown(() {
      for (final n in nodes) {
        n.dispose();
      }
    });
    Future<void> pump(TextDirection direction) => tester.pumpWidget(
      host(
        direction: direction,
        DsToolbar(
          children: [
            for (var i = 0; i < 3; i++)
              DsButton.icon(
                focusNode: nodes[i],
                icon: const DsIcon(DsIcons.bold),
                semanticLabel: 'b$i',
                onPressed: () {},
              ),
          ],
        ),
      ),
    );
    await pump(TextDirection.ltr);
    nodes[0].requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(nodes[1].hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(nodes[2].hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(nodes[0].hasFocus, isTrue, reason: 'wraps');
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(nodes[0].hasFocus, isTrue);
    // Every item stays its own Tab stop (K-50).
    for (final n in nodes) {
      expect(n.canRequestFocus && !n.skipTraversal, isTrue);
    }

    await pump(TextDirection.rtl);
    nodes[0].requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(nodes[1].hasFocus, isTrue, reason: 'mirrored in RTL');
  });

  testWidgets('standard contrast keeps soft fills edgeless', (tester) async {
    final light = DsThemeData();
    await tester.pumpWidget(
      host(
        const DsBadge(status: DsStatus.warning, label: Text('Taslak')),
        theme: light,
      ),
    );
    expect(decoOf(tester, find.byType(DsBadge)).shadows, isEmpty);
  });

  testWidgets('an alert names its status for screen readers (ux V25)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const DsAlert(status: DsStatus.warning, title: Text('Kota doluyor')),
      ),
    );
    expect(
      tester.getSemantics(find.byType(DsAlert)).label,
      contains('Warning'),
    );
    handle.dispose();
  });

  testWidgets('the status dot is read by its label (F-16, R5)', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(const DsStatusDot(label: Text('Çevrimiçi'))));
    expect(find.bySemanticsLabel('Çevrimiçi'), findsOneWidget);
    handle.dispose();
  });

  for (final kind in ['spinner', 'ring']) {
    testWidgets('$kind does not turn under reduced motion (ux V20)', (
      tester,
    ) async {
      final reduced = DsThemeData(motion: const DsMotion(reduced: true));
      await tester.pumpWidget(
        host(
          kind == 'spinner' ? const DsSpinner() : const DsProgressRing(),
          theme: reduced,
        ),
      );
      expect(find.byType(RotationTransition), findsNothing);
      if (kind == 'ring') {
        final painter =
            tester
                    .widget<CustomPaint>(
                      find
                          .descendant(
                            of: find.byType(DsProgressRing),
                            matching: find.byType(CustomPaint),
                          )
                          .first,
                    )
                    .painter!
                as dynamic;
        final start = painter.start as double;
        await tester.pump(const Duration(milliseconds: 300));
        final later =
            tester
                    .widget<CustomPaint>(
                      find
                          .descendant(
                            of: find.byType(DsProgressRing),
                            matching: find.byType(CustomPaint),
                          )
                          .first,
                    )
                    .painter!
                as dynamic;
        expect(later.start, start, reason: 'the arc stays still');
      }
      // It still shows that it is working: the opacity changes.
      double opacity() {
        final fade = find.byType(FadeTransition);
        if (fade.evaluate().isNotEmpty) {
          return tester.widget<FadeTransition>(fade.first).opacity.value;
        }
        return tester.widget<Opacity>(find.byType(Opacity).first).opacity;
      }

      final a = opacity();
      await tester.pump(const Duration(milliseconds: 400));
      expect(opacity(), isNot(a));
    });
  }
}

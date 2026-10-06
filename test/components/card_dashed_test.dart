import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// `DsCard(dashed: true)`: an empty slot with a dashed outline along the
/// card corners, in the theme's form boundary color (3:1); pressable, it
/// fills on hover.
void main() {
  final light = DsThemeData();

  DsDashedBorder dashes(WidgetTester tester) =>
      tester.widget<DsDashedBorder>(find.byType(DsDashedBorder));

  DsBoxDecoration box(WidgetTester tester) =>
      tester
              .widget<AnimatedContainer>(
                find.descendant(
                  of: find.byType(DsCard),
                  matching: find.byType(AnimatedContainer),
                ),
              )
              .decoration!
          as DsBoxDecoration;

  testWidgets('a dashed card has no fill or shadow and a dashed outline in '
      'the form boundary color along the card corners', (tester) async {
    await tester.pumpWidget(
      host(const DsCard(dashed: true, child: Text('Boş')), theme: light),
    );
    final d = dashes(tester);
    expect(d.color, light.colors.borderField);
    expect(d.width, greaterThan(0));
    expect(d.dashLength, greaterThan(0));
    expect(d.dashGap, greaterThan(0));
    expect(d.borderRadius, BorderRadius.circular(light.radii.card));
    expect(box(tester).color?.a, 0);
    expect(box(tester).shadows, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a plain card draws no dashes', (tester) async {
    await tester.pumpWidget(host(const DsCard(child: Text('kart'))));
    expect(find.byType(DsDashedBorder), findsNothing);
  });

  testWidgets('works without any scope (R3)', (tester) async {
    await tester.pumpWidget(
      host(DsCard(dashed: true, onPressed: () {}, child: const Text('Ekle'))),
    );
    expect(find.byType(DsDashedBorder), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the outline follows the corner style', (tester) async {
    final sharp = DsThemeData(cornerStyle: DsCornerStyle.sharp);
    await tester.pumpWidget(
      host(const DsCard(dashed: true, child: Text('Boş')), theme: sharp),
    );
    expect(
      dashes(tester).borderRadius,
      BorderRadius.circular(sharp.radii.card),
    );
  });

  testWidgets('the outline follows a radius set in the card theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        DsCardTheme(
          data: DsCardThemeData(
            style: DsCardStyle(borderRadius: BorderRadius.circular(6)),
          ),
          child: const DsCard(dashed: true, child: Text('Boş')),
        ),
        theme: light,
      ),
    );
    expect(dashes(tester).borderRadius, BorderRadius.circular(6));
    expect(box(tester).borderRadius, BorderRadius.circular(6));
  });

  testWidgets('a pressable slot fills and darkens its outline on hover, '
      'without the lift', (tester) async {
    useTraditionalHighlights();
    var taps = 0;
    await tester.pumpWidget(
      host(
        DsCard(
          dashed: true,
          onPressed: () => taps++,
          semanticLabel: 'Ekle',
          child: const Text('Ekle'),
        ),
        theme: light,
      ),
    );
    expect(dashes(tester).color, light.colors.borderField);
    await hover(tester, find.byType(DsCard));
    await tester.pumpAndSettle();
    expect(box(tester).color, light.colors.hover);
    expect(box(tester).shadows, isEmpty);
    expect(dashes(tester).color, light.colors.textMuted);
    await tester.tap(find.byType(DsCard));
    expect(taps, 1);
  });

  testWidgets('keyboard focus draws the focus ring; Enter presses it', (
    tester,
  ) async {
    useTraditionalHighlights();
    var taps = 0;
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      host(
        DsCard(
          dashed: true,
          focusNode: node,
          onPressed: () => taps++,
          semanticLabel: 'Ekle',
          child: const Text('Ekle'),
        ),
        theme: light,
      ),
    );
    node.requestFocus();
    // Any key marks keyboard modality.
    await tester.sendKeyEvent(LogicalKeyboardKey.f12);
    await tester.pumpAndSettle();
    expect(box(tester).shadows, containsAll(light.focusShadows));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('a pressable slot is a button named by its label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        DsCard(
          dashed: true,
          onPressed: () {},
          semanticLabel: 'Pano ekle',
          child: const Text('Ekle'),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Pano ekle'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(DsCard)),
      isSemantics(label: 'Pano ekle', isButton: true),
    );
    semantics.dispose();
  });

  testWidgets('DsCardStyle.dashed styles the slot', (tester) async {
    const ink = Color(0xFF3355AA);
    await tester.pumpWidget(
      host(
        const DsCard(
          dashed: true,
          style: DsCardStyle(
            dashed: DsCardStyle(
              borderColor: ink,
              borderWidth: 2,
              dashLength: 10,
              dashGap: 3,
            ),
          ),
          child: Text('Boş'),
        ),
        theme: light,
      ),
    );
    final d = dashes(tester);
    expect(d.color, ink);
    expect(d.width, 2);
    expect(d.dashLength, 10);
    expect(d.dashGap, 3);
  });

  testWidgets('the content keeps its state when dashed turns on', (
    tester,
  ) async {
    final key = GlobalKey<_CounterState>();
    Widget card({required bool dashed}) => host(
      DsCard(
        dashed: dashed,
        onPressed: () {},
        child: _Counter(key: key),
      ),
    );
    await tester.pumpWidget(card(dashed: false));
    key.currentState!.count = 3;
    await tester.pumpWidget(card(dashed: true));
    expect(key.currentState!.count, 3);
  });
}

class _Counter extends StatefulWidget {
  const _Counter({super.key});

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) => Text('$count');
}

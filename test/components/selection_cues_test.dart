import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Selection that does not rest on a faint fill or hue alone.
/// A bright accent fill gets an edge, a selected chip a check, a selected
/// segment a heavier label; channels draw no line.
void main() {
  final yellow = DsSeed.color(const Color(0xFFFFC72C));

  DsBoxDecoration decorationIn<W extends Widget>(
    WidgetTester tester,
    Type type,
  ) =>
      (tester.widget<W>(
            find
                .descendant(of: find.byType(type), matching: find.byType(W))
                .first,
          ) as dynamic).decoration
          as DsBoxDecoration;

  List<Color> innerRings(DsBoxDecoration d) => [
    for (final s in d.shadows)
      if (s.inset && s.blur == 0 && s.offset == Offset.zero && s.color.a > 0)
        s.color,
  ];

  group('bright accent edge', () {
    for (final (name, seed, edged) in [
      ('yellow', yellow, true),
      ('blue', DsSeed.blue, false),
    ]) {
      testWidgets('$name: checked checkbox, radio and on switch', (
        tester,
      ) async {
        final theme = DsThemeData(seed: seed);
        final edge = theme.colors.accentEdge;
        expect(edge.a > 0, edged);
        await tester.pumpWidget(
          host(
            theme: theme,
            Column(
              children: [
                DsCheckbox(value: true, onChanged: (_) {}),
                DsRadioGroup<int>(
                  value: 1,
                  onChanged: (_) {},
                  child: const DsRadio(value: 1),
                ),
                DsSwitch(value: true, onChanged: (_) {}),
              ],
            ),
          ),
        );
        final expected = edged ? [edge] : <Color>[];
        expect(
          innerRings(decorationIn<AnimatedContainer>(tester, DsCheckbox)),
          expected,
        );
        expect(
          innerRings(decorationIn<AnimatedContainer>(tester, DsRadio<int>)),
          expected,
        );
        expect(
          innerRings(decorationIn<AnimatedContainer>(tester, DsSwitch)),
          expected,
        );
      });
    }

    test('a bright filled selection wears the edge; soft does not', () {
      final fill = DsThemeData(
        seed: yellow,
        selectionStyle: DsSelectionStyle.strong,
      );
      expect(fill.selectedEdge, fill.colors.accentEdge);
      expect(DsThemeData(seed: yellow).selectedEdge, isNull);
      expect(
        DsThemeData(selectionStyle: DsSelectionStyle.strong).selectedEdge,
        isNull,
      );
    });

    test('the edge stands 3:1 off the card over the fill and its hover', () {
      final k = DsThemeData(seed: yellow).colors;
      for (final fill in [k.accent, k.accentHover, k.accentPress]) {
        expect(
          DsColorUtils.contrastRatio(
            Color.alphaBlend(k.accentEdge, fill),
            k.surface,
          ),
          greaterThanOrEqualTo(3),
        );
      }
    });
  });

  group('channel line', () {
    for (final contrast in DsContrast.values) {
      testWidgets('${contrast.name}: none on slider and progress tracks', (
        tester,
      ) async {
        final theme = DsThemeData(contrast: contrast);
        await tester.pumpWidget(
          host(
            theme: theme,
            SizedBox(
              width: 200,
              child: Column(
                children: [
                  DsSlider(value: .3, onChanged: (_) {}),
                  const DsProgressBar(value: .3),
                ],
              ),
            ),
          ),
        );
        expect(theme.shadows.channel, isEmpty);
        expect(innerRings(decorationIn<Container>(tester, DsSlider)), isEmpty);
        expect(
          innerRings(decorationIn<Container>(tester, DsProgressBar)),
          isEmpty,
        );
      });
    }
  });

  group('selected chip check', () {
    testWidgets('shows a check, in place of the leading icon', (tester) async {
      Widget chips({required bool selected, bool? showCheck}) => host(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DsChip(
              label: const Text('Design'),
              selected: selected,
              onChanged: (_) {},
              style: showCheck == null
                  ? null
                  : DsChipStyle(showCheck: showCheck),
            ),
            DsChip(
              label: const Text('Tag'),
              leading: const DsIcon(DsIcons.x),
              selected: selected,
              onChanged: (_) {},
            ),
          ],
        ),
      );
      Iterable<DsIconData> icons() =>
          tester.widgetList<DsIcon>(find.byType(DsIcon)).map((i) => i.icon);

      await tester.pumpWidget(chips(selected: false));
      expect(icons(), [DsIcons.x]);
      await tester.pumpWidget(chips(selected: true));
      expect(icons(), [DsIcons.check, DsIcons.check]);
      await tester.pumpWidget(chips(selected: true, showCheck: false));
      expect(icons(), [DsIcons.check]);
    });
  });

  group('segmented selection weight', () {
    testWidgets('the selected label is semibold and the control keeps its '
        'width', (tester) async {
      var value = 'a';
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, set) => DsSegmentedControl<String>(
              value: value,
              onChanged: (v) => set(() => value = v),
              segments: const [
                DsSegment(value: 'a', label: Text('Wednesday')),
                DsSegment(value: 'b', label: Text('Day')),
              ],
            ),
          ),
        ),
      );
      FontWeight? weight(String text) => tester
          .widget<RichText>(
            find.descendant(
              of: find.text(text),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style
          ?.fontWeight;
      final before = tester.getSize(find.byType(DsSegmentedControl<String>));
      expect(weight('Wednesday'), FontWeight.w600);
      expect(weight('Day'), FontWeight.w500);

      await tester.tap(find.text('Day'));
      await tester.pumpAndSettle();
      expect(weight('Wednesday'), FontWeight.w500);
      expect(weight('Day'), FontWeight.w600);
      expect(tester.getSize(find.byType(DsSegmentedControl<String>)), before);
    });
  });
}

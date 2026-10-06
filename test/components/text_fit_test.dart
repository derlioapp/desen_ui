import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Narrow widths and large text: components lay out without overflow
/// errors, and labels wrap or grow instead of losing their text (WCAG 1.4.4
/// and 1.4.10).

Widget _app(
  Widget child, {
  required double width,
  double textScale = 1,
  DsThemeData? theme,
}) => DsApp(
  theme: theme ?? DsThemeData(),
  themeMode: DsThemeMode.light,
  locale: const Locale('en', 'US'),
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: TextScaler.linear(textScale)),
    child: c!,
  ),
  home: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: width, child: child),
  ),
);

/// Pumps [child] and returns every framework error it raised.
Future<List<Object>> _pump(
  WidgetTester tester,
  Widget child, {
  required double width,
  double textScale = 1,
  DsThemeData? theme,
}) async {
  await tester.pumpWidget(
    _app(child, width: width, textScale: textScale, theme: theme),
  );
  await tester.pump(const Duration(seconds: 1));
  final errors = <Object>[];
  Object? e;
  while ((e = tester.takeException()) != null) {
    errors.add(e!);
  }
  return errors;
}

/// Whether the text [label] is shown in full: not ellipsized or cut.
bool _fullyShown(WidgetTester tester, String label) {
  final p = tester.renderObject<RenderParagraph>(find.text(label).first);
  return !p.didExceedMaxLines;
}

void main() {
  group('multi-select tags', () {
    final options = [
      for (var i = 0; i < 30; i++)
        DsSelectOption(
          value: i,
          label: i.isEven ? 'Option $i' : 'A much longer option label $i',
        ),
    ];

    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('30 tags in a 120px field at ${scale}x lay out', (
        tester,
      ) async {
        final errors = await _pump(
          tester,
          DsMultiSelect<int>(
            value: [for (var i = 0; i < 30; i++) i],
            onChanged: (_) {},
            options: options,
          ),
          width: 120,
          textScale: scale,
        );
        expect(errors, isEmpty);
      });
    }

    testWidgets('a long tag label wraps at 2x text instead of being cut', (
      tester,
    ) async {
      const label = 'Design system foundations';
      final errors = await _pump(
        tester,
        DsMultiSelect<int>(
          value: const [1, 2],
          onChanged: (_) {},
          options: const [
            DsSelectOption(value: 1, label: 'Frontend'),
            DsSelectOption(value: 2, label: label),
          ],
        ),
        width: 288,
        textScale: 2,
      );
      expect(errors, isEmpty);
      expect(_fullyShown(tester, label), isTrue);
      expect(_fullyShown(tester, 'Frontend'), isTrue);
    });

    testWidgets('collapsed tags keep to one line', (tester) async {
      await _pump(
        tester,
        DsMultiSelect<int>(
          value: const [1],
          collapseTags: true,
          onChanged: (_) {},
          options: const [
            DsSelectOption(
              value: 1,
              label: 'A label far too long for the one line it gets here',
            ),
          ],
        ),
        width: 200,
      );
      final text = tester.widget<Text>(
        find.text('A label far too long for the one line it gets here'),
      );
      expect(text.maxLines, 1);
    });
  });
}

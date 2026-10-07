import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui/src/painting/numeric_span.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../components/helpers.dart';

/// Numeric text keeps tabular figures on its digits only: in Schibsted
/// Grotesk `tnum` also widens `.`, `,`, `:` and `/` to a digit's width,
/// so "12.480,00" read like a typewriter. Digits still line up in a
/// column.
void main() {
  const tnum = FontFeature.tabularFigures();
  final y = DsTypography();
  final numeric = y.numeric(y.small);

  /// (text, tabular) per run.
  List<(String, bool)> runs(TextSpan span) => [
    if (span.children == null)
      (span.text!, span.style?.fontFeatures?.contains(tnum) ?? false)
    else
      for (final child in span.children!.cast<TextSpan>())
        (
          child.text!,
          // A child without features of its own takes the parent's.
          (child.style?.fontFeatures ?? span.style?.fontFeatures ?? const [])
              .contains(tnum),
        ),
  ];

  test('tabular digits, proportional separators', () {
    final span = numericSpan('12.480,00', style: numeric);
    expect(span.style, numeric);
    expect(span.toPlainText(), '12.480,00');
    expect(runs(span), [
      ('12', true),
      ('.', false),
      ('480', true),
      (',', false),
      ('00', true),
    ]);
  });

  test('counters, signs and units', () {
    expect(runs(numericSpan('13 / 100', style: numeric)), [
      ('13', true),
      (' / ', false),
      ('100', true),
    ]);
    expect(runs(numericSpan('−4,5 kg', style: numeric)), [
      ('−', false),
      ('4', true),
      (',', false),
      ('5', true),
      (' kg', false),
    ]);
    expect(runs(numericSpan('99+', style: numeric)), [
      ('99', true),
      ('+', false),
    ]);
  });

  test('separators are drawn narrower than a digit, digits still tabular', () {
    double width(InlineSpan span) => (TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    )..layout()).width;
    const amount = '12.480,00';
    final split = width(numericSpan(amount, style: numeric));
    // Every run tabular: the separators take a digit's width.
    final allTabular = width(TextSpan(text: amount, style: numeric));
    // No tabular figures at all.
    final proportional = width(TextSpan(text: amount, style: y.small));
    expect(split, lessThan(allTabular - 4));
    expect(split, greaterThanOrEqualTo(proportional));
  });

  test('digits of other scripts count as digits', () {
    expect(runs(numericSpan('١٢٫٥', style: numeric)), [
      ('١٢', true),
      ('٫', false),
      ('٥', true),
    ]);
  });

  test('only digits, or none, stays one span', () {
    expect(numericSpan('2026', style: numeric).children, isNull);
    expect(numericSpan('Ocak', style: numeric).children, isNull);
  });

  test('a style without tabular figures is left alone', () {
    final plain = numericSpan('12.480,00', style: y.small);
    expect(plain.children, isNull);
    expect(plain.style, y.small);
    expect(numericSpan('1,5').children, isNull);
  });

  test('other font features stay on every run', () {
    final ss01 = FontFeature.stylisticSet(1);
    final span = numericSpan(
      '1.5',
      style: TextStyle(fontFeatures: [tnum, ss01]),
    );
    final dot = span.children![1] as TextSpan;
    expect(dot.style!.fontFeatures, [ss01, const FontFeature.disable('tnum')]);
  });

  testWidgets('a table amount sets its separators proportionally, and the '
      'digits still line up', (tester) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 400,
          height: 300,
          child: DsTable<String>(
            rows: const ['12.480,00', '2.175,50'],
            rowKey: (v) => v,
            columns: [
              DsTableColumn<String>(
                id: 'amount',
                label: 'Amount',
                text: (v) => v,
                numeric: true,
              ),
            ],
          ),
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('12.480,00'));
    expect((text.textSpan! as TextSpan).children, hasLength(5));
    // End-aligned: the decimals of both rows end at the same edge.
    expect(
      tester.getRect(find.text('12.480,00')).right,
      moreOrLessEquals(
        tester.getRect(find.text('2.175,50')).right,
        epsilon: 0.5,
      ),
    );
  });

  testWidgets('a stepper shows a decimal value with tabular digits only', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(DsStepper(value: 2.5, max: 10, step: .5, onChanged: (_) {})),
    );
    final shown = tester.widget<Text>(find.text('2.5').last);
    expect(runs(shown.textSpan! as TextSpan), [
      ('2', true),
      ('.', false),
      ('5', true),
    ]);
  });
}

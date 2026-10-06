import 'dart:ui' show SemanticsValidationResult;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Regressions from the blind audit (phase B): checkbox, radio, switch,
/// chip.
void main() {
  final light = DsThemeData();

  DsBoxDecoration boxOf(WidgetTester tester, Finder control) =>
      tester
              .widget<AnimatedContainer>(
                find
                    .descendant(
                      of: control,
                      matching: find.byType(AnimatedContainer),
                    )
                    .first,
              )
              .decoration!
          as DsBoxDecoration;

  testWidgets('an empty fieldError does not crash a checkbox (eng M1)', (
    tester,
  ) async {
    final theme = DsThemeData(
      adjustShadows: (s, c, b) => s.copyWith(fieldError: const []),
    );
    await tester.pumpWidget(
      host(
        Column(
          children: [
            DsCheckbox(value: false, error: true, onChanged: (_) {}),
            DsRadioGroup<int>(
              value: 1,
              onChanged: (_) {},
              child: const DsRadio(value: 2, error: true),
            ),
          ],
        ),
        theme: theme,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      boxOf(tester, find.byType(DsCheckbox)).shadows.first.color,
      theme.colors.danger.text,
    );
  });

  testWidgets('errors are announced as invalid (ux V9, F-16)', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        Column(
          children: [
            DsCheckbox(
              value: false,
              error: true,
              semanticLabel: 'Terms',
              onChanged: (_) {},
            ),
            DsRadioGroup<int>(
              value: 1,
              onChanged: (_) {},
              child: const DsRadio(value: 2, error: true, label: Text('Two')),
            ),
          ],
        ),
        theme: light,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Terms')).validationResult,
      SemanticsValidationResult.invalid,
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Two')).validationResult,
      SemanticsValidationResult.invalid,
    );
    handle.dispose();
  });

  testWidgets('error edge is 2px; checked + error turns danger (visual M6)', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        Column(
          children: [
            DsCheckbox(value: false, error: true, onChanged: (_) {}),
            DsCheckbox(value: true, error: true, onChanged: (_) {}),
          ],
        ),
        theme: light,
      ),
    );
    final off = boxOf(tester, find.byType(DsCheckbox).first);
    expect(off.shadows.first.spread, 2, reason: 'not told by hue alone');
    final on = boxOf(tester, find.byType(DsCheckbox).last);
    expect(on.color, light.colors.danger.fill);
    expect(on.shadows.where((s) => s.color.a > 0), isEmpty);
  });

  testWidgets('disabled keeps the shape (visual M7)', (tester) async {
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            DsCheckbox(value: false, onChanged: null),
            DsCheckbox(value: true, onChanged: null),
            DsChip(label: Text('Seçili'), selected: true, onChanged: null),
          ],
        ),
        theme: light,
      ),
    );
    final unchecked = boxOf(tester, find.byType(DsCheckbox).first);
    expect(unchecked.shadows.first, DsShadow.innerRing(light.colors.border));
    final checked = boxOf(tester, find.byType(DsCheckbox).last);
    expect(checked.shadows.where((s) => s.color.a > 0), isEmpty);
    final chip = boxOf(tester, find.byType(DsChip));
    expect(chip.color, light.colors.disabled);
    expect(
      chip.shadows.where((s) => s.color.a > 0),
      isEmpty,
      reason: 'a selected chip has no outline, disabled or not',
    );
  });

  testWidgets('a labelled switch works inside a Row (B10)', (tester) async {
    await tester.pumpWidget(
      host(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DsSwitch(
              value: true,
              label: const Text('Bildirimler'),
              onChanged: (_) {},
            ),
          ],
        ),
        theme: light,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}

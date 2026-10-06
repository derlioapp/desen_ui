@Tags(['golden'])
library;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_harness.dart';

/// Visual regression for DsNumberField (concept card 39): rest, focused,
/// a hovered button, with a unit, a Turkish currency with grouping, error,
/// disabled, read-only and RTL with the buttons mirrored, light and dark
/// (KALITE K-24).
void main() {
  for (final MapEntry(key: mode, value: theme) in themesFor(
    DsSeed.blue,
  ).entries) {
    testWidgets('number field $mode', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      // A desktop with a mouse: hover shows.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      const width = 220.0;
      Widget cell(String label, Widget field) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Text(
            label,
            style: theme.typography.caption.copyWith(
              color: theme.colors.textSubtle,
            ),
          ),
          SizedBox(width: width, child: field),
        ],
      );
      void none(num? _) {}
      await pumpGolden(
        tester,
        Wrap(
          spacing: 32,
          runSpacing: 24,
          children: [
            cell(
              'rest',
              DsNumberField(value: 3, min: 0, max: 10, onChanged: none),
            ),
            cell(
              'focused',
              DsNumberField(
                value: 3,
                min: 0,
                max: 10,
                focusNode: focus,
                onChanged: none,
              ),
            ),
            cell(
              'hovered button',
              DsNumberField(
                key: const ValueKey('hover'),
                value: 3,
                onChanged: none,
              ),
            ),
            cell(
              'unit',
              DsNumberField(
                value: 72.5,
                format: const DsNumberFormat(decimals: 1),
                unit: 'kg',
                onChanged: none,
              ),
            ),
            cell(
              'tr currency, at max',
              DsLocalizationScope(
                localizations: const DsLocalizationsTr(),
                child: DsNumberField(
                  value: 12500,
                  max: 12500,
                  format: const DsNumberFormat(decimals: 2, grouping: true),
                  unit: '₺',
                  onChanged: none,
                ),
              ),
            ),
            cell(
              'error',
              DsField(
                errorText: 'En fazla 10.',
                child: DsNumberField(value: 12, unit: 'adet', onChanged: none),
              ),
            ),
            cell(
              'disabled',
              const DsNumberField(value: 4, unit: 'kg', onChanged: null),
            ),
            cell(
              'read-only',
              DsNumberField(value: 4, readOnly: true, onChanged: none),
            ),
            cell(
              'placeholder',
              DsNumberField(value: null, placeholder: '0', onChanged: none),
            ),
          ],
        ),
        theme: theme,
      );
      focus.requestFocus();
      await tester.pump();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      final hovered = find.descendant(
        of: find.byKey(const ValueKey('hover')),
        matching: find.byWidgetPredicate(
          (w) => w is DsIcon && w.icon == DsIcons.plus,
        ),
      );
      await mouse.moveTo(tester.getCenter(hovered));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await expectGolden(tester, 'goldens/number_field_$mode.png');
      focus.unfocus();
      await tester.pump();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.textInput,
        null,
      );
    });

    testWidgets('number field rtl $mode', (tester) async {
      void none(num? _) {}
      await pumpGolden(
        tester,
        SizedBox(
          width: 220,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              DsNumberField(value: 3, min: 0, max: 10, onChanged: none),
              DsNumberField(
                value: 72.5,
                format: const DsNumberFormat(decimals: 1),
                unit: 'kg',
                onChanged: none,
              ),
            ],
          ),
        ),
        theme: theme,
        direction: TextDirection.rtl,
      );
      await expectGolden(tester, 'goldens/number_field_rtl_$mode.png');
    });
  }
}

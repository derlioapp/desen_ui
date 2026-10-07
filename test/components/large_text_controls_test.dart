import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Controls with a label grow with large text, as a text field does, so
/// the label keeps clear of their edges; at the regular size they keep
/// their heights.
void main() {
  final controls = <String, (Widget, double)>{
    'button': (DsButton(onPressed: () {}, child: const Text('Save')), 40),
    'chip': (
      DsChip(label: const Text('Save'), selected: false, onChanged: (_) {}),
      32,
    ),
    'segmented control': (
      DsSegmentedControl<int>(
        value: 0,
        onChanged: (_) {},
        segments: const [
          DsSegment(value: 0, label: Text('Save')),
          DsSegment(value: 1, label: Text('Other')),
        ],
      ),
      38,
    ),
    'select': (
      DsSelect<int>(
        value: 0,
        onChanged: (_) {},
        semanticLabel: 'Action',
        options: const [DsSelectOption(value: 0, label: 'Save')],
      ),
      40,
    ),
  };

  Future<(double, double, double)> measure(
    WidgetTester tester,
    Widget control,
    double scale,
  ) async {
    await tester.pumpWidget(
      DsApp(
        theme: DsThemeData(platform: TargetPlatform.macOS),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Align(alignment: Alignment.topLeft, child: control),
      ),
    );
    await tester.pumpAndSettle();
    final box = tester.getRect(find.byWidget(control));
    final label = tester.getRect(find.text('Save'));
    return (box.height, label.top - box.top, box.bottom - label.bottom);
  }

  for (final MapEntry(key: name, value: (control, height))
      in controls.entries) {
    testWidgets('$name: same height at the regular size, room for the label '
        'at 2x', (tester) async {
      expect((await measure(tester, control, 1)).$1, height);
      final (_, top, bottom) = await measure(tester, control, 2);
      expect(top, greaterThanOrEqualTo(5), reason: 'top');
      expect(bottom, greaterThanOrEqualTo(5), reason: 'bottom');
    });
  }
}

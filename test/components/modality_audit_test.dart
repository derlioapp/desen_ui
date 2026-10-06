import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Unfocused group controls ignore keyboard/pointer modality
/// flips instead of rebuilding on every input event in the app.
void main() {
  final controls = <String, Widget>{
    'tabs': DsTabs<int>(
      value: 0,
      onChanged: (_) {},
      tabs: const [DsTab(value: 0, label: Text('a'))],
    ),
    'segmented': DsSegmentedControl<int>(
      value: 0,
      onChanged: (_) {},
      segments: const [
        DsSegment(value: 0, label: Text('a')),
        DsSegment(value: 1, label: Text('b')),
      ],
    ),
    'slider': SizedBox(
      width: 200,
      child: DsSlider(value: .5, onChanged: (_) {}),
    ),
    'stepper': DsStepper(value: 1, onChanged: (_) {}),
    'radio': DsRadioGroup<int>(
      value: 0,
      onChanged: (_) {},
      child: const DsRadio(value: 0),
    ),
  };

  for (final MapEntry(key: name, value: control) in controls.entries) {
    testWidgets('$name does not rebuild on modality flips while unfocused', (
      tester,
    ) async {
      useTraditionalHighlights();
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [control, const SizedBox(width: 50, height: 50)],
          ),
        ),
      );
      // A pointer press hides focus, a key brings it back.
      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.tapAt(const Offset(2, 2));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  }
}

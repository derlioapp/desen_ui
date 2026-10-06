import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keyboard modality is global. The test binding clears every keyboard
/// handler after each test; an app's suite must not become order-dependent.
/// The tests run in order and depend on it on purpose.
void main() {
  Widget app(String label) => DsApp(
    theme: DsThemeData(platform: TargetPlatform.macOS),
    home: Center(
      child: DsButton(onPressed: () {}, child: Text(label)),
    ),
  );

  testWidgets('A: a tap hides keyboard focus', (tester) async {
    await tester.pumpWidget(app('a'));
    await tester.tap(find.text('a'));
    await tester.pump();
    expect(DsFocusVisibility.keyboard.value, isFalse);
  });

  testWidgets('B: the next test starts afresh, and keys still count', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(
      DsFocusVisibility.keyboard.value,
      isTrue,
      reason: 'the desktop initial state, not the tap of test A',
    );
    await tester.pumpWidget(app('b'));
    await tester.tap(find.text('b'));
    await tester.pump();
    expect(DsFocusVisibility.keyboard.value, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      DsFocusVisibility.keyboard.value,
      isTrue,
      reason: 'the key handler listens again after the binding reset',
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('C: debugReset pins the starting value', (tester) async {
    await tester.pumpWidget(app('c'));
    await tester.tap(find.text('c'));
    await tester.pump();
    DsFocusVisibility.debugReset(keyboard: true);
    expect(DsFocusVisibility.keyboard.value, isTrue);
    DsFocusVisibility.debugReset(keyboard: false);
    expect(DsFocusVisibility.keyboard.value, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pump();
    expect(DsFocusVisibility.keyboard.value, isTrue, reason: 'it listens');
    // Without a value: the platform's own start (Android in tests: hidden).
    DsFocusVisibility.debugReset();
    expect(
      DsFocusVisibility.keyboard.value,
      defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS,
    );
  });
}

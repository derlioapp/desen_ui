import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../components/helpers.dart';

const _tick = 'HapticFeedbackType.selectionClick';
const _impact = 'HapticFeedbackType.lightImpact';

/// Records every `HapticFeedback.vibrate` call by its feedback type.
List<String?> _recordHaptics(WidgetTester tester) {
  final calls = <String?>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String?);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

DsThemeData _theme(TargetPlatform platform, [DsHaptics? haptics]) =>
    DsThemeData(platform: platform, haptics: haptics);

final _iOS = _theme(TargetPlatform.iOS);

/// A stateful harness: [build] gets the current value and a setter.
Widget _stateful<T>(
  T initial,
  Widget Function(T value, ValueChanged<T> set) build,
) {
  var value = initial;
  return StatefulBuilder(
    builder: (context, setState) =>
        build(value, (v) => setState(() => value = v)),
  );
}

void main() {
  group('the setting', () {
    test('plays: none is silent, subtle only selections, full both', () {
      expect(DsHaptics.none.plays(DsHapticEvent.selection), isFalse);
      expect(DsHaptics.none.plays(DsHapticEvent.command), isFalse);
      expect(DsHaptics.subtle.plays(DsHapticEvent.selection), isTrue);
      expect(DsHaptics.subtle.plays(DsHapticEvent.command), isFalse);
      expect(DsHaptics.full.plays(DsHapticEvent.selection), isTrue);
      expect(DsHaptics.full.plays(DsHapticEvent.command), isTrue);
    });

    test('defaults to subtle on iOS and Android, none on desktop', () {
      for (final p in [TargetPlatform.iOS, TargetPlatform.android]) {
        expect(_theme(p).haptics, isNull);
        expect(_theme(p).effectiveHaptics, DsHaptics.subtle, reason: '$p');
      }
      for (final p in [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      ]) {
        expect(_theme(p).effectiveHaptics, DsHaptics.none, reason: '$p');
      }
    });

    test('an explicit setting wins over the platform default', () {
      expect(
        _theme(TargetPlatform.iOS, DsHaptics.none).effectiveHaptics,
        DsHaptics.none,
      );
      expect(
        _theme(TargetPlatform.android, DsHaptics.full).effectiveHaptics,
        DsHaptics.full,
      );
      expect(
        _theme(TargetPlatform.macOS, DsHaptics.full).effectiveHaptics,
        DsHaptics.full,
      );
    });

    test('takes part in equality, hashCode, copyWith and lerp', () {
      final a = _theme(TargetPlatform.iOS);
      final b = a.copyWith(haptics: () => DsHaptics.full);
      expect(b.haptics, DsHaptics.full);
      expect(a == b, isFalse);
      expect(a.hashCode == b.hashCode, isFalse);
      // Not a generation input: the tokens stay.
      expect(identical(b.colors, a.colors), isTrue);
      expect(b.copyWith(haptics: () => null), a);
      expect(b.copyWith(), b);
      // Regenerating keeps it.
      expect(b.copyWith(brightness: Brightness.dark).haptics, DsHaptics.full);
      // Settings switch at the midpoint.
      expect(DsThemeData.lerp(a, b, 0.4).haptics, isNull);
      expect(DsThemeData.lerp(a, b, 0.6).haptics, DsHaptics.full);
    });

    testWidgets('DsScope keeps it through dark mode and reduced motion', (
      tester,
    ) async {
      final calls = _recordHaptics(tester);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            platformBrightness: Brightness.dark,
            disableAnimations: true,
          ),
          child: DsScope(
            theme: _theme(TargetPlatform.iOS, DsHaptics.full),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: DsButton(onPressed: () {}, child: const Text('Kaydet')),
              ),
            ),
          ),
        ),
      );
      final theme = DsTheme.of(tester.element(find.byType(DsButton)));
      expect(theme.isDark, isTrue);
      expect(theme.motion.reduced, isTrue);
      expect(theme.haptics, DsHaptics.full);
      await tester.tap(find.byType(DsButton));
      expect(calls, [_impact]);
    });
  });

  group('DsPressable', () {
    Future<void> pump(
      WidgetTester tester,
      DsThemeData theme, {
      DsHapticEvent? haptic = DsHapticEvent.command,
      VoidCallback? onPressed,
      VoidCallback? onLongPress,
    }) => tester.pumpWidget(
      host(
        DsPressable(
          onPressed: onPressed,
          onLongPress: onLongPress,
          haptic: haptic,
          builder: (_, _, _) => const SizedBox(width: 40, height: 40),
        ),
        theme: theme,
      ),
    );

    testWidgets('a command plays a light impact under full only', (
      tester,
    ) async {
      final calls = _recordHaptics(tester);
      for (final (setting, expected) in [
        (DsHaptics.none, <String?>[]),
        (DsHaptics.subtle, <String?>[]),
        (DsHaptics.full, [_impact]),
      ]) {
        calls.clear();
        await pump(
          tester,
          _theme(TargetPlatform.iOS, setting),
          onPressed: () {},
        );
        await tester.tap(find.byType(DsPressable));
        expect(calls, expected, reason: '$setting');
      }
    });

    testWidgets('a selection ticks under subtle and full', (tester) async {
      final calls = _recordHaptics(tester);
      for (final (setting, expected) in [
        (DsHaptics.none, <String?>[]),
        (DsHaptics.subtle, [_tick]),
        (DsHaptics.full, [_tick]),
      ]) {
        calls.clear();
        await pump(
          tester,
          _theme(TargetPlatform.android, setting),
          haptic: DsHapticEvent.selection,
          onPressed: () {},
        );
        await tester.tap(find.byType(DsPressable));
        expect(calls, expected, reason: '$setting');
      }
    });

    testWidgets('plays before the callback runs', (tester) async {
      final calls = _recordHaptics(tester);
      int? seen;
      await pump(
        tester,
        _theme(TargetPlatform.iOS, DsHaptics.full),
        onPressed: () => seen = calls.length,
      );
      await tester.tap(find.byType(DsPressable));
      expect(seen, 1);
    });

    testWidgets('desktop stays silent whatever the setting', (tester) async {
      final calls = _recordHaptics(tester);
      for (final platform in [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      ]) {
        await pump(
          tester,
          _theme(platform, DsHaptics.full),
          haptic: DsHapticEvent.selection,
          onPressed: () {},
        );
        await tester.tap(find.byType(DsPressable));
      }
      expect(calls, isEmpty);
    });

    testWidgets('haptic: null, disabled and long press stay silent', (
      tester,
    ) async {
      final calls = _recordHaptics(tester);
      final full = _theme(TargetPlatform.iOS, DsHaptics.full);
      await pump(tester, full, haptic: null, onPressed: () {});
      await tester.tap(find.byType(DsPressable));
      await pump(tester, full);
      await tester.tap(find.byType(DsPressable), warnIfMissed: false);
      await pump(tester, full, onLongPress: () {});
      await tester.longPress(find.byType(DsPressable));
      expect(calls, isEmpty);
    });

    testWidgets('keyboard activation stays silent', (tester) async {
      final calls = _recordHaptics(tester);
      final node = FocusNode();
      addTearDown(node.dispose);
      var presses = 0;
      await tester.pumpWidget(
        host(
          DsPressable(
            focusNode: node,
            onPressed: () => presses++,
            haptic: DsHapticEvent.selection,
            builder: (_, _, _) => const SizedBox(width: 40, height: 40),
          ),
          theme: _theme(TargetPlatform.iOS, DsHaptics.full),
        ),
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(presses, 2);
      expect(calls, isEmpty);
    });

    testWidgets('works without a theme above', (tester) async {
      final calls = _recordHaptics(tester);
      await tester.pumpWidget(
        host(
          DsPressable(
            onPressed: () {},
            haptic: DsHapticEvent.selection,
            builder: (_, _, _) => const SizedBox(width: 40, height: 40),
          ),
        ),
      );
      await tester.tap(find.byType(DsPressable));
      // The fallback theme follows the test platform (Android): subtle.
      expect(calls, [_tick]);
    });
  });

  group('controls on iOS (platform default)', () {
    testWidgets('a button stays silent', (tester) async {
      final calls = _recordHaptics(tester);
      await tester.pumpWidget(
        host(
          DsButton(onPressed: () {}, child: const Text('Kaydet')),
          theme: _iOS,
        ),
      );
      await tester.tap(find.byType(DsButton));
      expect(calls, isEmpty);
    });

    testWidgets('a switch, a checkbox and a chip tick', (tester) async {
      final calls = _recordHaptics(tester);
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsSwitch(value: false, onChanged: (_) {}),
              DsCheckbox(value: false, onChanged: (_) {}),
              DsChip(
                label: const Text('Tasarım'),
                selected: false,
                onChanged: (_) {},
              ),
            ],
          ),
          theme: _iOS,
        ),
      );
      await tester.tap(find.byType(DsSwitch));
      await tester.tap(find.byType(DsCheckbox));
      await tester.tap(find.byType(DsChip));
      expect(calls, [_tick, _tick, _tick]);
    });

    testWidgets('a radio ticks when the choice moves', (tester) async {
      final calls = _recordHaptics(tester);
      await tester.pumpWidget(
        host(
          _stateful<String?>(
            'a',
            (value, set) => DsRadioGroup<String>(
              value: value,
              onChanged: set,
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DsRadio(value: 'a', label: Text('Aylık')),
                  DsRadio(value: 'b', label: Text('Yıllık')),
                ],
              ),
            ),
          ),
          theme: _iOS,
        ),
      );
      await tester.tap(find.text('Aylık'));
      await tester.pump();
      expect(calls, isEmpty);
      await tester.tap(find.text('Yıllık'));
      await tester.pump();
      expect(calls, [_tick]);
    });

    testWidgets('a segmented control ticks on a new segment only', (
      tester,
    ) async {
      final calls = _recordHaptics(tester);
      await tester.pumpWidget(
        host(
          _stateful<String>(
            'day',
            (value, set) => DsSegmentedControl<String>(
              value: value,
              onChanged: set,
              segments: const [
                DsSegment(value: 'day', label: Text('Gün')),
                DsSegment(value: 'week', label: Text('Hafta')),
              ],
            ),
          ),
          theme: _iOS,
        ),
      );
      await tester.tap(find.text('Gün'));
      await tester.pump();
      expect(calls, isEmpty);
      await tester.tap(find.text('Hafta'));
      await tester.pump();
      expect(calls, [_tick]);
    });

    testWidgets('choice chips tick on a new chip only', (tester) async {
      final calls = _recordHaptics(tester);
      await tester.pumpWidget(
        host(
          _stateful<String>(
            'all',
            (value, set) => DsChoiceChips<String>(
              value: value,
              onChanged: set,
              options: const [
                DsChipOption(value: 'all', label: Text('Tümü')),
                DsChipOption(value: 'unread', label: Text('Okunmamış')),
              ],
            ),
          ),
          theme: _iOS,
        ),
      );
      await tester.tap(find.text('Tümü'));
      await tester.pump();
      expect(calls, isEmpty);
      await tester.tap(find.text('Okunmamış'));
      await tester.pump();
      expect(calls, [_tick]);
    });

    testWidgets('tabs tick on a new tab only', (tester) async {
      final calls = _recordHaptics(tester);
      await tester.pumpWidget(
        host(
          _stateful<String>(
            'general',
            (value, set) => DsTabs<String>(
              value: value,
              onChanged: set,
              tabs: const [
                DsTab(value: 'general', label: Text('Genel')),
                DsTab(value: 'members', label: Text('Üyeler')),
              ],
            ),
          ),
          theme: _iOS,
        ),
      );
      await tester.tap(find.text('Genel'));
      await tester.pump();
      expect(calls, isEmpty);
      await tester.tap(find.text('Üyeler'));
      await tester.pump();
      expect(calls, [_tick]);
    });

    testWidgets('a stepped slider ticks per step; a continuous one never', (
      tester,
    ) async {
      final calls = _recordHaptics(tester);
      Widget slider({int? divisions}) => host(
        SizedBox(
          width: 400,
          child: _stateful<double>(
            0,
            (value, set) =>
                DsSlider(value: value, divisions: divisions, onChanged: set),
          ),
        ),
        theme: _iOS,
      );

      await tester.pumpWidget(slider(divisions: 4));
      final rect = tester.getRect(find.byType(DsSlider));
      final gesture = await tester.startGesture(rect.centerLeft);
      for (var x = 0.0; x <= rect.width; x += 20) {
        await gesture.moveTo(rect.centerLeft + Offset(x, 0));
        await tester.pump();
      }
      await gesture.up();
      // Four steps from 0 to the end, one tick each.
      expect(calls, List.filled(4, _tick));

      calls.clear();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(slider());
      await tester.drag(find.byType(DsSlider), const Offset(200, 0));
      await tester.pump();
      expect(calls, isEmpty);
    });

    testWidgets('a stepper ticks when the value changes', (tester) async {
      final calls = _recordHaptics(tester);
      Finder icon(DsIconData data) =>
          find.byWidgetPredicate((w) => w is DsIcon && w.icon == data);
      await tester.pumpWidget(
        host(
          _stateful<int>(
            0,
            (value, set) => DsStepper(value: value, max: 1, onChanged: set),
          ),
          theme: _theme(TargetPlatform.iOS, DsHaptics.full),
        ),
      );
      await tester.tap(icon(DsIcons.plus));
      await tester.pump();
      // One tick, not a tick and a command impact.
      expect(calls, [_tick]);
      // At the maximum the button is off: nothing plays.
      await tester.tap(icon(DsIcons.plus), warnIfMissed: false);
      await tester.pump();
      expect(calls, [_tick]);
    });

    testWidgets('a number field step button ticks', (tester) async {
      final calls = _recordHaptics(tester);
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 200,
            child: _stateful<num?>(
              1,
              (value, set) => DsNumberField(value: value, onChanged: set),
            ),
          ),
          theme: _iOS,
        ),
      );
      await tester.tap(
        find.byWidgetPredicate((w) => w is DsIcon && w.icon == DsIcons.plus),
      );
      await tester.pump();
      expect(calls, [_tick]);
    });

    testWidgets('picking a day ticks', (tester) async {
      final calls = _recordHaptics(tester);
      await tester.pumpWidget(
        host(
          DsCalendar(
            value: null,
            currentDate: DateTime(2026, 10, 6),
            onChanged: (_) {},
          ),
          theme: _iOS,
        ),
      );
      await tester.tap(find.text('14'));
      expect(calls, [_tick]);
    });

    testWidgets('picking a select option ticks; plain menu items do not', (
      tester,
    ) async {
      final calls = _recordHaptics(tester);
      await tester.pumpWidget(
        DsApp(
          theme: _iOS,
          home: Center(
            child: SizedBox(
              width: 240,
              child: DsSelect<int>(
                value: 1,
                onChanged: (_) {},
                options: const [
                  DsSelectOption(value: 1, label: 'One'),
                  DsSelectOption(value: 2, label: 'Two'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DsSelect<int>));
      await tester.pumpAndSettle();
      // Opening the select is a command: silent under subtle.
      expect(calls, isEmpty);
      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(calls, [_tick]);
    });
  });
  group('keys stay silent on iOS', () {
    late FocusNode node;
    setUp(() => node = FocusNode());
    tearDown(() => node.dispose());

    Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(key);
      await tester.pump();
    }

    testWidgets('tabs and a segmented control', (tester) async {
      final calls = _recordHaptics(tester);
      var tab = 'general';
      await tester.pumpWidget(
        host(
          _stateful<String>(
            'general',
            (value, set) => DsTabs<String>(
              value: value,
              focusNode: node,
              onChanged: (v) {
                tab = v;
                set(v);
              },
              tabs: const [
                DsTab(value: 'general', label: Text('Genel')),
                DsTab(value: 'members', label: Text('Üyeler')),
              ],
            ),
          ),
          theme: _iOS,
        ),
      );
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(tab, 'members');

      var segment = 'day';
      await tester.pumpWidget(
        host(
          _stateful<String>(
            'day',
            (value, set) => DsSegmentedControl<String>(
              value: value,
              focusNode: node,
              onChanged: (v) {
                segment = v;
                set(v);
              },
              segments: const [
                DsSegment(value: 'day', label: Text('Gün')),
                DsSegment(value: 'week', label: Text('Hafta')),
              ],
            ),
          ),
          theme: _iOS,
        ),
      );
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(segment, 'week');
      expect(calls, isEmpty);
    });

    testWidgets('a stepped slider and a stepper', (tester) async {
      final calls = _recordHaptics(tester);
      var volume = 0.0;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 400,
            child: _stateful<double>(
              0,
              (value, set) => DsSlider(
                value: value,
                divisions: 4,
                focusNode: node,
                onChanged: (v) {
                  volume = v;
                  set(v);
                },
              ),
            ),
          ),
          theme: _iOS,
        ),
      );
      await press(tester, LogicalKeyboardKey.arrowRight);
      expect(volume, 0.25);

      var guests = 0;
      await tester.pumpWidget(
        host(
          _stateful<int>(
            0,
            (value, set) => DsStepper(
              value: value,
              focusNode: node,
              onChanged: (v) {
                guests = v;
                set(v);
              },
            ),
          ),
          theme: _iOS,
        ),
      );
      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(guests, 1);
      expect(calls, isEmpty);
    });

    testWidgets('a radio group moved with arrows', (tester) async {
      final calls = _recordHaptics(tester);
      String? plan = 'a';
      await tester.pumpWidget(
        host(
          _stateful<String?>(
            'a',
            (value, set) => DsRadioGroup<String>(
              value: value,
              onChanged: (v) {
                plan = v;
                set(v);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DsRadio(
                    value: 'a',
                    focusNode: node,
                    label: const Text('Aylık'),
                  ),
                  const DsRadio(value: 'b', label: Text('Yıllık')),
                ],
              ),
            ),
          ),
          theme: _iOS,
        ),
      );
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(plan, 'b');
      expect(calls, isEmpty);
    });

    testWidgets('an app call to DsHapticFeedback.play still plays', (
      tester,
    ) async {
      final calls = _recordHaptics(tester);
      await tester.pumpWidget(host(const SizedBox(), theme: _iOS));
      // After a key press, as from a shortcut handler.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      DsHapticFeedback.play(
        tester.element(find.byType(SizedBox).first),
        DsHapticEvent.selection,
      );
      expect(calls, [_tick]);
    });
  });
}

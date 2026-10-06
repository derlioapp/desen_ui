import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Read-only is not disabled: a read-only field reads as a value on the
/// page (no fill, the decorative hairline, text at full contrast), still
/// selects and shows focus, and drops the buttons that would edit it. A
/// disabled field stays dimmed.
void main() {
  final theme = DsThemeData();
  final k = theme.colors;
  const clear = Color(0x00000000);

  Widget app(Widget child) => DsApp(
    theme: theme,
    themeMode: DsThemeMode.light,
    home: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: SizedBox(width: 320, child: child),
      ),
    ),
  );

  DsBoxDecoration well(WidgetTester tester, Type of) =>
      tester
              .widget<AnimatedContainer>(
                find
                    .descendant(
                      of: find.byType(of),
                      matching: find.byType(AnimatedContainer),
                    )
                    .first,
              )
              .decoration!
          as DsBoxDecoration;
  DsShadow? edge(DsBoxDecoration d) =>
      d.shadows.where((x) => x.inset && x.color.a > 0).firstOrNull;
  EditableText editable(WidgetTester tester) =>
      tester.widget<EditableText>(find.byType(EditableText));
  Finder icon(DsIconData data) =>
      find.byWidgetPredicate((w) => w is DsIcon && w.icon == data);

  void expectReadOnlyLook(DsBoxDecoration d) {
    expect(d.color, clear);
    expect(edge(d)!.color, k.border);
    expect(edge(d)!.spread, 1);
  }

  group('text field', () {
    testWidgets('no fill, hairline edge, text at full contrast', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const DsTextField(initialValue: 'Salt okunur', readOnly: true)),
      );
      expectReadOnlyLook(well(tester, DsTextField));
      expect(editable(tester).style.color, k.text);
      expect(editable(tester).readOnly, isTrue);
      // Still selectable.
      expect(editable(tester).enableInteractiveSelection, isTrue);
    });

    testWidgets('differs from disabled, which stays dimmed', (tester) async {
      await tester.pumpWidget(
        app(const DsTextField(initialValue: 'Pasif', enabled: false)),
      );
      final d = well(tester, DsTextField);
      expect(d.color, k.disabled);
      expect(editable(tester).style.color, k.onDisabled);
      expect(k.onDisabled, isNot(k.text));
      expect(k.disabled, isNot(clear));
    });

    testWidgets('focus still shows: the 2px focus edge', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        app(DsTextField(initialValue: 'x', readOnly: true, focusNode: node)),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      final d = well(tester, DsTextField);
      expect(d.color, clear);
      expect(edge(d)!.color, k.focus);
      expect(edge(d)!.spread, 2);
      // The text selects while focused.
      editable(tester).controller.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 1,
      );
      await tester.pump();
      expect(editable(tester).selectionColor, isNotNull);
    });

    testWidgets('no clear button; the show-password button stays', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          const Column(
            children: [
              DsTextField(initialValue: 'x', clearable: true, readOnly: true),
              DsTextField(
                initialValue: 'gizli',
                obscureText: true,
                revealable: true,
                readOnly: true,
              ),
            ],
          ),
        ),
      );
      expect(icon(DsIcons.x), findsNothing);
      expect(icon(DsIcons.eye), findsOneWidget);
    });

    testWidgets('a search field drops its lift too', (tester) async {
      await tester.pumpWidget(
        app(const DsSearchField(initialValue: 'q', readOnly: true)),
      );
      final d = well(tester, DsTextField);
      expect(d.color, clear);
      expect(d.shadows.where((x) => !x.inset && x.color.a > 0), isEmpty);
      expect(icon(DsIcons.x), findsNothing);
    });

    testWidgets('screen readers still hear read-only', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          const DsTextField(
            initialValue: 'x',
            readOnly: true,
            semanticLabel: 'Kod',
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(EditableText)),
        isSemantics(label: 'Kod', isReadOnly: true, isTextField: true),
      );
      semantics.dispose();
    });

    test('a theme can restyle read-only', () {
      final s = DsTextFieldStyle.resolveLayers(
        [
          DsTextField.defaultStyle(theme),
          DsTextFieldStyle(readOnly: DsTextFieldStyle(background: k.hover)),
        ],
        const {},
        readOnly: true,
      );
      expect(s.background, k.hover);
      expect(s.borderColor, k.border);
      // Disabled wins over read-only.
      final off = DsTextFieldStyle.resolveLayers(
        [DsTextField.defaultStyle(theme)],
        {WidgetState.disabled},
        readOnly: true,
      );
      expect(off.background, k.disabled);
    });
  });

  testWidgets('number field: the read-only look, no step buttons', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      app(DsNumberField(value: 72, readOnly: true, onChanged: (_) {})),
    );
    expectReadOnlyLook(well(tester, DsTextField));
    expect(icon(DsIcons.plus), findsNothing);
    expect(icon(DsIcons.minus), findsNothing);
    final data = tester
        .getSemantics(find.byType(EditableText))
        .getSemanticsData();
    expect(data.flagsCollection.isReadOnly, isTrue);
    expect(data.hasAction(SemanticsAction.increase), isFalse);
    expect(data.hasAction(SemanticsAction.decrease), isFalse);
    semantics.dispose();
  });

  testWidgets('number field disabled keeps its buttons, dimmed', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const DsNumberField(value: 72, onChanged: null)),
    );
    expect(well(tester, DsTextField).color, k.disabled);
    expect(icon(DsIcons.plus), findsOneWidget);
  });

  testWidgets('time field: the read-only look, no clock button', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        DsTimePicker(
          value: const DsTime(9, 30),
          readOnly: true,
          onChanged: (_) {},
        ),
      ),
    );
    expectReadOnlyLook(well(tester, DsTextField));
    expect(icon(DsIcons.clock), findsNothing);
  });

  testWidgets('select: the read-only look, no chevron', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      app(
        DsSelect<int>(
          value: 1,
          readOnly: true,
          focusNode: node,
          options: const [DsSelectOption(value: 1, label: 'Bir')],
          onChanged: (_) {},
        ),
      ),
    );
    expectReadOnlyLook(well(tester, DsSelect<int>));
    expect(icon(DsIcons.chevronDown), findsNothing);
    final label = tester.widget<Text>(find.text('Bir'));
    expect(label.style?.color, k.text);
    // Keyboard focus still shows.
    useTraditionalHighlights();
    node.requestFocus();
    await tester.sendKeyEvent(LogicalKeyboardKey.f12);
    await tester.pumpAndSettle();
    expect(edge(well(tester, DsSelect<int>))!.color, k.focus);
  });

  group('multi-select', () {
    const cities = [
      DsSelectOption(value: 'ank', label: 'Ankara'),
      DsSelectOption(value: 'ist', label: 'İstanbul'),
    ];

    testWidgets('read-only: the field look, no chevron and no clear', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          DsMultiSelect<String>(
            value: const ['ank'],
            onChanged: (_) {},
            options: cities,
            readOnly: true,
          ),
        ),
      );
      expectReadOnlyLook(well(tester, DsMultiSelect<String>));
      expect(icon(DsIcons.chevronDown), findsNothing);
      expect(icon(DsIcons.x), findsNothing);
      expect(find.text('Ankara'), findsOneWidget);
    });

    testWidgets('a focused field with an error keeps a danger icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          DsMultiSelect<String>(
            value: const [],
            onChanged: (_) {},
            options: cities,
            error: true,
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      for (final alert in tester.widgetList<DsIcon>(
        icon(DsIcons.circleAlert),
      )) {
        expect(alert.color, isNot(k.focus));
      }
      expect(edge(well(tester, DsMultiSelect<String>))!.color, k.focus);
    });
  });
}

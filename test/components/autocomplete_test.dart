import 'dart:async';
import 'dart:ui' show CheckedState, ImageFilter, SemanticsRole, Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui/src/components/autocomplete/layout.dart';
import 'package:desen_ui/src/components/autocomplete/match.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// DsAutocomplete and DsMultiSelect (KALITE Faz 7b, concept 27, S-29).
void main() {
  const cities = [
    DsSelectOption(value: 'ist', label: 'İstanbul'),
    DsSelectOption(value: 'izm', label: 'İzmir'),
    DsSelectOption(value: 'isp', label: 'Isparta'),
    DsSelectOption(value: 'ank', label: 'Ankara'),
    DsSelectOption(value: 'sir', label: 'Şırnak'),
    DsSelectOption(value: 'esk', label: 'Eskişehir'),
  ];

  Widget app(
    Widget child, {
    DsThemeData? theme,
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    double width = 320,
    bool supportsAnnounce = true,
  }) => DsApp(
    theme: theme ?? DsThemeData(),
    themeMode: DsThemeMode.light,
    locale: const Locale('tr'),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
        supportsAnnounce: supportsAnnounce,
      ),
      child: Directionality(textDirection: direction, child: child!),
    ),
    home: Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: SizedBox(width: width, child: child),
      ),
    ),
  );

  /// A single autocomplete over [cities] that keeps its value.
  Widget single({
    String? initial,
    ValueChanged<String?>? onChanged,
    ValueChanged<String>? onCreate,
    DsOptionsBuilder<String>? optionsBuilder,
    List<DsSelectOption<String>> options = cities,
    bool enabled = true,
    String? label,
  }) {
    String? value = initial;
    return StatefulBuilder(
      builder: (context, setState) {
        final box = DsAutocomplete<String>(
          value: value,
          onChanged: enabled
              ? (v) {
                  setState(() => value = v);
                  onChanged?.call(v);
                }
              : null,
          options: options,
          optionsBuilder: optionsBuilder,
          onCreate: onCreate,
          semanticLabel: label == null ? 'Şehir' : null,
          placeholder: 'Şehir ara',
        );
        return label == null ? box : DsField(label: Text(label), child: box);
      },
    );
  }

  Widget multi({
    List<String> initial = const [],
    ValueChanged<List<String>>? onChanged,
  }) {
    var values = initial;
    return StatefulBuilder(
      builder: (context, setState) => DsMultiSelect<String>(
        value: values,
        onChanged: (v) {
          setState(() => values = v);
          onChanged?.call(v);
        },
        options: cities,
        semanticLabel: 'Şehirler',
      ),
    );
  }

  Finder editable() => find.byType(EditableText);
  Finder icon(DsIconData data) =>
      find.byWidgetPredicate((w) => w is DsIcon && w.icon == data);
  String text(WidgetTester tester) =>
      tester.widget<EditableText>(editable().first).controller.text;

  /// The text field's node as platforms see it (merged).
  SemanticsData fieldData(WidgetTester tester) {
    var node = tester.getSemantics(editable().first);
    while (node.isMergedIntoParent) {
      node = node.parent!;
    }
    return node.getSemanticsData();
  }

  bool textFocused(WidgetTester tester) =>
      tester.widget<EditableText>(editable().first).focusNode.hasPrimaryFocus;

  /// Labels of the listed options, top to bottom.
  List<String> listed(WidgetTester tester) => [
    for (final e
        in find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(RichText),
            )
            .evaluate())
      (e.widget as RichText).text.toPlainText(),
  ];

  Future<void> key(WidgetTester tester, LogicalKeyboardKey k) async {
    await tester.sendKeyEvent(k);
    await tester.pumpAndSettle();
  }

  group('matching', () {
    test('folds Turkish case both ways', () {
      expect(containsFolded('İstanbul', 'ist'), isTrue);
      expect(containsFolded('Isparta', 'ısp'), isTrue);
      expect(containsFolded('Şırnak', 'ŞIR'), isTrue);
      expect(containsFolded('Eskişehir', 'ŞEH'), isTrue);
      expect(containsFolded('Ankara', 'ist'), isFalse);
    });

    test('an option\'s label is folded once and then remembered', () {
      const a = DsSelectOption(value: 1, label: 'İSTANBUL');
      final first = foldedLabel(a);
      expect(first, 'istanbul');
      expect(identical(foldedLabel(a), first), isTrue);
    });

    testWidgets('typing filters a long list by folded labels', (tester) async {
      final options = [
        for (var i = 0; i < 3000; i++)
          DsSelectOption(value: i, label: i == 1234 ? 'Şırnak' : 'Ankara $i'),
      ];
      await tester.pumpWidget(
        DsApp(
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 300,
              child: DsAutocomplete<int>(
                value: null,
                onChanged: (_) {},
                options: options,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'ŞIR');
      await tester.pumpAndSettle();
      expect(listed(tester), ['Şırnak']);
    });

    test('the matched range maps back to the label', () {
      expect(matchRange('İstanbul', 'ist'), const TextRange(start: 0, end: 3));
      expect(matchRange('Eskişehir', 'ŞEH'), const TextRange(start: 4, end: 7));
      // ß folds to two letters: the range covers the one character.
      expect(matchRange('Straße', 'ss'), const TextRange(start: 4, end: 5));
      expect(matchRange('Ankara', ''), isNull);
      expect(matchRange('Ankara', 'x'), isNull);
    });

    test('the match is a bold span', () {
      final span = highlightMatch(
        'Eskişehir',
        'ŞEH',
        match: const TextStyle(fontWeight: FontWeight.w700),
      );
      final parts = span.children!.cast<TextSpan>();
      expect(parts.map((s) => s.text), ['Eski', 'şeh', 'ir']);
      expect(parts[1].style!.fontWeight, FontWeight.w700);
      expect(parts[0].style, isNull);
    });
  });

  group('DsAutocomplete', () {
    testWidgets('typing filters with Turkish case folding', (tester) async {
      await tester.pumpWidget(app(single()));
      await tester.tap(editable());
      await tester.pumpAndSettle();
      expect(
        listed(tester),
        hasLength(cities.length),
        reason: 'a click lists all',
      );
      await tester.enterText(editable(), 'ıs');
      await tester.pumpAndSettle();
      expect(listed(tester), ['İstanbul', 'Isparta']);
      await tester.enterText(editable(), 'IŞ');
      await tester.pumpAndSettle();
      expect(listed(tester), ['Eskişehir']);
      await tester.enterText(editable(), 'ŞIR');
      await tester.pumpAndSettle();
      expect(listed(tester), ['Şırnak']);
    });

    testWidgets('matched letters are drawn in weight 700', (tester) async {
      await tester.pumpWidget(app(single()));
      await tester.tap(editable());
      await tester.enterText(editable(), 'mir');
      await tester.pumpAndSettle();
      final rich = tester.widget<RichText>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(RichText),
        ),
      );
      final bold = <String>[];
      rich.text.visitChildren((span) {
        if (span is TextSpan &&
            span.style?.fontWeight == FontWeight.w700 &&
            span.text != null) {
          bold.add(span.text!);
        }
        return true;
      });
      expect(bold, ['mir']);
    });

    testWidgets('keyboard: Down, Up, Enter, Escape (K-83)', (tester) async {
      String? chosen;
      await tester.pumpWidget(app(single(onChanged: (v) => chosen = v)));
      await tester.tap(editable());
      await tester.pumpAndSettle();
      await key(tester, LogicalKeyboardKey.escape);
      expect(find.byType(ListView), findsNothing);

      // Down opens on the first option; focus stays in the text.
      await key(tester, LogicalKeyboardKey.arrowDown);
      expect(find.byType(ListView), findsOneWidget);
      expect(textFocused(tester), isTrue);
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.arrowUp);
      await key(tester, LogicalKeyboardKey.arrowUp); // wraps to the last
      await key(tester, LogicalKeyboardKey.enter);
      expect(chosen, 'esk');
      expect(text(tester), 'Eskişehir');
      expect(find.byType(ListView), findsNothing, reason: 'Enter closes');

      // Typing filters; the first match is active; Escape closes, then
      // reverts the text to the chosen label, then leaves the value alone
      // (it goes on to the page; clearing is the clear button's job).
      await tester.enterText(editable(), 'ank');
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsOneWidget);
      await key(tester, LogicalKeyboardKey.escape);
      expect(find.byType(ListView), findsNothing);
      expect(text(tester), 'ank');
      await key(tester, LogicalKeyboardKey.escape);
      expect(text(tester), 'Eskişehir');
      expect(chosen, 'esk');
      await key(tester, LogicalKeyboardKey.escape);
      expect(text(tester), 'Eskişehir');
      expect(chosen, 'esk');
    });

    testWidgets('Tab chooses the active option and moves on', (tester) async {
      String? chosen;
      var calls = 0;
      final after = FocusNode();
      addTearDown(after.dispose);
      await tester.pumpWidget(
        app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              single(
                onChanged: (v) {
                  chosen = v;
                  calls++;
                },
              ),
              DsTextField(focusNode: after, semanticLabel: 'Sonraki'),
            ],
          ),
        ),
      );
      await tester.tap(editable().first);
      await tester.enterText(editable().first, 'ank');
      await tester.pumpAndSettle();
      await key(tester, LogicalKeyboardKey.tab);
      expect(chosen, 'ank');
      expect(calls, 1, reason: 'leaving does not choose it again');
      expect(after.hasFocus, isTrue);
      expect(find.byType(ListView), findsNothing);
      expect(text(tester), 'Ankara');
    });

    testWidgets('Home and End stay in the text', (tester) async {
      await tester.pumpWidget(app(single()));
      await tester.tap(editable());
      await tester.enterText(editable(), 'iz');
      await tester.pumpAndSettle();
      await key(tester, LogicalKeyboardKey.home);
      final e = tester.widget<EditableText>(editable());
      expect(e.controller.selection.baseOffset, 0);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('mouse: hover moves the active row, a click chooses', (
      tester,
    ) async {
      String? chosen;
      await tester.pumpWidget(app(single(onChanged: (v) => chosen = v)));
      await tester.tap(editable());
      await tester.pumpAndSettle();
      await hover(tester, find.text('Ankara'));
      DsBoxDecoration decorationOf(String label) =>
          tester
                  .widget<AnimatedContainer>(
                    find
                        .ancestor(
                          of: find.text(label),
                          matching: find.byType(AnimatedContainer),
                        )
                        .first,
                  )
                  .decoration!
              as DsBoxDecoration;
      final k = DsThemeData().colors;
      expect(decorationOf('Ankara').color, k.selection);
      expect(decorationOf('İzmir').color, isNot(k.selection));
      expect(
        decorationOf('Ankara').shadows,
        isEmpty,
        reason: 'no ring for the pointer',
      );
      await tester.tap(find.text('Ankara'));
      await tester.pumpAndSettle();
      expect(chosen, 'ank');
      expect(find.byType(ListView), findsNothing);
      expect(textFocused(tester), isTrue, reason: 'focus stays in the text');
    });

    testWidgets('the keyboard-active row is a highlight, with no ring '
        '(K-54, K-82)', (tester) async {
      DsBoxDecoration activeRow() =>
          tester
                  .widget<AnimatedContainer>(
                    find
                        .ancestor(
                          of: find.text('İstanbul'),
                          matching: find.byType(AnimatedContainer),
                        )
                        .first,
                  )
                  .decoration!
              as DsBoxDecoration;
      for (final contrast in DsContrast.values) {
        final theme = DsThemeData(contrast: contrast);
        await tester.pumpWidget(app(single(), theme: theme));
        await tester.tap(editable());
        await tester.pumpAndSettle();
        await key(tester, LogicalKeyboardKey.arrowDown);
        final d = activeRow();
        expect(d.color, theme.colors.selection);
        final ring = d.shadows.map((s) => s.color).contains(theme.colors.focus);
        expect(ring, isFalse, reason: '$contrast');
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('leaving keeps an exact label, reverts anything else', (
      tester,
    ) async {
      String? chosen = 'x';
      await tester.pumpWidget(
        app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              single(initial: 'ank', onChanged: (v) => chosen = v),
              // Below the popup, which would take the tap.
              const SizedBox(height: 320),
              const DsTextField(semanticLabel: 'Sonraki'),
            ],
          ),
        ),
      );
      expect(text(tester), 'Ankara');
      await tester.tap(editable().first);
      await tester.enterText(editable().first, 'xyz');
      await tester.pumpAndSettle();
      expect(find.text('Sonuç yok'), findsOneWidget);
      await tester.tap(editable().last);
      await tester.pumpAndSettle();
      expect(text(tester), 'Ankara');
      expect(chosen, 'x', reason: 'not changed');

      await tester.tap(editable().first);
      await tester.enterText(editable().first, 'izmir');
      await tester.tap(editable().last);
      await tester.pumpAndSettle();
      expect(chosen, 'izm');
      expect(text(tester), 'İzmir');
    });

    testWidgets('free text goes to onCreate', (tester) async {
      String? custom;
      await tester.pumpWidget(app(single(onCreate: (v) => custom = v)));
      await tester.tap(editable());
      await tester.enterText(editable(), 'Ardahan');
      await tester.pumpAndSettle();
      await key(tester, LogicalKeyboardKey.enter);
      expect(custom, 'Ardahan');
    });

    testWidgets('the clear button clears the value and keeps focus', (
      tester,
    ) async {
      String? chosen = 'ank';
      await tester.pumpWidget(
        app(single(initial: 'ank', onChanged: (v) => chosen = v)),
      );
      await tester.tap(find.bySemanticsLabel('Temizle'));
      await tester.pumpAndSettle();
      expect(chosen, isNull);
      expect(text(tester), '');
      expect(textFocused(tester), isTrue);
    });

    testWidgets('async: loading, results, stale answers dropped, no results', (
      tester,
    ) async {
      final pending = <String, Completer<List<DsSelectOption<String>>>>{};
      await tester.pumpWidget(
        app(
          single(
            options: const [],
            optionsBuilder: (q) => (pending[q] = Completer()).future,
          ),
        ),
      );
      await tester.tap(editable());
      await tester.enterText(editable(), 'a');
      await tester.pump();
      await tester.enterText(editable(), 'an');
      await tester.pump();
      expect(find.byType(DsSpinner), findsOneWidget);
      expect(find.text('Yükleniyor'), findsOneWidget);
      pending['an']!.complete(const [
        DsSelectOption(value: 'ank', label: 'Ankara'),
      ]);
      await tester.pumpAndSettle();
      expect(listed(tester), ['Ankara']);
      // The older answer arrives late and is ignored.
      pending['a']!.complete(cities);
      await tester.pumpAndSettle();
      expect(listed(tester), ['Ankara']);
      await tester.enterText(editable(), 'anx');
      await tester.pump();
      pending['anx']!.complete(const []);
      await tester.pumpAndSettle();
      expect(find.text('Sonuç yok'), findsOneWidget);
    });

    testWidgets('announces the result count once typing pauses', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(app(single()));
      await tester.tap(editable());
      await tester.pumpAndSettle();
      tester.takeAnnouncements();
      await tester.enterText(editable(), 'i');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(editable(), 'is');
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeAnnouncements(), isEmpty, reason: 'debounced');
      await tester.pump(const Duration(seconds: 1));
      final said = tester.takeAnnouncements().map((a) => a.message).toList();
      expect(said, ['2 sonuç']);
      await tester.enterText(editable(), 'isx');
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeAnnouncements().map((a) => a.message), ['Sonuç yok']);
      semantics.dispose();
    });

    testWidgets('announces the active option as it moves', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(app(single(initial: 'ank')));
      await tester.tap(editable());
      await tester.pumpAndSettle();
      await key(tester, LogicalKeyboardKey.escape);
      tester.takeAnnouncements();
      await key(tester, LogicalKeyboardKey.arrowDown);
      expect(tester.takeAnnouncements().map((a) => a.message), [
        'Ankara, Seçili',
      ], reason: 'opens on the chosen option');
      await key(tester, LogicalKeyboardKey.arrowDown);
      expect(tester.takeAnnouncements().map((a) => a.message), ['Şırnak']);
      semantics.dispose();
    });

    testWidgets('semantics: expanded text field, menu of radio items', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(app(single(initial: 'ank')));
      var data = fieldData(tester);
      expect(data.flagsCollection.isExpanded, Tristate.isFalse);
      expect(data.flagsCollection.isTextField, isTrue);
      expect(data.label, contains('Şehir'));
      expect(data.value, 'Ankara');
      await tester.tap(editable());
      await tester.pumpAndSettle();
      expect(fieldData(tester).flagsCollection.isExpanded, Tristate.isTrue);
      // The field controls the popup (aria-controls on the web).
      final controls = fieldData(tester).controlsNodes;
      expect(controls, hasLength(1));
      expect(
        find.semantics.byPredicate((n) => n.identifier == controls!.single),
        findsOne,
      );
      final item = tester.getSemantics(find.text('Ankara').last);
      data = item.getSemanticsData();
      expect(data.role, SemanticsRole.menuItemRadio);
      expect(data.flagsCollection.isChecked, CheckedState.isTrue);
      expect(data.label, 'Ankara');
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      SemanticsNode? menu = item.parent;
      while (menu != null &&
          menu.getSemanticsData().role != SemanticsRole.menu) {
        menu = menu.parent;
      }
      expect(menu, isNotNull);
      expect(menu!.label, 'Şehir');
      semantics.dispose();
    });

    testWidgets('DsField: label, required and error', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          DsField(
            label: const Text('Şehir'),
            required: true,
            errorText: 'Bir şehir seçin.',
            child: DsAutocomplete<String>(
              value: null,
              onChanged: (_) {},
              options: cities,
            ),
          ),
        ),
      );
      final data = fieldData(tester);
      expect(data.label, contains('Şehir'));
      expect(data.flagsCollection.isRequired, Tristate.isTrue);
      expect(data.validationResult, SemanticsValidationResult.invalid);
      expect(icon(DsIcons.circleAlert), findsWidgets);
      semantics.dispose();
    });

    testWidgets('disabled: no popup, no clear', (tester) async {
      await tester.pumpWidget(app(single(initial: 'ank', enabled: false)));
      await tester.tap(
        find.byType(DsAutocomplete<String>),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsNothing);
      expect(find.bySemanticsLabel('Temizle'), findsNothing);
    });

    testWidgets('RTL: the popup lines up and the chevron sits at the start', (
      tester,
    ) async {
      await tester.pumpWidget(app(single(), direction: TextDirection.rtl));
      await tester.tap(editable());
      await tester.pumpAndSettle();
      final field = tester.getRect(find.byType(DsAutocomplete<String>));
      final popup = tester.getRect(
        find.ancestor(
          of: find.byType(ListView),
          matching: find.byType(DsSurface),
        ),
      );
      expect(popup.left, moreOrLessEquals(field.left, epsilon: .5));
      expect(popup.width, moreOrLessEquals(field.width, epsilon: .5));
      final chevron = tester.getCenter(icon(DsIcons.chevronDown));
      expect(chevron.dx, lessThan(field.center.dx));
    });

    testWidgets('text scale 2.0 at 358px: no overflow', (tester) async {
      tester.view.physicalSize = const Size(358, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(
          DsField(label: const Text('Şehir'), child: single()),
          textScale: 2,
          width: 326,
        ),
      );
      await tester.tap(editable());
      await tester.enterText(editable(), 'i');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(listed(tester), isNotEmpty);
    });

    testWidgets('R3: works with only an Overlay (K-52)', (tester) async {
      String? chosen;
      await tester.pumpWidget(
        host(
          Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (_) => Center(
                  child: SizedBox(
                    width: 300,
                    child: single(onChanged: (v) => chosen = v),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.tap(editable());
      await tester.pumpAndSettle();
      await tester.enterText(editable(), 'ank');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ankara').last);
      await tester.pumpAndSettle();
      expect(chosen, 'ank');
      // The keys work too: arrows move the option, not the caret.
      await tester.enterText(editable(), 'ir');
      await tester.pumpAndSettle();
      expect(listed(tester), ['İzmir', 'Şırnak', 'Eskişehir']);
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.enter);
      expect(chosen, 'sir');
    });

    testWidgets('focus returns to the text after choosing with the mouse', (
      tester,
    ) async {
      await tester.pumpWidget(app(single()));
      await tester.tap(icon(DsIcons.chevronDown));
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsOneWidget);
      expect(
        textFocused(tester),
        isTrue,
        reason: 'the chevron focuses the text',
      );
      await tester.tap(find.text('İzmir'));
      await tester.pumpAndSettle();
      expect(textFocused(tester), isTrue);
    });

    testWidgets('a theme switch while open reaches the popup', (tester) async {
      var mode = DsThemeMode.light;
      late StateSetter set;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return DsApp(
              theme: DsThemeData(),
              darkTheme: DsThemeData(brightness: Brightness.dark),
              locale: const Locale('tr'),
              themeMode: mode,
              home: Center(child: SizedBox(width: 300, child: single())),
            );
          },
        ),
      );
      await tester.tap(editable());
      await tester.pumpAndSettle();
      Color panel() =>
          (tester
                      .widget<DecoratedBox>(
                        find
                            .ancestor(
                              of: find.byType(ListView),
                              matching: find.byType(DecoratedBox),
                            )
                            .last,
                      )
                      .decoration
                  as DsBoxDecoration)
              .color!;
      final light = panel();
      set(() => mode = DsThemeMode.dark);
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsOneWidget, reason: 'stays open');
      expect(panel(), isNot(light));
      expect(panel(), DsThemeData(brightness: Brightness.dark).colors.overlay);
    });
  });

  group('empty and loading text, free text (onCreate)', () {
    testWidgets('emptyText and loadingText replace the defaults', (
      tester,
    ) async {
      final pending = Completer<List<DsSelectOption<String>>>();
      for (final many in [false, true]) {
        await tester.pumpWidget(
          app(
            many
                ? DsMultiSelect<String>(
                    value: const [],
                    onChanged: (_) {},
                    options: cities,
                    semanticLabel: 'Şehirler',
                    emptyText: 'Bu adla şehir yok',
                  )
                : DsAutocomplete<String>(
                    value: null,
                    onChanged: (_) {},
                    options: const [],
                    optionsBuilder: (_) => pending.future,
                    semanticLabel: 'Şehir',
                    emptyText: 'Bu adla şehir yok',
                    loadingText: 'Şehirler aranıyor',
                  ),
          ),
        );
        await tester.tap(editable());
        await tester.enterText(editable(), 'xyz');
        await tester.pump();
        if (!many) {
          expect(find.text('Şehirler aranıyor'), findsOneWidget);
          expect(find.text('Yükleniyor'), findsNothing);
          pending.complete(const []);
          await tester.pumpAndSettle();
        } else {
          await tester.pumpAndSettle();
        }
        expect(find.text('Bu adla şehir yok'), findsOneWidget);
        expect(find.text('Sonuç yok'), findsNothing);
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('with onCreate, an empty list offers the typed text; Enter '
        'or a click takes it', (tester) async {
      final semantics = tester.ensureSemantics();
      String? custom;
      await tester.pumpWidget(app(single(onCreate: (v) => custom = v)));
      await tester.tap(editable());
      await tester.enterText(editable(), 'Ardahan ');
      await tester.pumpAndSettle();
      expect(find.text('Sonuç yok'), findsNothing);
      final row = find.text('“Ardahan” kullan');
      expect(row, findsOneWidget);
      expect(
        tester.getSemantics(row),
        isSemantics(label: '“Ardahan” kullan', hasTapAction: true),
      );
      await key(tester, LogicalKeyboardKey.enter);
      expect(custom, 'Ardahan');

      custom = null;
      await tester.enterText(editable(), 'Kars2');
      await tester.pumpAndSettle();
      await tester.tap(find.text('“Kars2” kullan'));
      await tester.pumpAndSettle();
      expect(custom, 'Kars2');
      expect(find.byType(ListView), findsNothing, reason: 'closed');
      semantics.dispose();
    });

    testWidgets('multi-select: the offered text is added and the text '
        'empties', (tester) async {
      final added = <String>[];
      await tester.pumpWidget(
        app(
          DsMultiSelect<String>(
            value: const [],
            onChanged: (_) {},
            options: cities,
            semanticLabel: 'Şehirler',
            onCreate: added.add,
          ),
        ),
      );
      await tester.tap(editable());
      await tester.enterText(editable(), 'Ardahan');
      await tester.pumpAndSettle();
      expect(find.text('“Ardahan” kullan'), findsOneWidget);
      await key(tester, LogicalKeyboardKey.enter);
      expect(added, ['Ardahan']);
      expect(text(tester), '');
    });

    testWidgets('English: "Use “Ankara”"', (tester) async {
      await tester.pumpWidget(
        DsApp(
          locale: const Locale('en'),
          home: Center(
            child: SizedBox(
              width: 300,
              child: DsAutocomplete<String>(
                value: null,
                onChanged: (_) {},
                options: const [],
                onCreate: (_) {},
                semanticLabel: 'City',
              ),
            ),
          ),
        ),
      );
      await tester.tap(editable());
      await tester.enterText(editable(), 'Ankara');
      await tester.pumpAndSettle();
      expect(find.text('Use “Ankara”'), findsOneWidget);
      expect(find.text('No results'), findsNothing);
    });
  });

  testWidgets('the popup takes the menu style\'s backdropFilter (K-154)', (
    tester,
  ) async {
    final blur = ImageFilter.blur(sigmaX: 20, sigmaY: 20);
    const fill = Color(0xB8FFFFFF);
    for (final field in [single(), multi()]) {
      await tester.pumpWidget(
        app(
          DsMenuTheme(
            data: DsMenuThemeData(
              style: DsMenuStyle(background: fill, backdropFilter: blur),
            ),
            child: field,
          ),
        ),
      );
      await tester.tap(editable());
      await tester.pumpAndSettle();
      final filter = find.ancestor(
        of: find.byType(ListView),
        matching: find.byType(BackdropFilter),
      );
      expect(filter, findsOneWidget);
      expect(tester.widget<BackdropFilter>(filter).filter, blur);
      final fills = tester
          .widgetList<DecoratedBox>(
            find.descendant(of: filter, matching: find.byType(DecoratedBox)),
          )
          .map((d) => d.decoration)
          .whereType<DsBoxDecoration>()
          .map((d) => d.color);
      expect(fills, contains(fill));
      await tester.pumpWidget(const SizedBox());
    }
  });

  group('DsMultiSelect', () {
    testWidgets('adds with Enter, keeps open, shows a check', (tester) async {
      List<String> values = const [];
      await tester.pumpWidget(app(multi(onChanged: (v) => values = v)));
      await tester.tap(editable());
      await tester.enterText(editable(), 'iz');
      await tester.pumpAndSettle();
      await key(tester, LogicalKeyboardKey.enter);
      expect(values, ['izm']);
      expect(text(tester), '', reason: 'the text empties');
      expect(find.byType(ListView), findsOneWidget, reason: 'stays open');
      expect(listed(tester), hasLength(cities.length));
      expect(icon(DsIcons.check), findsOneWidget);
      // A tag inside the field, with a named remove button.
      expect(find.bySemanticsLabel('Kaldır: İzmir'), findsOneWidget);
      // Enter again on the same (active) option removes it.
      await key(tester, LogicalKeyboardKey.enter);
      expect(values, isEmpty);
    });

    testWidgets('a click adds; the remove button and Backspace remove', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      List<String> values = const [];
      await tester.pumpWidget(app(multi(onChanged: (v) => values = v)));
      await tester.tap(editable());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ankara'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Isparta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Şırnak'));
      await tester.pumpAndSettle();
      expect(values, ['ank', 'isp', 'sir']);
      final menuItem = tester.getSemantics(find.text('Ankara').last);
      expect(menuItem.getSemanticsData().role, SemanticsRole.menuItemCheckbox);
      expect(
        menuItem.getSemanticsData().flagsCollection.isChecked,
        CheckedState.isTrue,
      );

      await key(tester, LogicalKeyboardKey.escape);
      await tester.tap(find.bySemanticsLabel('Kaldır: Isparta'));
      await tester.pumpAndSettle();
      expect(values, ['ank', 'sir']);
      expect(textFocused(tester), isTrue);
      tester.takeAnnouncements();
      await key(tester, LogicalKeyboardKey.backspace);
      expect(values, ['ank']);
      expect(tester.takeAnnouncements().map((a) => a.message), [
        'Şırnak kaldırıldı',
      ]);
      semantics.dispose();
    });

    /// The fill of the tag labelled [label].
    DsBoxDecoration tagOf(WidgetTester tester, String label) =>
        tester
                .widget<Container>(
                  find
                      .ancestor(
                        of: find.text(label),
                        matching: find.byType(Container),
                      )
                      .first,
                )
                .decoration!
            as DsBoxDecoration;

    testWidgets('tags are small neutral chips in the text color', (
      tester,
    ) async {
      final k = DsThemeData().colors;
      await tester.pumpWidget(app(multi(initial: ['ank'])));
      await tester.pumpAndSettle();
      expect(tagOf(tester, 'Ankara').color, k.neutral.tint);
      expect(tester.widget<Text>(find.text('Ankara')).style!.color, k.text);
      final tag = tester.getRect(
        find
            .ancestor(of: find.text('Ankara'), matching: find.byType(Container))
            .first,
      );
      final field = tester.getRect(find.byType(DsMultiSelect<String>));
      expect(tag.height, 22, reason: 'a little over half the 40 field');
      expect(field.height, 40, reason: 'one line of tags keeps the height');
      // Even air above and below.
      expect(tag.top - field.top, closeTo(field.bottom - tag.bottom, .5));
    });

    testWidgets('disabled tags keep their filled shape', (tester) async {
      final k = DsThemeData().colors;
      await tester.pumpWidget(
        app(
          const DsMultiSelect<String>(
            value: ['ank'],
            onChanged: null,
            options: cities,
            semanticLabel: 'Şehirler',
          ),
        ),
      );
      expect(tagOf(tester, 'Ankara').color, k.channelStrong);
      expect(tagOf(tester, 'Ankara').shadows, isEmpty, reason: 'no outline');
      expect(
        tester.widget<Text>(find.text('Ankara')).style!.color,
        k.onDisabled,
      );
    });

    testWidgets('arrows make a tag active; Backspace and Delete remove it', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final k = DsThemeData().colors;
      List<String> values = const ['ist', 'izm', 'ank'];
      await tester.pumpWidget(
        app(multi(initial: values, onChanged: (v) => values = v)),
      );
      await tester.showKeyboard(editable());
      await tester.pumpAndSettle();
      Color fill(String label) => tagOf(tester, label).color!;
      tester.takeAnnouncements();

      // From the start of the text: the last tag, in the accent.
      await key(tester, LogicalKeyboardKey.arrowLeft);
      expect(fill('Ankara'), k.selectionStrong);
      expect(fill('İzmir'), k.neutral.tint);
      expect(tester.takeAnnouncements().map((a) => a.message), ['Ankara']);
      expect(find.byType(ListView), findsNothing, reason: 'stays closed');
      await key(tester, LogicalKeyboardKey.arrowLeft);
      expect(fill('İzmir'), k.selectionStrong);
      expect(fill('Ankara'), k.neutral.tint);
      // Right walks forward and past the last tag back to the text.
      await key(tester, LogicalKeyboardKey.arrowRight);
      await key(tester, LogicalKeyboardKey.arrowRight);
      for (final label in ['İstanbul', 'İzmir', 'Ankara']) {
        expect(fill(label), k.neutral.tint);
      }
      expect(textFocused(tester), isTrue, reason: 'focus never left');

      // Backspace removes the active tag; the one before takes over.
      await key(tester, LogicalKeyboardKey.arrowLeft);
      await key(tester, LogicalKeyboardKey.arrowLeft);
      tester.takeAnnouncements();
      await key(tester, LogicalKeyboardKey.backspace);
      expect(values, ['ist', 'ank']);
      expect(
        tester.takeAnnouncements().map((a) => a.message),
        contains('İzmir kaldırıldı'),
      );
      expect(fill('İstanbul'), k.selectionStrong);
      // Delete removes it; the one that slides in takes over.
      await key(tester, LogicalKeyboardKey.delete);
      expect(values, ['ank']);
      expect(fill('Ankara'), k.selectionStrong);
      // Typing leaves the tags.
      await tester.enterText(editable(), 'a');
      await tester.pumpAndSettle();
      await key(tester, LogicalKeyboardKey.escape);
      expect(fill('Ankara'), k.neutral.tint);
      expect(values, ['ank']);
      semantics.dispose();
    });

    testWidgets('right to left: Right reaches the tags', (tester) async {
      final k = DsThemeData().colors;
      await tester.pumpWidget(
        app(multi(initial: ['ist', 'ank']), direction: TextDirection.rtl),
      );
      await tester.showKeyboard(editable());
      await tester.pumpAndSettle();
      await key(tester, LogicalKeyboardKey.arrowLeft);
      expect(tagOf(tester, 'Ankara').color, k.neutral.tint);
      await key(tester, LogicalKeyboardKey.arrowRight);
      expect(tagOf(tester, 'Ankara').color, k.selectionStrong);
    });

    testWidgets('empty text follows the last tag; typed text wraps', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          StatefulBuilder(
            builder: (context, setState) => DsMultiSelect<String>(
              value: const ['ank'],
              onChanged: (_) {},
              options: cities,
              semanticLabel: 'Şehirler',
              // More room than is left after the tag.
              style: const DsAutocompleteStyle(inputMinWidth: 200),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final tag = tester.getRect(find.text('Ankara'));
      final height = tester.getSize(find.byType(DsMultiSelect<String>)).height;
      Rect input() => tester.getRect(editable());
      // No empty line below the tags.
      expect(input().center.dy, closeTo(tag.center.dy, 2));
      expect(input().left, greaterThan(tag.right));
      expect(height, 40);

      await tester.showKeyboard(editable());
      await tester.enterText(editable(), 'iz');
      await tester.pumpAndSettle();
      expect(input().top, greaterThan(tag.bottom), reason: 'a line below');
      expect(
        tester.getSize(find.byType(DsMultiSelect<String>)).height,
        greaterThan(height),
      );

      await tester.enterText(editable(), '');
      await tester.pumpAndSettle();
      expect(input().center.dy, closeTo(tag.center.dy, 2), reason: 'back');
    });
    testWidgets('wrapping tags grow the field', (tester) async {
      await tester.pumpWidget(app(multi(), width: 240));
      final one = tester.getSize(find.byType(DsMultiSelect<String>)).height;
      await tester.pumpWidget(
        app(multi(initial: ['ist', 'izm', 'isp', 'ank', 'sir']), width: 240),
      );
      await tester.pumpAndSettle();
      final more = tester.getSize(find.byType(DsMultiSelect<String>)).height;
      expect(more, greaterThan(one + 20));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the clear button removes every value', (tester) async {
      List<String> values = const ['ank'];
      await tester.pumpWidget(
        app(multi(initial: values, onChanged: (v) => values = v)),
      );
      await tester.tap(find.bySemanticsLabel('Temizle'));
      await tester.pumpAndSettle();
      expect(values, isEmpty);
    });

    testWidgets('RTL and text scale 2.0 at 358px', (tester) async {
      tester.view.physicalSize = const Size(358, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(
          multi(initial: ['ist', 'esk', 'sir']),
          direction: TextDirection.rtl,
          textScale: 2,
          width: 326,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final field = tester.getRect(find.byType(DsMultiSelect<String>));
      final first = tester.getRect(find.text('İstanbul'));
      expect(
        first.right,
        greaterThan(field.center.dx),
        reason: 'tags start at the right',
      );
    });
  });

  group('collapsed tags (S-40)', () {
    const all = ['ist', 'izm', 'isp', 'ank', 'sir', 'esk'];
    final labels = [
      for (final v in all) cities.firstWhere((o) => o.value == v).label,
    ];

    Widget collapsed({
      List<String> initial = all,
      bool enabled = true,
      bool readOnly = false,
      ValueChanged<List<String>>? onChanged,
    }) {
      var values = initial;
      return StatefulBuilder(
        builder: (context, setState) => DsMultiSelect<String>(
          value: values,
          onChanged: enabled
              ? (v) {
                  setState(() => values = v);
                  onChanged?.call(v);
                }
              : null,
          readOnly: readOnly,
          options: cities,
          semanticLabel: 'Şehirler',
          collapseTags: true,
        ),
      );
    }

    /// The box of the tag (or "+N") whose text is [text].
    Rect tagRect(WidgetTester tester, String text) => tester.getRect(
      find
          .ancestor(of: find.text(text), matching: find.byType(Container))
          .first,
    );
    bool shows(WidgetTester tester, String text) =>
        find.text(text).hitTestable().evaluate().isNotEmpty;
    List<String> shownTags(WidgetTester tester) => [
      for (final l in labels)
        if (shows(tester, l)) l,
    ];

    /// The "+N" that shows, or null.
    String? shownMore(WidgetTester tester) {
      for (var n = 0; n <= labels.length; n++) {
        if (shows(tester, '+$n')) return '+$n';
      }
      return null;
    }

    testWidgets('one line; the "+N" counts exactly the tags that do not fit', (
      tester,
    ) async {
      final t = DsThemeData(density: DsDensity.compact);
      final a = DsAutocomplete.defaultStyle(t);
      final gap = a.tagGap!;
      final caret = DsTextField.defaultStyle(t).caretWidth! + 1;
      final reserve = gap + a.inputGap! + caret;
      final counts = <int>{};
      for (var width = 150.0; width <= 760; width += 9) {
        await tester.pumpWidget(app(collapsed(), width: width, theme: t));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final shown = shownTags(tester);
        final more = shownMore(tester);
        final n = labels.length;
        final k = shown.length;
        counts.add(n - k);
        // The first k tags in order, never "+0", and the count is right
        // (only the narrowest field shows the count alone).
        expect(shown, labels.take(k), reason: 'at $width');
        expect(more, k < n ? '+${n - k}' : null, reason: 'at $width');
        if (k == 0) {
          expect(width, lessThan(200), reason: 'a tag fits at $width');
          continue;
        }
        // One line, as tall as the field without tags.
        expect(
          tester.getSize(find.byType(DsMultiSelect<String>)).height,
          40,
          reason: 'at $width',
        );
        final flow = tester.getRect(find.byType(TagFlow));
        final input = tester.getRect(editable());
        expect(input.width, greaterThanOrEqualTo(caret - .01));
        expect(input.right, lessThanOrEqualTo(flow.right + .01));
        if (k < n) {
          final chip = tagRect(tester, more!);
          final last = tagRect(tester, shown.last);
          expect(chip.left, closeTo(last.right + gap, .01));
          expect(chip.center.dy, closeTo(last.center.dy, .01));
          // The next tag would not have fit: beside the next "+N" (as
          // wide here), or, for the last tag, without one ("+1", not a
          // clipped tag).
          final next = tagRect(tester, labels[k]).width;
          final need = k + 1 < n
              ? chip.left + next + gap + chip.width + reserve
              : chip.left + next + reserve;
          expect(need, greaterThan(flow.right), reason: 'at $width');
        }
      }
      expect(
        counts,
        containsAll([0, 1, 2, 3]),
        reason: 'several counts, "+1" and every tag among them',
      );
    });

    testWidgets('focus shows every tag for the arrow keys; leaving collapses', (
      tester,
    ) async {
      final k = DsThemeData().colors;
      await tester.pumpWidget(app(collapsed(), width: 260));
      await tester.pumpAndSettle();
      final height = tester.getSize(find.byType(DsMultiSelect<String>)).height;
      expect(shownMore(tester), isNotNull);
      expect(shows(tester, 'Eskişehir'), isFalse);

      await tester.showKeyboard(editable());
      await tester.pumpAndSettle();
      expect(shownTags(tester), labels);
      expect(shownMore(tester), isNull);
      expect(find.textContaining('+'), findsNothing, reason: 'not built');
      expect(
        tester.getSize(find.byType(DsMultiSelect<String>)).height,
        greaterThan(height),
        reason: 'the tags wrap',
      );
      // The arrow keys reach the tag that was hidden.
      await key(tester, LogicalKeyboardKey.arrowLeft);
      expect(
        (tester
                    .widget<Container>(
                      find
                          .ancestor(
                            of: find.text('Eskişehir'),
                            matching: find.byType(Container),
                          )
                          .first,
                    )
                    .decoration!
                as DsBoxDecoration)
            .color,
        k.selectionStrong,
      );
      expect(textFocused(tester), isTrue);

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(shownMore(tester), isNotNull);
      expect(tester.getSize(find.byType(DsMultiSelect<String>)).height, height);
    });

    testWidgets('a tap on the "+N" focuses the field and opens it', (
      tester,
    ) async {
      await tester.pumpWidget(app(collapsed(), width: 260));
      await tester.pumpAndSettle();
      await tester.tap(find.text(shownMore(tester)!).hitTestable());
      await tester.pumpAndSettle();
      expect(textFocused(tester), isTrue);
      expect(shownTags(tester), labels);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('semantics: "N more" with the hidden labels; no stop', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(app(collapsed(), width: 260));
      await tester.pumpAndSettle();
      final more = shownMore(tester)!;
      final hidden = int.parse(more.substring(1));
      final node = tester.getSemantics(
        find.bySemanticsLabel('$hidden tane daha'),
      );
      final data = node.getSemanticsData();
      expect(data.value, labels.skip(labels.length - hidden).join(', '));
      expect(data.flagsCollection.isFocused, Tristate.none);
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(data.hasAction(SemanticsAction.focus), isFalse);
      // One "+N" node; the hidden tags and their buttons are not nodes.
      expect(find.bySemanticsLabel(RegExp('tane daha')), findsOneWidget);
      expect(find.bySemanticsLabel('Kaldır: Eskişehir'), findsNothing);
      expect(find.bySemanticsLabel('Kaldır: İstanbul'), findsOneWidget);

      await tester.showKeyboard(editable());
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('tane daha')), findsNothing);
      expect(find.bySemanticsLabel('Kaldır: Eskişehir'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('English: "3 more"', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        DsApp(
          locale: const Locale('en'),
          home: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: 260, child: collapsed()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final hidden = int.parse(shownMore(tester)!.substring(1));
      expect(find.bySemanticsLabel('$hidden more'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a disabled field stays collapsed; read-only shows all on '
        'focus', (tester) async {
      await tester.pumpWidget(app(collapsed(enabled: false), width: 260));
      await tester.pumpAndSettle();
      final disabledMore = shownMore(tester);
      expect(disabledMore, isNotNull);
      await tester.tap(find.byType(DsMultiSelect<String>));
      await tester.pumpAndSettle();
      expect(shownMore(tester), disabledMore, reason: 'never takes focus');

      await tester.pumpWidget(app(collapsed(readOnly: true), width: 260));
      await tester.pumpAndSettle();
      expect(shownMore(tester), isNotNull);
      // No remove buttons: more tags fit than in an editable field.
      final readOnlyShown = shownTags(tester).length;
      await tester.pumpWidget(app(collapsed(), width: 260));
      await tester.pumpAndSettle();
      expect(readOnlyShown, greaterThanOrEqualTo(shownTags(tester).length));

      await tester.pumpWidget(app(collapsed(readOnly: true), width: 260));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DsMultiSelect<String>));
      await tester.pumpAndSettle();
      expect(textFocused(tester), isTrue);
      expect(shownTags(tester), labels);
      expect(find.byType(ListView), findsNothing, reason: 'does not open');
    });

    testWidgets('one tag never gets a "+N"; a first tag too long shrinks', (
      tester,
    ) async {
      const long = [
        DsSelectOption(value: 'a', label: 'Kahramanmaraş Büyükşehir'),
        DsSelectOption(value: 'b', label: 'Afyonkarahisar'),
        DsSelectOption(value: 'c', label: 'Ankara'),
      ];
      Widget field(List<String> values) => DsMultiSelect<String>(
        value: values,
        onChanged: (_) {},
        options: long,
        semanticLabel: 'Şehirler',
        collapseTags: true,
      );
      final compact = DsThemeData(density: DsDensity.compact);
      await tester.pumpWidget(
        app(field(const ['a']), width: 200, theme: compact),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(shows(tester, 'Kahramanmaraş Büyükşehir'), isTrue);
      expect(find.textContaining('+').hitTestable(), findsNothing);
      expect(tester.getSize(find.byType(DsMultiSelect<String>)).height, 40);

      await tester.pumpWidget(
        app(field(const ['a', 'b', 'c']), width: 200, theme: compact),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(shows(tester, 'Kahramanmaraş Büyükşehir'), isTrue);
      expect(shows(tester, '+2'), isTrue);
      final flow = tester.getRect(find.byType(TagFlow));
      expect(tagRect(tester, '+2').right, lessThan(flow.right));
    });

    testWidgets('right to left: mirrored', (tester) async {
      await tester.pumpWidget(
        app(collapsed(), width: 260, direction: TextDirection.rtl),
      );
      await tester.pumpAndSettle();
      final flow = tester.getRect(find.byType(TagFlow));
      final shown = shownTags(tester);
      final more = shownMore(tester)!;
      expect(shown, labels.take(shown.length));
      expect(tagRect(tester, shown.first).right, closeTo(flow.right, .01));
      for (var i = 1; i < shown.length; i++) {
        expect(
          tagRect(tester, shown[i]).right,
          lessThan(tagRect(tester, shown[i - 1]).left),
        );
      }
      expect(
        tagRect(tester, more).right,
        lessThan(tagRect(tester, shown.last).left),
      );
      expect(
        tester.getRect(editable()).right,
        lessThan(tagRect(tester, more).left),
      );
    });

    testWidgets('text scale 2.0 at 358px: one line, no overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(358, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final direction in TextDirection.values) {
        await tester.pumpWidget(
          app(collapsed(), textScale: 2, width: 326, direction: direction),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final shown = shownTags(tester);
        final more = shownMore(tester);
        expect(shown, isNotEmpty);
        expect(more, '+${labels.length - shown.length}');
        final line = tagRect(tester, shown.first).center.dy;
        for (final l in [...shown, more!]) {
          expect(tagRect(tester, l).center.dy, closeTo(line, .01));
        }
        final flow = tester.getRect(find.byType(TagFlow));
        expect(tagRect(tester, more).left, greaterThanOrEqualTo(flow.left));
        expect(tagRect(tester, more).right, lessThanOrEqualTo(flow.right));
      }
    });

    testWidgets('the form field passes it on', (tester) async {
      await tester.pumpWidget(
        app(
          DsMultiSelectFormField<String>(
            options: cities,
            initialValue: all,
            collapseTags: true,
          ),
          width: 260,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DsMultiSelect<String>>(find.byType(DsMultiSelect<String>))
            .collapseTags,
        isTrue,
      );
      expect(shownMore(tester), isNotNull);
    });
  });

  group('contrast', () {
    const seeds = [
      DsSeed.blue,
      DsSeed.navy,
      DsSeed.graphite,
      DsSeed.oxblood,
      DsSeed.forest,
      DsSeed.indigo,
    ];
    test('checks read in every preset, mode and contrast', () {
      final failures = <String>[];
      for (final seed in seeds) {
        for (final brightness in Brightness.values) {
          for (final contrast in DsContrast.values) {
            final k = DsThemeData(
              seed: seed,
              brightness: brightness,
              contrast: contrast,
            ).colors;
            void at(String what, Color fg, Color bg, double min) {
              final ratio = DsColorUtils.contrastRatio(fg, bg);
              if (ratio < min) {
                failures.add(
                  '$seed ${brightness.name} ${contrast.name} $what: '
                  '${ratio.toStringAsFixed(2)} < $min',
                );
              }
            }

            // The tags: test/theme/tag_contrast_test.dart.
            // The check of a chosen option, on the popup and on the
            // active row's highlight (icon, 3:1).
            at('check', k.accentText, k.overlay, 3);
            at('check on highlight', k.accentText, k.selection, 3);
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  });
}

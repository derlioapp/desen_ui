import 'dart:ui' show SemanticsValidationResult, Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// DsTextField part 2 (KALITE Faz 7a): slots, the clear and show-password
/// buttons, the counter, the multi-line form, DsSearchField and the link
/// to DsField.
void main() {
  Widget app(
    Widget child, {
    DsThemeData? theme,
    TextDirection direction = TextDirection.ltr,
    double width = 320,
    MediaQueryData Function(MediaQueryData)? media,
  }) => DsApp(
    theme: theme ?? DsThemeData(),
    themeMode: DsThemeMode.light,
    builder: (context, child) => Directionality(
      textDirection: direction,
      child: media == null
          ? child!
          : MediaQuery(data: media(MediaQuery.of(context)), child: child!),
    ),
    home: Center(
      child: SizedBox(width: width, child: child),
    ),
  );

  Finder editableFinder() => find.byType(EditableText);

  EditableTextState editable(WidgetTester tester) =>
      tester.state<EditableTextState>(editableFinder());

  Finder button(String label) =>
      find.byWidgetPredicate((w) => w is DsButton && w.semanticLabel == label);

  DsBoxDecoration decoration(WidgetTester tester) =>
      tester
              .widget<AnimatedContainer>(
                find
                    .descendant(
                      of: find.byWidgetPredicate(
                        (w) => w is DsTextField || w is DsSearchField,
                      ),
                      matching: find.byType(AnimatedContainer),
                    )
                    .first,
              )
              .decoration!
          as DsBoxDecoration;

  /// Captures polite announcements.
  List<String> announcements(WidgetTester tester) {
    final said = <String>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (message) async {
        final data = (message! as Map)['data'] as Map;
        if (data['message'] case final String text) said.add(text);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
            SystemChannels.accessibility,
            null,
          ),
    );
    return said;
  }

  group('slots', () {
    testWidgets('leading and trailing take the style\'s icon color and size', (
      tester,
    ) async {
      final theme = DsThemeData();
      await tester.pumpWidget(
        app(
          const DsTextField(
            leading: DsIcon(DsIcons.mail),
            trailing: Text('kg'),
          ),
          theme: theme,
        ),
      );
      final icon = tester.renderObject<RenderBox>(find.byType(DsIcon));
      expect(icon.size, const Size.square(16));
      final theming = tester.widget<IconTheme>(
        find
            .ancestor(of: find.byType(DsIcon), matching: find.byType(IconTheme))
            .first,
      );
      expect(theming.data.color, theme.colors.textMuted);
      final unit = tester.widget<RichText>(
        find.descendant(of: find.text('kg'), matching: find.byType(RichText)),
      );
      expect(unit.text.style!.color, theme.colors.textSubtle);
      // Leading, text, trailing in reading order.
      expect(
        tester.getCenter(find.byType(DsIcon)).dx,
        lessThan(tester.getCenter(editableFinder()).dx),
      );
      expect(
        tester.getCenter(find.text('kg')).dx,
        greaterThan(tester.getCenter(editableFinder()).dx),
      );
    });

    testWidgets('a focused field paints its leading icon in focus', (
      tester,
    ) async {
      final theme = DsThemeData();
      await tester.pumpWidget(
        app(const DsTextField(leading: DsIcon(DsIcons.mail)), theme: theme),
      );
      await tester.tap(editableFinder());
      await tester.pump();
      final theming = tester.widget<IconTheme>(
        find
            .ancestor(of: find.byType(DsIcon), matching: find.byType(IconTheme))
            .first,
      );
      expect(theming.data.color, theme.colors.focus);
    });

    testWidgets('the error icon comes last, after the buttons', (tester) async {
      await tester.pumpWidget(
        app(
          const DsTextField(
            initialValue: 'secret',
            obscureText: true,
            revealable: true,
            clearable: true,
            error: true,
          ),
        ),
      );
      final error = find.byWidgetPredicate(
        (w) => w is DsIcon && w.icon == DsIcons.circleAlert,
      );
      final xs = [
        tester.getCenter(button('Clear')).dx,
        tester.getCenter(button('Show password')).dx,
        tester.getCenter(error).dx,
      ];
      expect(xs, orderedEquals([...xs]..sort()));
    });

    testWidgets('text affixes sit close to the value; trailing text '
        'follows it; icons keep the wider gap', (tester) async {
      final style = DsTextField.defaultStyle(DsThemeData());
      for (final rtl in [false, true]) {
        await tester.pumpWidget(
          app(
            const DsTextField(
              initialValue: 'derlio',
              leading: Text('https://'),
              trailing: Text('.desen.app'),
            ),
            width: 400,
            direction: rtl ? TextDirection.rtl : TextDirection.ltr,
          ),
        );
        final text = paintedText(tester);
        final before = tester.getRect(find.text('https://'));
        final after = tester.getRect(find.text('.desen.app'));
        final box = tester.getRect(find.byType(DsTextField));
        if (!rtl) {
          expect(text.left - before.right, moreOrLessEquals(style.affixGap!));
          expect(after.left - text.right, moreOrLessEquals(style.affixGap!));
          expect(
            after.right,
            lessThan(box.center.dx),
            reason: 'not at the end',
          );
        } else {
          expect(before.left - text.right, moreOrLessEquals(style.affixGap!));
          expect(text.left - after.right, moreOrLessEquals(style.affixGap!));
          expect(after.left, greaterThan(box.center.dx));
        }
      }
      expect(style.affixGap, lessThan(style.gap!));

      // Typing moves the unit along.
      final controller = TextEditingController(text: '7');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(DsTextField(controller: controller, trailing: const Text('kg'))),
      );
      final x1 = tester.getRect(find.text('kg')).left;
      controller.text = '72000';
      await tester.pump();
      expect(tester.getRect(find.text('kg')).left, greaterThan(x1));

      // An icon keeps the icon gap and the trailing end.
      await tester.pumpWidget(
        app(
          const DsTextField(
            initialValue: 'a',
            leading: DsIcon(DsIcons.mail),
            trailing: DsIcon(DsIcons.search),
          ),
        ),
      );
      final icons = find.byType(DsIcon);
      expect(
        tester.getRect(editableFinder()).left -
            tester.getRect(icons.first).right,
        style.gap,
      );
      expect(
        tester.getRect(icons.last).right,
        moreOrLessEquals(
          tester.getRect(find.byType(DsTextField)).right - 12,
          epsilon: 1,
        ),
      );
    });

    testWidgets('trailing text follows the placeholder while empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const DsTextField(placeholder: '0,00', trailing: Text('TL'))),
      );
      final placeholder = tester.getRect(find.text('0,00'));
      final unit = tester.getRect(find.text('TL'));
      // As close as it sits to a value.
      expect(
        unit.left - placeholder.right,
        moreOrLessEquals(DsTextField.defaultStyle(DsThemeData()).affixGap!),
      );
    });

    testWidgets('a number field\'s unit follows the number', (tester) async {
      await tester.pumpWidget(
        app(
          DsNumberField(value: 72, onChanged: (_) {}, unit: 'kg'),
          width: 400,
        ),
      );
      final text = paintedText(tester);
      final unit = tester.getRect(find.text('kg'));
      expect(unit.left - text.right, moreOrLessEquals(DsSpace.s4));
      final field = tester.getRect(find.byType(DsNumberField));
      expect(unit.right, lessThan(field.center.dx));
    });

    testWidgets('RTL: leading and trailing mirror', (tester) async {
      await tester.pumpWidget(
        app(
          const DsTextField(
            initialValue: 'שלום',
            leading: DsIcon(DsIcons.mail),
            clearable: true,
          ),
          direction: TextDirection.rtl,
        ),
      );
      final text = tester.getCenter(editableFinder()).dx;
      expect(tester.getCenter(find.byType(DsIcon).first).dx, greaterThan(text));
      expect(tester.getCenter(button('Clear')).dx, lessThan(text));
      expect(tester.takeException(), isNull);
    });
  });

  group('clear button', () {
    testWidgets('shows with text, clears, keeps focus and reports', (
      tester,
    ) async {
      final changes = <String>[];
      await tester.pumpWidget(
        app(DsTextField(clearable: true, onChanged: changes.add)),
      );
      expect(button('Clear'), findsNothing);
      await tester.enterText(editableFinder(), 'fatura');
      await tester.pump();
      expect(button('Clear'), findsOneWidget);
      expect(editable(tester).widget.focusNode.hasFocus, isTrue);
      await tester.tap(button('Clear'));
      await tester.pump();
      expect(editable(tester).widget.controller.text, isEmpty);
      expect(editable(tester).widget.focusNode.hasFocus, isTrue);
      expect(changes, ['fatura', '']);
      expect(button('Clear'), findsNothing);
    });

    testWidgets('clearing an unfocused field focuses it', (tester) async {
      await tester.pumpWidget(
        app(const DsTextField(clearable: true, initialValue: 'abc')),
      );
      expect(editable(tester).widget.focusNode.hasFocus, isFalse);
      await tester.tap(button('Clear'));
      await tester.pump();
      expect(editable(tester).widget.controller.text, isEmpty);
      expect(editable(tester).widget.focusNode.hasFocus, isTrue);
    });

    testWidgets('hidden while disabled or read-only', (tester) async {
      await tester.pumpWidget(
        app(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsTextField(clearable: true, initialValue: 'a', enabled: false),
              DsTextField(clearable: true, initialValue: 'a', readOnly: true),
            ],
          ),
        ),
      );
      expect(button('Clear'), findsNothing);
    });

    testWidgets('is not a Tab stop', (tester) async {
      await tester.pumpWidget(
        app(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsTextField(clearable: true, initialValue: 'a'),
              DsTextField(initialValue: 'b'),
            ],
          ),
        ),
      );
      final first = tester.state<EditableTextState>(editableFinder().first);
      final second = tester.state<EditableTextState>(editableFinder().last);
      first.widget.focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(second.widget.focusNode.hasFocus, isTrue);
    });

    testWidgets('a full tap target without a taller field (touch)', (
      tester,
    ) async {
      final theme = DsThemeData(platform: TargetPlatform.iOS);
      await tester.pumpWidget(
        app(
          const DsTextField(clearable: true, initialValue: 'abc'),
          theme: theme,
        ),
      );
      // Same height as a field without the button.
      expect(tester.getSize(find.byType(DsTextField)).height, 40);
      final target = tester.getRect(
        find.descendant(
          of: button('Clear'),
          matching: find.byType(DsMinTapTarget),
        ),
      );
      expect(target.width, greaterThanOrEqualTo(44));
      // A tap 18px beside the 22px button still clears.
      final center = tester.getCenter(button('Clear'));
      await tester.tapAt(center - const Offset(18, 0));
      await tester.pump();
      expect(editable(tester).widget.controller.text, isEmpty);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });

  group('show password', () {
    testWidgets('toggles the bullets and keeps the selection', (tester) async {
      final controller = TextEditingController(text: 'hunter22');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(
          DsTextField(
            controller: controller,
            obscureText: true,
            revealable: true,
          ),
        ),
      );
      await tester.tap(editableFinder());
      await tester.pump();
      controller.selection = const TextSelection(
        baseOffset: 2,
        extentOffset: 5,
      );
      await tester.pump();
      expect(editable(tester).widget.obscureText, isTrue);
      await tester.tap(button('Show password'));
      await tester.pump();
      expect(editable(tester).widget.obscureText, isFalse);
      expect(
        controller.selection,
        const TextSelection(baseOffset: 2, extentOffset: 5),
      );
      expect(editable(tester).widget.focusNode.hasFocus, isTrue);
      expect(button('Hide password'), findsOneWidget);
      await tester.tap(button('Hide password'));
      await tester.pump();
      expect(editable(tester).widget.obscureText, isTrue);
    });

    testWidgets('is a Tab stop after the field', (tester) async {
      await tester.pumpWidget(
        app(const DsTextField(obscureText: true, revealable: true)),
      );
      editable(tester).widget.focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        focused.findAncestorWidgetOfExactType<DsButton>()?.semanticLabel,
        'Show password',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(editable(tester).widget.obscureText, isFalse);
    });
  });

  group('counter', () {
    testWidgets('shows "count / max" in tabular figures under the field', (
      tester,
    ) async {
      final theme = DsThemeData();
      await tester.pumpWidget(
        app(const DsTextField(maxLength: 100), theme: theme),
      );
      expect(find.text('0 / 100'), findsOneWidget);
      await tester.enterText(editableFinder(), 'Merhaba dünya');
      await tester.pump();
      expect(find.text('13 / 100'), findsOneWidget);
      final style = tester.widget<Text>(find.text('13 / 100')).style!;
      expect(style.fontFamily, contains(theme.typography.family));
      expect(style.fontFeatures, [const FontFeature.tabularFigures()]);
      expect(style.color, theme.colors.textSubtle);
      // Below the field, at the end.
      final field = tester.getRect(find.byType(AnimatedContainer).first);
      final counter = tester.getRect(find.text('13 / 100'));
      expect(counter.top, greaterThan(field.bottom));
      expect(counter.right, closeTo(field.right, 0.5));
    });

    testWidgets('is enforced by default', (tester) async {
      await tester.pumpWidget(app(const DsTextField(maxLength: 5)));
      await tester.enterText(editableFinder(), 'abcdefgh');
      await tester.pump();
      expect(editable(tester).widget.controller.text, 'abcde');
      expect(find.text('5 / 5'), findsOneWidget);
    });

    testWidgets('a soft limit lets typing go on and shows an error', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final theme = DsThemeData();
      await tester.pumpWidget(
        app(
          const DsTextField(
            maxLength: 5,
            maxLengthEnforcement: MaxLengthEnforcement.none,
          ),
          theme: theme,
        ),
      );
      await tester.enterText(editableFinder(), 'abcdefgh');
      await tester.pump();
      expect(editable(tester).widget.controller.text, 'abcdefgh');
      final counter = tester.widget<Text>(find.text('8 / 5')).style!;
      expect(counter.color, theme.colors.danger.text);
      expect(counter.fontWeight, FontWeight.w600);
      expect(decoration(tester).shadows.first.spread, 2);
      final data = tester.getSemantics(editableFinder()).getSemanticsData();
      expect(data.validationResult, SemanticsValidationResult.invalid);
      expect(data.hint, contains('8 of 5 characters'));
      handle.dispose();
    });

    testWidgets('announces politely near the limit, once per step', (
      tester,
    ) async {
      final said = announcements(tester);
      await tester.pumpWidget(
        app(
          const DsTextField(
            maxLength: 20,
            maxLengthEnforcement: MaxLengthEnforcement.none,
          ),
          media: (m) => m.copyWith(supportsAnnounce: true),
        ),
      );
      for (final text in [
        'a' * 10,
        'a' * 17, // 3 left: not yet in the last tenth (2)
        'a' * 18, // 2 left
        'a' * 19, // 1 left: still the same step
        'a' * 20, // the limit
        'a' * 21, // over
        'a' * 22,
      ]) {
        await tester.enterText(editableFinder(), text);
        await tester.pump();
      }
      expect(said, [
        '2 characters left',
        '0 characters left',
        '1 character too many',
      ]);
    });

    testWidgets('no announcements where the platform has none', (tester) async {
      final said = announcements(tester);
      await tester.pumpWidget(
        app(
          const DsTextField(maxLength: 4),
          media: (m) => m.copyWith(supportsAnnounce: false),
        ),
      );
      await tester.enterText(editableFinder(), 'abcd');
      await tester.pump();
      expect(said, isEmpty);
    });

    testWidgets('inside a DsField it shares the message row', (tester) async {
      await tester.pumpWidget(
        app(
          const DsField(
            label: Text('Bio'),
            description: Text('Shown on your profile.'),
            child: DsTextField(maxLength: 50),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('0 / 50'), findsOneWidget);
      final description = tester.getRect(find.text('Shown on your profile.'));
      final counter = tester.getRect(find.text('0 / 50'));
      // One row: the description at the start, the counter at the end.
      expect(counter.top, closeTo(description.top, 1));
      expect(counter.left, greaterThan(description.right));
      await tester.enterText(editableFinder(), 'abc');
      await tester.pump();
      expect(find.text('3 / 50'), findsOneWidget);
    });

    testWidgets('the counter leaves the field when the limit goes', (
      tester,
    ) async {
      Widget build(int? max) => app(
        DsField(
          label: const Text('Bio'),
          child: DsTextField(maxLength: max),
        ),
      );
      await tester.pumpWidget(build(10));
      await tester.pump();
      expect(find.text('0 / 10'), findsOneWidget);
      await tester.pumpWidget(build(null));
      await tester.pump();
      await tester.pump();
      expect(find.text('0 / 10'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('multi-line', () {
    testWidgets('grows from minLines to maxLines, then scrolls', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(
          DsTextField.multiline(
            controller: controller,
            minLines: 2,
            maxLines: 4,
          ),
        ),
      );
      double height() => tester.getSize(find.byType(DsTextField)).height;
      final two = height();
      controller.text = 'a\nb\nc';
      await tester.pump();
      final three = height();
      expect(three, greaterThan(two));
      controller.text = 'a\nb\nc\nd';
      await tester.pump();
      final four = height();
      expect(four, greaterThan(three));
      // Typing past maxLines keeps the height and scrolls to the caret.
      await tester.enterText(editableFinder(), 'a\nb\nc\nd\ne\nf\ng');
      await tester.pumpAndSettle();
      expect(height(), four);
      final scroll = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(DsTextField),
          matching: find.byType(Scrollable),
        ),
      );
      expect(scroll.position.pixels, greaterThan(0));
    });

    testWidgets('Enter adds a line', (tester) async {
      await tester.pumpWidget(app(const DsTextField.multiline()));
      final state = editable(tester);
      expect(state.widget.keyboardType, TextInputType.multiline);
      await tester.tap(editableFinder());
      await tester.pump();
      state.updateEditingValue(
        const TextEditingValue(
          text: 'a',
          selection: TextSelection.collapsed(offset: 1),
        ),
      );
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.newline);
      await tester.pump();
      expect(state.widget.focusNode.hasFocus, isTrue);
    });

    testWidgets('takes the text area padding and a counter', (tester) async {
      await tester.pumpWidget(
        app(const DsTextField.multiline(maxLength: 280, initialValue: 'Not')),
      );
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      expect(container.padding, const EdgeInsetsDirectional.all(DsSpace.s12));
      expect(find.text('3 / 280'), findsOneWidget);
    });
  });

  group('search field', () {
    testWidgets('magnifier, search action, label and control look', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final theme = DsThemeData();
      await tester.pumpWidget(
        app(const DsSearchField(placeholder: 'Görev ara'), theme: theme),
      );
      expect(
        find.byWidgetPredicate((w) => w is DsIcon && w.icon == DsIcons.search),
        findsOneWidget,
      );
      expect(editable(tester).widget.textInputAction, TextInputAction.search);
      final data = tester.getSemantics(editableFinder()).getSemanticsData();
      expect(data.label, 'Search');
      expect(data.hint, 'Görev ara');
      final box = decoration(tester);
      expect(box.color, theme.colors.control);
      expect(
        box.borderRadius,
        BorderRadius.circular(theme.radii.control(theme.sizes.md)),
      );
      handle.dispose();
    });

    testWidgets('Escape clears first, then is left to the layer around', (
      tester,
    ) async {
      final changes = <String>[];
      var outer = 0;
      await tester.pumpWidget(
        app(
          CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () => outer++,
            },
            child: DsSearchField(onChanged: changes.add),
          ),
        ),
      );
      await tester.tap(editableFinder());
      await tester.enterText(editableFinder(), 'fatura');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(editable(tester).widget.controller.text, isEmpty);
      expect(changes.last, '');
      expect(editable(tester).widget.focusNode.hasFocus, isTrue);
      expect(outer, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(outer, 1);
    });

    testWidgets('the shortcut hint shows while empty', (tester) async {
      await tester.pumpWidget(
        app(
          const DsSearchField(shortcut: '⌘K'),
          theme: DsThemeData(platform: TargetPlatform.macOS),
        ),
      );
      expect(find.byType(DsShortcut), findsOneWidget);
      await tester.enterText(editableFinder(), 'a');
      await tester.pump();
      expect(find.byType(DsShortcut), findsNothing);
      expect(button('Clear'), findsOneWidget);
    });

    testWidgets('no shortcut hint on touch platforms', (tester) async {
      for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
        await tester.pumpWidget(
          app(
            const DsSearchField(shortcut: '⌘K'),
            theme: DsThemeData(platform: platform),
          ),
        );
        expect(find.byType(DsShortcut), findsNothing, reason: '$platform');
      }
    });

    testWidgets('named by a DsField label instead of "Search"', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(const DsField(label: Text('Filtre'), child: DsSearchField())),
      );
      await tester.pump();
      final data = tester.getSemantics(editableFinder()).getSemanticsData();
      expect(data.label, 'Filtre');
      handle.dispose();
    });
  });

  group('in a DsField', () {
    testWidgets('buttons stay separate nodes; the label names the field', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          const DsField(
            label: Text('Parola'),
            required: true,
            errorText: 'En az 8 karakter olmalı.',
            child: DsTextField(
              initialValue: 'abc',
              obscureText: true,
              revealable: true,
            ),
          ),
        ),
      );
      await tester.pump();
      final field = tester.getSemantics(editableFinder()).getSemanticsData();
      expect(field.label, 'Parola');
      expect(field.flagsCollection.isTextField, isTrue);
      expect(field.flagsCollection.isRequired, Tristate.isTrue);
      expect(field.validationResult, SemanticsValidationResult.invalid);
      final reveal = tester
          .getSemantics(button('Show password'))
          .getSemanticsData();
      expect(reveal.label, 'Show password');
      expect(reveal.flagsCollection.isButton, isTrue);
      expect(reveal.hasAction(SemanticsAction.tap), isTrue);
      // The message is the field's hint, heard on the field itself, and
      // not a node of its own after the button.
      expect(field.hint, 'Error\nEn az 8 karakter olmalı.');
      expect(
        find.bySemanticsLabel(RegExp('En az 8 karakter olmalı')),
        findsNothing,
      );
      // The label is not read twice.
      expect(find.bySemanticsLabel('Parola'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('without buttons it stays one node', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        app(const DsField(label: Text('E-posta'), child: DsTextField())),
      );
      await tester.pump();
      final node = tester.getSemantics(editableFinder());
      expect(tester.getSemantics(find.text('E-posta')), same(node));
      handle.dispose();
    });

    testWidgets('takes the field error look', (tester) async {
      final theme = DsThemeData();
      await tester.pumpWidget(
        app(
          const DsField(
            label: Text('E-posta'),
            errorText: 'Geçerli bir adres girin.',
            child: DsTextField(leading: DsIcon(DsIcons.mail)),
          ),
          theme: theme,
        ),
      );
      final ring = decoration(tester).shadows.first;
      expect(ring.color, theme.shadows.fieldError.first.color);
      expect(ring.spread, 2);
    });
  });

  group('look', () {
    testWidgets('disabled keeps its shape: a faint edge (K-66)', (
      tester,
    ) async {
      final theme = DsThemeData();
      await tester.pumpWidget(
        app(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsTextField(enabled: false, initialValue: 'a'),
              DsSearchField(enabled: false),
            ],
          ),
          theme: theme,
        ),
      );
      for (final i in [0, 1]) {
        final d =
            tester
                    .widget<AnimatedContainer>(
                      find.byType(AnimatedContainer).at(i),
                    )
                    .decoration!
                as DsBoxDecoration;
        expect(d.color, theme.colors.disabled, reason: '$i');
        final rings = [
          for (final s in d.shadows)
            if (s.inset) s,
        ];
        expect(rings.single.color, theme.colors.border, reason: '$i');
        expect(rings.single.spread, 1, reason: '$i');
        // No lift: a disabled control is flat.
        expect(d.shadows.where((s) => !s.inset), isEmpty, reason: '$i');
      }
    });

    testWidgets('large text at phone width: no overflow', (tester) async {
      tester.view.physicalSize = const Size(358, 800) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        app(
          width: 358,
          media: (m) => m.copyWith(textScaler: const TextScaler.linear(2)),
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsField(
                label: Text('E-posta'),
                description: Text('İş adresiniz.'),
                child: DsTextField(
                  leading: DsIcon(DsIcons.mail),
                  clearable: true,
                  initialValue: 'deniz@derlio.app',
                  maxLength: 100,
                ),
              ),
              DsTextField(
                obscureText: true,
                revealable: true,
                initialValue: 'secret',
                error: true,
              ),
              DsSearchField(shortcut: '⌘K', placeholder: 'Ara'),
              DsTextField.multiline(maxLength: 280),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('works without DsApp or DsScope (R3)', (tester) async {
      final changes = <String>[];
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DsTextField(
                  clearable: true,
                  maxLength: 10,
                  onChanged: changes.add,
                ),
                const DsSearchField(shortcut: '⌘K'),
                const DsTextField.multiline(),
                const DsTextField(obscureText: true, revealable: true),
              ],
            ),
          ),
        ),
      );
      await tester.enterText(editableFinder().first, 'abc');
      await tester.pump();
      expect(find.text('3 / 10'), findsOneWidget);
      await tester.tap(button('Clear'));
      await tester.pump();
      expect(changes, ['abc', '']);
      await tester.tap(button('Show password'));
      await tester.pump();
      expect(
        tester
            .state<EditableTextState>(editableFinder().last)
            .widget
            .obscureText,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Ö3: a theme variant styles only search fields', (
      tester,
    ) async {
      const red = Color(0xFFFF0000);
      await tester.pumpWidget(
        app(
          const DsTextFieldTheme(
            data: DsTextFieldThemeData(
              variants: {
                DsTextFieldVariant.search: DsTextFieldStyle(background: red),
              },
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [DsSearchField(), DsTextField()],
            ),
          ),
        ),
      );
      Color? fill(int i) =>
          (tester
                      .widget<AnimatedContainer>(
                        find.byType(AnimatedContainer).at(i),
                      )
                      .decoration!
                  as DsBoxDecoration)
              .color;
      expect(fill(0), red);
      expect(fill(1), isNot(red));
    });
  });

  test('debug properties name the form', () {
    final props = DiagnosticPropertiesBuilder();
    const DsTextField.multiline().debugFillProperties(props);
    expect(
      props.properties.map((p) => p.toString()),
      contains('variant: multiline'),
    );
  });
}

/// The painted extent of the field's text, not the editor's box: the
/// editor keeps the caret's room at its right edge.
Rect paintedText(WidgetTester tester) {
  final editor = tester.allRenderObjects.whereType<RenderEditable>().first;
  final glyphs = editor
      .getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: editor.plainText.length),
      )
      .map((b) => b.toRect())
      .reduce((a, b) => a.expandToInclude(b));
  return MatrixUtils.transformRect(editor.getTransformTo(null), glyphs);
}

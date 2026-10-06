import 'dart:ui' show SemanticsValidationResult, Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// DsField: label, description, error and required around a control
/// (WCAG 3.3.1).
void main() {
  const options = [
    DsSelectOption(value: 'web', label: 'Derlio Web'),
    DsSelectOption(value: 'mobile', label: 'Derlio Mobil'),
  ];

  Widget select({String? error, bool required = false, DsFieldStyle? style}) =>
      SizedBox(
        width: 320,
        child: DsField(
          label: const Text('Project'),
          description: const Text('Reports link to it.'),
          errorText: error,
          required: required,
          style: style,
          child: DsSelect<String>(
            value: null,
            error: error != null,
            onChanged: (_) {},
            options: options,
          ),
        ),
      );

  /// A host whose MediaQuery says whether announcements are supported.
  Widget announcing(Widget child, {bool supported = true}) => Builder(
    builder: (context) => MediaQuery(
      data: MediaQueryData.fromView(View.of(context))
          .copyWith(supportsAnnounce: supported),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: child),
      ),
    ),
  );

  TextStyle styleOf(WidgetTester tester, Finder text) => tester
      .widget<RichText>(
        find.descendant(of: text, matching: find.byType(RichText)).first,
      )
      .text
      .style!;

  group('semantics', () {
    testWidgets('the label names the control; description follows', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(select(required: true)));
      final node = tester.getSemantics(find.byType(DsSelect<String>));
      final data = node.getSemanticsData();
      // One node: the label, the required word, the control; the
      // description is the hint, read after the name and the state.
      expect(data.label, startsWith('Project\nRequired'));
      expect(data.label, isNot(contains('Reports link to it.')));
      expect(data.hint, endsWith('Reports link to it.'));
      expect(data.label, isNot(contains('*')));
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.flagsCollection.isRequired, Tristate.isTrue);
      expect(data.validationResult, SemanticsValidationResult.none);
      expect(tester.getSemantics(find.text('Project')), same(node));
      handle.dispose();
    });

    testWidgets('an open menu is not merged into the field', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 400,
            height: 400,
            child: Overlay(
              initialEntries: [
                OverlayEntry(builder: (_) => Center(child: select())),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byType(DsSelect<String>));
      await tester.pumpAndSettle();
      final option = tester
          .getSemantics(find.text('Derlio Web').last)
          .getSemanticsData();
      expect(option.label, 'Derlio Web');
      expect(
        tester
            .getSemantics(find.byType(DsSelect<String>))
            .getSemanticsData()
            .label,
        isNot(contains('Derlio Web')),
      );
      handle.dispose();
    });

    testWidgets('an error replaces the description and marks it invalid', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(select(error: 'Choose a project.')));
      await tester.pumpAndSettle();
      final data = tester
          .getSemantics(find.byType(DsSelect<String>))
          .getSemanticsData();
      expect(data.hint, endsWith('Error\nChoose a project.'));
      expect(data.label, isNot(contains('Choose a project.')));
      expect(data.hint, isNot(contains('Reports link to it.')));
      expect(data.validationResult, SemanticsValidationResult.invalid);
      expect(find.text('Reports link to it.'), findsNothing);
      handle.dispose();
    });

    testWidgets('a new error is announced politely, once', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(announcing(select()));
      expect(tester.takeAnnouncements(), isEmpty);
      await tester.pumpWidget(announcing(select(error: 'Choose a project.')));
      final a = tester.takeAnnouncements();
      expect(a, hasLength(1));
      expect(a.single.message, 'Error\nChoose a project.');
      expect(a.single.assertiveness, Assertiveness.polite);
      await tester.pumpAndSettle();
      // Not a live region as well: it would be heard twice.
      expect(
        tester
            .getSemantics(find.byType(DsSelect<String>))
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isFalse,
      );
      // The same error again: nothing; a different one: announced.
      await tester.pumpWidget(announcing(select(error: 'Choose a project.')));
      expect(tester.takeAnnouncements(), isEmpty);
      await tester.pumpWidget(announcing(select(error: 'Pick another.')));
      expect(tester.takeAnnouncements().single.message, 'Error\nPick another.');
      handle.dispose();
    });

    testWidgets('an error there from the start is read, not announced', (
      tester,
    ) async {
      await tester.pumpWidget(announcing(select(error: 'Choose a project.')));
      expect(tester.takeAnnouncements(), isEmpty);
    });

    testWidgets('without announcements (Android) it is a live region', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(announcing(select(), supported: false));
      SemanticsData data() =>
          tester.getSemantics(find.byType(DsSelect<String>)).getSemanticsData();
      expect(data().flagsCollection.isLiveRegion, isFalse);
      await tester.pumpWidget(
        announcing(select(error: 'Choose a project.'), supported: false),
      );
      await tester.pumpAndSettle();
      expect(tester.takeAnnouncements(), isEmpty);
      expect(data().flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });

    testWidgets('a group keeps its controls apart', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DsField(
            group: true,
            label: const Text('Notify me'),
            required: true,
            errorText: 'Pick at least one.',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DsCheckbox(
                  value: false,
                  error: true,
                  onChanged: (_) {},
                  label: const Text('Mentions'),
                ),
                DsCheckbox(
                  value: false,
                  error: true,
                  onChanged: (_) {},
                  label: const Text('Assignments'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final first = tester.getSemantics(find.byType(DsCheckbox).first);
      final second = tester.getSemantics(find.byType(DsCheckbox).last);
      expect(first, isNot(same(second)));
      expect(first.getSemanticsData().label, 'Mentions');
      expect(
        first.getSemanticsData().validationResult,
        SemanticsValidationResult.invalid,
      );
      expect(
        tester.getSemantics(find.text('Notify me')).getSemanticsData().label,
        'Notify me\nRequired',
      );
      expect(
        tester
            .getSemantics(find.textContaining('Pick at least one.'))
            .getSemanticsData()
            .label,
        'Error\nPick at least one.',
      );
      handle.dispose();
    });
  });

  group('look', () {
    testWidgets('label, description and error take their tokens', (
      tester,
    ) async {
      final t = DsThemeData();
      await tester.pumpWidget(host(select(required: true), theme: t));
      expect(styleOf(tester, find.text('Project')).color, t.colors.textMuted);
      expect(
        styleOf(tester, find.text('Project')).fontSize,
        t.typography.fieldLabel.fontSize,
      );
      expect(styleOf(tester, find.text('*')).color, t.colors.danger.text);
      expect(
        styleOf(tester, find.text('Reports link to it.')).color,
        t.colors.textSubtle,
      );
      await tester.pumpWidget(
        host(select(error: 'Choose a project.'), theme: t),
      );
      await tester.pumpAndSettle();
      final message = find.textContaining('Choose a project.');
      expect(styleOf(tester, message).color, t.colors.danger.text);
      expect(
        tester
            .widget<DsIcon>(
              find
                  .descendant(
                    of: find.byType(DsField),
                    matching: find.byWidgetPredicate(
                      (w) => w is DsIcon && w.icon == DsIcons.circleAlert,
                    ),
                  )
                  .last,
            )
            .color,
        t.colors.danger.text,
      );
    });

    testWidgets('the error grows the field on a spring without overshoot', (
      tester,
    ) async {
      await tester.pumpWidget(host(select()));
      final start = tester.getSize(find.byType(DsField)).height;
      await tester.pumpWidget(
        host(
          select(
            error:
                'Choose a project. Reports need one, and the list shows '
                'only the projects you can edit.',
          ),
        ),
      );
      final heights = <double>[];
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        heights.add(tester.getSize(find.byType(DsField)).height);
      }
      await tester.pumpAndSettle();
      final end = tester.getSize(find.byType(DsField)).height;
      expect(end, greaterThan(start));
      expect(heights.first, lessThan(end), reason: 'it animates');
      for (final h in heights) {
        expect(h, lessThanOrEqualTo(end + .01), reason: 'no overshoot');
      }
      for (var i = 1; i < heights.length; i++) {
        expect(heights[i], greaterThanOrEqualTo(heights[i - 1] - .01));
      }
    });

    testWidgets('with reduce motion the size jumps', (tester) async {
      final t = DsThemeData(motion: const DsMotion(reduced: true));
      await tester.pumpWidget(host(select(), theme: t));
      await tester.pumpWidget(
        host(
          select(error: 'Choose a project. It links the reports.'),
          theme: t,
        ),
      );
      await tester.pump();
      final first = tester.getSize(find.byType(DsField)).height;
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(DsField)).height, first);
    });

    testWidgets('mirrors in RTL', (tester) async {
      await tester.pumpWidget(
        host(
          select(error: 'Choose a project.', required: true),
          direction: TextDirection.rtl,
        ),
      );
      await tester.pumpAndSettle();
      final field = tester.getRect(find.byType(DsField));
      final label = tester.getRect(find.text('Project'));
      final mark = tester.getRect(find.text('*'));
      expect(label.right, moreOrLessEquals(field.right));
      expect(mark.right, lessThan(label.left + 1));
      final icon = tester.getRect(
        find
            .byWidgetPredicate(
              (w) => w is DsIcon && w.icon == DsIcons.circleAlert,
            )
            .last,
      );
      expect(icon.right, moreOrLessEquals(field.right, epsilon: 1));
    });

    testWidgets('large text: no overflow at phone width', (tester) async {
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 358,
            child: DsField(
              label: const Text('Which project should the weekly report use'),
              errorText:
                  'Choose a project. The weekly report needs one to know '
                  'whose numbers to show.',
              required: true,
              child: DsSelect<String>(
                value: null,
                error: true,
                onChanged: (_) {},
                options: options,
              ),
            ),
          ),
          textScale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // The icon grows with the text.
      expect(
        tester
            .getSize(
              find
                  .byWidgetPredicate(
                    (w) => w is DsIcon && w.icon == DsIcons.circleAlert,
                  )
                  .last,
            )
            .height,
        DsField.defaultStyle(DsThemeData()).iconSize! * 2,
      );
    });
  });

  testWidgets('works without a scope', (tester) async {
    await tester.pumpWidget(host(select(error: 'Choose a project.')));
    await tester.pumpAndSettle();
    expect(find.text('Project'), findsOneWidget);
    expect(find.textContaining('Choose a project.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('customization', () {
    testWidgets('Ö1: one field\'s style', (tester) async {
      const ink = Color(0xFF0050AA);
      await tester.pumpWidget(
        host(
          select(
            error: 'Choose a project.',
            style: const DsFieldStyle(
              labelStyle: TextStyle(color: ink),
              error: DsFieldStyle(iconColor: ink),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(styleOf(tester, find.text('Project')).color, ink);
      // The font comes from the defaults below.
      expect(
        styleOf(tester, find.text('Project')).fontSize,
        DsThemeData().typography.fieldLabel.fontSize,
      );
      expect(
        tester
            .widget<DsIcon>(
              find
                  .byWidgetPredicate(
                    (w) => w is DsIcon && w.icon == DsIcons.circleAlert,
                  )
                  .last,
            )
            .color,
        ink,
      );
    });

    testWidgets('Ö3: a subtree\'s fields', (tester) async {
      const ink = Color(0xFF7A1F5C);
      await tester.pumpWidget(
        host(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DsFieldTheme(
                data: DsFieldThemeData(
                  style: DsFieldStyle(
                    messageStyle: TextStyle(color: ink),
                    labelGap: 2,
                  ),
                ),
                child: DsField(
                  label: Text('Inside'),
                  description: Text('Inside hint'),
                  child: SizedBox(width: 10, height: 10),
                ),
              ),
              DsField(
                label: Text('Outside'),
                description: Text('Outside hint'),
                child: SizedBox(width: 10, height: 10),
              ),
            ],
          ),
        ),
      );
      expect(styleOf(tester, find.text('Inside hint')).color, ink);
      expect(styleOf(tester, find.text('Outside hint')).color, isNot(ink));
    });
  });

  testWidgets('the control can read the field', (tester) async {
    final seen = <DsFieldScope?>[];
    Widget probe() => Builder(
      builder: (context) {
        seen.add(DsFieldScope.maybeOf(context));
        return const SizedBox(width: 10, height: 10);
      },
    );
    await tester.pumpWidget(
      host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DsField(
              label: const Text('A'),
              errorText: 'Wrong',
              required: true,
              child: probe(),
            ),
            DsField(group: true, label: const Text('B'), child: probe()),
            probe(),
          ],
        ),
      ),
    );
    expect(seen[0]!.hasError, isTrue);
    expect(seen[0]!.isRequired, isTrue);
    expect(seen[0]!.isLabelled, isTrue);
    expect(seen[1]!.hasError, isFalse);
    expect(seen[1]!.isLabelled, isFalse);
    expect(seen[2], isNull);
  });

  group('controls read the field', () {
    DsBoxDecoration selectBox(WidgetTester tester) =>
        tester
                .widget<AnimatedContainer>(
                  find
                      .descendant(
                        of: find.byType(DsSelect<String>),
                        matching: find.byType(AnimatedContainer),
                      )
                      .first,
                )
                .decoration!
            as DsBoxDecoration;

    testWidgets('a field error reaches a select without error: true', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final theme = DsThemeData();
      await tester.pumpWidget(
        host(
          theme: theme,
          SizedBox(
            width: 320,
            child: DsField(
              label: const Text('Project'),
              errorText: 'Pick one.',
              child: DsSelect<String>(
                value: null,
                onChanged: (_) {},
                options: options,
              ),
            ),
          ),
        ),
      );
      final data = tester
          .getSemantics(find.byType(DsSelect<String>))
          .getSemanticsData();
      expect(data.validationResult, SemanticsValidationResult.invalid);
      // The 2px error edge and the error icon, not color alone.
      final ring = selectBox(tester).shadows.first;
      expect(ring.color, theme.shadows.fieldError.first.color);
      expect(ring.spread, 2);
      expect(
        find.descendant(
          of: find.byType(DsSelect<String>),
          matching: find.byWidgetPredicate(
            (w) => w is DsIcon && w.icon == DsIcons.circleAlert,
          ),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('a field error reaches checkboxes and radios in a group', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DsField(
            group: true,
            label: const Text('Topics'),
            errorText: 'Pick one.',
            child: DsRadioGroup<String>(
              value: null,
              onChanged: (_) {},
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DsCheckbox(
                    value: false,
                    onChanged: (_) {},
                    label: const Text('Mentions'),
                  ),
                  const DsRadio(value: 'team', label: Text('Team')),
                ],
              ),
            ),
          ),
        ),
      );
      for (final finder in [
        find.byType(DsCheckbox),
        find.byType(DsRadio<String>),
      ]) {
        expect(
          tester.getSemantics(finder).getSemanticsData().validationResult,
          SemanticsValidationResult.invalid,
          reason: '$finder',
        );
      }
      handle.dispose();
    });

    testWidgets('without a field error they stay valid', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DsField(
            group: true,
            label: const Text('Topics'),
            child: DsCheckbox(
              value: false,
              onChanged: (_) {},
              label: const Text('Mentions'),
            ),
          ),
        ),
      );
      expect(
        tester
            .getSemantics(find.byType(DsCheckbox))
            .getSemanticsData()
            .validationResult,
        SemanticsValidationResult.none,
      );
      handle.dispose();
    });

    testWidgets('a labelled select is named by the field, not the '
        'placeholder', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DsField(
                  label: const Text('Project'),
                  child: DsSelect<String>(
                    value: null,
                    placeholder: 'Choose…',
                    onChanged: (_) {},
                    options: options,
                  ),
                ),
                DsSelect<String>(
                  value: null,
                  placeholder: 'Choose…',
                  onChanged: (_) {},
                  options: options,
                ),
              ],
            ),
          ),
        ),
      );
      final inField = tester
          .getSemantics(find.byType(DsSelect<String>).first)
          .getSemanticsData();
      expect(inField.label, 'Project');
      // Alone, the placeholder still names it.
      expect(find.bySemanticsLabel('Choose…'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a disabled select keeps a faint edge', (tester) async {
      final theme = DsThemeData();
      await tester.pumpWidget(
        host(
          theme: theme,
          const SizedBox(
            width: 320,
            child: DsSelect<String>(
              value: null,
              onChanged: null,
              options: options,
            ),
          ),
        ),
      );
      final box = selectBox(tester);
      expect(box.color, theme.colors.disabled);
      final ring = box.shadows.first;
      expect(ring.inset, isTrue);
      expect(ring.color, theme.colors.border);
      expect(ring.spread, 1);
    });
  });
}

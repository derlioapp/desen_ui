import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// On touch the segmented control, the text field, the select and the
/// multi-select are drawn shorter than the smallest tap target (44): each
/// takes the target's room around its drawn box, as a button does, so a
/// tap just past the drawn edge reaches it wherever it sits (here, a list
/// item's edge), and its node is the target's height.
void main() {
  final ios = DsThemeData(platform: TargetPlatform.iOS);
  final mac = DsThemeData(platform: TargetPlatform.macOS);

  /// [child] at the top of a list, alone in its item: no room around it
  /// but its own.
  Widget inList(Widget child, {DsThemeData? theme}) => host(
    theme: theme ?? ios,
    SizedBox(
      width: 360,
      height: 400,
      child: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (_) => ListView(
              padding: const EdgeInsets.only(top: 60),
              children: [child, const SizedBox(height: 120)],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> tapAt(WidgetTester tester, Offset at) async {
    await tester.tapAt(at);
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('segmented control', () {
    Widget control(ValueChanged<int> onChanged) => DsSegmentedControl<int>(
      value: 0,
      onChanged: onChanged,
      segments: const [
        DsSegment(value: 0, label: Text('Day')),
        DsSegment(value: 1, label: Text('Week')),
        DsSegment(value: 2, label: Text('Month')),
      ],
    );

    /// The drawn channel.
    Rect channel(WidgetTester tester) => tester.getRect(
      find
          .descendant(
            of: find.byType(DsSegmentedControl<int>),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );

    testWidgets('takes 44 of room and looks the same; desktop does not', (
      tester,
    ) async {
      await tester.pumpWidget(inList(control((_) {}), theme: mac));
      final drawn = channel(tester).height;
      expect(drawn, lessThan(44));
      expect(
        tester.getSize(find.byType(DsSegmentedControl<int>)).height,
        drawn,
      );

      await tester.pumpWidget(inList(control((_) {})));
      await tester.pumpAndSettle();
      final box = tester.getRect(find.byType(DsSegmentedControl<int>));
      expect(box.height, 44);
      expect(channel(tester).height, drawn);
      expect(channel(tester).center, box.center);
    });

    testWidgets('in a list, taps just above and below reach the segment '
        'there', (tester) async {
      int? got;
      await tester.pumpWidget(inList(control((v) => got = v)));
      await tester.pumpAndSettle();
      final drawn = channel(tester);
      final week = tester.getCenter(find.text('Week')).dx;
      final month = tester.getCenter(find.text('Month')).dx;

      await tapAt(tester, Offset(week, drawn.top - 2.5));
      expect(got, 1);
      await tapAt(tester, Offset(month, drawn.bottom + 2.5));
      expect(got, 2);
      // On the channel's rim, outside the segments themselves.
      await tapAt(tester, Offset(week, drawn.top + 1));
      expect(got, 1);
    });

    testWidgets('each segment is a 44 target for screen readers', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(inList(control((_) {})));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      final node = tester.getSemantics(find.text('Week'));
      expect(node.rect.height, 44);
      expect(node.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      semantics.dispose();
    });
  });

  group('text field', () {
    testWidgets('takes 44 of room around its 40 well; desktop does not', (
      tester,
    ) async {
      await tester.pumpWidget(inList(const DsTextField(), theme: mac));
      expect(tester.getSize(find.byType(DsTextField)).height, 40);

      await tester.pumpWidget(inList(const DsTextField()));
      final box = tester.getRect(find.byType(DsTextField));
      final well = tester.getRect(wellOf(find.byType(DsTextField)));
      expect(box.height, 44);
      expect(well.height, 40);
      expect(well.center, box.center);
    });

    testWidgets('in a list, a tap just above or below focuses it, the '
        'caret where the finger was', (tester) async {
      final controller = TextEditingController(text: 'hello world');
      addTearDown(controller.dispose);
      await tester.pumpWidget(inList(DsTextField(controller: controller)));
      final well = tester.getRect(wellOf(find.byType(DsTextField)));
      final world = tester.getTopRight(find.text('hello world'));

      await tester.tapAt(Offset(world.dx - 4, well.top - 1.5));
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue, reason: 'focused');
      expect(controller.selection.baseOffset, greaterThan(6));

      // Elsewhere, then below the well, near its start.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.tapAt(Offset(well.left + 16, well.bottom + 1.5));
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.context, isNotNull);
      expect(controller.selection.baseOffset, lessThan(3));
    });

    testWidgets('meets the 44 tap target guideline', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        inList(const DsTextField(style: DsTextFieldStyle(height: 40))),
      );
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      semantics.dispose();
    });

    testWidgets('lines up with a button beside it at the top', (tester) async {
      await tester.pumpWidget(
        host(
          theme: ios,
          SizedBox(
            width: 360,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                const Expanded(child: DsTextField(placeholder: 'Search')),
                DsButton(onPressed: () {}, child: const Text('Go')),
              ],
            ),
          ),
        ),
      );
      final well = tester.getRect(wellOf(find.byType(DsTextField)));
      final button = tester.getRect(
        find
            .descendant(
              of: find.byType(DsButton),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(button.height, well.height);
      expect(button.top, well.top);
    });
  });

  group('select', () {
    Widget select() => DsSelect<int>(
      value: null,
      onChanged: (_) {},
      options: const [
        DsSelectOption(value: 1, label: 'One'),
        DsSelectOption(value: 2, label: 'Two'),
      ],
    );

    testWidgets('in a list, a tap just above opens it, from the drawn edge', (
      tester,
    ) async {
      await tester.pumpWidget(inList(select()));
      final box = tester.getRect(find.byType(DsSelect<int>));
      final well = tester.getRect(wellOf(find.byType(DsSelect<int>)));
      expect(box.height, 44);
      expect(well.height, 40);
      await tester.tapAt(Offset(well.center.dx, well.top - 1.5));
      await tester.pumpAndSettle();
      expect(find.text('Two'), findsOneWidget, reason: 'the menu opened');
      final menu = tester.getRect(find.byType(DsMenu));
      expect(menu.top - well.bottom, closeTo(DsSpace.s4, .1));
    });

    testWidgets('meets the 44 tap target guideline', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(inList(select()));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      semantics.dispose();
    });
  });

  testWidgets('a time field takes 44; its popup opens from the drawn edge, '
      'as on desktop', (tester) async {
    double gap(DsThemeData theme) {
      final well = tester.getRect(wellOf(find.byType(DsTimePicker)));
      final popup = tester.getRect(find.byType(DsSurface).last);
      return popup.top - well.bottom;
    }

    Future<void> open(DsThemeData theme) async {
      await tester.pumpWidget(
        inList(
          theme: theme,
          DsTimePicker(value: const DsTime(9, 30), onChanged: (_) {}),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Choose time'));
      await tester.pumpAndSettle();
    }

    final semantics = tester.ensureSemantics();
    await open(mac);
    expect(tester.getSize(find.byType(DsTimePicker)).height, 40);
    final desktop = gap(mac);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    await open(ios);
    expect(tester.getSize(find.byType(DsTimePicker)).height, 44);
    expect(gap(ios), closeTo(desktop, .1));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    semantics.dispose();
  });

  testWidgets('a time field meets the 44 tap target guideline', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      inList(DsTimePicker(value: const DsTime(9, 30), onChanged: (_) {})),
    );
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    semantics.dispose();
  });

  group('multi-select', () {
    Widget multi() => DsMultiSelect<String>(
      value: const ['a'],
      onChanged: (_) {},
      options: const [
        DsSelectOption(value: 'a', label: 'Ankara'),
        DsSelectOption(value: 'b', label: 'Bursa'),
      ],
    );

    testWidgets('takes 44 around its well; its text field takes none', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(inList(multi()));
      await tester.pumpAndSettle();
      final box = tester.getRect(find.byType(DsMultiSelect<String>));
      final well = tester.getRect(wellOf(find.byType(DsMultiSelect<String>)));
      expect(box.height, 44);
      expect(well.height, 40);
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      semantics.dispose();
    });
  });
}

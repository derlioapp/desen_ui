import 'dart:ui' show SemanticsRole, SemanticsValidationResult, Tristate;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Controls that hold their options in a node of their own (segmented
/// control, choice chips, tabs, radio group) inside a DsField: each option
/// stays reachable, and the field's label names the group.
void main() {
  /// [node] and every node below it.
  List<SemanticsNode> nodesUnder(SemanticsNode node) {
    final all = <SemanticsNode>[node];
    node.visitChildren((child) {
      all.addAll(nodesUnder(child));
      return true;
    });
    return all;
  }

  /// The nodes inside the field whose label mentions [text].
  List<SemanticsData> naming(WidgetTester tester, String text) => [
    for (final node in nodesUnder(tester.getSemantics(find.byType(DsField))))
      if (node.getSemanticsData().label.contains(text)) node.getSemanticsData(),
  ];

  final controls = <String, Widget Function(String, ValueChanged<String>)>{
    'segmented control': (value, onChanged) => DsSegmentedControl<String>(
      value: value,
      onChanged: onChanged,
      segments: const [
        DsSegment(value: 'monthly', label: Text('Monthly')),
        DsSegment(value: 'yearly', label: Text('Yearly')),
        DsSegment(value: 'lifetime', label: Text('Lifetime')),
      ],
    ),
    'choice chips': (value, onChanged) => DsChoiceChips<String>(
      value: value,
      onChanged: onChanged,
      options: const [
        DsChipOption(value: 'monthly', label: Text('Monthly')),
        DsChipOption(value: 'yearly', label: Text('Yearly')),
        DsChipOption(value: 'lifetime', label: Text('Lifetime')),
      ],
    ),
    'tabs': (value, onChanged) => DsTabs<String>(
      value: value,
      onChanged: onChanged,
      tabs: const [
        DsTab(value: 'monthly', label: Text('Monthly')),
        DsTab(value: 'yearly', label: Text('Yearly')),
        DsTab(value: 'lifetime', label: Text('Lifetime')),
      ],
    ),
  };

  for (final MapEntry(key: name, value: control) in controls.entries) {
    testWidgets('a $name in a field keeps its options apart, named by the '
        'field', (tester) async {
      final handle = tester.ensureSemantics();
      var value = 'monthly';
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 500,
            child: StatefulBuilder(
              builder: (context, setState) => DsField(
                label: const Text('Billing'),
                description: const Text('Change it any time.'),
                required: true,
                child: control(value, (v) => setState(() => value = v)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "Yearly" is a node of its own, not merged into the field's, with
      // its own action.
      final yearly = find.semantics.byLabel(RegExp(r'^Yearly'));
      expect(yearly.evaluate().single.isMergedIntoParent, isFalse);
      tester.semantics.tap(yearly);
      await tester.pumpAndSettle();
      expect(value, 'yearly');

      // The group is named by the field's label once, and carries the
      // description and the required state.
      final named = naming(tester, 'Billing');
      expect(named, hasLength(1));
      expect(named.single.label, 'Billing');
      expect(named.single.hint, 'Change it any time.');
      expect(named.single.flagsCollection.isRequired, Tristate.isTrue);
      expect(naming(tester, 'Change it any time.'), isEmpty);
      handle.dispose();
    });
  }

  testWidgets('the field label comes before the control\'s own name', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 500,
          child: DsField(
            label: const Text('Billing'),
            errorText: 'Choose a plan.',
            child: DsSegmentedControl<String>(
              value: 'monthly',
              onChanged: (_) {},
              semanticLabel: 'Plan',
              segments: const [
                DsSegment(value: 'monthly', label: Text('Monthly')),
                DsSegment(value: 'yearly', label: Text('Yearly')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final group = naming(tester, 'Billing').single;
    expect(group.label, 'Billing\nPlan');
    expect(group.hint, 'Error\nChoose a plan.');
    expect(group.validationResult, SemanticsValidationResult.invalid);
    handle.dispose();
  });

  group('radio group', () {
    Widget shipping({
      bool group = true,
      String? errorText = 'Choose one.',
      String? semanticLabel,
    }) => DsField(
      group: group,
      label: const Text('Shipping'),
      errorText: errorText,
      required: true,
      child: DsRadioGroup<String>(
        value: null,
        onChanged: (_) {},
        semanticLabel: semanticLabel,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DsRadio(value: 'standard', label: Text('Standard')),
            DsRadio(value: 'express', label: Text('Express')),
          ],
        ),
      ),
    );

    /// The radio group node.
    SemanticsData radioGroup(WidgetTester tester) =>
        nodesUnder(tester.getSemantics(find.byType(DsField)))
            .map((n) => n.getSemanticsData())
            .singleWhere((d) => d.role == SemanticsRole.radioGroup);

    testWidgets('a group field names the radio group and gives it the '
        'error', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(shipping()));
      await tester.pumpAndSettle();
      final group = radioGroup(tester);
      expect(group.label, 'Shipping');
      expect(group.hint, 'Error\nChoose one.');
      expect(group.flagsCollection.isRequired, Tristate.isTrue);
      // Heard on the group, not again as text around it.
      expect(naming(tester, 'Shipping'), hasLength(1));
      expect(naming(tester, 'Choose one.'), isEmpty);
      // The radios stay apart.
      expect(
        tester.getSemantics(find.text('Standard')).getSemanticsData().label,
        'Standard',
      );
      handle.dispose();
    });

    testWidgets('a field that is not a group names it too', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(shipping(group: false)));
      await tester.pumpAndSettle();
      expect(radioGroup(tester).label, 'Shipping');
      expect(
        tester.getSemantics(find.text('Express')).getSemanticsData().label,
        'Express',
      );
      handle.dispose();
    });

    testWidgets('without announcements the error stays a live region', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQueryData.fromView(View.of(context))
                .copyWith(supportsAnnounce: false),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Center(child: shipping()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final live = naming(
        tester,
        'Choose one.',
      ).where((d) => d.flagsCollection.isLiveRegion).toList();
      expect(live, hasLength(1));
      handle.dispose();
    });

    testWidgets('semanticLabel names it without a field', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DsRadioGroup<String>(
            value: null,
            onChanged: (_) {},
            semanticLabel: 'Shipping',
            child: const DsRadio(value: 'standard', label: Text('Standard')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final group = tester.getSemantics(find.text('Standard')).parent!;
      expect(group.getSemanticsData().role, SemanticsRole.radioGroup);
      expect(group.label, 'Shipping');
      handle.dispose();
    });

    testWidgets('a group of checkboxes keeps the label and message as '
        'text', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          DsField(
            group: true,
            label: const Text('Notify me'),
            errorText: 'Pick one.',
            child: DsCheckbox(
              value: false,
              onChanged: (_) {},
              label: const Text('Mentions'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(naming(tester, 'Notify me').single.label, 'Notify me');
      expect(naming(tester, 'Pick one.').single.label, 'Error\nPick one.');
      handle.dispose();
    });
  });
}

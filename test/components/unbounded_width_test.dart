import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Full-width components under an unbounded width (in a Row, in an
/// UnconstrainedBox) lay out instead of throwing: the progress bar takes
/// its style's width, the alert and the accordion their content's width,
/// a select its widest label's.
void main() {
  const alert = DsAlert(
    title: Text('Saved'),
    description: Text('Your changes were saved.'),
  );
  const accordion = DsAccordion<int>(
    initialValue: {1},
    items: [
      DsAccordionItem(value: 1, title: Text('Section one'), child: Text('One')),
      DsAccordionItem(value: 2, title: Text('Section two'), child: Text('Two')),
    ],
  );

  final parents = <String, Widget Function(Widget)>{
    'Row': (c) => Row(mainAxisSize: MainAxisSize.min, children: [c]),
    'UnconstrainedBox': (c) =>
        UnconstrainedBox(constrainedAxis: Axis.vertical, child: c),
  };

  for (final parent in parents.entries) {
    testWidgets('progress bar in a ${parent.key} takes its style width', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(parent.value(const DsProgressBar(value: .4))),
      );
      expect(tester.takeException(), isNull);
      final width = tester.getSize(find.byType(DsProgressBar)).width;
      expect(width, DsProgressBar.defaultStyle(DsThemeData()).width);
      // The fill is 40% of that track.
      final fill = tester.getSize(
        find.descendant(
          of: find.byType(FractionallySizedBox),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(fill.width, moreOrLessEquals(width * .4));
    });

    testWidgets('indeterminate progress bar in a ${parent.key} lays out', (
      tester,
    ) async {
      await tester.pumpWidget(host(parent.value(const DsProgressBar())));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(DsProgressBar)).width, greaterThan(0));
    });

    testWidgets('alert in a ${parent.key} takes its content width', (
      tester,
    ) async {
      await tester.pumpWidget(host(parent.value(alert)));
      expect(tester.takeException(), isNull);
      final box = tester.getSize(find.byType(DsAlert));
      final text = tester.getSize(find.text('Your changes were saved.'));
      expect(box.width, greaterThan(text.width));
      expect(box.width, lessThan(800));
    });

    testWidgets('accordion in a ${parent.key} takes its content width', (
      tester,
    ) async {
      await tester.pumpWidget(host(parent.value(accordion)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      final box = tester.getSize(find.byType(DsAccordion<int>));
      expect(
        box.width,
        greaterThan(tester.getSize(find.text('Section one')).width),
      );
      expect(box.width, lessThan(800));
      // Still opens and closes.
      await tester.tap(find.text('Section two'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Two'), findsOneWidget);
    });
  }

  testWidgets('a bounded width is unchanged: the components fill it', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [DsProgressBar(value: .5), alert, accordion],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.getSize(find.byType(DsProgressBar)).width, 300);
    expect(tester.getSize(find.byType(DsAlert)).width, 300);
    expect(tester.getSize(find.byType(DsAccordion<int>)).width, 300);
  });

  testWidgets('progress bar in a loose parent spans its width', (tester) async {
    // A centered column gives loose constraints; the track still spans the
    // width and the fill is the value's share of it.
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 200,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [DsProgressBar(value: .3, animate: false)],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(DsProgressBar)).width, 200);
    final fill = tester.getSize(
      find.descendant(
        of: find.byType(FractionallySizedBox),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(fill.width, moreOrLessEquals(60));
  });

  testWidgets('progress bar and alert work under IntrinsicHeight', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 300,
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [DsProgressBar(value: .5), alert],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(DsAlert)).width, 300);
  });

  testWidgets('style width sets the unbounded progress bar width', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DsProgressBar(value: .5, style: DsProgressBarStyle(width: 90)),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byType(DsProgressBar)).width, 90);
  });

  testWidgets('a select in a Row measures options changed in place', (
    tester,
  ) async {
    final options = [const DsSelectOption(value: 1, label: 'One')];
    var value = 1;
    late StateSetter setState;
    await tester.pumpWidget(
      DsApp(
        home: Center(
          child: StatefulBuilder(
            builder: (context, s) {
              setState = s;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DsSelect<int>(
                    value: value,
                    onChanged: (_) {},
                    options: options,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    final before = tester.getSize(find.byType(DsSelect<int>)).width;
    setState(() {
      options.add(const DsSelectOption(value: 2, label: 'A much longer label'));
      value = 2;
    });
    await tester.pump();
    final after = tester.getSize(find.byType(DsSelect<int>)).width;
    expect(after, greaterThan(before));
    final label = tester.renderObject<RenderParagraph>(
      find.text('A much longer label'),
    );
    expect(label.didExceedMaxLines, isFalse, reason: 'shown whole');
  });
}

import 'dart:async';

import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui/src/icons/icon.dart' show RenderDsIcon;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _line = DsIconData(['M4 12h16']);
const _thin = DsIconData(['M4 12h16'], strokeWidth: 1.5);

/// The stroke width each [DsIcon] under [finder] draws with.
List<double> _strokes(WidgetTester tester, [Finder? finder]) => [
  for (final e in (finder ?? find.byType(DsIcon)).evaluate())
    (e.renderObject! as RenderDsIcon).strokeWidth,
];

void main() {
  Widget under(double? weight, Widget icon) => Directionality(
    textDirection: TextDirection.ltr,
    child: IconTheme(
      data: IconThemeData(weight: weight),
      child: icon,
    ),
  );

  testWidgets('the icon theme\'s weight scales the stroke; 400 is the '
      'icon\'s own', (tester) async {
    await tester.pumpWidget(under(400, const DsIcon(_line)));
    expect(_strokes(tester), [2]);
    await tester.pumpWidget(under(350, const DsIcon(_line)));
    expect(_strokes(tester), [1.75]);
    await tester.pumpWidget(under(500, const DsIcon(_line)));
    expect(_strokes(tester), [2.5]);
    // Relative to the icon's own stroke.
    await tester.pumpWidget(under(300, const DsIcon(_thin)));
    expect(_strokes(tester), [1.125]);
  });

  testWidgets('DsIcon.strokeWidth wins over the weight', (tester) async {
    await tester.pumpWidget(under(350, const DsIcon(_line, strokeWidth: 2)));
    expect(_strokes(tester), [2]);
  });

  testWidgets('without a weight the icon keeps its own stroke', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: DsIcon(_line),
      ),
    );
    expect(_strokes(tester), [2]);
  });

  testWidgets('a weight set around DsScope passes through its defaults', (
    tester,
  ) async {
    await tester.pumpWidget(under(350, const DsScope(child: DsIcon(_line))));
    expect(_strokes(tester), [1.75]);
  });

  testWidgets('a weight set in DsApp.builder reaches icons inside '
      'components and layers', (tester) async {
    late BuildContext root;
    await tester.pumpWidget(
      DsApp(
        builder: (context, child) => IconTheme.merge(
          data: const IconThemeData(weight: 350),
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            root = context;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DsToast(title: 'Saved', onDismiss: _noop),
                  DsPopover(
                    contentBuilder: (_) => const DsIcon(DsIcons.check),
                    builder: (context, controller, _) => DsButton(
                      onPressed: controller.toggle,
                      child: const Text('Share'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    // The toast's own close button.
    expect(_strokes(tester), [1.75]);

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    unawaited(
      showDsDialog<void>(
        context: root,
        builder: (_) => const DsIcon(DsIcons.info),
      ),
    );
    await tester.pumpAndSettle();
    for (final icon in [DsIcons.check, DsIcons.info]) {
      expect(
        _strokes(
          tester,
          find.byWidgetPredicate((w) => w is DsIcon && w.icon == icon),
        ),
        [1.75],
        reason: '$icon',
      );
    }
  });
}

void _noop() {}

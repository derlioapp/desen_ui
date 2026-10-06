import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// The dialog's actions answer dry layout (parents that measure before
/// they lay out ask for it) with the size their real layout takes, side
/// by side and stacked.
void main() {
  Widget dialog(List<String> labels) => DsDialog(
    title: const Text('Delete the project?'),
    actions: [
      for (final label in labels)
        DsButton(onPressed: () {}, child: Text(label)),
    ],
  );

  for (final (name, width, labels) in [
    ('side by side', 400.0, ['Cancel', 'Delete']),
    ('stacked', 240.0, ['Keep the project', 'Delete it permanently']),
  ]) {
    testWidgets('dry layout matches the layout: $name', (tester) async {
      await tester.pumpWidget(
        host(SizedBox(width: width, child: dialog(labels))),
      );
      final box = tester.renderObject<RenderBox>(find.byType(DsDialog));
      final constraints = box.constraints;
      late Size dry;
      expect(() => dry = box.getDryLayout(constraints), returnsNormally);
      expect(dry, box.size);
      // Looser constraints too, as a measuring parent would pass.
      expect(
        () => box.getDryLayout(BoxConstraints(maxWidth: width)),
        returnsNormally,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the actions stack in a narrow dialog, side by side in a wide '
      'one', (tester) async {
    await tester.pumpWidget(
      host(SizedBox(width: 400, child: dialog(['Cancel', 'Delete']))),
    );
    expect(
      tester.getTopLeft(find.text('Cancel')).dy,
      tester.getTopLeft(find.text('Delete')).dy,
    );
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 240,
          child: dialog(['Keep the project', 'Delete it permanently']),
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('Delete it permanently')).dy,
      greaterThan(tester.getBottomLeft(find.text('Keep the project')).dy),
    );
  });
}

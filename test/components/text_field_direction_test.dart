import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// A text field can set its text's own direction, and ask for a keyboard
/// that does not learn.
void main() {
  testWidgets('an LTR value in an RTL app keeps the field\'s RTL layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 300,
          child: DsTextField(
            initialValue: 'TR12 0006',
            textDirection: TextDirection.ltr,
            leading: DsIcon(DsIcons.creditCard),
          ),
        ),
        direction: TextDirection.rtl,
      ),
    );
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.textDirection, TextDirection.ltr);
    // The leading slot still leads on the right.
    final field = tester.getRect(find.byType(DsTextField));
    final icon = tester.getRect(find.byType(DsIcon));
    expect(icon.center.dx, greaterThan(field.center.dx));
  });

  testWidgets('enableIMEPersonalizedLearning reaches the keyboard', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 300,
          child: DsTextField(enableIMEPersonalizedLearning: false),
        ),
      ),
    );
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText))
          .enableIMEPersonalizedLearning,
      isFalse,
    );
  });
}

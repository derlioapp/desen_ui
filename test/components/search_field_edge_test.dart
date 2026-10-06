import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The search field is drawn as a control, with the soft control edge; the
/// search variant of the text field theme gives it the text field's edge,
/// as its docs show.
void main() {
  Widget app(Widget child, DsThemeData theme) => DsApp(
    theme: theme,
    themeMode: DsThemeMode.light,
    home: Center(child: SizedBox(width: 320, child: child)),
  );

  /// The field's edge: the inset ring of its decoration.
  Color? edge(WidgetTester tester) {
    final box =
        tester
                .widget<AnimatedContainer>(
                  find
                      .descendant(
                        of: find.byType(DsTextField),
                        matching: find.byType(AnimatedContainer),
                      )
                      .first,
                )
                .decoration!
            as DsBoxDecoration;
    return box.shadows
        .where((x) => x.inset && x.color.a > 0)
        .firstOrNull
        ?.color;
  }

  testWidgets('a quieter control edge by default', (tester) async {
    final theme = DsThemeData();
    await tester.pumpWidget(app(const DsSearchField(), theme));
    expect(edge(tester), theme.colors.borderControl);
  });

  testWidgets('the search variant gives it the text field edge', (
    tester,
  ) async {
    final theme = DsThemeData();
    final colors = theme.colors;
    await tester.pumpWidget(
      app(
        DsTextFieldTheme(
          data: DsTextFieldThemeData(
            variants: {
              DsTextFieldVariant.search: DsTextFieldStyle(
                borderColor: colors.borderField,
                hovered: DsTextFieldStyle(borderColor: colors.borderField),
              ),
            },
          ),
          child: const DsSearchField(),
        ),
        theme,
      ),
    );
    expect(edge(tester), colors.borderField);
  });
}

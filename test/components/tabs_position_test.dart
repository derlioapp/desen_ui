import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Off the web, where the tab role does not tell it, every tab is
/// announced with its position after its label, as in the bottom nav.
void main() {
  Widget tabs({String? semanticLabel}) => DsTabs<int>(
    value: 0,
    onChanged: (_) {},
    tabs: [
      const DsTab(value: 0, label: Text('Genel')),
      DsTab(
        value: 1,
        label: const Text('Üyeler'),
        semanticLabel: semanticLabel,
      ),
      const DsTab(value: 2, label: Text('Güvenlik'), enabled: false),
    ],
  );

  SemanticsData semanticsOf(WidgetTester tester, String text) =>
      tester.getSemantics(find.text(text)).getSemanticsData();

  testWidgets('each tab reads its position after its label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(tabs()));
    expect(semanticsOf(tester, 'Genel').label, 'Genel\nTab 1 of 3');
    expect(semanticsOf(tester, 'Üyeler').label, 'Üyeler\nTab 2 of 3');
    expect(
      semanticsOf(tester, 'Güvenlik').label,
      'Güvenlik\nTab 3 of 3',
      reason: 'a disabled tab keeps its place',
    );
    expect(semanticsOf(tester, 'Genel').role, SemanticsRole.tab);
    handle.dispose();
  });

  testWidgets('a semantic label keeps the position after it', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(tabs(semanticLabel: 'Ekip üyeleri')));
    final label = semanticsOf(tester, 'Üyeler').label;
    expect(label, startsWith('Ekip üyeleri'));
    expect(label, endsWith('\nTab 2 of 3'));
    handle.dispose();
  });

  testWidgets('the position speaks the app language', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('tr'),
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: host(tabs()),
      ),
    );
    expect(semanticsOf(tester, 'Üyeler').label, 'Üyeler\n2. sekme, toplam 3');
    handle.dispose();
  });
}

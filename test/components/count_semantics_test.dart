import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// A count beside a label is heard after it: the number by default
/// ("Inbox, 4"), or what the app says it counts ("4 unread").
void main() {
  Widget sidebar({bool collapsed = false, String? countLabel}) => SizedBox(
    width: 240,
    height: 300,
    child: DsSidebar<String>(
      collapsed: collapsed,
      value: 'inbox',
      onChanged: (_) {},
      children: [
        DsSidebarItem(
          value: 'inbox',
          leading: const DsIcon(DsIcons.inbox),
          label: const Text('Inbox'),
          count: 4,
          countSemanticLabel: countLabel,
        ),
      ],
    ),
  );

  String sidebarLabel(WidgetTester tester) => tester
      .getSemantics(find.byType(DsPressable).first)
      .getSemanticsData()
      .label;

  testWidgets('sidebar: the number after the label by default', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(sidebar()));
    expect(sidebarLabel(tester), 'Inbox\n4');
    handle.dispose();
  });

  testWidgets('sidebar: the app\'s count label, expanded and collapsed', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(sidebar(countLabel: '4 unread')));
    expect(sidebarLabel(tester), 'Inbox\n4 unread');
    // The number still shows.
    expect(find.text('4'), findsOneWidget);

    await tester.pumpWidget(
      host(sidebar(collapsed: true, countLabel: '4 unread')),
    );
    await tester.pumpAndSettle();
    expect(sidebarLabel(tester), contains('4 unread'));
    expect(sidebarLabel(tester), isNot(contains('\n4\n')));
    handle.dispose();
  });

  testWidgets('tabs: the app\'s count label replaces the bare number', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 400,
          child: DsTabs<String>(
            value: 'drafts',
            onChanged: (_) {},
            tabs: const [
              DsTab(
                value: 'drafts',
                label: Text('Drafts'),
                count: 3,
                countSemanticLabel: '3 drafts',
              ),
              DsTab(value: 'sent', label: Text('Sent'), count: 12),
            ],
          ),
        ),
      ),
    );
    final drafts = tester
        .getSemantics(find.text('Drafts'))
        .getSemanticsData()
        .label;
    expect(drafts, startsWith('Drafts\n3 drafts'));
    final sent = tester
        .getSemantics(find.text('Sent'))
        .getSemanticsData()
        .label;
    expect(sent, startsWith('Sent\n12'));
    handle.dispose();
  });
}

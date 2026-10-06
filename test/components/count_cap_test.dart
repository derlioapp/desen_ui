import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Every count in the library caps the same way: above 99 it shows and
/// announces "99+" (DsCount.text), whether in a bubble, a tab or a
/// sidebar item.
void main() {
  testWidgets('a sidebar item caps its count like a tab', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 240,
          child: DsSidebar(
            children: [
              DsSidebarItem(
                label: const Text('Inbox'),
                count: 120,
                onPressed: () {},
              ),
              DsSidebarItem(
                label: const Text('Drafts'),
                count: 99,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('120'), findsNothing);
    expect(find.text('99+'), findsOneWidget);
    expect(find.text('99'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Inbox\s+99\+')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('DsCount.text is the shared rule', (tester) async {
    late String over, under;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) {
            over = DsCount.text(context, 1000);
            under = DsCount.text(context, 7);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(over, '99+');
    expect(under, '7');
  });
}

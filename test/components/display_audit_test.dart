import 'dart:typed_data';

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Regressions from the blind audit (phase B): avatar, card, list row.
void main() {
  testWidgets('a failed avatar image falls back to initials (B21, M14)', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        DsAvatar(
          initials: 'AB',
          image: MemoryImage(Uint8List.fromList(const [0, 1, 2, 3, 4])),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('AB'), findsOneWidget);
  });

  testWidgets('an avatar group keeps names and status (B26)', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const DsAvatarGroup(
          avatars: [
            DsAvatar(
              initials: 'AL',
              semanticLabel: 'Ada Lovelace',
              status: DsStatus.success,
            ),
            DsAvatar(initials: 'GH', semanticLabel: 'Grace Hopper'),
          ],
        ),
      ),
    );
    expect(find.bySemanticsLabel('Ada Lovelace, Online'), findsOneWidget);
    final group = tester.widget<DsAvatarGroup>(find.byType(DsAvatarGroup));
    expect(group.avatars.first.status, DsStatus.success);
    final drawn = tester.widgetList<DsAvatar>(
      find.descendant(
        of: find.byType(DsAvatarGroup),
        matching: find.byType(DsAvatar),
      ),
    );
    expect(drawn.first.status, DsStatus.success);
    handle.dispose();
  });

  testWidgets('max: 0 shows only the overflow bubble (B27)', (tester) async {
    await tester.pumpWidget(
      host(
        const DsAvatarGroup(
          max: 0,
          avatars: [
            DsAvatar(initials: 'AL'),
            DsAvatar(initials: 'GH'),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('+2'), findsOneWidget);
  });

  for (final kind in ['card', 'list row']) {
    testWidgets('making a $kind interactive keeps its content (B25)', (
      tester,
    ) async {
      var inits = 0;
      late StateSetter setOuter;
      VoidCallback? onPressed;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: StatefulBuilder(
              builder: (context, setState) {
                setOuter = setState;
                final probe = _Probe(onInit: () => inits++);
                return kind == 'card'
                    ? DsCard(onPressed: onPressed, child: probe)
                    : DsListRow(
                        title: const Text('Satır'),
                        trailing: probe,
                        onPressed: onPressed,
                      );
              },
            ),
          ),
        ),
      );
      expect(inits, 1);
      setOuter(() => onPressed = () {});
      await tester.pump();
      setOuter(() => onPressed = null);
      await tester.pump();
      expect(inits, 1);
    });
  }
}

class _Probe extends StatefulWidget {
  const _Probe({required this.onInit});

  final VoidCallback onInit;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 20, height: 20);
}

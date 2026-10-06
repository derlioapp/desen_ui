import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// Avatar status and loading: the status is announced with the name, a
/// group keeps every status dot visible, and a photo shows the initials
/// until its first frame.
void main() {
  testWidgets('the status is announced with the name', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DsAvatar(
              initials: 'AK',
              semanticLabel: 'Ayşe Kaya',
              status: DsStatus.success,
            ),
            DsAvatar(initials: 'MÖ', status: DsStatus.warning),
            DsAvatar(initials: 'DA', status: DsStatus.danger),
            DsAvatar(initials: 'EK', status: DsStatus.neutral),
            DsAvatar(
              initials: 'ZT',
              status: DsStatus.info,
              statusLabel: 'In a meeting',
            ),
            DsAvatar(initials: 'NS'),
          ],
        ),
      ),
    );
    expect(find.bySemanticsLabel('Ayşe Kaya, Online'), findsOneWidget);
    expect(find.bySemanticsLabel('MÖ, Away'), findsOneWidget);
    expect(find.bySemanticsLabel('DA, Busy'), findsOneWidget);
    expect(find.bySemanticsLabel('EK, Offline'), findsOneWidget);
    expect(find.bySemanticsLabel('ZT, In a meeting'), findsOneWidget);
    expect(find.bySemanticsLabel('NS'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('the status word is localized', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      Localizations(
        locale: const Locale('tr'),
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: host(
          const DsAvatar(
            initials: 'AK',
            semanticLabel: 'Ayşe Kaya',
            status: DsStatus.success,
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Ayşe Kaya, Çevrimiçi'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a group keeps every status dot visible', (tester) async {
    final theme = DsThemeData.light();
    final boundary = GlobalKey();
    await tester.pumpWidget(
      host(
        RepaintBoundary(
          key: boundary,
          child: const DsAvatarGroup(
            avatars: [
              DsAvatar(initials: 'DA', status: DsStatus.success),
              DsAvatar(initials: 'EK', status: DsStatus.danger),
              DsAvatar(initials: 'MÖ'),
            ],
          ),
        ),
        theme: theme,
      ),
    );
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final data = await tester.runAsync(() async {
      final image = await render.toImage();
      final bytes = await image.toByteData();
      final width = image.width;
      image.dispose();
      return (bytes!, width);
    });
    final (bytes, width) = data!;
    Color at(Offset p) {
      final i = (p.dy.round() * width + p.dx.round()) * 4;
      return Color.fromARGB(
        bytes.getUint8(i + 3),
        bytes.getUint8(i),
        bytes.getUint8(i + 1),
        bytes.getUint8(i + 2),
      );
    }

    // sm avatars: 32 across, a fifth overlapped; dots of 10 on the
    // bottom-end corner of each avatar's box.
    const d = 32.0, step = d - d / 5, dot = 10.0;
    for (final (i, status) in [(0, DsStatus.success), (1, DsStatus.danger)]) {
      final center = Offset(i * step + d - dot / 2, d - dot / 2);
      expect(
        at(center),
        isSameColorAs(theme.colors.status(status).signal),
        reason: 'the dot of avatar $i is drawn over the next avatar',
      );
    }
  });

  /// A real 4 × 4 PNG: in a widget test it decodes only under runAsync.
  Future<Uint8List> png(WidgetTester tester) async {
    late Uint8List bytes;
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 4, 4),
        Paint()..color = const Color(0xFF3366CC),
      );
      final image = await recorder.endRecording().toImage(4, 4);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      bytes = data!.buffer.asUint8List();
    });
    return bytes;
  }

  testWidgets('a photo shows the initials until its first frame', (
    tester,
  ) async {
    final bytes = await png(tester);
    await tester.pumpWidget(
      host(DsAvatar(initials: 'MC', image: MemoryImage(bytes))),
    );
    await tester.pump();
    expect(find.text('MC'), findsOneWidget);
  });

  testWidgets('a decoded photo replaces the initials', (tester) async {
    final provider = MemoryImage(await png(tester));
    await tester.pumpWidget(host(const SizedBox()));
    await tester.runAsync(
      () => precacheImage(provider, tester.element(find.byType(SizedBox))),
    );
    await tester.pumpWidget(
      host(DsAvatar(initials: 'MC', image: provider, resizeImage: false)),
    );
    await tester.pump();
    expect(find.text('MC'), findsNothing);
    expect(find.byType(RawImage), findsOneWidget);
  });
}

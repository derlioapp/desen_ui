import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// S-34: danger toasts interrupt; the others stay a polite live region.
void main() {
  Widget app(
    void Function(BuildContext context) onPressed, {
    bool supportsAnnounce = true,
    TextDirection direction = TextDirection.ltr,
  }) => MediaQuery(
    data: MediaQueryData(
      size: const Size(800, 600),
      supportsAnnounce: supportsAnnounce,
    ),
    child: DsApp(
      home: Directionality(
        textDirection: direction,
        child: Center(
          child: Builder(
            builder: (context) => DsButton(
              onPressed: () => onPressed(context),
              child: const Text('Go'),
            ),
          ),
        ),
      ),
    ),
  );

  bool anyLiveRegion(WidgetTester tester, String title) {
    SemanticsNode? node = tester.getSemantics(find.text(title));
    while (node != null) {
      if (node.getSemanticsData().flagsCollection.isLiveRegion) return true;
      node = node.parent;
    }
    return false;
  }

  testWidgets('a danger toast is announced assertively, once', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      app(
        (context) => showDsToast(
          context: context,
          title: 'Could not save',
          description: 'Network error',
          status: DsStatus.danger,
        ),
      ),
    );
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    final announcements = tester.takeAnnouncements();
    expect(announcements, hasLength(1));
    expect(
      announcements.single.message,
      'Error\nCould not save\nNetwork error',
    );
    expect(announcements.single.assertiveness, Assertiveness.assertive);
    expect(announcements.single.textDirection, TextDirection.ltr);
    // Not a live region too: it would be heard twice.
    expect(anyLiveRegion(tester, 'Could not save'), isFalse);
    // A rebuild does not announce again.
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeAnnouncements(), isEmpty);
    semantics.dispose();
  });

  testWidgets('the announcement keeps the caller\'s language and direction', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      app(
        (context) => showDsToast(
          context: context,
          title: 'Kaydedilemedi',
          status: DsStatus.danger,
        ),
        direction: TextDirection.rtl,
      ),
    );
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    final a = tester.takeAnnouncements().single;
    expect(a.textDirection, TextDirection.rtl);
    expect(a.message, startsWith(const DsLocalizationsEn().error));
    semantics.dispose();
  });

  testWidgets('other statuses stay a polite live region', (tester) async {
    final semantics = tester.ensureSemantics();
    for (final status in [null, ...DsStatus.values]) {
      if (status == DsStatus.danger) continue;
      await tester.pumpWidget(
        app(
          (context) => showDsToast(
            context: context,
            title: 'Saved $status',
            status: status,
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(tester.takeAnnouncements(), isEmpty, reason: '$status');
      expect(anyLiveRegion(tester, 'Saved $status'), isTrue, reason: '$status');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
    semantics.dispose();
  });

  testWidgets('without announcement support danger stays a live region', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      app(
        (context) => showDsToast(
          context: context,
          title: 'Failed',
          status: DsStatus.danger,
        ),
        supportsAnnounce: false,
      ),
    );
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    expect(tester.takeAnnouncements(), isEmpty);
    expect(anyLiveRegion(tester, 'Failed'), isTrue);
    semantics.dispose();
  });

  testWidgets('a danger toast replaced in the same frame is not announced', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      app((context) {
        showDsToast(context: context, title: 'Old', status: DsStatus.danger);
        showDsToast(context: context, title: 'New');
      }),
    );
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    expect(tester.takeAnnouncements(), isEmpty);
    expect(anyLiveRegion(tester, 'New'), isTrue);
    semantics.dispose();
  });
}

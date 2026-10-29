import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A toast whose text changes while it shows, and one that stays.
void main() {
  late DsToastController toast;

  /// Shows a toast as soon as the app is up, with [show]'s arguments.
  Future<void> open(
    WidgetTester tester,
    DsToastController Function(BuildContext context) show, {
    bool supportsAnnounce = true,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: const Size(800, 600),
          supportsAnnounce: supportsAnnounce,
        ),
        child: DsApp(
          home: Center(
            child: Builder(
              builder: (context) => DsButton(
                onPressed: () => toast = show(context),
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
  }

  final reading = const DsMotion().toastDuration;

  testWidgets('update changes the text in place, without motion', (
    tester,
  ) async {
    await open(
      tester,
      (context) => showDsToast(
        context: context,
        title: 'Downloading',
        description: '0/3',
        persistent: true,
      ),
    );
    double opacity() => tester
        .widget<Opacity>(
          find.ancestor(
            of: find.byType(DsToast),
            matching: find.byType(Opacity),
          ),
        )
        .opacity;
    final element = tester.element(find.byType(DsToast));
    final at = tester.getRect(find.byType(DsToast));
    final shown = opacity();
    toast.update(title: 'Downloading', description: '1/3');
    await tester.pump();
    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('0/3'), findsNothing);
    // The same toast, where it was, fully shown: no leave and enter.
    expect(tester.element(find.byType(DsToast)), same(element));
    expect(tester.getRect(find.byType(DsToast)), at);
    expect(opacity(), shown);
    expect(tester.hasRunningAnimations, isFalse);

    // A new title, and no description.
    toast.update(title: 'Done');
    await tester.pump();
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('1/3'), findsNothing);
    toast.dismiss();
    await tester.pumpAndSettle();
  });

  testWidgets('a persistent toast stays until dismissed', (tester) async {
    await open(
      tester,
      (context) =>
          showDsToast(context: context, title: 'Downloading', persistent: true),
    );
    await tester.pump(reading * 20);
    expect(toast.isShowing, isTrue);
    expect(find.text('Downloading'), findsOneWidget);
    // Hovering and leaving starts no timer either.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.byType(DsToast)));
    await tester.pump();
    await mouse.moveTo(Offset.zero);
    await tester.pump(reading * 3);
    expect(toast.isShowing, isTrue);
    await mouse.removePointer();

    toast.dismiss();
    expect(await toast.closed, DsToastClosedReason.dismissed);
    await tester.pumpAndSettle();
    expect(find.byType(DsToast), findsNothing);
  });

  testWidgets('an update gives a timed toast its time again', (tester) async {
    await open(
      tester,
      (context) => showDsToast(context: context, title: 'Step 1'),
    );
    await tester.pump(reading - const Duration(seconds: 1));
    toast.update(title: 'Step 2');
    await tester.pump(reading - const Duration(seconds: 1));
    expect(toast.isShowing, isTrue, reason: 'its time started again');
    await tester.pump(const Duration(seconds: 2));
    expect(toast.isShowing, isFalse);
    expect(await toast.closed, DsToastClosedReason.timeout);
    await tester.pumpAndSettle();
  });

  testWidgets('an update once the toast is closing does nothing', (
    tester,
  ) async {
    await open(
      tester,
      (context) => showDsToast(context: context, title: 'Saved'),
    );
    toast.dismiss();
    toast.update(title: 'Changed');
    await tester.pump();
    expect(find.text('Changed'), findsNothing);
    await tester.pumpAndSettle();
  });

  testWidgets('screen readers hear a change at most once per toast duration, '
      'the latest last', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(
      tester,
      (context) => showDsToast(
        context: context,
        title: 'Downloading',
        description: '0/9',
        persistent: true,
      ),
    );
    Finder heard(String count) => find.bySemanticsLabel('Downloading\n$count');
    expect(heard('0/9'), findsOneWidget);

    // Shown moments ago: the change waits, while the text drawn moves.
    toast.update(title: 'Downloading', description: '1/9');
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1/9'), findsOneWidget);
    expect(heard('0/9'), findsOneWidget);
    toast.update(title: 'Downloading', description: '2/9');
    await tester.pump(reading - const Duration(seconds: 1));
    // Its turn: the latest text, not each step.
    expect(heard('2/9'), findsOneWidget);

    // Quiet a while, a change is heard at once, then holds again.
    await tester.pump(reading * 2);
    toast.update(title: 'Downloading', description: '3/9');
    await tester.pump();
    expect(heard('3/9'), findsOneWidget);
    toast.update(title: 'Downloading', description: '4/9');
    await tester.pump(reading ~/ 2);
    expect(heard('3/9'), findsOneWidget);
    await tester.pump(reading ~/ 2);
    expect(heard('4/9'), findsOneWidget);

    toast.dismiss();
    await tester.pumpAndSettle();
    semantics.dispose();
  });

  testWidgets('a danger toast announces its changes assertively, held too', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await open(
      tester,
      (context) => showDsToast(
        context: context,
        title: 'Sync failed',
        description: 'Retrying in 3',
        status: DsStatus.danger,
        persistent: true,
      ),
    );
    expect(tester.takeAnnouncements(), hasLength(1));
    toast.update(title: 'Sync failed', description: 'Retrying in 2');
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeAnnouncements(), isEmpty);
    await tester.pump(reading);
    final said = tester.takeAnnouncements();
    expect(said, hasLength(1));
    expect(said.single.message, 'Error\nSync failed\nRetrying in 2');
    expect(said.single.assertiveness, Assertiveness.assertive);
    toast.dismiss();
    await tester.pumpAndSettle();
    semantics.dispose();
  });
}

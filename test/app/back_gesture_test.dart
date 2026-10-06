import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// S-30: the iOS back swipe and Android's predictive back on DsPageRoute.
void main() {
  final ios = TargetPlatformVariant.only(TargetPlatform.iOS);
  final android = TargetPlatformVariant.only(TargetPlatform.android);

  /// A navigator of DsPageRoutes named by their text; '/' is home.
  Future<GlobalKey<NavigatorState>> pumpNavigator(
    WidgetTester tester, {
    TextDirection direction = TextDirection.ltr,
    bool canPop = true,
    bool fullscreenDialog = false,
    bool reduceMotion = false,
  }) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: const Size(800, 600),
          disableAnimations: reduceMotion,
        ),
        child: Directionality(
          textDirection: direction,
          child: DsTheme(
            data: DsThemeData(motion: DsMotion(reduced: reduceMotion)),
            child: Navigator(
              key: key,
              onGenerateRoute: (settings) => DsPageRoute<void>(
                settings: settings,
                fullscreenDialog: fullscreenDialog && settings.name != '/',
                builder: (_) => PopScope(
                  canPop: canPop || settings.name == '/',
                  child: SizedBox.expand(
                    child: Text(settings.name == '/' ? 'A' : 'B'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    key.currentState!.pushNamed('/b');
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);
    return key;
  }

  bool onB(WidgetTester tester) =>
      find.text('B').evaluate().isNotEmpty &&
      ModalRoute.of(tester.element(find.text('B')))!.isCurrent;

  // A slow drag: 2 s, far below the fling speed.
  Future<void> slowDrag(WidgetTester tester, Offset from, double dx) async {
    await tester.timedDragFrom(from, Offset(dx, 0), const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  group('iOS back swipe', () {
    testWidgets('a drag from the start edge past half the width pops', (
      tester,
    ) async {
      final nav = await pumpNavigator(tester);
      await slowDrag(tester, const Offset(5, 300), 500);
      expect(find.text('B'), findsNothing);
      expect(find.text('A'), findsOneWidget);
      expect(nav.currentState!.userGestureInProgress, isFalse);
    }, variant: ios);

    testWidgets('the page follows the finger, then the gesture ends', (
      tester,
    ) async {
      final nav = await pumpNavigator(tester);
      final gesture = await tester.startGesture(const Offset(5, 300));
      await gesture.moveBy(const Offset(40, 0));
      await gesture.moveBy(const Offset(160, 0));
      await tester.pump();
      expect(nav.currentState!.userGestureInProgress, isTrue);
      final slide = tester.widget<FractionalTranslation>(
        find
            .ancestor(
              of: find.text('B'),
              matching: find.byType(FractionalTranslation),
            )
            .first,
      );
      // 200px dragged, less the touch slop, of an 800px page.
      expect(slide.translation.dx, inExclusiveRange(.15, .26));
      // The page underneath shows through.
      expect(find.text('A'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(onB(tester), isTrue);
      expect(nav.currentState!.userGestureInProgress, isFalse);
    }, variant: ios);

    testWidgets('a short drag settles back', (tester) async {
      final nav = await pumpNavigator(tester);
      await slowDrag(tester, const Offset(5, 300), 150);
      expect(onB(tester), isTrue);
      expect(nav.currentState!.userGestureInProgress, isFalse);
      final slide = tester.widget<FractionalTranslation>(
        find
            .ancestor(
              of: find.text('B'),
              matching: find.byType(FractionalTranslation),
            )
            .first,
      );
      expect(slide.translation, Offset.zero);
    }, variant: ios);

    testWidgets('a fling pops even when short', (tester) async {
      await pumpNavigator(tester);
      await tester.flingFrom(const Offset(5, 300), const Offset(120, 0), 1600);
      await tester.pumpAndSettle();
      expect(find.text('B'), findsNothing);
    }, variant: ios);

    testWidgets('a fling back toward the edge cancels a long drag', (
      tester,
    ) async {
      await pumpNavigator(tester);
      final gesture = await tester.startGesture(const Offset(5, 300));
      for (var i = 0; i < 12; i++) {
        await gesture.moveBy(
          const Offset(50, 0),
          timeStamp: Duration(milliseconds: 100 * i),
        );
        await tester.pump();
      }
      // A quick move back toward the start edge, then release.
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(
          const Offset(-40, 0),
          timeStamp: Duration(milliseconds: 1200 + 10 * i),
        );
      }
      await gesture.up(timeStamp: const Duration(milliseconds: 1240));
      await tester.pumpAndSettle();
      expect(onB(tester), isTrue);
    }, variant: ios);

    testWidgets('a drag away from the edge does nothing', (tester) async {
      final nav = await pumpNavigator(tester);
      await slowDrag(tester, const Offset(200, 300), 500);
      expect(onB(tester), isTrue);
      expect(nav.currentState!.userGestureInProgress, isFalse);
    }, variant: ios);

    testWidgets('PopScope(canPop: false) blocks it', (tester) async {
      final nav = await pumpNavigator(tester, canPop: false);
      await slowDrag(tester, const Offset(5, 300), 500);
      expect(onB(tester), isTrue);
      expect(nav.currentState!.userGestureInProgress, isFalse);
    }, variant: ios);

    testWidgets('RTL: the swipe starts at the right edge', (tester) async {
      await pumpNavigator(tester, direction: TextDirection.rtl);
      // The left edge is the end edge in RTL: nothing.
      await slowDrag(tester, const Offset(5, 300), 500);
      expect(onB(tester), isTrue);
      await slowDrag(tester, const Offset(795, 300), -500);
      expect(find.text('B'), findsNothing);
      expect(find.text('A'), findsOneWidget);
    }, variant: ios);

    testWidgets('not on the first route', (tester) async {
      final nav = await pumpNavigator(tester);
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      await slowDrag(tester, const Offset(5, 300), 500);
      expect(find.text('A'), findsOneWidget);
      expect(nav.currentState!.canPop(), isFalse);
      expect(nav.currentState!.userGestureInProgress, isFalse);
    }, variant: ios);

    testWidgets('not on a full screen dialog', (tester) async {
      await pumpNavigator(tester, fullscreenDialog: true);
      await slowDrag(tester, const Offset(5, 300), 500);
      expect(onB(tester), isTrue);
    }, variant: ios);

    testWidgets('reduce motion: the page fades with the finger', (
      tester,
    ) async {
      await pumpNavigator(tester, reduceMotion: true);
      final gesture = await tester.startGesture(const Offset(5, 300));
      await gesture.moveBy(const Offset(40, 0));
      await gesture.moveBy(const Offset(360, 0));
      await tester.pump();
      expect(
        find.ancestor(
          of: find.text('B'),
          matching: find.byType(FractionalTranslation),
        ),
        findsNothing,
      );
      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(of: find.text('B'), matching: find.byType(FadeTransition))
            .first,
      );
      expect(fade.opacity.value, inExclusiveRange(.4, .6));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pumpAndSettle();
      // Released just past half: it pops.
      expect(find.text('B'), findsNothing);
    }, variant: ios);

    testWidgets('no edge swipe on Android', (tester) async {
      await pumpNavigator(tester);
      await slowDrag(tester, const Offset(5, 300), 500);
      expect(onB(tester), isTrue);
    }, variant: android);
  });

  group('Android predictive back', () {
    Future<void> back(
      WidgetTester tester,
      String method, {
      double progress = 0,
      int edge = 0,
    }) async {
      final args = <String, Object?>{
        'touchOffset': <double>[5, 300],
        'progress': progress,
        'swipeEdge': edge,
      };
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/backgesture',
        const StandardMethodCodec().encodeMethodCall(
          MethodCall(
            method,
            method.startsWith('commit') || method.startsWith('cancel')
                ? null
                : args,
          ),
        ),
        (_) {},
      );
      await tester.pump();
    }

    Transform transformOfB(WidgetTester tester) => tester.widget<Transform>(
      find.ancestor(of: find.text('B'), matching: find.byType(Transform)).first,
    );

    testWidgets('previews, then pops on commit', (tester) async {
      final nav = await pumpNavigator(tester);
      await back(tester, 'startBackGesture');
      expect(nav.currentState!.userGestureInProgress, isTrue);
      await back(tester, 'updateBackGestureProgress', progress: .5);
      // Half way: shrunk half way to the end scale, drifted right.
      final m = transformOfB(tester).transform;
      expect(m.entry(0, 0), closeTo(.95, .001));
      expect(m.getTranslation().x, closeTo(DsPageRoute.rise / 2, .001));
      expect(find.text('A'), findsOneWidget);
      await back(tester, 'commitBackGesture');
      await tester.pumpAndSettle();
      expect(find.text('B'), findsNothing);
      expect(nav.currentState!.userGestureInProgress, isFalse);
    }, variant: android);

    testWidgets('settles back on cancel', (tester) async {
      final nav = await pumpNavigator(tester);
      await back(tester, 'startBackGesture', edge: 1);
      await back(tester, 'updateBackGestureProgress', progress: .4, edge: 1);
      // From the right edge it drifts left.
      expect(transformOfB(tester).transform.getTranslation().x, lessThan(0));
      await back(tester, 'cancelBackGesture');
      await tester.pumpAndSettle();
      expect(onB(tester), isTrue);
      expect(nav.currentState!.userGestureInProgress, isFalse);
      expect(transformOfB(tester).transform.entry(0, 0), 1);
    }, variant: android);

    testWidgets('PopScope(canPop: false) keeps the page', (tester) async {
      final nav = await pumpNavigator(tester, canPop: false);
      await back(tester, 'startBackGesture');
      expect(nav.currentState!.userGestureInProgress, isFalse);
      await back(tester, 'commitBackGesture');
      await tester.pumpAndSettle();
      expect(onB(tester), isTrue);
    }, variant: android);

    testWidgets('not on the first route', (tester) async {
      final nav = await pumpNavigator(tester);
      nav.currentState!.pop();
      await tester.pumpAndSettle();
      await back(tester, 'startBackGesture');
      expect(nav.currentState!.userGestureInProgress, isFalse);
    }, variant: android);
  });
}

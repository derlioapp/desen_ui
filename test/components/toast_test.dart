import 'dart:async';

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The toast host, timing, keyboard and context.
void main() {
  /// An app with one button that runs [onPressed] with its context.
  Widget app(
    void Function(BuildContext context) onPressed, {
    MediaQueryData media = const MediaQueryData(size: Size(800, 600)),
    DsThemeMode mode = DsThemeMode.light,
    Widget Function(Widget child)? around,
  }) => MediaQuery(
    data: media,
    child: DsApp(
      themeMode: mode,
      home: Center(
        child: (around ?? (c) => c)(
          Builder(
            builder: (context) => DsButton(
              onPressed: () => onPressed(context),
              child: const Text('Go'),
            ),
          ),
        ),
      ),
    ),
  );

  group('one at a time', () {
    testWidgets('two toasts in one frame: the first leaves', (tester) async {
      final controllers = <DsToastController>[];
      await tester.pumpWidget(
        app((context) {
          controllers
            ..add(showDsToast(context: context, title: 'First'))
            ..add(showDsToast(context: context, title: 'Second'));
        }),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
      expect(controllers[0].isShowing, isFalse);
      expect(controllers[1].isShowing, isTrue);
      controllers[0].dismiss();
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget, reason: 'a stale dismiss');
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsNothing);
      expect(find.byType(DsToast), findsNothing);
    });

    testWidgets('a replaced toast that already showed leaves too', (
      tester,
    ) async {
      var n = 0;
      await tester.pumpWidget(
        app((context) => showDsToast(context: context, title: 'Toast ${++n}')),
      );
      await tester.tap(find.text('Go'));
      await tester.pump();
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.byType(DsToast), findsOneWidget);
      expect(find.text('Toast 2'), findsOneWidget);
    });

    testWidgets('a toast\'s own close button removes it', (tester) async {
      await tester.pumpWidget(
        app((context) => showDsToast(context: context, title: 'Hi')),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      tester.widget<DsToast>(find.byType(DsToast)).onDismiss!();
      await tester.pumpAndSettle();
      expect(find.byType(DsToast), findsNothing);
    });
  });

  group('timing (WCAG 2.2.1)', () {
    testWidgets('with a screen reader on, a toast with an action stays', (
      tester,
    ) async {
      const media = MediaQueryData(
        size: Size(800, 600),
        accessibleNavigation: true,
      );
      await tester.pumpWidget(
        app((context) {
          showDsToast(
            context: context,
            title: 'Deleted',
            actionLabel: 'Undo',
            onAction: () {},
          );
        }, media: media),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 2));
      await tester.pumpAndSettle();
      expect(find.text('Deleted'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(find.text('Deleted'), findsNothing);
    });

    testWidgets('with a screen reader on, a plain toast still times out', (
      tester,
    ) async {
      const media = MediaQueryData(
        size: Size(800, 600),
        accessibleNavigation: true,
      );
      await tester.pumpWidget(
        app(
          (context) => showDsToast(context: context, title: 'Saved'),
          media: media,
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
      expect(find.text('Saved'), findsNothing);
    });

    testWidgets('F8 moves focus in, which pauses it; Escape dismisses and '
        'focus returns', (tester) async {
      await tester.pumpWidget(
        app(
          (context) => showDsToast(
            context: context,
            title: 'Deleted',
            actionLabel: 'Undo',
            onAction: () {},
            duration: const Duration(seconds: 2),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      final opener = FocusManager.instance.primaryFocus;
      await tester.sendKeyEvent(LogicalKeyboardKey.f8);
      await tester.pump();
      String? focused() =>
          ((FocusManager.instance.primaryFocus?.context
                          ?.findAncestorWidgetOfExactType<DsButton>())
                      ?.child
                  as Text?)
              ?.data;
      expect(focused(), 'Undo');
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      expect(find.text('Deleted'), findsOneWidget, reason: 'paused');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Deleted'), findsNothing);
      expect(FocusManager.instance.primaryFocus, opener);
    });
  });

  testWidgets('stays above the on-screen keyboard', (tester) async {
    const media = MediaQueryData(
      size: Size(390, 844),
      viewInsets: EdgeInsets.only(bottom: 320),
    );
    await tester.pumpWidget(
      app(
        (context) => showDsToast(context: context, title: 'Saved'),
        media: media,
      ),
    );
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byType(DsToast)).bottom,
      lessThanOrEqualTo(844 - 320),
    );
  });

  group('closing', () {
    /// Shows a toast with an Undo action and returns its controller.
    Future<DsToastController> show(
      WidgetTester tester, {
      VoidCallback? onUndo,
    }) async {
      late DsToastController toast;
      await tester.pumpWidget(
        app(
          (context) => toast = showDsToast(
            context: context,
            title: 'Deleted',
            actionLabel: 'Undo',
            onAction: onUndo ?? () {},
            duration: const Duration(seconds: 4),
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      return toast;
    }

    testWidgets('closed completes with the action', (tester) async {
      var undone = 0;
      final toast = await show(tester, onUndo: () => undone++);
      DsToastClosedReason? reason;
      unawaited(toast.closed.then((r) => reason = r));
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(undone, 1);
      expect(reason, DsToastClosedReason.action);
    });

    testWidgets('closed completes with dismissed: close button, Escape, '
        'swipe and dismiss()', (tester) async {
      Future<DsToastClosedReason> close(
        Future<void> Function(DsToastController toast) how,
      ) async {
        final toast = await show(tester);
        await how(toast);
        await tester.pumpAndSettle();
        expect(find.text('Deleted'), findsNothing);
        return toast.closed;
      }

      expect(
        await close(
          (_) => tester.tap(find.bySemanticsLabel('Dismiss notification')),
        ),
        DsToastClosedReason.dismissed,
      );
      expect(
        await close((_) async {
          await tester.sendKeyEvent(LogicalKeyboardKey.f8);
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        }),
        DsToastClosedReason.dismissed,
      );
      expect(
        await close(
          (_) => tester.drag(find.text('Deleted'), const Offset(200, 0)),
        ),
        DsToastClosedReason.dismissed,
      );
      expect(
        await close((toast) async => toast.dismiss()),
        DsToastClosedReason.dismissed,
      );
    });

    testWidgets('closed completes with timeout and with replaced', (
      tester,
    ) async {
      final first = await show(tester);
      DsToastClosedReason? reason;
      unawaited(first.closed.then((r) => reason = r));
      await tester.pump(const Duration(seconds: 3));
      expect(reason, isNull, reason: 'still showing');
      await tester.pump(const Duration(seconds: 2));
      expect(reason, DsToastClosedReason.timeout);
      await tester.pumpAndSettle();

      final second = await show(tester);
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(await second.closed, DsToastClosedReason.replaced);
    });

    testWidgets('a toast already leaving runs no action', (tester) async {
      var undone = 0;
      final toast = await show(tester, onUndo: () => undone++);
      toast.dismiss();
      await tester.pump();
      expect(find.byType(DsToast), findsOneWidget, reason: 'fading out');
      tester.widget<DsToast>(find.byType(DsToast)).onAction!();
      await tester.pumpAndSettle();
      expect(undone, 0);
    });

    testWidgets('actionLabel and onAction come together', (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        app(
          (c) {},
          around: (child) => Builder(
            builder: (c) {
              context = c;
              return child;
            },
          ),
        ),
      );
      expect(
        () => showDsToast(context: context, title: 'Hi', actionLabel: 'Undo'),
        throwsAssertionError,
      );
      expect(
        () => showDsToast(context: context, title: 'Hi', onAction: () {}),
        throwsAssertionError,
      );
    });

    testWidgets('the swipe gives screen readers no scroll action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await show(tester);
      expect(find.text('Deleted'), findsOneWidget);
      for (final action in [
        SemanticsAction.scrollLeft,
        SemanticsAction.scrollRight,
      ]) {
        expect(find.semantics.byAction(action), findsNothing);
      }
      semantics.dispose();
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
    });
  });

  testWidgets('long text scrolls from the keyboard with focus on the action', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        (context) => showDsToast(
          context: context,
          title: 'Sync finished with warnings',
          description: List.filled(40, 'One file was skipped.').join(' '),
          actionLabel: 'Details',
          onAction: () {},
        ),
        media: const MediaQueryData(
          size: Size(360, 300),
          textScaler: TextScaler.linear(2),
        ),
      ),
    );
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.f8);
    await tester.pump();
    ScrollPosition body() => tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(DsToast),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    expect(body().maxScrollExtent, greaterThan(0));
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(body().pixels, body().maxScrollExtent);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.pumpAndSettle();
    expect(body().pixels, lessThan(body().maxScrollExtent));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  });

  group('context', () {
    testWidgets('follows a theme switch while it shows', (tester) async {
      late StateSetter setMode;
      var mode = DsThemeMode.light;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setMode = setState;
            return app(
              (context) => showDsToast(context: context, title: 'Saved'),
              mode: mode,
            );
          },
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      bool dark() => DsTheme.of(tester.element(find.text('Saved'))).isDark;
      expect(dark(), isFalse);
      setMode(() => mode = DsThemeMode.dark);
      await tester.pumpAndSettle();
      expect(dark(), isTrue);
    });

    testWidgets('keeps the opener\'s component theme and strings', (
      tester,
    ) async {
      const red = Color(0xFFFF0000);
      await tester.pumpWidget(
        app(
          (context) => showDsToast(
            context: context,
            title: 'Saved',
            status: DsStatus.danger,
          ),
          around: (child) => DsLocalizationScope(
            localizations: const _Tr(),
            child: DsToastTheme(
              data: const DsToastThemeData(
                style: DsToastStyle(background: red),
              ),
              child: child,
            ),
          ),
        ),
      );
      final semantics = tester.ensureSemantics();
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      final box = tester.widget<DsSurface>(
        find.descendant(
          of: find.byType(DsToast),
          matching: find.byType(DsSurface),
        ),
      );
      expect(box.decoration.color, red);
      expect(find.bySemanticsLabel('Bildirimi kapat'), findsOneWidget);
      expect(find.bySemanticsLabel('Hata'), findsOneWidget);
      semantics.dispose();
      await tester.pump(const Duration(seconds: 30));
      await tester.pumpAndSettle();
    });
  });

  group('buttons', () {
    /// The visible box of the button that holds [part].
    Finder box(Finder part) => find
        .descendant(
          of: find.ancestor(of: part, matching: find.byType(DsButton)).first,
          matching: find.byType(AnimatedContainer),
        )
        .first;

    Widget toast({DsToastStyle? style}) => DsApp(
      // An app-wide button look the toast's own buttons do not take.
      builder: (context, child) => DsButtonTheme(
        data: const DsButtonThemeData(
          style: DsButtonStyle(foreground: Color(0xFFFF0000)),
        ),
        child: child!,
      ),
      home: Center(
        child: DsToast(
          title: 'Moved to trash',
          actionLabel: 'Undo',
          onAction: () {},
          onDismiss: () {},
          style: style,
        ),
      ),
    );

    testWidgets('the action and close buttons take the toast\'s styles', (
      tester,
    ) async {
      const ink = Color(0xFF101010), fill = Color(0xFF123456);
      await tester.pumpWidget(
        toast(
          style: const DsToastStyle(
            actionStyle: DsButtonStyle(foreground: ink),
            closeStyle: DsButtonStyle(background: fill, iconSize: 20),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final undo = tester.renderObject<RenderParagraph>(find.text('Undo'));
      expect(undo.text.style?.color, ink);
      final close = find.byType(DsIcon);
      expect(
        (tester.widget<AnimatedContainer>(box(close)).decoration!
                as DsBoxDecoration)
            .color,
        fill,
      );
      expect(tester.getSize(close).width, 20);
    });

    testWidgets('without them the app\'s button theme does not reach in; '
        'the close icon keeps closeIconSize', (tester) async {
      await tester.pumpWidget(
        toast(style: const DsToastStyle(closeIconSize: 18)),
      );
      await tester.pumpAndSettle();
      final undo = tester.renderObject<RenderParagraph>(find.text('Undo'));
      expect(undo.text.style?.color, isNot(const Color(0xFFFF0000)));
      expect(tester.getSize(find.byType(DsIcon)).width, 18);
    });
  });
}

class _Tr extends DsLocalizationsEn {
  const _Tr();

  @override
  String get dismissNotification => 'Bildirimi kapat';

  @override
  String get error => 'Hata';
}

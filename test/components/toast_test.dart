import 'package:desen_ui/desen_ui.dart';
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
}

class _Tr extends DsLocalizationsEn {
  const _Tr();

  @override
  String get dismissNotification => 'Bildirimi kapat';

  @override
  String get error => 'Hata';
}

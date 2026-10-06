import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Component themes keep the subtree's state when the list of themes
/// changes, rebuild a reader only for its own type, and travel into
/// layers through Flutter's `InheritedTheme.capture`, like [DsTheme].
void main() {
  group('DsComponentThemes', () {
    testWidgets('changing the list keeps the state of the subtree', (
      tester,
    ) async {
      // No key: the counter keeps its state only if it stays in place.
      Widget app({required bool dense}) => DsComponentThemes(
        themes: [
          const DsChipThemeData(style: DsChipStyle(height: 40)),
          if (dense) const DsButtonThemeData(size: DsSize.sm),
        ],
        child: const _Counter(),
      );
      _CounterState counter() => tester.state(find.byType(_Counter));
      await tester.pumpWidget(app(dense: false));
      counter().value = 7;
      await tester.pumpWidget(app(dense: true));
      expect(counter().value, 7);
      await tester.pumpWidget(app(dense: false));
      expect(counter().value, 7);
    });

    testWidgets('each theme merges over an outer one of its type', (
      tester,
    ) async {
      late DsButtonThemeData button;
      late DsChipThemeData chip;
      await tester.pumpWidget(
        DsButtonTheme(
          data: const DsButtonThemeData(variant: DsButtonVariant.ghost),
          child: DsComponentThemes(
            themes: const [
              DsButtonThemeData(size: DsSize.sm),
              DsChipThemeData(style: DsChipStyle(height: 40)),
              // A later theme of the same type merges over an earlier one.
              DsButtonThemeData(size: DsSize.lg),
            ],
            child: Builder(
              builder: (context) {
                button = DsButtonTheme.of(context);
                chip = DsChipTheme.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(button.variant, DsButtonVariant.ghost);
      expect(button.size, DsSize.lg);
      expect(chip.style?.height, 40);
    });

    testWidgets('a single theme below merges over the list', (tester) async {
      late DsButtonThemeData button;
      await tester.pumpWidget(
        DsComponentThemes(
          themes: const [
            DsButtonThemeData(size: DsSize.sm, variant: DsButtonVariant.ghost),
          ],
          child: DsButtonTheme(
            data: const DsButtonThemeData(size: DsSize.lg),
            child: Builder(
              builder: (context) {
                button = DsButtonTheme.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(button.size, DsSize.lg);
      expect(button.variant, DsButtonVariant.ghost);
    });
  });

  testWidgets('a Desen dialog carries a DsComponentThemes list from the '
      'page', (tester) async {
    await tester.pumpWidget(
      DsApp(
        home: Center(
          child: DsComponentThemes(
            themes: const [DsButtonThemeData(size: DsSize.xs)],
            child: Builder(
              builder: (context) => DsButton(
                onPressed: () => showDsConfirm(context: context, title: 'Q'),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(DsButtonTheme.of(tester.element(find.text('Q'))).size, DsSize.xs);
  });

  testWidgets('a reader rebuilds only when its own type changes', (
    tester,
  ) async {
    var builds = 0;
    final reader = Builder(
      builder: (context) {
        builds++;
        DsButtonTheme.of(context);
        return const SizedBox();
      },
    );
    Widget app(double chipHeight, DsSize size) => DsComponentThemes(
      themes: [
        DsChipThemeData(style: DsChipStyle(height: chipHeight)),
        DsButtonThemeData(size: size),
      ],
      child: reader,
    );
    await tester.pumpWidget(app(40, DsSize.sm));
    expect(builds, 1);
    await tester.pumpWidget(app(44, DsSize.sm));
    expect(builds, 1, reason: 'only the chip theme changed');
    await tester.pumpWidget(app(44, DsSize.lg));
    expect(builds, 2);
  });

  group('InheritedTheme.capture', () {
    testWidgets('carries DsTheme and component themes into another tree', (
      tester,
    ) async {
      final theme = DsThemeData(seed: DsSeed.forest);
      late CapturedThemes captured;
      await tester.pumpWidget(
        DsTheme(
          data: theme,
          child: DsComponentThemes(
            themes: const [DsButtonThemeData(size: DsSize.sm)],
            child: DsChipTheme(
              data: const DsChipThemeData(style: DsChipStyle(height: 40)),
              child: Builder(
                builder: (context) {
                  captured = InheritedTheme.capture(from: context, to: null);
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      // A separate tree, as a layer of a navigator above the themes is.
      late DsThemeData seenTheme;
      late DsButtonThemeData seenButton;
      late DsChipThemeData seenChip;
      await tester.pumpWidget(
        captured.wrap(
          Builder(
            builder: (context) {
              seenTheme = DsTheme.of(context);
              seenButton = DsButtonTheme.of(context);
              seenChip = DsChipTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seenTheme, theme);
      expect(seenButton.size, DsSize.sm);
      expect(seenChip.style?.height, 40);
    });

    testWidgets('a page-level theme reaches a plain RawDialogRoute', (
      tester,
    ) async {
      final theme = DsThemeData(seed: DsSeed.forest);
      final navigator = GlobalKey<NavigatorState>();
      late BuildContext opener;
      DsThemeData? inDialog;
      DsButtonThemeData? buttonInDialog;
      await tester.pumpWidget(
        WidgetsApp(
          navigatorKey: navigator,
          color: const Color(0xFF000000),
          builder: (context, child) => child!,
          home: DsTheme(
            data: theme,
            child: DsButtonTheme(
              data: const DsButtonThemeData(size: DsSize.lg),
              child: Builder(
                builder: (context) {
                  opener = context;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );
      final themes = InheritedTheme.capture(
        from: opener,
        to: navigator.currentContext,
      );
      navigator.currentState!.push(
        RawDialogRoute<void>(
          pageBuilder: (context, _, _) => themes.wrap(
            Builder(
              builder: (context) {
                inDialog = DsTheme.of(context);
                buttonInDialog = DsButtonTheme.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(inDialog, theme);
      expect(buttonInDialog?.size, DsSize.lg);
    });
  });
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int value = 0;

  @override
  Widget build(BuildContext context) => const SizedBox();
}

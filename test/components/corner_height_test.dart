import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Controls are rounded by the height they end up with: a style that sets
/// only a height keeps the corners in proportion, a radius set in a style
/// wins, and in the pill style a control stays a capsule at any height.
void main() {
  Widget app(Widget child, {DsThemeData? theme}) => DsApp(
    theme: theme ?? DsThemeData(),
    themeMode: DsThemeMode.light,
    home: Center(
      child: SizedBox(width: 320, child: Center(child: child)),
    ),
  );

  /// The top-left radius of every decoration drawn inside [of], outermost
  /// first.
  List<double> radii(WidgetTester tester, Finder of) => [
    for (final box in tester.widgetList<DecoratedBox>(
      find.descendant(of: of, matching: find.byType(DecoratedBox)),
    ))
      if (box.decoration case DsBoxDecoration(:final borderRadius))
        borderRadius.resolve(TextDirection.ltr).topLeft.x,
  ];

  final standard = DsThemeData();
  final pill = DsThemeData(cornerStyle: DsCornerStyle.pill);

  group('button', () {
    testWidgets('a style height rounds it by that height', (tester) async {
      await tester.pumpWidget(
        app(
          DsButton(
            style: const DsButtonStyle(height: 56),
            onPressed: () {},
            child: const Text('Kaydet'),
          ),
        ),
      );
      final seen = radii(tester, find.byType(DsButton));
      expect(seen, contains(standard.radii.control(56)));
      expect(seen, isNot(contains(standard.radii.control(40))));
    });

    testWidgets('an icon button too', (tester) async {
      await tester.pumpWidget(
        app(
          DsButton.icon(
            style: const DsButtonStyle(height: 56),
            icon: const DsIcon(DsIcons.plus),
            semanticLabel: 'Ekle',
            onPressed: () {},
          ),
        ),
      );
      expect(
        radii(tester, find.byType(DsButton)),
        contains(standard.radii.control(56)),
      );
    });

    testWidgets('a height from the button theme too', (tester) async {
      await tester.pumpWidget(
        app(
          DsButtonTheme(
            data: const DsButtonThemeData(style: DsButtonStyle(height: 56)),
            child: DsButton(onPressed: () {}, child: const Text('Kaydet')),
          ),
        ),
      );
      expect(
        radii(tester, find.byType(DsButton)),
        contains(standard.radii.control(56)),
      );
    });

    testWidgets('a radius set in a style wins', (tester) async {
      await tester.pumpWidget(
        app(
          DsButton(
            style: DsButtonStyle(
              height: 56,
              borderRadius: BorderRadius.circular(3),
            ),
            onPressed: () {},
            child: const Text('Kaydet'),
          ),
        ),
      );
      final seen = radii(tester, find.byType(DsButton));
      expect(seen, contains(3.0));
      expect(seen, isNot(contains(standard.radii.control(56))));
    });

    testWidgets('pill stays a capsule at any height', (tester) async {
      await tester.pumpWidget(
        app(
          theme: pill,
          DsButton(
            style: const DsButtonStyle(height: 56),
            onPressed: () {},
            child: const Text('Kaydet'),
          ),
        ),
      );
      expect(radii(tester, find.byType(DsButton)), contains(56 / 2));
    });
  });

  group('text field', () {
    testWidgets('a style height rounds it by that height', (tester) async {
      await tester.pumpWidget(
        app(const DsTextField(style: DsTextFieldStyle(height: 56))),
      );
      final seen = radii(tester, find.byType(DsTextField));
      expect(seen, contains(standard.radii.control(56)));
      expect(seen, isNot(contains(standard.radii.control(40))));
    });

    testWidgets('a height from the field theme too', (tester) async {
      await tester.pumpWidget(
        app(
          const DsTextFieldTheme(
            data: DsTextFieldThemeData(style: DsTextFieldStyle(height: 56)),
            child: DsTextField(),
          ),
        ),
      );
      expect(
        radii(tester, find.byType(DsTextField)),
        contains(standard.radii.control(56)),
      );
    });

    testWidgets('a radius set in a style wins', (tester) async {
      await tester.pumpWidget(
        app(
          DsTextField(
            style: DsTextFieldStyle(
              height: 56,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      );
      expect(radii(tester, find.byType(DsTextField)), contains(3.0));
    });

    testWidgets('pill stays a capsule at any height', (tester) async {
      await tester.pumpWidget(
        app(
          theme: pill,
          const DsTextField(style: DsTextFieldStyle(height: 56)),
        ),
      );
      expect(radii(tester, find.byType(DsTextField)), contains(56 / 2));
    });
  });

  testWidgets('select: a style height rounds it by that height', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        DsSelect<int>(
          value: 1,
          style: const DsSelectStyle(height: 56),
          options: const [DsSelectOption(value: 1, label: 'Tasarım')],
          onChanged: (_) {},
        ),
      ),
    );
    expect(
      radii(tester, find.byType(DsSelect<int>)),
      contains(standard.radii.control(56)),
    );
  });

  testWidgets('chip: a style height rounds it by that height', (tester) async {
    await tester.pumpWidget(
      app(
        DsChip(
          label: const Text('Tasarım'),
          selected: false,
          style: const DsChipStyle(height: 40),
          onChanged: (_) {},
        ),
      ),
    );
    final seen = radii(tester, find.byType(DsChip));
    expect(seen, contains(standard.radii.control(40)));
    expect(seen, isNot(contains(standard.radii.control(32))));
  });

  group('segmented control', () {
    Widget control({DsSegmentedControlStyle? style}) => DsSegmentedControl<int>(
      value: 0,
      style: style,
      segments: const [
        DsSegment(value: 0, label: Text('Gün')),
        DsSegment(value: 1, label: Text('Hafta')),
      ],
      onChanged: (_) {},
    );

    testWidgets('the channel and the thumb follow the height and inset', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          control(style: const DsSegmentedControlStyle(height: 40, inset: 4)),
        ),
      );
      final channel = standard.radii.control(40 + 2 * 4);
      final seen = radii(tester, find.byType(DsSegmentedControl<int>));
      expect(seen.first, channel);
      expect(seen, contains(standard.radii.nested(channel, 4)));
    });

    testWidgets('the thumb stays concentric with a channel radius set in '
        'a style', (tester) async {
      await tester.pumpWidget(
        app(
          control(
            style: DsSegmentedControlStyle(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      );
      final inset = DsSegmentedControl.defaultStyle(standard).inset!;
      final seen = radii(tester, find.byType(DsSegmentedControl<int>));
      expect(seen.first, 5);
      expect(seen, contains(standard.radii.nested(5, inset)));
    });

    testWidgets('pill stays a capsule at any height', (tester) async {
      await tester.pumpWidget(
        app(
          theme: pill,
          control(style: const DsSegmentedControlStyle(height: 40, inset: 4)),
        ),
      );
      final seen = radii(tester, find.byType(DsSegmentedControl<int>));
      expect(seen.first, (40 + 2 * 4) / 2);
      expect(seen, contains(40 / 2));
    });
  });

  testWidgets('stepper: the track and buttons follow the height and inset', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        DsStepper(
          value: 1,
          style: const DsStepperStyle(height: 40, inset: 4),
          onChanged: (_) {},
        ),
      ),
    );
    final track = standard.radii.control(40 + 2 * 4);
    final seen = radii(tester, find.byType(DsStepper<int>));
    expect(seen.first, track);
    expect(seen, contains(standard.radii.nested(track, 4)));
  });

  group('toolbar', () {
    // Desktop, so the tap areas do not reach past the padding.
    final desktop = DsThemeData(platform: TargetPlatform.macOS);
    final inset = (DsToolbar.defaultStyle(desktop).padding! as EdgeInsets).top;

    Widget toolbar({DsToolbarStyle? style}) => DsToolbar(
      style: style,
      children: [
        DsToolbarToggle(
          icon: const DsIcon(DsIcons.bold),
          semanticLabel: 'Kalın',
          selected: true,
          onChanged: (_) {},
        ),
        DsButton.icon(
          variant: DsButtonVariant.ghost,
          size: DsSize.sm,
          icon: const DsIcon(DsIcons.link),
          semanticLabel: 'Bağlantı',
          onPressed: () {},
        ),
      ],
    );

    double toggleRadius(WidgetTester tester) =>
        radii(tester, find.byType(DsToolbarToggle)).first;

    testWidgets('the bar follows a toggle size set in the toggle theme and '
        'its items stay concentric', (tester) async {
      await tester.pumpWidget(
        app(
          theme: desktop,
          DsToolbarToggleTheme(
            data: const DsToolbarToggleThemeData(
              style: DsToolbarToggleStyle(size: 40),
            ),
            child: toolbar(),
          ),
        ),
      );
      final bar = desktop.radii.control(40 + 2 * inset);
      expect(radii(tester, find.byType(DsToolbar)).first, bar);
      final nested = desktop.radii.nested(bar, inset);
      expect(toggleRadius(tester), nested);
      expect(radii(tester, find.byType(DsButton)), contains(nested));
    });

    testWidgets('by default the bar is rounded by the small size', (
      tester,
    ) async {
      await tester.pumpWidget(app(theme: desktop, toolbar()));
      final size = desktop.sizes.sm;
      final bar = desktop.radii.control(size + 2 * inset);
      expect(radii(tester, find.byType(DsToolbar)).first, bar);
      expect(toggleRadius(tester), desktop.radii.nested(bar, inset));
    });

    testWidgets('the toggles nest in a bar radius set in a style', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          theme: desktop,
          toolbar(
            style: DsToolbarStyle(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
      expect(radii(tester, find.byType(DsToolbar)).first, 16);
      expect(toggleRadius(tester), desktop.radii.nested(16, inset));
    });

    testWidgets('a radius in the toggle theme wins inside the bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          theme: desktop,
          DsToolbarToggleTheme(
            data: DsToolbarToggleThemeData(
              style: DsToolbarToggleStyle(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: toolbar(),
          ),
        ),
      );
      expect(toggleRadius(tester), 3);
    });

    testWidgets('a radius in the button theme wins for toolbar buttons', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          theme: desktop,
          DsButtonTheme(
            data: DsButtonThemeData(
              style: DsButtonStyle(borderRadius: BorderRadius.circular(3)),
            ),
            child: toolbar(),
          ),
        ),
      );
      final buttons = radii(tester, find.byType(DsButton));
      expect(buttons, contains(3.0));
      final bar = radii(tester, find.byType(DsToolbar)).first;
      expect(buttons, isNot(contains(desktop.radii.nested(bar, inset))));
      // The toggles keep the nested corner.
      expect(toggleRadius(tester), desktop.radii.nested(bar, inset));
    });

    testWidgets('a toggle on its own is rounded as a control of its size', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          theme: desktop,
          DsToolbarToggle(
            icon: const DsIcon(DsIcons.bold),
            semanticLabel: 'Kalın',
            selected: false,
            style: const DsToolbarToggleStyle(size: 40),
            onChanged: (_) {},
          ),
        ),
      );
      expect(toggleRadius(tester), desktop.radii.control(40));
    });

    testWidgets('pill: the bar and its toggles stay capsules at any size', (
      tester,
    ) async {
      final pillDesktop = DsThemeData(
        cornerStyle: DsCornerStyle.pill,
        platform: TargetPlatform.macOS,
      );
      await tester.pumpWidget(
        app(
          theme: pillDesktop,
          DsToolbarToggleTheme(
            data: const DsToolbarToggleThemeData(
              style: DsToolbarToggleStyle(size: 40),
            ),
            child: toolbar(),
          ),
        ),
      );
      expect(radii(tester, find.byType(DsToolbar)).first, (40 + 2 * inset) / 2);
      expect(toggleRadius(tester), 40 / 2);
    });
  });

  group('floating bottom nav', () {
    final inset =
        (DsBottomNav.defaultStyle(
                  standard,
                  variant: DsBottomNavVariant.floating,
                ).padding!
                as EdgeInsets)
            .top;

    Widget nav({DsBottomNavItemStyle? itemStyle, DsBottomNavStyle? style}) =>
        DsBottomNav<int>(
          value: 0,
          onChanged: (_) {},
          style: style,
          itemStyle: itemStyle,
          items: const [
            DsBottomNavItem(
              value: 0,
              icon: DsIcon(DsIcons.house),
              label: Text('Ana'),
            ),
            DsBottomNavItem(
              value: 1,
              icon: DsIcon(DsIcons.user),
              label: Text('Profil'),
            ),
          ],
        );

    testWidgets('an item height set in a style rounds the bar by it and '
        'keeps the items concentric', (tester) async {
      await tester.pumpWidget(
        app(nav(itemStyle: const DsBottomNavItemStyle(height: 60))),
      );
      final bar = standard.radii.control(60 + 2 * inset);
      final seen = radii(tester, find.byType(DsBottomNav<int>));
      expect(seen.first, bar);
      expect(seen, contains(standard.radii.nested(bar, inset)));
    });

    testWidgets('an item height from the item theme too', (tester) async {
      await tester.pumpWidget(
        app(
          DsBottomNavItemTheme(
            data: const DsBottomNavItemThemeData(
              style: DsBottomNavItemStyle(height: 60),
            ),
            child: nav(),
          ),
        ),
      );
      expect(
        radii(tester, find.byType(DsBottomNav<int>)).first,
        standard.radii.control(60 + 2 * inset),
      );
    });

    testWidgets('the items nest in a bar radius set in a style', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          nav(style: DsBottomNavStyle(borderRadius: BorderRadius.circular(20))),
        ),
      );
      final seen = radii(tester, find.byType(DsBottomNav<int>));
      expect(seen.first, 20);
      expect(seen, contains(standard.radii.nested(20, inset)));
    });

    testWidgets('pill stays a capsule at any item height', (tester) async {
      await tester.pumpWidget(
        app(
          theme: pill,
          nav(itemStyle: const DsBottomNavItemStyle(height: 60)),
        ),
      );
      final seen = radii(tester, find.byType(DsBottomNav<int>));
      expect(seen.first, (60 + 2 * inset) / 2);
      expect(seen, contains(60 / 2));
    });
  });

  group('multi-select tags', () {
    // Soft corners, where the nested radii stay apart from the minimum.
    final soft = DsThemeData(cornerStyle: DsCornerStyle.soft);
    final defaults = DsAutocomplete.defaultStyle(soft);
    final air = (defaults.tagsPadding! as EdgeInsetsDirectional).top;
    final remove = defaults.tagRemoveStyle!;
    final removeInset = (defaults.tagHeight! - remove.height!) / 2;

    Widget select() => DsMultiSelect<String>(
      value: const ['ank'],
      onChanged: (_) {},
      semanticLabel: 'Şehirler',
      options: const [
        DsSelectOption(value: 'ank', label: 'Ankara'),
        DsSelectOption(value: 'izm', label: 'İzmir'),
      ],
    );

    testWidgets('tags and their remove buttons nest in a field height set '
        'in the field theme', (tester) async {
      await tester.pumpWidget(
        app(
          theme: soft,
          DsTextFieldTheme(
            data: const DsTextFieldThemeData(
              style: DsTextFieldStyle(height: 56),
            ),
            child: select(),
          ),
        ),
      );
      final field = soft.radii.control(56);
      final tag = soft.radii.nested(field, air);
      final seen = radii(tester, find.byType(DsMultiSelect<String>));
      expect(seen, contains(field));
      expect(seen, contains(tag));
      expect(seen, contains(soft.radii.nested(tag, removeInset)));
    });

    testWidgets('by default they nest in the default field', (tester) async {
      await tester.pumpWidget(app(theme: soft, select()));
      final field = soft.radii.control(soft.sizes.md);
      final seen = radii(tester, find.byType(DsMultiSelect<String>));
      expect(seen, contains(soft.radii.nested(field, air)));
    });

    testWidgets('a tag radius set in a style wins, and the remove button '
        'nests in it', (tester) async {
      await tester.pumpWidget(
        app(
          theme: soft,
          DsMultiSelect<String>(
            value: const ['ank'],
            onChanged: (_) {},
            semanticLabel: 'Şehirler',
            style: DsAutocompleteStyle(
              tagBorderRadius: BorderRadius.circular(11),
            ),
            options: const [DsSelectOption(value: 'ank', label: 'Ankara')],
          ),
        ),
      );
      final seen = radii(tester, find.byType(DsMultiSelect<String>));
      expect(seen, contains(11.0));
      expect(seen, contains(soft.radii.nested(11, removeInset)));
    });
  });
}

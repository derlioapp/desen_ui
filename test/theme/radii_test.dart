import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// The corner rules: controls by height, one radius per container kind,
/// nested pieces derived from what holds them, and the checkbox apart.
void main() {
  double r(BorderRadiusGeometry? g) => g!.resolve(TextDirection.ltr).topLeft.x;

  /// The corners a control draws: a radius its style sets, otherwise the
  /// rule at its height (what each control's build applies).
  double drawn(DsThemeData t, BorderRadiusGeometry? set, double height) =>
      r(t.radii.controlCorners(set, height));

  DsThemeData themeFor(DsCornerStyle style) =>
      DsThemeData(cornerStyle: style, platform: TargetPlatform.macOS);

  const factors = {
    DsCornerStyle.sharp: .1,
    DsCornerStyle.standard: .25,
    DsCornerStyle.soft: .375,
    DsCornerStyle.pill: .5,
  };

  group('controls', () {
    test('radius is height times the style factor', () {
      for (final MapEntry(key: style, value: f) in factors.entries) {
        final radii = DsRadii.forStyle(style);
        expect(radii.controlFactor, f, reason: style.name);
        for (final h in [22.0, 28.0, 32.0, 40.0, 48.0, 60.0]) {
          expect(radii.control(h), h * f, reason: '${style.name} at $h');
        }
      }
      expect(DsRadii.standard.control(40), 10, reason: 'the default at 40');
    });

    test('every button size follows its height', () {
      for (final style in DsCornerStyle.values) {
        final t = themeFor(style);
        for (final size in DsSize.values) {
          final s = DsButton.defaultStyle(
            t,
            variant: DsButtonVariant.secondary,
            size: size,
          );
          // Unset, so the height the layers settle on decides.
          expect(s.borderRadius, isNull, reason: '${style.name} ${size.name}');
          expect(
            drawn(t, s.borderRadius, s.height!),
            t.radii.control(s.height!),
            reason: '${style.name} ${size.name}',
          );
        }
      }
    });

    test('control styles leave the radius to the height', () {
      final t = themeFor(DsCornerStyle.standard);
      final seg = DsSegmentedControl.defaultStyle(t);
      final stepper = DsStepper.defaultStyle(t);
      final unset = <String, BorderRadiusGeometry?>{
        'text field': DsTextField.defaultStyle(t).borderRadius,
        'search field': DsTextField.defaultStyle(
          t,
          variant: DsTextFieldVariant.search,
        ).borderRadius,
        'shortcut hint': DsTextField.defaultStyle(
          t,
          variant: DsTextFieldVariant.search,
        ).shortcutBorderRadius,
        'select': DsSelect.defaultStyle(t).borderRadius,
        'chip': DsChip.defaultStyle(t).borderRadius,
        'tooltip': DsTooltip.defaultStyle(t).borderRadius,
        'pagination item': DsPagination.defaultStyle(t).borderRadius,
        'sidebar item': DsSidebarItem.defaultStyle(t).borderRadius,
        'calendar day': DsCalendar.defaultStyle(t).dayRadius,
        'empty-state icon box': DsEmptyState.defaultStyle(t).iconBoxRadius,
        'dialog icon box': DsDialog.defaultStyle(t).iconBoxRadius,
        'segmented channel': seg.borderRadius,
        'segmented thumb': seg.thumbRadius,
        'stepper track': stepper.borderRadius,
        'stepper button': stepper.buttonRadius,
        'bottom bar item': DsBottomNav.defaultItemStyle(
          t,
          variant: DsBottomNavVariant.bar,
        ).borderRadius,
        'floating bottom nav': DsBottomNav.defaultStyle(
          t,
          variant: DsBottomNavVariant.floating,
        ).borderRadius,
        'floating bottom nav item': DsBottomNav.defaultItemStyle(
          t,
          variant: DsBottomNavVariant.floating,
        ).borderRadius,
        'toolbar': DsToolbar.defaultStyle(t).borderRadius,
        'toolbar toggle': DsToolbarToggle.defaultStyle(t).borderRadius,
        'autocomplete tag': DsAutocomplete.defaultStyle(t).tagBorderRadius,
        'tag remove button': DsAutocomplete.defaultStyle(t)
            .tagRemoveStyle!
            .borderRadius,
      };
      for (final MapEntry(key: name, value: radius) in unset.entries) {
        expect(radius, isNull, reason: name);
      }
    });

    test('controlCorners: the rule at the height, or the radius set', () {
      const radii = DsRadii.standard;
      expect(radii.controlCorners(null, 48), BorderRadius.circular(12));
      final set = BorderRadius.circular(3);
      expect(radii.controlCorners(set, 48), same(set));
      final pill = DsRadii.forStyle(DsCornerStyle.pill);
      for (final h in [22.0, 40.0, 56.0]) {
        expect(pill.controlCorners(null, h), BorderRadius.circular(h / 2));
      }
    });

    test('a field and a button of the same height share a radius', () {
      for (final style in DsCornerStyle.values) {
        final t = themeFor(style);
        final button = DsButton.defaultStyle(
          t,
          variant: DsButtonVariant.secondary,
          size: DsSize.md,
        );
        final field = DsTextField.defaultStyle(t);
        final search = DsTextField.defaultStyle(
          t,
          variant: DsTextFieldVariant.search,
        );
        final select = DsSelect.defaultStyle(t);
        expect(field.height, button.height);
        expect(search.height, button.height);
        expect(select.height, button.height);
        final corner = drawn(t, button.borderRadius, button.height!);
        expect(
          drawn(t, field.borderRadius, field.height!),
          corner,
          reason: style.name,
        );
        expect(
          drawn(t, search.borderRadius, search.height!),
          corner,
          reason: style.name,
        );
        expect(
          drawn(t, select.borderRadius, select.height!),
          corner,
          reason: style.name,
        );
      }
    });

    test('in the pill style every control is a capsule', () {
      final t = themeFor(DsCornerStyle.pill);
      void capsule(String name, BorderRadiusGeometry? radius, double height) {
        expect(
          r(radius),
          greaterThanOrEqualTo(height / 2),
          reason: '$name: radius ${r(radius)} on a $height tall box',
        );
      }

      // A control rounded by its height: what it draws.
      void control(String name, BorderRadiusGeometry? set, double height) =>
          capsule(name, t.radii.controlCorners(set, height), height);

      for (final size in DsSize.values) {
        final b = DsButton.defaultStyle(t, variant: .primary, size: size);
        control('button ${size.name}', b.borderRadius, b.height!);
      }
      final field = DsTextField.defaultStyle(t);
      control('text field', field.borderRadius, field.height!);
      final search = DsTextField.defaultStyle(
        t,
        variant: DsTextFieldVariant.search,
      );
      control('search field', search.borderRadius, search.height!);
      final select = DsSelect.defaultStyle(t);
      control('select', select.borderRadius, select.height!);
      final chip = DsChip.defaultStyle(t);
      control('chip', chip.borderRadius, chip.height!);
      final tooltip = DsTooltip.defaultStyle(t);
      control('tooltip', tooltip.borderRadius, tooltip.height!);
      final calendar = DsCalendar.defaultStyle(t);
      control('calendar day', calendar.dayRadius, calendar.daySize!);
      final pages = DsPagination.defaultStyle(t);
      control('pagination item', pages.borderRadius, pages.itemSize!);
      final sidebar = DsSidebarItem.defaultStyle(t);
      control('sidebar item', sidebar.borderRadius, sidebar.height!);
      final empty = DsEmptyState.defaultStyle(t);
      control('empty-state icon box', empty.iconBoxRadius, empty.iconBoxSize!);
      final dialog = DsDialog.defaultStyle(t);
      control('dialog icon box', dialog.iconBoxRadius, dialog.iconBoxSize!);
      final seg = DsSegmentedControl.defaultStyle(t);
      final channel = t.radii.controlCorners(
        seg.borderRadius,
        seg.height! + 2 * seg.inset!,
      );
      capsule('segmented channel', channel, seg.height! + 2 * seg.inset!);
      capsule(
        'segmented thumb',
        t.radii.nestedCorners(seg.thumbRadius, channel, seg.inset!),
        seg.height!,
      );
      final stepper = DsStepper.defaultStyle(t);
      final track = t.radii.controlCorners(
        stepper.borderRadius,
        stepper.height! + 2 * stepper.inset!,
      );
      capsule('stepper track', track, stepper.height! + 2 * stepper.inset!);
      capsule(
        'stepper button',
        t.radii.nestedCorners(stepper.buttonRadius, track, stepper.inset!),
        stepper.height!,
      );
      // Bars of controls and what nests in them, as their builds round
      // them: the bar by its items and padding, the items nested in it.
      final toggle = DsToolbarToggle.defaultStyle(t);
      final bar = DsToolbar.defaultStyle(t);
      final barInset = (bar.padding! as EdgeInsets).top;
      final barCorners = t.radii.controlCorners(
        bar.borderRadius,
        toggle.size! + 2 * barInset,
      );
      capsule('toolbar', barCorners, toggle.size! + 2 * barInset);
      capsule(
        'toolbar toggle',
        t.radii.nestedCorners(toggle.borderRadius, barCorners, barInset),
        toggle.size!,
      );
      control('lone toolbar toggle', toggle.borderRadius, toggle.size!);
      final nav = DsBottomNav.defaultStyle(
        t,
        variant: DsBottomNavVariant.floating,
      );
      final navItem = DsBottomNav.defaultItemStyle(
        t,
        variant: DsBottomNavVariant.floating,
      );
      final navInset = (nav.padding! as EdgeInsets).top;
      final navCorners = t.radii.controlCorners(
        nav.borderRadius,
        navItem.height! + 2 * navInset,
      );
      capsule('bottom nav', navCorners, navItem.height! + 2 * navInset);
      capsule(
        'bottom nav item',
        t.radii.nestedCorners(navItem.borderRadius, navCorners, navInset),
        navItem.height!,
      );
      final barItem = DsBottomNav.defaultItemStyle(
        t,
        variant: DsBottomNavVariant.bar,
      );
      control('bottom bar item', barItem.borderRadius, barItem.height!);
      final tags = DsAutocomplete.defaultStyle(t);
      final tagCorners = t.radii.nestedCorners(
        tags.tagBorderRadius,
        t.radii.controlCorners(field.borderRadius, field.height!),
        (tags.tagsPadding! as EdgeInsetsDirectional).top,
      );
      capsule('autocomplete tag', tagCorners, tags.tagHeight!);
      final remove = tags.tagRemoveStyle!;
      capsule(
        'tag remove button',
        t.radii.nestedCorners(
          remove.borderRadius,
          tagCorners,
          (tags.tagHeight! - remove.height!) / 2,
        ),
        remove.height!,
      );
    });
  });

  group('containers', () {
    test('one radius per style; pill keeps the standard one', () {
      const cards = {
        DsCornerStyle.sharp: 4.0,
        DsCornerStyle.standard: 14.0,
        DsCornerStyle.soft: 21.0,
        DsCornerStyle.pill: 14.0,
      };
      for (final MapEntry(key: style, value: card) in cards.entries) {
        final radii = DsRadii.forStyle(style);
        expect(radii.card, card, reason: style.name);
        expect(radii.overlay, card, reason: style.name);
      }
    });

    test('cards and floating layers read their token', () {
      for (final style in DsCornerStyle.values) {
        final t = themeFor(style);
        expect(r(DsCard.defaultStyle(t).borderRadius), t.radii.card);
        expect(r(DsListSection.defaultStyle(t).borderRadius), t.radii.card);
        expect(r(DsMenu.defaultStyle(t).borderRadius), t.radii.overlay);
        expect(r(DsPopover.defaultStyle(t).borderRadius), t.radii.overlay);
        expect(r(DsDialog.defaultStyle(t).borderRadius), t.radii.overlay);
        expect(r(DsPanel.defaultStyle(t).borderRadius), t.radii.overlay);
        expect(r(DsToast.defaultStyle(t).borderRadius), t.radii.overlay);
      }
    });
  });

  group('nested pieces', () {
    test('outer less inset, never below the floor nor above the outer', () {
      const radii = DsRadii.standard;
      expect(radii.nestedMin, 4);
      expect(radii.nested(14, 6), 8);
      expect(radii.nested(14, 5), 9);
      expect(radii.nested(14, 16), 4, reason: 'the floor');
      expect(radii.nested(2, 1), 2, reason: 'never rounder than the outer');
      expect(
        radii.nested(0, 4),
        0,
        reason: 'a square box keeps square insides',
      );
    });

    test('nestedCorners: each outer corner less the inset', () {
      const radii = DsRadii.standard;
      final set = BorderRadius.circular(2);
      expect(radii.nestedCorners(set, BorderRadius.circular(14), 6), same(set));
      expect(
        radii.nestedCorners(null, BorderRadius.circular(14), 6),
        BorderRadius.circular(8),
      );
      expect(
        radii.nestedCorners(
          null,
          const BorderRadius.only(topLeft: Radius.circular(14)),
          6,
        ),
        const BorderRadius.only(topLeft: Radius.circular(8)),
        reason: 'a square corner stays square',
      );
      expect(
        radii.nestedCorners(
          null,
          const BorderRadius.all(Radius.elliptical(20, 10)),
          4,
        ),
        const BorderRadius.all(Radius.elliptical(16, 6)),
      );
      expect(
        radii.nestedCorners(
          null,
          const BorderRadiusDirectional.horizontal(start: Radius.circular(14)),
          6,
        ),
        const BorderRadiusDirectional.horizontal(start: Radius.circular(8)),
        reason: 'directional corners stay directional',
      );
    });

    test('a piece nested in a capsule is a capsule', () {
      final radii = DsRadii.forStyle(DsCornerStyle.pill);
      for (final (outer, inset) in [(38.0, 3.0), (42.0, 5.0), (60.0, 5.0)]) {
        expect(
          radii.nested(radii.control(outer), inset),
          (outer - 2 * inset) / 2,
        );
      }
    });

    test('components derive their inner radii from the outer one', () {
      for (final style in DsCornerStyle.values) {
        final t = themeFor(style);
        final seg = DsSegmentedControl.defaultStyle(t);
        final channel = t.radii.controlCorners(
          seg.borderRadius,
          seg.height! + 2 * seg.inset!,
        );
        expect(
          r(t.radii.nestedCorners(seg.thumbRadius, channel, seg.inset!)),
          t.radii.nested(r(channel), seg.inset!),
          reason: '${style.name} segmented',
        );
        final stepper = DsStepper.defaultStyle(t);
        final track = t.radii.controlCorners(
          stepper.borderRadius,
          stepper.height! + 2 * stepper.inset!,
        );
        expect(
          r(t.radii.nestedCorners(stepper.buttonRadius, track, stepper.inset!)),
          t.radii.nested(r(track), stepper.inset!),
          reason: '${style.name} stepper',
        );
        final menu = DsMenu.defaultStyle(t);
        expect(
          r(DsMenuItem.defaultStyle(t).borderRadius),
          t.radii.nested(
            r(menu.borderRadius),
            (menu.padding! as EdgeInsets).top,
          ),
          reason: '${style.name} menu row',
        );
        final section = DsListSection.defaultStyle(t);
        expect(
          r(DsListRow.defaultStyle(t).borderRadius),
          t.radii.nested(
            r(section.borderRadius),
            (section.padding! as EdgeInsets).top,
          ),
          reason: '${style.name} list row',
        );
      }
    });
  });

  group('checkbox', () {
    test('rounds by its size and never becomes a circle', () {
      for (final style in DsCornerStyle.values) {
        final radii = DsRadii.forStyle(style);
        for (final size in [14.0, 18.0, 24.0]) {
          expect(
            radii.checkbox(size),
            lessThanOrEqualTo(size * DsRadii.maxCheckboxFactor),
            reason: '${style.name} at $size',
          );
          expect(radii.checkbox(size), lessThan(size / 2));
        }
      }
      expect(DsRadii.standard.checkbox(18), closeTo(18 * .28, 1e-9));
      // Even a factor asked for as a circle stays a rounded square.
      final round = DsRadii.standard.copyWith(checkboxFactor: .5);
      expect(round.checkbox(18), 18 / 3);
    });

    test('the checkbox reads its radius from its size', () {
      final t = themeFor(DsCornerStyle.pill);
      final s = DsCheckbox.defaultStyle(t);
      expect(r(s.borderRadius), t.radii.checkbox(s.size!));
      expect(r(s.borderRadius), lessThan(s.size! / 2));
    });
  });

  group('customizing', () {
    test('adjustRadii changes the factor for every control', () {
      final t = DsThemeData(
        adjustRadii: (r, style) => r.copyWith(controlFactor: .3),
      );
      final b = DsButton.defaultStyle(t, variant: .primary, size: DsSize.lg);
      expect(drawn(t, b.borderRadius, b.height!), 48 * .3);
      final field = DsTextField.defaultStyle(t);
      expect(drawn(t, field.borderRadius, field.height!), 40 * .3);
    });

    test('lerp, copyWith and equality', () {
      final a = DsRadii.forStyle(DsCornerStyle.standard);
      final b = DsRadii.forStyle(DsCornerStyle.pill);
      expect(DsRadii.lerp(a, b, 0), a);
      expect(DsRadii.lerp(a, b, 1), b);
      expect(DsRadii.lerp(a, b, .5).controlFactor, .375);
      expect(a.copyWith(card: 20).card, 20);
      expect(a.copyWith(), a);
      expect(a == b, isFalse);
    });
  });
}

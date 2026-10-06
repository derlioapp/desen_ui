import 'dart:ui' show Brightness, Color;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart' hide Color;
import 'package:flutter_test/flutter_test.dart';

import '../components/helpers.dart';

/// Every token class compares every field (`DsShadows ==` used to
/// skip `surfaceRaised`, so a theme change to the hovered-card shadow was
/// missed). Each field is changed alone through `copyWith`; the copy must
/// differ, and the hash too.
///
/// `copyWith` is called through [Function.apply] with the field name, so a
/// new field only needs its name added here.
void expectEveryFieldCounts<T extends Object>(
  T base,
  Function copyWith,
  Map<String, Object> changes,
) {
  for (final MapEntry(key: name, value: value) in changes.entries) {
    final changed =
        Function.apply(copyWith, const [], {Symbol(name): value}) as T;
    expect(changed == base, isFalse, reason: '$T.$name is not compared');
    expect(
      changed.hashCode == base.hashCode,
      isFalse,
      reason: '$T.$name is not hashed',
    );
  }
}

void main() {
  test('DsShadows compares every stack', () {
    final s = DsThemeData().shadows;
    const odd = [DsShadow(color: Color(0xFFFF0000), blur: 40)];
    expectEveryFieldCounts(s, s.copyWith, {
      for (final name in [
        'surface', 'surfaceRaised', 'control', 'controlLift', //
        'fieldError', 'accent', 'danger', 'overlay', 'sidebarEdge', //
        'channel', 'channelThumb', 'knob', 'knobOn', 'tooltip', //
        'focusOffset', 'focusTight',
      ])
        name: odd,
    });
  });

  test('a theme differing only in the hovered-card shadow differs', () {
    final a = DsThemeData();
    final b = DsThemeData(
      adjustShadows: (s, k, br) => s.copyWith(
        surfaceRaised: const [DsShadow(color: Color(0xFFFF0000), blur: 40)],
      ),
    );
    expect(a == b, isFalse);
  });

  testWidgets('a hovered card picks up a new raised shadow', (tester) async {
    final base = DsThemeData();
    final red = [const DsShadow(color: Color(0xFFFF0000), blur: 40)];
    Widget app(DsThemeData theme) => Directionality(
      textDirection: TextDirection.ltr,
      child: DsTheme(
        data: theme,
        child: Center(
          child: DsCard(
            onPressed: () {},
            child: const SizedBox(width: 100, height: 60),
          ),
        ),
      ),
    );
    useTraditionalHighlights();
    await tester.pumpWidget(app(base));
    await hover(tester, find.byType(DsCard));
    await tester.pumpWidget(
      app(
        base.copyWith(
          adjustShadows: () =>
              (s, k, b) => s.copyWith(surfaceRaised: red),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final painted =
        tester
                .widget<AnimatedContainer>(
                  find.descendant(
                    of: find.byType(DsCard),
                    matching: find.byType(AnimatedContainer),
                  ),
                )
                .decoration!
            as DsBoxDecoration;
    expect(painted.shadows, red);
  });

  test('DsColors compares every role', () {
    final k = DsThemeData().colors;
    const odd = Color(0xFF123457);
    final status = k.danger.copyWith(fill: odd);
    expectEveryFieldCounts(k, k.copyWith, {
      for (final name in k.toMap().keys)
        if (!name.contains('.')) name: odd,
      for (final name in ['neutral', 'danger', 'success', 'warning', 'info'])
        name: status,
    });
  });

  test('DsStatusColors compares every field', () {
    final st = DsThemeData().colors.info;
    expectEveryFieldCounts(st, st.copyWith, {
      for (final name in [
        'fill', 'fillHover', 'onFill', 'tint', 'tintHover', 'text', //
      ])
        name: const Color(0xFF123457),
    });
  });

  test('DsRadii compares every value', () {
    const r = DsRadii.standard;
    expectEveryFieldCounts(r, r.copyWith, {
      for (final name in [
        'controlFactor', 'card', 'overlay', 'checkboxFactor', 'nestedMin', //
      ])
        name: 33.0,
    });
  });

  test('DsSizes compares every size', () {
    const s = DsSizes.compact;
    expectEveryFieldCounts(s, s.copyWith, {
      for (final name in [
        'xs', 'sm', 'md', 'lg', 'row', 'listRow', 'day', 'minTapTarget', //
        'iconXs', 'iconSm', 'iconMd', 'iconLg',
      ])
        name: 99.0,
    });
  });

  test('DsMotion compares every rule', () {
    const m = DsMotion();
    expectEveryFieldCounts(m, m.copyWith, {
      'toneSpring': const DsSpring(duration: Duration(milliseconds: 77)),
      'moveSpring': const DsSpring(duration: Duration(milliseconds: 77)),
      'pressScale': .5,
      'pressScaleLarge': .5,
      'overlayOffset': 77.0,
      'overlayScale': .5,
      'exitFactor': .5,
      'shimmer': const Duration(milliseconds: 77),
      'spinner': const Duration(milliseconds: 77),
      'indeterminate': const Duration(milliseconds: 77),
      'sweepCurve': Curves.linear,
      'hoverDelay': const Duration(milliseconds: 77),
      'hoverGrace': const Duration(milliseconds: 77),
      'toastDuration': const Duration(milliseconds: 77),
      'reduced': true,
    });
  });

  test('DsTypography compares every role', () {
    final t = DsTypography();
    expectEveryFieldCounts(t, t.copyWith, {
      for (final name in [
        'display', 'title', 'heading', 'body', 'bodyStrong', 'small', //
        'label', 'labelStrong', 'caption', 'fieldLabel', 'overline',
      ])
        name: const TextStyle(fontSize: 77),
    });
  });

  test('DsThemeData compares every setting and token group', () {
    final t = DsThemeData(density: DsDensity.compact);
    expectEveryFieldCounts(t, t.copyWith, {
      'brightness': Brightness.dark,
      'seed': DsSeed.forest,
      'contrast': DsContrast.soft,
      'cornerStyle': DsCornerStyle.pill,
      'density': DsDensity.touch,
      'platform': TargetPlatform.iOS,
      'selectionStyle': DsSelectionStyle.strong,
      'autoClashRule': false,
      'dangerOverride': () => const Color(0xFF123457),
      'successOverride': () => const Color(0xFF123457),
      'warningOverride': () => const Color(0xFF123457),
      'typography': DsTypography(family: 'Other'),
      'motion': const DsMotion(reduced: true),
    });
  });

  // Hooks are compared by what they produce, not by identity.
  test('DsThemeData compares hook results, not hook identity', () {
    DsThemeData make(double card) =>
        DsThemeData(adjustRadii: (r, _) => r.copyWith(card: card));
    expect(make(20), make(20));
    expect(make(20) == make(21), isFalse);
  });
}

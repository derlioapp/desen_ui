import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// At touch density the type ramp grows (body 16) while controls keep
/// their heights: the larger labels fit, stay on one line and sit in the
/// vertical middle of their controls, at phone width.
void main() {
  final touch = DsThemeData(
    density: DsDensity.touch,
    platform: TargetPlatform.iOS,
  );

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        SizedBox(width: 358, child: Center(child: child)),
        theme: touch,
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The paragraph that draws [text].
  RenderParagraph paragraph(WidgetTester tester, String text) =>
      tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text(text), matching: find.byType(RichText)),
      );

  /// Checks that [text] is on one line, unclipped, centered vertically in
  /// [control] (within a pixel).
  void expectCentered(WidgetTester tester, String text, Finder control) {
    expect(tester.takeException(), isNull, reason: text);
    final p = paragraph(tester, text);
    expect(p.didExceedMaxLines, isFalse, reason: text);
    expect(p.size.height, lessThan(p.text.style!.fontSize! * 2), reason: text);
    final box = tester.getRect(control);
    final label = tester.getRect(find.text(text));
    expect(label.height, lessThanOrEqualTo(box.height), reason: text);
    expect(label.center.dy, closeTo(box.center.dy, 1), reason: text);
  }

  test('the theme sets the touch ramp', () {
    expect(touch.typography.body.fontSize, 16);
    expect(touch.typography.label.fontSize, 15);
  });

  testWidgets('buttons: every size keeps its height and centers its label', (
    tester,
  ) async {
    await pump(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in DsSize.values)
            DsButton(
              size: s,
              onPressed: () {},
              child: Text('Kaydet ${s.name}'),
            ),
        ],
      ),
    );
    for (final (i, s) in DsSize.values.indexed) {
      expect(buttonBoxSize(tester, i).height, touch.sizes.height(s));
      final box = find
          .descendant(
            of: find.byType(DsButton),
            matching: find.byType(AnimatedContainer),
          )
          .at(i);
      expectCentered(tester, 'Kaydet ${s.name}', box);
      expect(
        paragraph(tester, 'Kaydet ${s.name}').text.style?.fontSize,
        touch.typography.controlLabel(s).fontSize,
      );
    }
  });

  testWidgets('chip, badge and segmented control', (tester) async {
    await pump(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          DsChip(
            label: const Text('Tasarım'),
            selected: false,
            onChanged: (_) {},
          ),
          const DsBadge(status: DsStatus.warning, label: Text('Taslak')),
          DsSegmentedControl<int>(
            value: 0,
            segments: const [
              DsSegment(value: 0, label: Text('Gün')),
              DsSegment(value: 1, label: Text('Hafta')),
            ],
            onChanged: (_) {},
          ),
        ],
      ),
    );
    expectCentered(tester, 'Tasarım', find.byType(DsChip));
    expectCentered(tester, 'Taslak', find.byType(DsBadge));
    expectCentered(tester, 'Hafta', find.byType(DsSegmentedControl<int>));
  });

  testWidgets('text field and select keep their height for body 16', (
    tester,
  ) async {
    await pump(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          const DsTextField(placeholder: 'E-posta adresi'),
          DsSelect<int>(
            value: 1,
            options: const [DsSelectOption(value: 1, label: 'Tasarım ekibi')],
            onChanged: (_) {},
          ),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(DsSelect<int>)).height, touch.sizes.md);
    expectCentered(tester, 'E-posta adresi', find.byType(DsTextField));
    expectCentered(tester, 'Tasarım ekibi', find.byType(DsSelect<int>));
    expect(
      paragraph(tester, 'Tasarım ekibi').text.style?.fontSize,
      touch.typography.body.fontSize,
    );
  });

  testWidgets('menu and list rows grow with the density, labels centered', (
    tester,
  ) async {
    await pump(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          DsMenu(
            children: [
              DsMenuItem(
                label: const Text('Yeniden adlandır'),
                onPressed: () {},
              ),
            ],
          ),
          DsListSection(
            children: [
              DsListRow(
                title: const Text('Bildirimler'),
                showChevron: true,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
    expectCentered(tester, 'Yeniden adlandır', find.byType(DsMenuItem));
    expect(tester.getSize(find.byType(DsMenuItem)).height, touch.sizes.row);
    expectCentered(tester, 'Bildirimler', find.byType(DsListRow));
    expect(tester.getSize(find.byType(DsListRow)).height, touch.sizes.listRow);
  });

  testWidgets('checkbox and switch labels with descriptions do not overflow', (
    tester,
  ) async {
    await pump(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          DsCheckbox(
            value: true,
            onChanged: (_) {},
            label: const Text('Haftalık özet'),
            description: const Text('Her pazartesi sabahı e-posta ile'),
          ),
          DsSwitch(
            value: false,
            onChanged: (_) {},
            label: const Text('Bildirimler'),
          ),
        ],
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      paragraph(tester, 'Haftalık özet').text.style?.fontSize,
      touch.typography.body.fontSize,
    );
    expect(
      paragraph(
        tester,
        'Her pazartesi sabahı e-posta ile',
      ).text.style?.fontSize,
      touch.typography.label.fontSize,
    );
  });

  testWidgets('compact keeps the 14px body in the same controls', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(
        DsButton(onPressed: () {}, child: const Text('Kaydet')),
        theme: DsThemeData(platform: TargetPlatform.macOS),
      ),
    );
    expect(paragraph(tester, 'Kaydet').text.style?.fontSize, 14);
  });
}

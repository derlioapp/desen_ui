import 'dart:ui' as ui;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// An icon beside a label sits on the label's optical center: the middle
/// of its letters' ink ("Save": cap height to baseline), within a pixel, in
/// every component that pairs them, at the pointer and touch densities and
/// with large text.
void main() {
  const icon = DsIcon(DsIcons.circle);
  const label = 'Save';
  Finder circle() => find.byWidgetPredicate(
    (w) => w is DsIcon && identical(w.icon, DsIcons.circle),
  );

  /// The label's ink center in global coordinates, from a 4x shot of
  /// [shot]: the first run of inked rows over the label's glyphs (an
  /// underline below them is left out).
  Future<double> inkCenter(WidgetTester tester, GlobalKey shot) async {
    final text = find.textContaining(label, findRichText: true).first;
    final ro = tester.renderObject(text);
    final RenderBox box;
    final InlineSpan span;
    List<TextBox> Function(TextSelection) boxesFor;
    if (ro is RenderParagraph) {
      (box, span, boxesFor) = (ro, ro.text, ro.getBoxesForSelection);
    } else {
      final editable = tester.renderObject<RenderEditable>(
        find.byWidgetPredicate((w) => w.runtimeType.toString() == '_Editable'),
      );
      (box, span, boxesFor) = (
        editable,
        editable.text!,
        editable.getBoxesForSelection,
      );
    }
    final at = span.toPlainText().indexOf(label);
    final glyphs = boxesFor(
      TextSelection(baseOffset: at, extentOffset: at + label.length),
    ).first.toRect().shift(box.localToGlobal(Offset.zero));

    const ratio = 4.0;
    final boundary =
        shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final (width, bytes) = (await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: ratio);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return (image.width, data!);
    }))!;
    int lum(int x, int y) {
      final c = bytes.getUint32((y * width + x) * 4);
      return ((c >> 24) & 255) + ((c >> 16) & 255) + ((c >> 8) & 255);
    }

    final left = ((glyphs.left + 1) * ratio).round();
    final right = ((glyphs.right - 1) * ratio).round();
    final top = ((glyphs.top - 3) * ratio).round();
    final bottom = ((glyphs.bottom + 3) * ratio).round();
    final background = lum(left, top);
    bool inked(int y) {
      for (var x = left; x <= right; x++) {
        if ((lum(x, y) - background).abs() > 120) return true;
      }
      return false;
    }

    final rows = [
      for (var y = top; y <= bottom; y++)
        if (inked(y)) y,
    ];
    final first = rows.first;
    var last = first;
    for (final y in rows.skip(1)) {
      if (y > last + 1) break;
      last = y;
    }
    return (first + last + 1) / 2 / ratio;
  }

  final cases = <String, Widget Function()>{
    for (final size in DsSize.values)
      'button ${size.name}': () => Center(
        child: DsButton(
          size: size,
          onPressed: () {},
          leading: icon,
          child: const Text(label),
        ),
      ),
    'button trailing': () => Center(
      child: DsButton(
        onPressed: () {},
        trailing: icon,
        child: const Text(label),
      ),
    ),
    'menu item': () => DsMenu(
      children: [
        DsMenuItem(label: const Text(label), leading: icon, onPressed: () {}),
      ],
    ),
    'sidebar item': () => DsSidebar<int>(
      value: 0,
      onChanged: (_) {},
      children: const [
        DsSidebarItem(value: 0, label: Text(label), leading: icon),
      ],
    ),
    'chip': () => DsChip(
      label: const Text(label),
      selected: false,
      onChanged: (_) {},
      leading: icon,
    ),
    'list row': () => const DsListRow(title: Text(label), leading: icon),
    'segment': () => DsSegmentedControl<int>(
      value: 1,
      onChanged: (_) {},
      segments: const [
        DsSegment(value: 0, label: Text(label), icon: icon),
        DsSegment(value: 1, label: Text('Other')),
      ],
    ),
    'select': () => DsSelect<int>(
      value: 0,
      onChanged: (_) {},
      leading: icon,
      options: const [DsSelectOption(value: 0, label: label)],
    ),
    'badge': () => const DsBadge(label: Text(label), icon: icon),
    'alert': () => const DsAlert(title: Text(label), icon: icon),
    'breadcrumb': () => DsBreadcrumb(
      items: [
        DsBreadcrumbItem(label: label, icon: icon, onPressed: () {}),
        const DsBreadcrumbItem(label: 'Other'),
      ],
    ),
    'external link': () =>
        DsLink(label: label, external: true, onPressed: () {}),
    'text field': () => const DsTextField(initialValue: label, leading: icon),
    'toast': () => const DsToast(title: label, status: DsStatus.success),
  };

  for (final (platform, scale) in [
    (TargetPlatform.macOS, 1.0),
    (TargetPlatform.macOS, 1.5),
    (TargetPlatform.macOS, 2.0),
    (TargetPlatform.iOS, 1.0),
    (TargetPlatform.iOS, 1.5),
  ]) {
    testWidgets('${platform.name}, text scale $scale', (tester) async {
      final off = <String>[];
      for (final MapEntry(key: name, value: build) in cases.entries) {
        final shot = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: shot,
            child: DsApp(
              theme: DsThemeData(platform: platform),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(width: 320, child: build()),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final iconFinder = switch (name) {
          'external link' || 'toast' => find.byType(DsIcon).first,
          _ => circle(),
        };
        final center = tester.getRect(iconFinder).center.dy;
        final delta = center - await inkCenter(tester, shot);
        if (delta.abs() >= 1) off.add('$name ${delta.toStringAsFixed(2)}');
      }
      expect(off, isEmpty);
    });
  }
}

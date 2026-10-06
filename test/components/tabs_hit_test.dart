import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// A tab answers across its whole cell: its label and half the gap on each
/// side, with the smallest tap target honored on touch platforms; the
/// layout of ordinary tabs does not change.
void main() {
  Widget tabs({
    required ValueChanged<int> onChanged,
    TargetPlatform platform = TargetPlatform.iOS,
  }) => host(
    theme: DsThemeData(platform: platform),
    SizedBox(
      width: 400,
      child: DsTabs<int>(
        value: 0,
        onChanged: onChanged,
        tabs: const [
          DsTab(value: 0, label: Text('All')),
          // A one-letter label: narrower than a touch target with its gap.
          DsTab(value: 1, label: Text('M')),
          DsTab(value: 2, label: Text('Done')),
        ],
      ),
    ),
  );

  /// The tab's own box (its label, widened when too short).
  Rect box(WidgetTester tester, String label) => tester.getRect(
    find
        .ancestor(of: find.text(label), matching: find.byType(GestureDetector))
        .first,
  );

  for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
    testWidgets('the gaps belong to the nearer tab (${platform.name})', (
      tester,
    ) async {
      int? got;
      await tester.pumpWidget(
        tabs(platform: platform, onChanged: (v) => got = v),
      );
      await tester.pumpAndSettle();
      final all = box(tester, 'All');
      final m = box(tester, 'M');
      final done = box(tester, 'Done');
      final leftMid = (all.right + m.left) / 2;
      final rightMid = (m.right + done.left) / 2;
      expect(m.left - all.right, greaterThan(4), reason: 'there is a gap');

      Future<int?> tapAt(Offset at) async {
        got = null;
        await tester.tapAt(at);
        await tester.pump(const Duration(milliseconds: 300));
        return got;
      }

      final y = m.center.dy;
      // In the gap, on this side of its middle: "M".
      expect(await tapAt(Offset(m.left - 1, y)), 1);
      expect(await tapAt(Offset(leftMid + 1, y)), 1);
      expect(await tapAt(Offset(m.right + 1, y)), 1);
      expect(await tapAt(Offset(rightMid - 1, y)), 1);
      // Past the middle: the neighbor. "All" is selected already, so it
      // reports nothing; "Done" reports 2.
      expect(await tapAt(Offset(leftMid - 1, y)), isNull);
      expect(await tapAt(Offset(rightMid + 1, y)), 2);
      // Near the top of the bar, above the label: "M".
      expect(await tapAt(Offset(m.center.dx, m.top + 1)), 1);
    });
  }

  testWidgets('on touch a tab cell is at least the smallest tap target', (
    tester,
  ) async {
    await tester.pumpWidget(tabs(onChanged: (_) {}));
    await tester.pumpAndSettle();
    final all = box(tester, 'All');
    final m = box(tester, 'M');
    final done = box(tester, 'Done');
    final cell = (m.right + done.left) / 2 - (all.right + m.left) / 2;
    expect(cell, greaterThanOrEqualTo(44));
    expect(m.height, greaterThanOrEqualTo(44));
    // The short label sits centered in its widened box.
    expect(tester.getCenter(find.text('M')).dx, moreOrLessEquals(m.center.dx));
  });

  testWidgets('ordinary tabs keep their width (no layout change)', (
    tester,
  ) async {
    for (final platform in [TargetPlatform.iOS, TargetPlatform.macOS]) {
      await tester.pumpWidget(tabs(platform: platform, onChanged: (_) {}));
      await tester.pumpAndSettle();
      expect(
        box(tester, 'Done').width,
        moreOrLessEquals(tester.getSize(find.text('Done')).width),
        reason: platform.name,
      );
    }
    // On a pointer platform even a one-letter tab keeps its width.
    expect(
      box(tester, 'M').width,
      moreOrLessEquals(tester.getSize(find.text('M')).width),
    );
  });
}

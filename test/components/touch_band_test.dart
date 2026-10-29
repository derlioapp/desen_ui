import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui/src/behavior/tap_band.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// On touch platforms a table's sort headers answer across the header row
/// without growing their layout, and [TapBand] takes taps around a box. A
/// band reaches as far as the parent's bounds, so each control here sits
/// directly in a box with room around it (padding, a column). Controls that
/// take a tap target's room instead: `touch_target_test.dart`.
void main() {
  final ios = DsThemeData(platform: TargetPlatform.iOS);

  /// [child] with room around it, as on a page.
  Widget page(Widget child) => host(
    theme: ios,
    Padding(padding: const EdgeInsets.all(40), child: child),
  );

  testWidgets('a sort header answers across the header row', (tester) async {
    DsTableSort? sort;
    await tester.pumpWidget(
      page(
        SizedBox(
          width: 360,
          height: 240,
          child: StatefulBuilder(
            builder: (context, setState) => DsTable<int>(
              rows: const [1, 2, 3],
              rowKey: (r) => r,
              sort: sort,
              onSortChanged: (s) => setState(() => sort = s),
              columns: [
                DsTableColumn<int>(
                  id: 'n',
                  label: 'Number',
                  value: (r) => r,
                  sortable: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final header = find.ancestor(
      of: find.text('Number'),
      matching: find.byType(DsPressable),
    );
    final button = tester.getRect(header);
    final sizes = DsTheme.sizesOf(tester.element(header));
    expect(button.height, greaterThanOrEqualTo(sizes.minTapTarget));
    // Near the top of the row, above the label: sorts.
    await tester.tapAt(Offset(button.center.dx, button.top + 1));
    await tester.pumpAndSettle();
    expect(sort?.columnId, 'n');
  });

  testWidgets('the label of a sort header stays where it was', (tester) async {
    // The padding moved inside the button: the label keeps its place,
    // centered on the header row.
    await tester.pumpWidget(
      page(
        SizedBox(
          width: 360,
          height: 240,
          child: DsTable<int>(
            rows: const [1],
            rowKey: (r) => r,
            onSortChanged: (_) {},
            columns: [
              DsTableColumn<int>(
                id: 'n',
                label: 'Number',
                value: (r) => r,
                sortable: true,
              ),
              DsTableColumn<int>(id: 'm', label: 'Plain', value: (r) => r),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.text('Number')).dy,
      moreOrLessEquals(tester.getCenter(find.text('Plain')).dy),
    );
  });

  testWidgets('TapBand: followTap lands on the nearest point; outset '
      'reaches past the edges', (tester) async {
    final taps = <String>[];
    Widget cell(String name) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => taps.add(name),
      child: const SizedBox(width: 50, height: 20),
    );
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 300,
          height: 100,
          child: Center(
            child: TapBand(
              size: 44,
              followTap: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [cell('a'), cell('b')],
              ),
            ),
          ),
        ),
      ),
    );
    final row = tester.getRect(find.byType(Row));
    await tester.tapAt(Offset(row.left + 75, row.top - 5));
    await tester.tapAt(Offset(row.left + 25, row.bottom + 5));
    await tester.tapAt(Offset(row.left + 75, row.top - 20));
    expect(taps, ['b', 'a'], reason: 'the last tap is past the band');

    taps.clear();
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 300,
          height: 100,
          child: Center(
            child: TapBand(
              size: 0,
              outset: const EdgeInsets.symmetric(horizontal: 10),
              child: cell('c'),
            ),
          ),
        ),
      ),
    );
    final c = tester.getRect(find.byType(GestureDetector));
    await tester.tapAt(Offset(c.left - 9, c.center.dy));
    await tester.tapAt(Offset(c.right + 9, c.center.dy));
    await tester.tapAt(Offset(c.right + 11, c.center.dy));
    expect(taps, ['c', 'c']);
  });
}

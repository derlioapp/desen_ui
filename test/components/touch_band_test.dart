import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui/src/behavior/tap_band.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// On touch platforms controls drawn shorter than the smallest tap target
/// (44) still answer across it, without growing their layout: the
/// segmented control, a table's sort headers and the select. A band
/// reaches as far as the parent's bounds, so each control here sits
/// directly in a box with room around it (padding, a column).
void main() {
  final ios = DsThemeData(platform: TargetPlatform.iOS);

  /// [child] with room around it, as on a page.
  Widget page(Widget child) => host(
    theme: ios,
    Padding(padding: const EdgeInsets.all(40), child: child),
  );

  group('segmented control', () {
    Widget control(ValueChanged<int> onChanged) => page(
      DsSegmentedControl<int>(
        value: 0,
        onChanged: onChanged,
        segments: const [
          DsSegment(value: 0, label: Text('Day')),
          DsSegment(value: 1, label: Text('Week')),
          DsSegment(value: 2, label: Text('Month')),
        ],
      ),
    );

    testWidgets('taps above, below and on the rim reach the segment there', (
      tester,
    ) async {
      int? got;
      await tester.pumpWidget(control((v) => got = v));
      await tester.pumpAndSettle();
      final box = tester.getRect(find.byType(DsSegmentedControl<int>));
      expect(box.height, lessThan(44), reason: 'drawn shorter than 44');
      final band = (44 - box.height) / 2;
      final week = tester.getCenter(find.text('Week')).dx;
      final month = tester.getCenter(find.text('Month')).dx;

      Future<int?> tapAt(Offset at) async {
        got = null;
        await tester.tapAt(at);
        await tester.pump(const Duration(milliseconds: 300));
        return got;
      }

      // Just above and just below the control, in the band.
      expect(await tapAt(Offset(week, box.top - band + 1)), 1);
      expect(await tapAt(Offset(month, box.bottom + band - 1)), 2);
      // On the channel's rim, outside the segments themselves.
      expect(await tapAt(Offset(week, box.top + 1)), 1);
      expect(await tapAt(Offset(month, box.bottom - 1)), 2);
      // Past the band: nothing.
      expect(await tapAt(Offset(week, box.top - band - 2)), isNull);
    });

    testWidgets('the layout does not grow', (tester) async {
      await tester.pumpWidget(control((_) {}));
      await tester.pumpAndSettle();
      final box = tester.getSize(find.byType(DsSegmentedControl<int>));
      final sizes = DsTheme.sizesOf(
        tester.element(find.byType(DsSegmentedControl<int>)),
      );
      expect(box.height, lessThan(sizes.minTapTarget));
    });
  });

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

  testWidgets('a select answers in the band around it (already a 44 band)', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        theme: ios,
        SizedBox(
          width: 400,
          height: 400,
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                // A form column: the select's band reaches into the
                // space around it.
                builder: (_) => Center(
                  child: SizedBox(
                    width: 200,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 16,
                      children: [
                        const SizedBox.shrink(),
                        DsSelect<int>(
                          value: null,
                          onChanged: (_) {},
                          options: const [
                            DsSelectOption(value: 1, label: 'One'),
                            DsSelectOption(value: 2, label: 'Two'),
                          ],
                        ),
                        const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final box = tester.getRect(find.byType(DsSelect<int>));
    expect(box.height, lessThan(44));
    final band = (44 - box.height) / 2;
    await tester.tapAt(Offset(box.center.dx, box.top - band + 1));
    await tester.pumpAndSettle();
    expect(find.text('Two'), findsOneWidget, reason: 'the menu opened');
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

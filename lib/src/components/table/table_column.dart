import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/case.dart';

/// The direction of a sorted [DsTable] column.
enum DsTableSortDirection {
  /// Low to high: A → Z, 1 → 9, oldest first.
  ascending,

  /// High to low: Z → A, 9 → 1, newest first.
  descending,
}

/// The sorted column of a [DsTable] and its direction.
@immutable
class DsTableSort {
  /// Sorts the column with [columnId] in [direction].
  const DsTableSort(
    this.columnId, [
    this.direction = DsTableSortDirection.ascending,
  ]);

  /// The [DsTableColumn.id] of the sorted column.
  final Object columnId;

  /// Low to high or high to low.
  final DsTableSortDirection direction;

  /// Whether the column sorts low to high.
  bool get ascending => direction == DsTableSortDirection.ascending;

  @override
  bool operator ==(Object other) =>
      other is DsTableSort &&
      other.columnId == columnId &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(columnId, direction);

  @override
  String toString() => 'DsTableSort($columnId, ${direction.name})';
}

/// How a [DsTable] lays out its rows: columns side by side, or one card
/// per row when the table is narrow.
///
/// ```dart
/// DsTable(layout: const .auto(), …) // cards below 480 px
/// ```
@immutable
class DsTableLayout {
  /// Rows of cells under column headers. Columns that do not fit scroll
  /// sideways, and the edge hiding them fades. The default.
  const DsTableLayout.rows() : breakpoint = 0;

  /// One card per row, each column on a line, its label before its value;
  /// a bar above the cards holds "select all" and the sort buttons.
  /// Selection, row taps, the row menu and the keyboard work as in rows.
  /// Needs a bounded width; in an unbounded one the table keeps its rows.
  const DsTableLayout.cards() : breakpoint = double.infinity;

  /// Rows, or cards while the table itself (not the screen) is narrower
  /// than [breakpoint]. 480 is where four columns and a checkbox no longer
  /// fit at their minimum widths, so a phone in portrait gets cards.
  const DsTableLayout.auto({this.breakpoint = 480});

  /// Below this width the table shows cards: 0 for [DsTableLayout.rows],
  /// infinity for [DsTableLayout.cards].
  final double breakpoint;

  /// Whether a table [width] wide shows cards.
  bool showsCards(double width) => width.isFinite && width < breakpoint;

  @override
  bool operator ==(Object other) =>
      other is DsTableLayout && other.breakpoint == breakpoint;

  @override
  int get hashCode => breakpoint.hashCode;

  @override
  String toString() => switch (breakpoint) {
    0 => 'DsTableLayout.rows()',
    double.infinity => 'DsTableLayout.cards()',
    _ => 'DsTableLayout.auto(breakpoint: $breakpoint)',
  };
}

/// Where a [DsTableColumn]'s header and cells sit horizontally. Follows the
/// reading direction: `end` is the right edge in left-to-right text.
enum DsTableCellAlignment {
  /// The reading start (left in English, right in Arabic).
  start,

  /// Centered.
  center,

  /// The reading end: numbers, so their digits line up.
  end,
}

enum _WidthKind { fixed, flex, intrinsic }

/// How wide a [DsTableColumn] is.
///
/// Widths are logical pixels at 1.0 text scale and grow with the text
/// scale, like CSS `em`: a column that holds "12.480,00 ₺" at 1.0 still
/// holds it at 2.0. A flex column under large text likewise keeps the
/// text it showed at 1.0: it is at least as wide as its header and the
/// sampled cell texts need, up to its 1.0 width grown by the scale. When
/// the minimums do not fit, the table scrolls sideways instead of
/// squeezing.
@immutable
class DsTableColumnWidth {
  /// Exactly [width].
  const DsTableColumnWidth.fixed(double this.width)
    : _kind = _WidthKind.fixed,
      flex = null,
      min = null,
      max = null;

  /// A share of the space left after the fixed and intrinsic columns, in
  /// proportion to [flex], never narrower than [min] (the table style's
  /// `minColumnWidth` when null).
  const DsTableColumnWidth.flex([double this.flex = 1, this.min])
    : _kind = _WidthKind.flex,
      width = null,
      max = null;

  /// As wide as the header and the cell texts need, between [min] and
  /// [max]. Measures the column's `text` (or `value`) of the first 200
  /// rows, so give a builder-only column a [min].
  const DsTableColumnWidth.intrinsic({this.min, this.max})
    : _kind = _WidthKind.intrinsic,
      width = null,
      flex = null;

  final _WidthKind _kind;

  /// The fixed width; null unless [DsTableColumnWidth.fixed].
  final double? width;

  /// The flex factor; null unless [DsTableColumnWidth.flex].
  final double? flex;

  /// The narrowest width, if any.
  final double? min;

  /// The widest an intrinsic column gets, if any.
  final double? max;

  /// Whether this is a [DsTableColumnWidth.fixed] width.
  bool get isFixed => _kind == _WidthKind.fixed;

  /// Whether this is a [DsTableColumnWidth.flex] width.
  bool get isFlex => _kind == _WidthKind.flex;

  /// Whether this is a [DsTableColumnWidth.intrinsic] width.
  bool get isIntrinsic => _kind == _WidthKind.intrinsic;

  @override
  bool operator ==(Object other) =>
      other is DsTableColumnWidth &&
      other._kind == _kind &&
      other.width == width &&
      other.flex == flex &&
      other.min == min &&
      other.max == max;

  @override
  int get hashCode => Object.hash(_kind, width, flex, min, max);
}

/// One column of a [DsTable]: its header and how it shows, sizes and sorts
/// each row's cell.
///
/// A cell shows [cell] when given, otherwise [text], otherwise [value] as a
/// string, on one line with an ellipsis.
///
/// ```dart
/// DsTableColumn<Invoice>(
///   id: 'amount',
///   label: 'Amount',
///   value: (i) => i.amount,          // sorts by the number
///   text: (i) => money.format(i.amount), // shows "12.480,00"
///   numeric: true,                    // tabular figures, end-aligned
///   sortable: true,
///   width: const .fixed(112),
/// )
/// ```
@immutable
class DsTableColumn<T> {
  /// Creates a column.
  const DsTableColumn({
    required this.id,
    required this.label,
    this.value,
    this.text,
    this.cell,
    this.numeric = false,
    this.alignment,
    this.width = const DsTableColumnWidth.flex(),
    this.sortable = false,
    this.comparator,
  }) : assert(
         cell != null || text != null || value != null,
         'A column needs a cell builder, a text or a value',
       ),
       assert(
         !sortable || comparator != null || value != null,
         'A sortable column needs a comparator or a value to compare',
       );

  /// Identifies the column in a [DsTableSort]. Keep it stable across
  /// rebuilds, e.g. a string.
  ///
  /// The table also knows the column by it: its sorted order and its
  /// measured width are kept under the id, not under the column object
  /// (columns hold closures, which cannot be compared). So the same id must
  /// mean the same [value], [text] and [comparator]; when they change for
  /// the same rows, change the id or `DsTable.rowsVersion`.
  final Object id;

  /// The header text.
  final String label;

  /// The cell's data, e.g. a number or a date: what the column sorts by
  /// when it has no [comparator], and the cell text when it has no [text].
  final Object? Function(T item)? value;

  /// The cell's text, e.g. a formatted amount ("12.480,00").
  final String Function(T item)? text;

  /// Builds the cell, e.g. a status badge. Wins over [text] and [value].
  final Widget Function(BuildContext context, T item)? cell;

  /// Shows numbers: tabular figures and end-aligned, so digits
  /// line up.
  final bool numeric;

  /// Where the header and cells sit. Defaults to end for [numeric] columns
  /// and start otherwise.
  final DsTableCellAlignment? alignment;

  /// How wide the column is.
  final DsTableColumnWidth width;

  /// Makes the header a sort button.
  final bool sortable;

  /// The ascending order of two rows. When null, the table compares
  /// [value]s: numbers, dates and other [Comparable]s directly, strings
  /// without regard to case, nulls last.
  final Comparator<T>? comparator;

  /// The resolved alignment.
  DsTableCellAlignment get effectiveAlignment =>
      alignment ??
      (numeric ? DsTableCellAlignment.end : DsTableCellAlignment.start);

  /// The text a cell shows without a [cell] builder.
  String textOf(T item) =>
      text?.call(item) ?? value?.call(item)?.toString() ?? '';

  /// Compares two rows in ascending order (see [comparator]); strings in
  /// the dictionary order of [language].
  int compare(T a, T b, {String? language}) {
    if (comparator != null) return comparator!(a, b);
    return compareValues(value?.call(a), value?.call(b), language: language);
  }

  /// The default order of two values: nulls last, strings in dictionary
  /// order for [language] ([dsCompareText]: "Çiçek" after "Cem" and before
  /// "Deniz" in Turkish), other [Comparable]s by their own order.
  ///
  /// Values of different kinds never throw; they keep a fixed order:
  /// numbers, then strings, then other comparables (grouped by type), then
  /// everything else by its text. So a placeholder such as `'n/a'` in a
  /// number column sorts after the numbers.
  static int compareValues(Object? a, Object? b, {String? language}) {
    if (a == null || b == null) {
      return a == null ? (b == null ? 0 : 1) : -1;
    }
    final rank = rankOf(a);
    final other = rankOf(b);
    if (rank != other) return rank - other;
    switch (rank) {
      case 0:
        return (a as num).compareTo(b as num);
      case 1:
        return dsCompareText(a as String, b as String, language: language);
      case 2:
        // Comparables of different types (a date and a duration) are
        // grouped by type instead of asked to compare.
        if (a.runtimeType != b.runtimeType) {
          return a.runtimeType.toString().compareTo(b.runtimeType.toString());
        }
        return (a as Comparable<Object?>).compareTo(b);
      default:
        return dsCompareText(a.toString(), b.toString(), language: language);
    }
  }

  /// The kind of a non-null value in [compareValues]' order: 0 numbers,
  /// 1 strings, 2 other [Comparable]s, 3 the rest.
  @internal
  static int rankOf(Object value) => switch (value) {
    num() => 0,
    String() => 1,
    Comparable() => 2,
    _ => 3,
  };
}

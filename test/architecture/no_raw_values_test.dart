import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// No raw values, checked mechanically: library code reads colors,
/// sizes, durations, curves and shadows from the theme or from the
/// component's `defaultStyle`.
///
/// Scope: every Dart file under `lib/src`, except
/// - `lib/src/theme/` and `lib/src/foundation/`, where the tokens and the
///   primitives they are built from are defined;
/// - generated files: `*_style.dart`, `l10n/strings/**`, `icons/icons.dart`.
///
/// Dimensions are checked outside a component's `defaultStyle`: the body
/// of a `static ... defaultStyle(...)` method is the one place a component
/// writes its own sizes, so it is skipped for the dimension checks. Colors,
/// durations, curves and shadows are checked there too; they come from the
/// theme. The dimension checks flag, on one line:
/// - a numeric `??` fallback (also split as `??` / number over two lines):
///   the resolved style already holds the default, so read it with `!`;
/// - `EdgeInsets*` and `Radius.circular` / `BorderRadius.circular` built
///   from a number;
/// - a number given to a size-like named argument (`width:`, `height:`,
///   `size:`, `spacing:`, `fontSize:`, `horizontal:`, `top:` ...), also as
///   a camelCase suffix (`iconSize:`, `trackHeight:`) and as a ternary
///   operand (`width: thick ? 2 : 1`), which covers `SizedBox(width: 8)`,
///   `Container(height: 4)` and the like;
/// - `Size(...)` and `Offset(...)` built from a number;
/// - an `opacity:` or `alpha:` other than 0 or 1, first operand or ternary
///   operand (`opacity: .35 + ...`, `withValues(alpha: .35)`);
/// - a ternary between numbers other than 0 and 1 (`checked ? 1 : 0.4`);
/// - a `FontWeight.wN00` literal.
/// A component's style body is any `static ... default*Style(` method, so
/// `defaultItemStyle` counts too.
/// Not checked: constructor parameter defaults (`this.height = 6`), which
/// are public API documented on the parameter, and arithmetic past the
/// first operand (`d / 2`), which is geometry.
///
/// A line that really needs a raw value carries `// ds-raw: <reason>` on
/// the line itself or the line above, so every exception is explained and
/// easy to find. Always allowed, because they are not design values:
/// - fully transparent `Color(0x00000000)`, the "no color" fallback;
/// - a neutral zero: `?? 0`, `?? 0.0`, `EdgeInsets.zero`, `width: 0`.
///
/// Typical `ds-raw` reasons: a 1px hairline, an optical nudge, a math
/// guard, a widget that has no style class yet (its sizes live in its
/// build method until it gets one).
void main() {
  final checks = <String, RegExp>{
    'raw color': _color,
    'raw duration': RegExp(r'\bDuration\('),
    'raw curve': RegExp(r'\bCurves\.|\bCubic\('),
    'raw shadow': RegExp(r'\b(BoxShadow|Shadow|DsShadow)\('),
  };
  final dimensionChecks = <String, RegExp>{
    'raw size fallback': _fallback,
    'raw insets': _insets,
    'raw radius': _radius,
    'raw size': _namedSize,
    'raw Size/Offset': _sizeOffset,
    'raw opacity': _opacity,
    'raw ternary': _ternary,
    'raw font weight': _fontWeight,
  };

  test('lib/src has no raw design values', () {
    final offenders = <String>[];
    final files = Directory('lib/src')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => _inScope(f.path.replaceAll(r'\', '/')));
    for (final file in files) {
      final lines = file.readAsLinesSync();
      var depth = 0; // bracket depth inside a defaultStyle body, 0 outside
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final code = line.split('//').first;
        // A fallback split over two lines (`x ??` / `16;`) is read whole.
        final joined = code.trimRight().endsWith('??') && i + 1 < lines.length
            ? code + lines[i + 1].split('//').first
            : code;
        if (depth == 0 && _defaultStyle.hasMatch(code)) depth = -1;
        final inDefaultStyle = depth != 0;
        if (inDefaultStyle) {
          depth = (depth < 0 ? 0 : depth) + _bracketDelta(code);
        }
        final excused =
            line.contains('ds-raw:') ||
            (i > 0 && lines[i - 1].contains('ds-raw:')) ||
            (_pending[file.path.replaceAll(r'\', '/')]?.contains(line.trim()) ??
                false);
        if (excused || line.trimLeft().startsWith('///')) continue;
        for (final MapEntry(key: kind, value: pattern) in {
          ...checks,
          if (!inDefaultStyle) ...dimensionChecks,
        }.entries) {
          if (pattern.hasMatch(pattern == _fallback ? joined : code)) {
            offenders.add('${file.path}:${i + 1} $kind: ${line.trim()}');
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('the check catches what it should', () {
    expect(_color.hasMatch('const Color(0xFF000000)'), isTrue);
    expect(_color.hasMatch('const Color(0x00000000)'), isFalse);
    expect(
      RegExp(r'\bDuration\(').hasMatch('const Duration(milliseconds: 1)'),
      isTrue,
    );
    expect(RegExp(r'\bDuration\(').hasMatch('Duration.zero'), isFalse);

    for (final raw in ['?? 32', '??16', '?? 0.5', '?? -1', '?? 1.0']) {
      expect(_fallback.hasMatch('size $raw'), isTrue, reason: raw);
    }
    for (final ok in ['?? 0', '?? 0.0', '?? DsSpace.s8', '?? style.gap!']) {
      expect(_fallback.hasMatch('size $ok'), isFalse, reason: ok);
    }

    expect(_insets.hasMatch('EdgeInsets.all(8)'), isTrue);
    expect(_insets.hasMatch('EdgeInsets.symmetric(horizontal: 12)'), isTrue);
    expect(_insets.hasMatch('EdgeInsetsDirectional.only(start: 4)'), isTrue);
    expect(_insets.hasMatch('EdgeInsets.fromLTRB(0, 0, 0, 1.5)'), isTrue);
    expect(_insets.hasMatch('EdgeInsets.all(0)'), isFalse);
    expect(_insets.hasMatch('EdgeInsets.only(top: gap)'), isFalse);
    expect(_insets.hasMatch('EdgeInsets.all(DsSpace.s8)'), isFalse);
    expect(_insets.hasMatch('EdgeInsets.zero'), isFalse);

    expect(_radius.hasMatch('BorderRadius.circular(4)'), isTrue);
    expect(_radius.hasMatch('Radius.circular(3)'), isTrue);
    expect(_radius.hasMatch('BorderRadius.circular(d / 2)'), isFalse);
    expect(_radius.hasMatch('BorderRadius.circular(DsRadii.pill)'), isFalse);

    expect(_namedSize.hasMatch('SizedBox(width: 8)'), isTrue);
    expect(_namedSize.hasMatch('SizedBox(height: 1.5, child: x)'), isTrue);
    expect(_namedSize.hasMatch('      spacing: 2,'), isTrue);
    expect(_namedSize.hasMatch('DsIcon(DsIcons.x, size: 14)'), isTrue);
    expect(_namedSize.hasMatch('.copyWith(fontSize: 11)'), isTrue);
    expect(_namedSize.hasMatch('SizedBox(width: 0)'), isFalse);
    expect(_namedSize.hasMatch('SizedBox(width: gap)'), isFalse);
    expect(_namedSize.hasMatch('SizedBox(width: DsSpace.s8)'), isFalse);
    expect(_namedSize.hasMatch('Text(x, maxLines: 1)'), isFalse);
    expect(_namedSize.hasMatch('Align(widthFactor: 1)'), isFalse);
    expect(_namedSize.hasMatch('Tween(begin: .35, end: 1)'), isFalse);
    // camelCase sizes and ternaries
    expect(_namedSize.hasMatch('iconSize: 20,'), isTrue);
    expect(_namedSize.hasMatch('trackHeight: 6,'), isTrue);
    expect(_namedSize.hasMatch('width: thick ? 2 : 1,'), isTrue);
    expect(_namedSize.hasMatch('height: floating ? 50 : 52,'), isTrue);
    expect(_namedSize.hasMatch('iconSize: s.iconSize!,'), isFalse);
    expect(_namedSize.hasMatch('width: d / 2,'), isFalse);
    expect(_namedSize.hasMatch('widthFactor: 1,'), isFalse);
    expect(_sizeOffset.hasMatch('const Size(52, 28)'), isTrue);
    expect(_sizeOffset.hasMatch('Size.square(20)'), isTrue);
    expect(_sizeOffset.hasMatch('Size(w, h)'), isFalse);
    expect(_sizeOffset.hasMatch('Offset.zero'), isFalse);
    expect(_opacity.hasMatch('opacity: .35 + .65 * v,'), isTrue);
    expect(_opacity.hasMatch('withValues(alpha: .35)'), isTrue);
    expect(_opacity.hasMatch('opacity: on ? 1 : .5,'), isTrue);
    expect(_opacity.hasMatch('opacity: checked ? 1 : 0,'), isFalse);
    expect(_opacity.hasMatch('withValues(alpha: 0)'), isFalse);
    expect(_opacity.hasMatch('opacity: v,'), isFalse);
    expect(_ternary.hasMatch('value: checked ? 1 : 0.4,'), isTrue);
    expect(_ternary.hasMatch('value: i == selected ? 1 : 0,'), isFalse);
    expect(_ternary.hasMatch('flex: a ? 2 : 1,'), isTrue);
    expect(_ternary.hasMatch('x ?? 16'), isFalse);
    expect(_ternary.hasMatch('addMonths(day, shift ? 12 : 1)'), isFalse);
    expect(_sizeOffset.hasMatch('const Offset(0, -1)'), isFalse);
    expect(_sizeOffset.hasMatch('Offset(box.width / 2, size)'), isFalse);
    expect(_sizeOffset.hasMatch('this.offset = const Offset(5, -4),'), isFalse);
    expect(_fontWeight.hasMatch('fontWeight: FontWeight.w500'), isTrue);
    expect(_fontWeight.hasMatch('fontWeight: style.fontWeight'), isFalse);
    expect(
      _defaultStyle.hasMatch('static DsXItemStyle defaultItemStyle('),
      isTrue,
    );

    expect(_inScope('lib/src/components/x/x.dart'), isTrue);
    expect(_inScope('lib/src/overlay/placement.dart'), isTrue);
    expect(_inScope('lib/src/components/x/x_style.dart'), isFalse);
    expect(_inScope('lib/src/theme/sizes.dart'), isFalse);
    expect(_inScope('lib/src/l10n/strings/tr.dart'), isFalse);
    expect(_inScope('lib/src/icons/icons.dart'), isFalse);
  });

  test('defaultStyle bodies are found and closed', () {
    const source = [
      'static DsXStyle defaultStyle(DsThemeData theme) {',
      '  return DsXStyle(',
      '    padding: EdgeInsets.all(8),',
      '  );',
      '}',
      'Widget build() => SizedBox(width: 8);',
    ];
    var depth = 0;
    final inside = <bool>[];
    for (final code in source) {
      if (depth == 0 && _defaultStyle.hasMatch(code)) depth = -1;
      inside.add(depth != 0);
      if (depth != 0) depth = (depth < 0 ? 0 : depth) + _bracketDelta(code);
    }
    expect(inside, [true, true, true, true, true, false]);
  });
}

/// A non-transparent literal color.
final _color = RegExp(
  r'Color\(0x(?!00000000\))|Color\.fromARGB\(|Color\.fromRGBO\(',
);

/// `?? <number>` other than a neutral zero (`?? 0`, `?? 0.0`).
final _fallback = RegExp(r'\?\?\s*(-\s*)?(0*[1-9]|0*\.0*[1-9]|0+\.\d*[1-9])');

/// A nonzero number literal (not part of a name like `s12`).
const _nonzero = r'(?<![\w.])(\d*[1-9]\d*(\.\d+)?|0?\.\d*[1-9]\d*)(?![\w.])';

/// `EdgeInsets*` built from at least one nonzero literal on the same line.
final _insets = RegExp(
  r'\bEdgeInsets(Directional)?\.(all|symmetric|only|fromLTRB|fromSTEB)\('
  r'[^)]*'
  '$_nonzero',
);

/// `Radius.circular(<literal>)` and `BorderRadius.circular(<literal>)`.
final _radius = RegExp(
  r'Radius\.circular\(\s*'
  '$_nonzero',
);

/// A number literal other than a neutral 0 or 1.
const _design =
    r'(?<![\w.])(?!(?:1(?:\.0+)?|0*(?:\.0+)?)(?![\w.\d]))'
    r'(\d*[1-9]\d*(\.\d+)?|0?\.\d*[1-9]\d*)(?![\w.])';

/// Any number literal.
const _number = r'(?<![\w.])\d*\.?\d+(?![\w.])';

/// Where a literal starts an argument's value: right after the colon, or
/// as a ternary operand within the same argument.
const _operand = r':\s*(?:[^,;()]*?[?:]\s*)?-?';

/// A nonzero literal passed to a size-like named argument, plain or as a
/// camelCase suffix (`iconSize`, `trackHeight`).
final _namedSize = RegExp(
  r'\b(?:\w*(?:[sS]ize|[wW]idth|[hH]eight|[dD]imension|[sS]pacing|[gG]ap|'
  r'[rR]adius|[tT]hickness|[eE]xtent|[iI]ndent|[mM]argin)|'
  r'letterSpacing|horizontal|vertical|top|bottom|left|right)'
  '$_operand$_nonzero',
);

/// `Size(...)` or `Offset(...)` (named constructors too) built from
/// literals only, one of them not 0 or ±1 (a unit direction is not a
/// design value). A parameter default (`this.offset = const Offset(5, -4)`)
/// is public API and passes, like `this.height = 6`.
final _sizeOffset = RegExp(
  r'(?<!=\s*(?:const\s+)?)\b(?:Size|Offset)(?:\.\w+)?\(\s*'
  '(?:-?$_number\\s*,\\s*)?-?$_design(?:\\s*,\\s*-?$_number)?'
  r'\s*\)',
);

/// An opacity or alpha other than 0 or 1.
final _opacity = RegExp(
  r'\b(?:opacity|alpha)'
  '$_operand$_design',
);

/// A named argument's value that picks between numbers, at least one of
/// them not 0 or 1 (`value: checked ? 1 : 0.4`). A 1/0 switch is logic.
final _ternary = RegExp(
  r'\b\w+:\s*[^,;()?]*\?\s*-?(?:'
  '$_design\\s*:\\s*-?$_number|$_number\\s*:\\s*-?$_design'
  ')',
);

/// A font weight literal.
final _fontWeight = RegExp(r'\bFontWeight\.w\d00\b');

/// The start of a component's `static ... default*Style(` method.
final _defaultStyle = RegExp(r'\bstatic\s+\w+\s+default\w*Style\(');

/// Lines the widened check found in files another
/// change owns: font weights written in build code. Move them into the
/// component's style (or mark them `ds-raw`) and drop the entry.
const _pending = {
  'lib/src/components/menu/menu.dart': {
    '? FontWeight.w600',
    '? FontWeight.w500',
  },
};

int _bracketDelta(String code) {
  var delta = 0;
  for (final c in code.codeUnits) {
    if (c == 0x28 || c == 0x7B || c == 0x5B) delta++; // ( { [
    if (c == 0x29 || c == 0x7D || c == 0x5D) delta--; // ) } ]
  }
  return delta;
}

bool _inScope(String path) =>
    path.endsWith('.dart') &&
    path.startsWith('lib/src/') &&
    !path.startsWith('lib/src/theme/') &&
    !path.startsWith('lib/src/foundation/') &&
    !path.startsWith('lib/src/l10n/strings/') &&
    path != 'lib/src/icons/icons.dart' &&
    !path.endsWith('_style.dart');

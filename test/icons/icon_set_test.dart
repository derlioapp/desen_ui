import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:desen_ui/desen_ui.dart';
import 'package:desen_ui/src/foundation/svg_path.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shapes as the generated part files spell them: name → path strings.
Map<String, List<String>> _shippedShapes() {
  final constant = RegExp(
    r'const _(\w+) = DsIconData\(\[(.*?)\]',
    dotAll: true,
  );
  final string = RegExp(r"'((?:[^'\\]|\\.)*)'");
  final shapes = <String, List<String>>{};
  for (final file in Directory('lib/src/icons/set').listSync()) {
    if (file is! File || !file.path.endsWith('.dart')) continue;
    for (final m in constant.allMatches(file.readAsStringSync())) {
      shapes[m[1]!] = [for (final s in string.allMatches(m[2]!)) s[1]!];
    }
  }
  return shapes;
}

void main() {
  test('every icon in tool/icons ships, and nothing else does', () {
    final source = Directory('tool/icons')
        .listSync()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.json'))
        .map((n) {
          final parts = n.substring(0, n.length - 5).split('-');
          return parts.first +
              parts
                  .skip(1)
                  .map((p) => p[0].toUpperCase() + p.substring(1))
                  .join();
        })
        .toSet();
    expect(source.length, greaterThan(2000));
    expect(_shippedShapes().keys.toSet(), source);
  });

  test('every shape parses and stays on the 24-unit grid', () {
    // A 2-unit round stroke reaches 1 unit past the path, so the path
    // itself stays inside the grid. Points along the outline are checked:
    // a path's bounds also cover its curves' control points.
    const grid = Rect.fromLTRB(-.05, -.05, 24.05, 24.05);
    final offenders = <String>[];
    for (final MapEntry(key: name, value: paths) in _shippedShapes().entries) {
      expect(paths, isNotEmpty, reason: name);
      for (final d in paths) {
        for (final metric in dsParseSvgPath(d).computeMetrics()) {
          for (var at = 0.0; at <= metric.length; at += .25) {
            final p = metric.getTangentForOffset(at)!.position;
            if (!grid.contains(p)) {
              offenders.add('$name $p');
              break;
            }
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('aliases are the same constant as the icon they name', () {
    expect(identical(DsIcons.volumeUp, DsIcons.volume2), isTrue);
    expect(identical(DsIcons.home, DsIcons.house), isTrue);
    expect(identical(DsIcons.close, DsIcons.x), isTrue);
  });

  test('icons that point along the reading direction mirror, others not', () {
    for (final icon in [
      DsIcons.chevronLeft,
      DsIcons.chevronRight,
      DsIcons.arrowLeft,
      DsIcons.logOut,
      DsIcons.undo,
      DsIcons.list,
    ]) {
      expect(icon.matchTextDirection, isTrue);
    }
    for (final icon in [
      DsIcons.play,
      DsIcons.chevronUp,
      DsIcons.clock,
      DsIcons.check,
      DsIcons.textAlignStart,
    ]) {
      expect(icon.matchTextDirection, isFalse);
    }
  });

  test('the metadata reads as JSON with the fields the generator needs', () {
    for (final file in Directory('tool/icons').listSync()) {
      if (!file.path.endsWith('.json')) continue;
      final meta =
          jsonDecode((file as File).readAsStringSync()) as Map<String, Object?>;
      expect(
        meta.keys,
        containsAll(['upstream', 'category', 'tags', 'aliases', 'mirror']),
        reason: file.path,
      );
    }
  });
}

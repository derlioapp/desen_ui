import 'dart:io';

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// The package bundles the faces `DsTypography` defaults to: pubspec.yaml
/// declares them under this package's name, every declared file ships and
/// every shipped file is declared, and so do the font licenses.
void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  /// Family → weight → asset, from the `flutter: fonts:` section.
  Map<String, Map<int, String>> declared() {
    final fonts = <String, Map<int, String>>{};
    Map<int, String>? family;
    String? asset;
    for (final line in pubspec.split('\n')) {
      final f = RegExp(r'^\s*- family: (\S+)\s*$').firstMatch(line);
      final a = RegExp(r'^\s*- asset: (\S+)\s*$').firstMatch(line);
      final w = RegExp(r'^\s*weight: (\d+)\s*$').firstMatch(line);
      if (f != null) fonts[f.group(1)!] = family = {};
      if (a != null) asset = a.group(1);
      if (w != null) family![int.parse(w.group(1)!)] = asset!;
    }
    return fonts;
  }

  test('declares the default faces, in this package', () {
    // Off Apple platforms, where the default text face is the bundled one.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final y = DsTypography();
    expect(pubspec, contains('name: ${y.package}\n'));
    expect(y.monoPackage, y.package);
    expect(declared(), {
      y.family: {
        400: 'fonts/SchibstedGrotesk-Regular.ttf',
        500: 'fonts/SchibstedGrotesk-Medium.ttf',
        600: 'fonts/SchibstedGrotesk-SemiBold.ttf',
        700: 'fonts/SchibstedGrotesk-Bold.ttf',
      },
      y.monoFamily: {
        400: 'fonts/GeistMono-Regular.ttf',
        500: 'fonts/GeistMono-Medium.ttf',
        600: 'fonts/GeistMono-SemiBold.ttf',
      },
    });
  });

  test('ships exactly the declared font files', () {
    final assets = {for (final weights in declared().values) ...weights.values};
    final files = {
      for (final f in Directory('fonts').listSync().whereType<File>())
        if (f.path.endsWith('.ttf')) 'fonts/${f.uri.pathSegments.last}',
    };
    expect(files, assets);
  });

  test('ships the font licenses', () {
    for (final name in ['OFL-SchibstedGrotesk.txt', 'OFL-GeistMono.txt']) {
      final text = File('fonts/$name').readAsStringSync();
      expect(text, contains('SIL OPEN FONT LICENSE Version 1.1'), reason: name);
    }
  });
}

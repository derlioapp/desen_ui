import 'dart:io';

import 'package:desen_ui_fonts/desen_ui_fonts.dart';
import 'package:flutter_test/flutter_test.dart';

/// The package declares the families its constants name, every declared
/// font file ships, and so do the licenses.
void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  test('declares the families DsFonts names', () {
    final families = RegExp(
      r'^\s*- family: (\S+)\s*$',
      multiLine: true,
    ).allMatches(pubspec).map((m) => m.group(1)).toSet();
    expect(families, {DsFonts.text, DsFonts.mono});
  });

  test('every declared font file exists', () {
    final assets = RegExp(
      r'^\s*- asset: (\S+)\s*$',
      multiLine: true,
    ).allMatches(pubspec).map((m) => m.group(1)!).toList();
    expect(assets, isNotEmpty);
    for (final asset in assets) {
      expect(File(asset).existsSync(), isTrue, reason: asset);
    }
  });

  test('ships the font licenses', () {
    final licenses = Directory('fonts')
        .listSync()
        .whereType<File>()
        .where((f) => f.uri.pathSegments.last.startsWith('OFL'))
        .toList();
    expect(licenses, hasLength(2));
  });

  test('names the package it is', () {
    expect(pubspec, contains('name: ${DsFonts.package}\n'));
  });
}

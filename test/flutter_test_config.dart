import 'dart:async';
import 'dart:io';

import 'package:desen_ui/desen_ui.dart' show DsFocusVisibility;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs before every test file.
///
/// - Loads the real bundled fonts, so goldens and text metrics match what
///   users see (flutter_test otherwise draws every glyph as a box).
/// - Installs a golden comparator that tolerates a hair of anti-aliasing
///   noise but fails on any visible change. Goldens are generated on macOS
///   (KALITE §2, S-18); on any other OS font rasterization differs, so
///   golden comparisons are skipped with a message while every behavior
///   test still runs.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadFonts();
  if (goldenFileComparator is LocalFileComparator) {
    final base = (goldenFileComparator as LocalFileComparator).basedir;
    goldenFileComparator = Platform.isMacOS
        ? TolerantGoldenComparator(base.resolve('_'))
        : MacOnlyGoldenComparator();
  }
  // Keyboard modality is global; each test starts as a desktop browser
  // would (focus visible), whatever the test platform.
  setUp(() => DsFocusVisibility.debugReset(keyboard: true));
  await testMain();
}

Future<void> _loadFonts() async {
  const families = {
    'packages/desen_ui/SchibstedGrotesk': [
      'Regular', 'Medium', 'SemiBold', 'Bold', //
    ],
    'packages/desen_ui/GeistMono': ['Regular', 'Medium', 'SemiBold'],
  };
  for (final MapEntry(key: family, value: weights) in families.entries) {
    final loader = FontLoader(family);
    final file = family.split('/').last;
    for (final w in weights) {
      final bytes = File('fonts/$file-$w.ttf').readAsBytesSync();
      loader.addFont(
        Future.value(ByteData.sublistView(Uint8List.fromList(bytes))),
      );
    }
    await loader.load();
  }
}

/// A [LocalFileComparator] that accepts differences below [tolerance]
/// (a fraction of pixels), absorbing sub-pixel anti-aliasing noise.
class TolerantGoldenComparator extends LocalFileComparator {
  TolerantGoldenComparator(super.testFile, {this.tolerance = 0.001});

  /// Largest accepted share of differing pixels.
  final double tolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= tolerance) {
      result.dispose();
      return true;
    }
    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}

/// Stands in for the golden comparator off macOS: goldens are generated on
/// macOS and other platforms rasterize text differently, so a comparison
/// there would only report noise. Marks the test skipped instead of failing
/// it, and never writes a golden.
class MacOnlyGoldenComparator extends GoldenFileComparator {
  MacOnlyGoldenComparator();

  static String _message(Uri golden) =>
      'Golden "$golden" skipped: goldens are generated and compared on '
      'macOS only (KALITE S-18). Behavior tests still run.';

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    markTestSkipped(_message(golden));
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async =>
      markTestSkipped(_message(golden));
}

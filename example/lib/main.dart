import 'package:flutter/widgets.dart';

import 'bench/corner_bench_app.dart';
import 'site/site_app.dart';
import 'snapshot/snapshot_app.dart';

void main() {
  // Native render check; see snapshot/snapshot_app.dart.
  if (const bool.fromEnvironment('DS_SNAPSHOT')) {
    runApp(
      SnapshotApp(dark: const String.fromEnvironment('DS_MODE') == 'dark'),
    );
    return;
  }
  // Corner benchmark, in profile mode; see bench/corner_bench_app.dart.
  if (const bool.fromEnvironment('DS_BENCH')) {
    runApp(const CornerBenchApp());
    return;
  }
  runApp(const SiteApp());
}

import 'dart:ui' as ui;

import 'package:desen_ui/desen_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'button_matrix.dart';
import 'save_stub.dart' if (dart.library.io) 'save_io.dart';

/// Native render check (KALITE S-05): renders the button scenes with the
/// platform's own engine (Impeller on macOS), saves a PNG of exactly what
/// was drawn and exits. No screen capture permission needed.
///
/// ```sh
/// flutter build macos --debug --dart-define=DS_SNAPSHOT=true --dart-define=DS_MODE=dark
/// ```
class SnapshotApp extends StatefulWidget {
  const SnapshotApp({super.key, required this.dark});

  final bool dark;

  @override
  State<SnapshotApp> createState() => _SnapshotAppState();
}

class _SnapshotAppState extends State<SnapshotApp> {
  final _boundary = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Let fonts settle and spinners reach a frame.
      final dpr = View.of(context).devicePixelRatio;
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      final render =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: dpr);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final path = await savePng(
        png!.buffer.asUint8List(),
        'desen_native_${widget.dark ? 'dark' : 'light'}.png',
      );
      // ignore: avoid_print
      print('DS_SNAPSHOT_PATH=$path dpr=$dpr');
      quit();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = DsThemeData(
      brightness: widget.dark ? Brightness.dark : Brightness.light,
    );
    return DsApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      themeMode: widget.dark ? DsThemeMode.dark : DsThemeMode.light,
      // Content is laid out at a fixed size; toImage captures all of it even
      // where it extends past the window.
      home: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: 1000,
        maxWidth: 1000,
        minHeight: 980,
        maxHeight: 980,
        child: RepaintBoundary(
          key: _boundary,
          child: Builder(
            builder: (context) => ColoredBox(
              color: DsTheme.colorsOf(context).canvas,
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: ButtonMatrix(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

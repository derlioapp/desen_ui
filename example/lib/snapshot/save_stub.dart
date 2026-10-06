import 'dart:typed_data';

/// Web has no file system; snapshot mode is desktop-only.
Future<String> savePng(Uint8List bytes, String name) =>
    throw UnsupportedError('Snapshot mode needs a desktop target.');

/// Ends the process.
void quit() {}

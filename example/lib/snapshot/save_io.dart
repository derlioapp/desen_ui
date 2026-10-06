import 'dart:io';
import 'dart:typed_data';

/// Writes [bytes] to the system temp directory (inside the sandbox
/// container on macOS) and returns the path.
Future<String> savePng(Uint8List bytes, String name) async {
  final file = File('${Directory.systemTemp.path}/$name');
  await file.writeAsBytes(bytes);
  return file.path;
}

/// Ends the process.
void quit() => exit(0);

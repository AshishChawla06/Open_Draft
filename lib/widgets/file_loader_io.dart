import 'dart:io';
import 'dart:typed_data';

/// Native implementation for file loading
Future<Uint8List?> loadFromLocalFile(String url) async {
  try {
    final filePath = url.replaceFirst('file://', '');
    final file = File(filePath);

    if (!await file.exists()) {
      return null;
    }

    return await file.readAsBytes();
  } catch (e) {
    return null;
  }
}

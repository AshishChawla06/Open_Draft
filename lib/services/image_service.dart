import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:logger/logger.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();
  static final _logger = Logger();

  /// Pick an image from gallery
  static Future<XFile?> pickImage() async {
    try {
      if (kIsWeb) {
        // For web, use image_picker
        try {
          final XFile? pickedFile = await _picker.pickImage(
            source: ImageSource.gallery,
          );
          if (pickedFile != null) {
            _logger.d('Image picked successfully: ${pickedFile.name}');
          }
          return pickedFile;
        } catch (webError) {
          _logger.e('Web image picker error: $webError');
          return null;
        }
      } else if (Platform.isAndroid || Platform.isIOS) {
        // On mobile, use image_picker with full feature set
        final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1800,
          imageQuality: 85,
        );
        return pickedFile;
      } else {
        // On desktop (Windows/macOS/Linux), use file_picker
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.single.path != null) {
          final path = result.files.single.path!;
          _logger.d('Image picked successfully (desktop): $path');
          return XFile(path);
        }
        return null;
      }
    } catch (e) {
      _logger.e('Error picking image', error: e);
      return null;
    }
  }

  /// Save image to app directory
  static Future<String?> saveImage(
    XFile imageFile,
    String id, {
    String category = 'covers',
  }) async {
    try {
      // On Web, we can't save to the file system like on mobile.
      // For now, we'll just return the path (blob URL) or handle it differently.
      if (kIsWeb) {
        return imageFile.path;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/$category');

      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final fileName = '$id.jpg';
      final savedPath = '${dir.path}/$fileName';

      // Compress and save
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image != null) {
        // Higher quality and width for non-cover images if needed,
        // but 600px is generally good for most mobile uses.
        final resized = img.copyResize(image, width: 800);
        final jpg = img.encodeJpg(resized, quality: 85);
        await File(savedPath).writeAsBytes(jpg);
        _logger.d('Saved image to: $savedPath');
        return savedPath;
      }
    } catch (e) {
      _logger.e('Error saving image', error: e);
    }
    return null;
  }

  /// Delete an image
  static Future<void> deleteImage(String path) async {
    try {
      if (kIsWeb) return;
      _logger.d('Attempting to delete image at: $path');
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        _logger.d('Successfully deleted image');
      } else {
        _logger.w('Deletion failed: File does not exist at $path');
      }
    } catch (e) {
      _logger.e('Error deleting image', error: e);
    }
  }

  /// Extract dominant color from image for Material You theming
  static Future<Color?> extractDominantColor(String imagePath) async {
    try {
      Uint8List bytes;
      if (kIsWeb) {
        // For web, use http to get bytes from URL (blob or relative)
        final response = await http.get(Uri.parse(imagePath));
        bytes = response.bodyBytes;
      } else {
        bytes = await File(imagePath).readAsBytes();
      }

      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Extract pixels for quantization
      // We resize for performance
      final resized = img.copyResize(image, width: 128);
      final pixels = <int>[];

      for (int y = 0; y < resized.height; y++) {
        for (int x = 0; x < resized.width; x++) {
          final pixel = resized.getPixel(x, y);
          // Material color utilities expects ARGB
          final argb =
              (pixel.a.toInt() << 24) |
              (pixel.r.toInt() << 16) |
              (pixel.g.toInt() << 8) |
              pixel.b.toInt();
          pixels.add(argb);
        }
      }

      // Quantize colors
      final quantizer = QuantizerCelebi();
      final result = await quantizer.quantize(pixels, 128);

      // Score and rank colors
      final ranked = Score.score(result.colorToCount);

      if (ranked.isNotEmpty) {
        final topColor = ranked.first;
        return Color(topColor);
      }

      return null;
    } catch (e) {
      _logger.e('Error extracting colors', error: e);
      return null;
    }
  }
}

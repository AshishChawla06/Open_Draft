import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:palette_generator/palette_generator.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery
  static Future<XFile?> pickImage() async {
    try {
      if (kIsWeb) {
        // For web, use a simpler approach that's more compatible with Edge
        // The image_picker_for_web has issues in some browsers
        try {
          final XFile? pickedFile = await _picker.pickImage(
            source: ImageSource.gallery,
            // Don't specify any options on web - let the browser handle it
          );

          if (pickedFile != null) {
            print('Image picked successfully: ${pickedFile.name}');
          }

          return pickedFile;
        } catch (webError) {
          print('Web image picker error: $webError');
          print('Error type: ${webError.runtimeType}');
          // On web, if the picker fails, it might be due to browser restrictions
          // or user cancellation. Return null gracefully.
          return null;
        }
      } else {
        // On mobile, use the full feature set
        final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1800,
          imageQuality: 85,
        );
        return pickedFile;
      }
    } catch (e) {
      print('Error picking image: $e');
      print('Error type: ${e.runtimeType}');
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
        return savedPath;
      }
    } catch (e) {
      print('Error saving image: $e');
    }
    return null;
  }

  /// Delete an image
  static Future<void> deleteImage(String path) async {
    try {
      if (kIsWeb) return;
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  /// Extract dominant color from image for Material You theming
  static Future<Color?> extractDominantColor(String imagePath) async {
    try {
      ImageProvider imageProvider;

      if (kIsWeb) {
        imageProvider = NetworkImage(imagePath);
      } else {
        imageProvider = FileImage(File(imagePath));
      }

      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        maximumColorCount: 20,
      );

      return paletteGenerator.dominantColor?.color;
    } catch (e) {
      print('Error extracting colors: $e');
      return null;
    }
  }
}

import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Native implementation for saving monster images
Future<String?> saveMonsterImage(
  String imagePath,
  String monsterIndexStr,
) async {
  try {
    // Get app documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final String customImagesDir = '${appDir.path}/custom_monster_images';

    // Create directory if it doesn't exist
    await Directory(customImagesDir).create(recursive: true);

    // Generate unique filename
    final String fileName =
        'monster_${DateTime.now().millisecondsSinceEpoch}_$monsterIndexStr';
    final String savedPath = '$customImagesDir/$fileName';

    // Copy file to app directory
    await File(imagePath).copy(savedPath);

    return savedPath;
  } catch (e) {
    return null;
  }
}

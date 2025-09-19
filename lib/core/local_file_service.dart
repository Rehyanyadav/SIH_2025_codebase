import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class LocalFileService {
  // Save image file locally in compressed format
  static Future<String> saveCompressedImage(File file, String filename, {int quality = 70}) async {
    final dir = await getApplicationDocumentsDirectory();
    final image = img.decodeImage(await file.readAsBytes());
    if (image == null) throw Exception('Invalid image');
    final compressed = img.encodeJpg(image, quality: quality);
    final path = '${dir.path}/$filename.jpg';
    final outFile = File(path);
    await outFile.writeAsBytes(compressed);
    return path;
  }

  // Load image file from local storage
  static Future<File> loadImage(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$filename.jpg');
  }
}

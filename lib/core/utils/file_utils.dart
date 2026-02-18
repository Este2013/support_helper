import 'dart:io';
import 'package:path/path.dart' as p;

class FileUtils {
  static Future<Directory> ensureDir(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String join(String base, String segment) => p.join(base, segment);

  static String basenameWithoutExtension(String path) =>
      p.basenameWithoutExtension(path);
}

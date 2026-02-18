import 'dart:convert';
import 'dart:io';

class JsonUtils {
  static Future<Map<String, dynamic>?> readJsonFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  static Future<void> writeJsonFile(String path, Map<String, dynamic> data) async {
    final file = File(path);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
    );
  }
}

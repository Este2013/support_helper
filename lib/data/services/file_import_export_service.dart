import 'package:file_picker/file_picker.dart';

class FileImportExportService {
  /// Open a file picker to select a JSON file. Returns the path or null if cancelled.
  Future<String?> pickJsonFileToImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      dialogTitle: 'Import Scenario',
    );
    return result?.files.single.path;
  }

  /// Open a file picker save dialog. Returns the path or null if cancelled.
  Future<String?> pickJsonFileToExport(String defaultName) async {
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Scenario',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    return result;
  }

  /// Open a file picker for any file type (attachments). Returns list of paths.
  Future<List<String>> pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      dialogTitle: 'Add Attachments',
      type: FileType.any,
    );
    return result?.files.map((f) => f.path!).whereType<String>().toList() ?? [];
  }
}

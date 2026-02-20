import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/app_constants.dart';

class StorageService {
  late final String appDir;
  late final String profilesDir;
  late final String scenariosDir;
  late final String settingsFilePath;

  Future<void> initialize() async {
    final base = await getApplicationSupportDirectory();
    appDir = p.join(base.path, AppConstants.appDirName);
    profilesDir = p.join(appDir, AppConstants.profilesDirName);
    scenariosDir = p.join(appDir, AppConstants.scenariosDirName);
    settingsFilePath = p.join(appDir, AppConstants.settingsFileName);

    await Directory(appDir).create(recursive: true);
    await Directory(profilesDir).create(recursive: true);
    await Directory(scenariosDir).create(recursive: true);
    // No directory creation needed for settingsFilePath — it's a file in appDir.
  }
}

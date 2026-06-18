import 'package:package_info_plus/package_info_plus.dart';

class AppVersionUtil {
  static String _installedVersion = '0.0.0';

  static String get installedVersion => _installedVersion;

  /// Reads version from the installed APK (pubspec.yaml → Android versionName).
  static Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    _installedVersion = info.version.trim();
  }
}

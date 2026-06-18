import 'app_version_util.dart';

class AppConstants {
  static const String appName = 'Device Guardian Customer';

  static const String fontFamily = 'Roboto';

  static const String baseUrl = 'https://api.deviceguardian.net/api';
  static const String imageUrl = 'https://api.deviceguardian.net/storage/';

  static const double maxLimitOfFileSentINConversation = 25;
  static const double maxLimitOfTotalFileSent = 5;
  static const double maxSizeOfASingleFile = 10;
  static const double maxImageSend = 10;

  /// Installed app version on this device (read from pubspec.yaml at startup).
  /// When releasing: bump `version` in pubspec.yaml and match `app_version` in API admin.
  static String get appVersion => AppVersionUtil.installedVersion;
}

import 'dart:io';

class DeviceInfoUtil {
  static String get deviceType {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }

  static String get deviceName {
    if (Platform.isIOS) return 'iOS Device';
    if (Platform.isAndroid) return 'Android Device';
    return Platform.operatingSystem;
  }
}

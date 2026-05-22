import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Device Guardian Customer';

  static const String fontFamily = 'Roboto';

  static const String baseUrl = 'https://api.deviceguardian.net/api';
  static const String imageUrl = 'https://api.deviceguardian.net/storage/';

  static const double maxLimitOfFileSentINConversation = 25;
  static const double maxLimitOfTotalFileSent = 5;
  static const double maxSizeOfASingleFile = 10;
  static const double maxImageSend = 10;

  // App Version - Update this when releasing a new version
  static const String appVersion = '1.0.1';
}

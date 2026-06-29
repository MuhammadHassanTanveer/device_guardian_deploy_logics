import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/login_provider.dart';
import '../screens/home_screen.dart';
import '../screens/shop_location_screen.dart';
import '../screens/update_pin_screen.dart';

class PostLoginNavigation {
  static Future<void> navigate(BuildContext context) async {
    if (!context.mounted) return;

    final loginProvider = context.read<LoginProvider>();

    if (!await loginProvider.hasShopLocationConfigured()) {
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ShopLocationScreen()),
        (route) => false,
      );
      return;
    }

    if (!await loginProvider.hasPinConfigured()) {
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const UpdatePinScreen(isFirstTime: true),
        ),
        (route) => false,
      );
      return;
    }

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }
}

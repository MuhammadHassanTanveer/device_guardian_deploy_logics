import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/customer_provider.dart';
import '../providers/home_provider.dart';
import '../providers/login_provider.dart';
import '../providers/profile_provider.dart';
import '../screens/login_screen.dart';

/// Global navigator key for navigation without context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Session Manager - Handles session expiration across all API calls
class SessionManager {
  static bool _isHandlingSessionExpiry = false;

  /// Check if response indicates session expiration (401 Unauthorized)
  static bool isSessionExpired(int statusCode) {
    return statusCode == 401;
  }

  /// Handle session expiration - clear data and navigate to login
  /// Returns true if session was expired and handled
  static Future<bool> handleSessionExpiry(int statusCode, {BuildContext? context}) async {
    if (!isSessionExpired(statusCode)) {
      return false;
    }

    // Prevent multiple simultaneous session expiry handlers
    if (_isHandlingSessionExpiry) {
      debugPrint('Session expiry already being handled, skipping...');
      return true;
    }

    _isHandlingSessionExpiry = true;
    debugPrint('=== SESSION EXPIRED - HANDLING LOGOUT ===');

    try {
      // Clear all SharedPreferences data
      await clearAllSharedPreferences();

      // Clear all provider data
      await _clearAllProviderData(context);

      // Navigate to login screen
      await _navigateToLogin();

      debugPrint('=== SESSION EXPIRY HANDLED SUCCESSFULLY ===');
      return true;
    } catch (e) {
      debugPrint('Error handling session expiry: $e');
      return true;
    } finally {
      // Reset flag after a delay to prevent rapid re-triggers
      Future.delayed(const Duration(seconds: 2), () {
        _isHandlingSessionExpiry = false;
      });
    }
  }

  /// Clear all SharedPreferences data
  static Future<void> clearAllSharedPreferences() async {
    debugPrint('Clearing all SharedPreferences data...');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('SharedPreferences cleared successfully');
    } catch (e) {
      debugPrint('Error clearing SharedPreferences: $e');
    }
  }

  /// Clear all provider data
  static Future<void> _clearAllProviderData(BuildContext? context) async {
    debugPrint('Clearing all provider data...');

    try {
      // Use the navigator key's context if no context provided
      final ctx = context ?? navigatorKey.currentContext;

      if (ctx != null) {
        try {
          ctx.read<LoginProvider>().clearError();
        } catch (e) {
          debugPrint('Error clearing LoginProvider: $e');
        }

        try {
          ctx.read<ProfileProvider>().clearProfileData();
        } catch (e) {
          debugPrint('Error clearing ProfileProvider: $e');
        }

        try {
          ctx.read<HomeProvider>().clearData();
        } catch (e) {
          debugPrint('Error clearing HomeProvider: $e');
        }

        try {
          ctx.read<CustomerProvider>().clearAllData();
        } catch (e) {
          debugPrint('Error clearing CustomerProvider: $e');
        }
      }

      debugPrint('Provider data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing provider data: $e');
    }
  }

  /// Navigate to login screen
  static Future<void> _navigateToLogin() async {
    debugPrint('Navigating to login screen...');

    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      // Show session expired message
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please login again.\nسیشن ختم ہو گیا۔ براہ کرم دوبارہ لاگ ان کریں۔'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Navigate to login screen and remove all previous routes
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      debugPrint('Navigation to login screen completed');
    } else {
      debugPrint('Navigator key is null, cannot navigate');
    }
  }

  /// Standard error response for session expiration
  static Map<String, dynamic> sessionExpiredResponse() {
    return {
      'success': false,
      'error': 'Session expired. Please login again.',
      'sessionExpired': true,
    };
  }
}


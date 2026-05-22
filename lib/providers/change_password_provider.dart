import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../util/app_constants.dart';
import '../util/session_manager.dart';

class ChangePasswordProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        _isLoading = false;
        _errorMessage = 'Session expired. Please login again.';
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/mobile/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      debugPrint('changePassword API Status: ${response.statusCode}');
      debugPrint('changePassword API Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true || data['status'] == true) {
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
          return true;
        }

        _isLoading = false;
        _errorMessage = data['message']?.toString() ?? 'Failed to change password';
        notifyListeners();
        return false;
      }

      if (response.statusCode == 401) {
        await SessionManager.handleSessionExpiry(response.statusCode);
        _isLoading = false;
        _errorMessage = 'Session expired. Please login again.';
        notifyListeners();
        return false;
      }

      _isLoading = false;
      _errorMessage = _parseErrorMessage(response.body, response.statusCode);
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('changePassword error: $e');
      _isLoading = false;
      _errorMessage = 'An error occurred. Please check your connection.';
      notifyListeners();
      return false;
    }
  }

  String _parseErrorMessage(String body, int statusCode) {
    try {
      final data = jsonDecode(body);
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
        if (firstError != null) {
          return firstError.toString();
        }
      }
      final message = data['message'];
      if (message != null && message.toString().isNotEmpty) {
        return message.toString();
      }
    } catch (_) {
      // Fall through to default message.
    }
    return 'Failed to change password ($statusCode)';
  }
}

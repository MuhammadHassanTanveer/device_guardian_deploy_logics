import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/login_session_model.dart';
import '../util/app_constants.dart';
import '../util/session_manager.dart';

enum LogoutSessionResult {
  removedOtherDevice,
  loggedOutCurrentDevice,
  failed,
}

class LinkDevicesProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;
  List<LoginSession> _sessions = [];

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;
  List<LoginSession> get sessions => List.unmodifiable(_sessions);

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> fetchSessions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getAuthToken();
      if (token.isEmpty) {
        _finishLoading('Session expired. Please login again.');
        return false;
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/mobile/login-sessions'),
        headers: _authHeaders(token),
      );

      debugPrint('fetchSessions API Status: ${response.statusCode}');
      debugPrint('fetchSessions API Response: ${response.body}');

      if (response.statusCode == 401) {
        await SessionManager.handleSessionExpiry(response.statusCode);
        _finishLoading('Session expired. Please login again.');
        return false;
      }

      if (response.statusCode == 200) {
        final parsed = LoginSessionsResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        if (parsed.success) {
          _sessions = parsed.sessions
              .where((session) => !session.isLegacyPlaceholder)
              .toList();
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
          return true;
        }
        _finishLoading(parsed.message.isNotEmpty
            ? parsed.message
            : 'Failed to load linked devices');
        return false;
      }

      _finishLoading(_parseErrorMessage(response.body, response.statusCode));
      return false;
    } catch (e) {
      debugPrint('fetchSessions error: $e');
      _finishLoading('An error occurred. Please check your connection.');
      return false;
    }
  }

  Future<LogoutSessionResult> logoutSession(int sessionId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getAuthToken();
      if (token.isEmpty) {
        _finishAction('Session expired. Please login again.');
        return LogoutSessionResult.failed;
      }

      final session = _sessions.firstWhere(
        (s) => s.sessionId == sessionId,
        orElse: () => LoginSession(
          sessionId: sessionId,
          deviceName: '',
          deviceType: '',
          isCurrent: false,
        ),
      );

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/mobile/logout-session'),
        headers: _authHeaders(token),
        body: jsonEncode({'session_id': sessionId}),
      );

      debugPrint('logoutSession API Status: ${response.statusCode}');
      debugPrint('logoutSession API Response: ${response.body}');

      if (response.statusCode == 401) {
        await SessionManager.handleSessionExpiry(response.statusCode);
        _finishAction('Session expired. Please login again.');
        return LogoutSessionResult.failed;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true || data['status'] == true) {
          if (session.isCurrent) {
            _isActionLoading = false;
            _sessions = [];
            notifyListeners();
            return LogoutSessionResult.loggedOutCurrentDevice;
          }

          _sessions = _sessions.where((s) => s.sessionId != sessionId).toList();
          _isActionLoading = false;
          _errorMessage = null;
          notifyListeners();
          return LogoutSessionResult.removedOtherDevice;
        }

        _finishAction(data['message']?.toString() ?? 'Failed to log out device');
        return LogoutSessionResult.failed;
      }

      _finishAction(_parseErrorMessage(response.body, response.statusCode));
      return LogoutSessionResult.failed;
    } catch (e) {
      debugPrint('logoutSession error: $e');
      _finishAction('An error occurred. Please check your connection.');
      return LogoutSessionResult.failed;
    }
  }

  Future<bool> logoutAllSessions() async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _getAuthToken();
      if (token.isEmpty) {
        _finishAction('Session expired. Please login again.');
        return false;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/mobile/logout-all-sessions'),
        headers: _authHeaders(token),
      );

      debugPrint('logoutAllSessions API Status: ${response.statusCode}');
      debugPrint('logoutAllSessions API Response: ${response.body}');

      if (response.statusCode == 401) {
        await SessionManager.handleSessionExpiry(response.statusCode);
        _finishAction('Session expired. Please login again.');
        return false;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true || data['status'] == true) {
          _sessions = [];
          _isActionLoading = false;
          _errorMessage = null;
          notifyListeners();
          return true;
        }

        _finishAction(
          data['message']?.toString() ?? 'Failed to log out all devices',
        );
        return false;
      }

      _finishAction(_parseErrorMessage(response.body, response.statusCode));
      return false;
    } catch (e) {
      debugPrint('logoutAllSessions error: $e');
      _finishAction('An error occurred. Please check your connection.');
      return false;
    }
  }

  void reset() {
    _isLoading = false;
    _isActionLoading = false;
    _errorMessage = null;
    _sessions = [];
    notifyListeners();
  }

  Future<String> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
  }

  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  void _finishLoading(String message) {
    _isLoading = false;
    _errorMessage = message;
    notifyListeners();
  }

  void _finishAction(String message) {
    _isActionLoading = false;
    _errorMessage = message;
    notifyListeners();
  }

  String _parseErrorMessage(String body, int statusCode) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final message = data['message'];
      if (message != null && message.toString().isNotEmpty) {
        return message.toString();
      }
    } catch (_) {
      // Fall through to default message.
    }
    return 'Request failed ($statusCode)';
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/app_version_model.dart';
import '../models/key_rate_model.dart';
import '../util/app_constants.dart';

class HomeProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _countsData;
  String? _userName;
  
  // App Version related
  AppVersionModel? _appVersionData;
  bool _isVersionOutdated = false;
  String _downloadUrl = '';

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get countsData => _countsData;
  String get userName => _userName ?? 'User';
  
  // App Version Getters
  AppVersionModel? get appVersionData => _appVersionData;
  bool get isVersionOutdated => _isVersionOutdated;
  String get downloadUrl => _downloadUrl;

  // Count data getters with fallbacks
  int get total => _parseToInt(_countsData?['total']);
  int get locked => _parseToInt(_countsData?['lock']);
  int get unlocked => _parseToInt(_countsData?['unlock']);
  int get inactive => _parseToInt(_countsData?['inactive']);
  String get crediteiPhone => _countsData?['credite_iphone']?.toString() ?? '0';
  String get crediteAndroid => _countsData?['credite_android']?.toString() ?? '0';

  // Helper to parse values to int
  int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Fetch counts from API
  Future<void> fetchCounts() async {
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
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/mobile/customers/counts'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("Counts API Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle both 'success' and 'status' fields
        if (data['success'] == true || data['status'] == true) {
          // Try different possible response structures for counts
          _countsData = data['data'] ?? data['Data'] ?? data['counts'] ?? data;
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        } else {
          _isLoading = false;
          _errorMessage = data['message'] ?? 'Failed to load counts';
          notifyListeners();
        }
      } else {
        _isLoading = false;
        _errorMessage = 'Failed to load counts. Please try again.';
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Counts fetch error: $e");
      _isLoading = false;
      _errorMessage = 'An error occurred. Please check your connection.';
      notifyListeners();
    }
  }

  /// Load user name from SharedPreferences or API
  Future<void> loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userName = prefs.getString('user_name');
      
      // If user name not stored, try to fetch from profile
      if (_userName == null || _userName!.isEmpty) {
        await _fetchUserName();
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Load user name error: $e");
    }
  }

  /// Fetch user name from profile API
  Future<void> _fetchUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final userId = prefs.getString('user_id') ?? '';

      if (token.isEmpty) return;

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/get_retailer_profile?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("Profile API Response for userName: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true || data['status'] == true) {
          final profileData = data['data'] ?? data['user'] ?? data;
          _userName = profileData['name'] ?? profileData['user_name'] ?? 'User';
          
          // Store user name in SharedPreferences for future use
          await prefs.setString('user_name', _userName!);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Fetch user name error: $e");
    }
  }

  /// Update user name (e.g., after profile update)
  Future<void> updateUserName(String name) async {
    _userName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    notifyListeners();
  }

  /// Fetch app version from API and check if update is required
  Future<bool> getAppVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/app-info'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("App Version API Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle both 'success' and 'status' fields
        if (data['success'] == true || data['status'] == true) {
          // Try different possible response structures
          final versionData = data['data'] ?? data['Data'] ?? data['app_info'] ?? data;

          if (versionData != null) {
            _appVersionData = AppVersionModel.fromJson(versionData);
            _downloadUrl = _appVersionData?.appDownloadUrl ?? '';
            
            // Compare versions
            final serverVersion = _appVersionData?.appVersion ?? '';
            final localVersion = AppConstants.appVersion;
            
            debugPrint("Server Version: $serverVersion");
            debugPrint("Local Version: $localVersion");
            
            // Check if version is outdated
            _isVersionOutdated = serverVersion.isNotEmpty && 
                                 serverVersion != localVersion;
            
            notifyListeners();
            return _isVersionOutdated;
          }
        }
      }
      
      _isVersionOutdated = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint("App Version fetch error: $e");
      _isVersionOutdated = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch key rate from API
  Future<KeyRateModel?> getKeyRate(int quantity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        debugPrint("Token is empty");
        return null;
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/get_key_rate?qty=$quantity'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("Key Rate API Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true || data['status'] == true) {
          final rateData = data['Data'] ?? data['data'] ?? data;
          return KeyRateModel.fromJson(rateData);
        }
      }
      return null;
    } catch (e) {
      debugPrint("Key Rate fetch error: $e");
      return null;
    }
  }

  /// Submit purchase request API
  Future<Map<String, dynamic>> submitPurchaseRequest({
    required int qty,
    required double price,
    required double amount,
    required String transactionId,
    File? paymentProof,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        debugPrint("Token is empty");
        return {'success': false, 'message': 'Session expired. Please login again.'};
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/purchase_request'),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Add required fields
      request.fields['qty'] = qty.toString();
      request.fields['price'] = price.toString();
      request.fields['amount'] = amount.toString();
      request.fields['transaction_id'] = transactionId;

      // Add optional payment proof image
      if (paymentProof != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'payment_proof',
            paymentProof.path,
          ),
        );
      }

      debugPrint("Purchase Request - qty: $qty, price: $price, amount: $amount, transaction_id: $transactionId");

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("Purchase Request API Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['success'] == true || data['status'] == true) {
          return {'success': true, 'message': data['message'] ?? 'Purchase request submitted successfully!'};
        } else {
          return {'success': false, 'message': data['message'] ?? 'Failed to submit purchase request.'};
        }
      } else {
        return {'success': false, 'message': 'Failed to submit purchase request. Please try again.'};
      }
    } catch (e) {
      debugPrint("Purchase Request error: $e");
      return {'success': false, 'message': 'An error occurred. Please check your connection.'};
    }
  }

  /// Clear data (e.g., on logout)
  void clearData() {
    _countsData = null;
    _userName = null;
    _errorMessage = null;
    _isLoading = false;
    _appVersionData = null;
    _isVersionOutdated = false;
    _downloadUrl = '';
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refresh all home data
  Future<void> refreshHomeData() async {
    await Future.wait([
      fetchCounts(),
      loadUserName(),
      getAppVersion(),
    ]);
  }
}

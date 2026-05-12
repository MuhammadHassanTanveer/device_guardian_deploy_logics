import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/login_model.dart';
import '../util/app_constants.dart';

class LoginProvider with ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;
  String? _pinCode;
  LoginUserData? _userData;

  String? get pinCode => _pinCode;
  LoginUserData? get userData => _userData;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/mobile/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        debugPrint("Login API Response: ${response.body}");

        // Parse response using model
        final loginResponse = LoginResponseModel.fromJson(jsonData);

        if (loginResponse.status && loginResponse.data != null) {
          _userData = loginResponse.data;

          debugPrint("Extracted token: ${_userData!.token.isNotEmpty ? 'Token present (${_userData!.token.length} chars)' : 'Token MISSING'}");
          debugPrint("Extracted user_id: ${_userData!.userId}");

          // Store in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', _userData!.token);
          await prefs.setString('user_id', _userData!.userId.toString());
          await prefs.setBool('is_logged_in', true);
          
          // Store additional user data
          await prefs.setString('user_email', _userData!.email);
          await prefs.setString('user_name', _userData!.name);
          await prefs.setString('user_avatar', _userData!.avatar);
          await prefs.setString('user_role', _userData!.role);
          await prefs.setString('user_phone', _userData!.phone);
          await prefs.setString('user_address', _userData!.address);
          await prefs.setString('user_uuid', _userData!.uuid);
          
          // Store city, state, country as JSON objects, and type
          await prefs.setString('user_city', jsonEncode(_userData!.city.toJson()));
          await prefs.setString('user_state', jsonEncode(_userData!.state.toJson()));
          await prefs.setString('user_country', jsonEncode(_userData!.country.toJson()));
          await prefs.setString('user_type', _userData!.type);
          
          // Store additional fields
          await prefs.setString('user_name_urdu', _userData!.nameUrdu);
          await prefs.setString('user_longitude', _userData!.longitude);
          await prefs.setString('user_latitude', _userData!.latitude);
          await prefs.setString('user_status', _userData!.status);

          debugPrint("Stored in SharedPreferences - auth_token: ${_userData!.token.isNotEmpty ? 'YES' : 'NO'}, user_id: ${_userData!.userId}");
          debugPrint("Stored city: ${_userData!.city}, state: ${_userData!.state}, country: ${_userData!.country}, type: ${_userData!.type}");

          isLoading = false;
          notifyListeners();
          return true;
        } else {
          errorMessage = loginResponse.message.isNotEmpty 
              ? loginResponse.message 
              : 'Login failed. Please try again.';
          isLoading = false;
          notifyListeners();
          return false;
        }
      } else if (response.statusCode == 401) {
        // 401 Unauthorized - Wrong email or password
        errorMessage = 'Invalid email or password. Please try again.';
        isLoading = false;
        notifyListeners();
        return false;
      } else {
        // Other error status codes
        try {
          final data = jsonDecode(response.body);
          errorMessage = data['message'] ?? 'Login failed. Please try again.';
        } catch (e) {
          errorMessage = 'Login failed. Please try again.';
        }
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      errorMessage = 'An error occurred. Please check your connection.';
      isLoading = false;
      print("login api exception:");
      print(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  /// Load user data from SharedPreferences (useful when app restarts)
  Future<LoginUserData?> loadUserDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    final userId = prefs.getString('user_id');
    if (userId == null || userId.isEmpty) return null;
    
    // Parse city, state, country from JSON
    LocationInfo city = LocationInfo(id: 0, name: '');
    LocationInfo state = LocationInfo(id: 0, name: '');
    LocationInfo country = LocationInfo(id: 0, name: '');
    
    try {
      final cityJson = prefs.getString('user_city');
      if (cityJson != null && cityJson.isNotEmpty) {
        city = LocationInfo.fromJson(jsonDecode(cityJson));
      }
    } catch (e) {
      // Fallback for legacy int format
      final cityId = prefs.getInt('user_city');
      if (cityId != null) {
        city = LocationInfo(id: cityId, name: '');
      }
    }
    
    try {
      final stateJson = prefs.getString('user_state');
      if (stateJson != null && stateJson.isNotEmpty) {
        state = LocationInfo.fromJson(jsonDecode(stateJson));
      }
    } catch (e) {
      // Fallback for legacy int format
      final stateId = prefs.getInt('user_state');
      if (stateId != null) {
        state = LocationInfo(id: stateId, name: '');
      }
    }
    
    try {
      final countryJson = prefs.getString('user_country');
      if (countryJson != null && countryJson.isNotEmpty) {
        country = LocationInfo.fromJson(jsonDecode(countryJson));
      }
    } catch (e) {
      // Fallback for legacy int format
      final countryId = prefs.getInt('user_country');
      if (countryId != null) {
        country = LocationInfo(id: countryId, name: '');
      }
    }
    
    _userData = LoginUserData(
      userId: int.tryParse(userId) ?? 0,
      email: prefs.getString('user_email') ?? '',
      token: prefs.getString('auth_token') ?? '',
      uuid: prefs.getString('user_uuid') ?? '',
      name: prefs.getString('user_name') ?? '',
      avatar: prefs.getString('user_avatar') ?? '',
      role: prefs.getString('user_role') ?? '',
      phone: prefs.getString('user_phone') ?? '',
      address: prefs.getString('user_address') ?? '',
      status: prefs.getString('user_status') ?? '',
      city: city,
      state: state,
      country: country,
      type: prefs.getString('user_type') ?? '',
      nameUrdu: prefs.getString('user_name_urdu') ?? '',
      longitude: prefs.getString('user_longitude') ?? '',
      latitude: prefs.getString('user_latitude') ?? '',
    );
    
    notifyListeners();
    return _userData;
  }

  /// Get stored user city from SharedPreferences
  Future<LocationInfo> getUserCity() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final cityJson = prefs.getString('user_city');
      if (cityJson != null && cityJson.isNotEmpty) {
        return LocationInfo.fromJson(jsonDecode(cityJson));
      }
    } catch (e) {
      // Fallback for legacy int format
      final cityId = prefs.getInt('user_city');
      if (cityId != null) {
        return LocationInfo(id: cityId, name: '');
      }
    }
    return LocationInfo(id: 0, name: '');
  }

  /// Get stored user state from SharedPreferences
  Future<LocationInfo> getUserState() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final stateJson = prefs.getString('user_state');
      if (stateJson != null && stateJson.isNotEmpty) {
        return LocationInfo.fromJson(jsonDecode(stateJson));
      }
    } catch (e) {
      // Fallback for legacy int format
      final stateId = prefs.getInt('user_state');
      if (stateId != null) {
        return LocationInfo(id: stateId, name: '');
      }
    }
    return LocationInfo(id: 0, name: '');
  }

  /// Get stored user country from SharedPreferences
  Future<LocationInfo> getUserCountry() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final countryJson = prefs.getString('user_country');
      if (countryJson != null && countryJson.isNotEmpty) {
        return LocationInfo.fromJson(jsonDecode(countryJson));
      }
    } catch (e) {
      // Fallback for legacy int format
      final countryId = prefs.getInt('user_country');
      if (countryId != null) {
        return LocationInfo(id: countryId, name: '');
      }
    }
    return LocationInfo(id: 0, name: '');
  }

  /// Get stored user type from SharedPreferences
  Future<String> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_type') ?? '';
  }

  /// Fetches pin code from API and returns:
  /// - null if API call fails
  /// - empty string if pin_code is null/empty
  /// - pin code string if exists
  Future<String?> getPinCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      if (token.isEmpty) {
        debugPrint("getPinCode: No auth token found");
        return null;
      }

      debugPrint("getPinCode: Fetching pin code...");

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/mobile/get-pin-code'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("getPinCode API Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle both 'success' and 'status' fields
        if (data['success'] == true || data['status'] == true) {
          final pinCode = data['data']?['pin_code'];
          
          // If pin_code exists, store it in SharedPreferences
          if (pinCode != null && pinCode.toString().isNotEmpty) {
            _pinCode = pinCode.toString();
            await prefs.setString('pin_code', _pinCode!);
            debugPrint("getPinCode: Pin code exists and stored: $_pinCode");
            return _pinCode;
          } else {
            debugPrint("getPinCode: Pin code is null or empty");
            return ''; // Return empty string to indicate pin is not set
          }
        } else {
          // Check if message indicates pin code not set
          final message = data['message']?.toString().toLowerCase() ?? '';
          if (message.contains('pin code not set') || message.contains('pin not set')) {
            debugPrint("getPinCode: API returned pin code not set");
            return ''; // Return empty string to indicate pin is not set
          }
          debugPrint("getPinCode: API returned success/status=false");
          return null;
        }
      } else {
        debugPrint("getPinCode: API returned status ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("getPinCode: Exception - $e");
      return null;
    }
  }

  /// Updates pin code via API and stores in SharedPreferences
  Future<bool> updatePin(String newPin) async {
    isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final userId = prefs.getString('user_id') ?? '';

      if (token.isEmpty) {
        debugPrint("updatePin: No auth token found");
        errorMessage = 'Session expired. Please login again.';
        isLoading = false;
        notifyListeners();
        return false;
      }

      if (userId.isEmpty) {
        debugPrint("updatePin: No user_id found");
        errorMessage = 'User ID not found. Please login again.';
        isLoading = false;
        notifyListeners();
        return false;
      }

      debugPrint("updatePin: Updating pin code for user_id: $userId");
      debugPrint("updatePin: Token length: ${token.length}");

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/mobile/update-pin-code'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'pin_code': newPin,
        }),
      );

      debugPrint("updatePin API Response Status: ${response.statusCode}");
      debugPrint("updatePin API Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true || data['status'] == true) {
          // Store pin code in SharedPreferences
          _pinCode = newPin;
          await prefs.setString('pin_code', newPin);
          debugPrint("updatePin: Pin code updated and stored: $newPin");
          
          isLoading = false;
          notifyListeners();
          return true;
        } else {
          errorMessage = data['message'] ?? 'Failed to update PIN';
          isLoading = false;
          notifyListeners();
          return false;
        }
      } else if (response.statusCode == 401) {
        // Unauthorized - token expired or invalid
        errorMessage = 'Session expired. Please login again.';
        debugPrint("updatePin: Unauthorized - Token may be expired");
        isLoading = false;
        notifyListeners();
        return false;
      } else {
        // Try to parse error message from response
        try {
          final data = jsonDecode(response.body);
          errorMessage = data['message'] ?? 'Failed to update PIN. Please try again.';
        } catch (e) {
          errorMessage = 'Failed to update PIN. Please try again.';
        }
        isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint("updatePin: Exception - $e");
      errorMessage = 'An error occurred. Please try again.';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get stored pin code from SharedPreferences
  Future<String?> getStoredPinCode() async {
    final prefs = await SharedPreferences.getInstance();
    _pinCode = prefs.getString('pin_code');
    return _pinCode;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _pinCode = null;
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}


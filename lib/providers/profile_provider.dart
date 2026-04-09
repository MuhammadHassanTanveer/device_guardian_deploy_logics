import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/retailer_profile_model.dart';
import '../models/login_model.dart';
import '../util/app_constants.dart';

class ProfileProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  RetailerProfileData? _profileData;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  RetailerProfileData? get profileData => _profileData;

  // Profile data getters
  String get name => _profileData?.name ?? 'N/A';
  String get email => _profileData?.email ?? 'N/A';
  String get phone => _profileData?.phone ?? 'N/A';
  String get address => _profileData?.address ?? 'N/A';
  LocationInfo get city => _profileData?.city ?? LocationInfo(id: 0, name: 'N/A');
  LocationInfo get state => _profileData?.state ?? LocationInfo(id: 0, name: 'N/A');
  LocationInfo get country => _profileData?.country ?? LocationInfo(id: 0, name: 'N/A');
  String get cityName => _profileData?.city.name ?? 'N/A';
  String get stateName => _profileData?.state.name ?? 'N/A';
  String get countryName => _profileData?.country.name ?? 'N/A';
  String get avatar => _profileData?.avatar ?? '';
  String get uuid => _profileData?.uuid ?? '';
  String get nameUrdu => _profileData?.nameUrdu ?? '';
  String get sinceMemberDate => _profileData?.sinceMemberDate ?? '';
  String get shopName => _profileData?.nameUrdu ?? '';
  String get createdAt => _profileData?.sinceMemberDate ?? '';

  /// Fetch user profile from API
  Future<void> fetchProfileData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final userId = prefs.getString('user_id') ?? '';

      if (token.isEmpty) {
        _isLoading = false;
        _errorMessage = 'Session expired. Please login again.';
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/get_retailer_profile?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("Profile API Response: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final profileResponse = RetailerProfileResponse.fromJson(jsonData);

        if (profileResponse.success && profileResponse.data != null) {
          _profileData = profileResponse.data;
          
          // Debug logging for location data
          debugPrint("=== PROFILE LOCATION DATA LOADED ===");
          debugPrint("Country: ${_profileData?.country.name} (ID: ${_profileData?.country.id})");
          debugPrint("State: ${_profileData?.state.name} (ID: ${_profileData?.state.id})");
          debugPrint("City: ${_profileData?.city.name} (ID: ${_profileData?.city.id})");
          debugPrint("=====================================");
          
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        } else {
          _isLoading = false;
          _errorMessage = profileResponse.message.isNotEmpty 
              ? profileResponse.message 
              : 'Failed to load profile';
          notifyListeners();
        }
      } else {
        _isLoading = false;
        _errorMessage = 'Failed to load profile. Please try again.';
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Profile fetch error: $e");
      _isLoading = false;
      _errorMessage = 'An error occurred. Please check your connection.';
      notifyListeners();
    }
  }

  /// Update user profile via API
  Future<bool> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String address,
    required int cityId,
    required int stateId,
    required int countryId,
    String? cityName,
    String? stateName,
    String? countryName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final userId = prefs.getString('user_id') ?? '';

      if (token.isEmpty) {
        _isLoading = false;
        _errorMessage = 'Session expired. Please login again.';
        notifyListeners();
        return false;
      }

      final body = {
        'user_id': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'city': cityId,
        'state': stateId,
        'country': countryId,
      };

      debugPrint("Update Profile Request Body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/update_retailer_profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      debugPrint("Update Profile API Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true || data['status'] == true) {
          // Update local profile data if it exists
          if (_profileData != null) {
            _profileData = RetailerProfileData(
              id: _profileData!.id,
              uuid: _profileData!.uuid,
              name: name,
              nameUrdu: _profileData!.nameUrdu,
              avatar: _profileData!.avatar,
              authkey: _profileData!.authkey,
              email: email,
              phone: phone,
              address: address,
              city: LocationInfo(id: cityId, name: cityName ?? _profileData!.city.name),
              state: LocationInfo(id: stateId, name: stateName ?? _profileData!.state.name),
              country: LocationInfo(id: countryId, name: countryName ?? _profileData!.country.name),
              sinceMemberDate: _profileData!.sinceMemberDate,
            );
          }
          
          // Save updated data to SharedPreferences
          await prefs.setString('user_name', name);
          
          // Save updated location data to SharedPreferences (as JSON to match login format)
          final updatedCountry = LocationInfo(id: countryId, name: countryName ?? _profileData?.country.name ?? '');
          final updatedState = LocationInfo(id: stateId, name: stateName ?? _profileData?.state.name ?? '');
          final updatedCity = LocationInfo(id: cityId, name: cityName ?? _profileData?.city.name ?? '');
          
          await prefs.setString('user_country', jsonEncode(updatedCountry.toJson()));
          await prefs.setString('user_state', jsonEncode(updatedState.toJson()));
          await prefs.setString('user_city', jsonEncode(updatedCity.toJson()));
          
          debugPrint("=== PROFILE UPDATED - SAVED TO SHARED PREFERENCES ===");
          debugPrint("Country: ${updatedCountry.name} (ID: ${updatedCountry.id})");
          debugPrint("State: ${updatedState.name} (ID: ${updatedState.id})");
          debugPrint("City: ${updatedCity.name} (ID: ${updatedCity.id})");
          debugPrint("=====================================================");
          
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
          return true;
        } else {
          _isLoading = false;
          _errorMessage = data['message'] ?? 'Failed to update profile';
          notifyListeners();
          return false;
        }
      } else {
        _isLoading = false;
        _errorMessage = 'Failed to update profile. Please try again.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint("Update profile error: $e");
      _isLoading = false;
      _errorMessage = 'An error occurred. Please check your connection.';
      notifyListeners();
      return false;
    }
  }

  /// Clear profile data (e.g., on logout)
  void clearProfileData() {
    _profileData = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Format date helper
  String formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}


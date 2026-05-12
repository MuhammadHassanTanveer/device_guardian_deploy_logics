import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/retailer_profile_model.dart';
import '../models/login_model.dart';
import '../util/app_constants.dart';
import '../util/session_manager.dart';

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
  String get companyName => _profileData?.companyName ?? 'N/A';
  String get companyNameUrdu => _profileData?.companyNameUrdu ?? '';
  String get gstNo => _profileData?.gstNo ?? '';
  String get sinceMemberDate => _profileData?.sinceMemberDate ?? '';
  String get shopName => (_profileData?.companyName != null && _profileData!.companyName.isNotEmpty) ? _profileData!.companyName : _profileData?.nameUrdu ?? '';
  String get createdAt => _profileData?.sinceMemberDate ?? '';

  /// Fetch user profile from API
  Future<void> fetchProfileData() async {
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
        Uri.parse('${AppConstants.baseUrl}/mobile/profile'),
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
          
          // Save location data to SharedPreferences for future use
          try {
            if (_profileData?.country != null) {
              await prefs.setString('user_country', jsonEncode(_profileData!.country.toJson()));
            }
            if (_profileData?.state != null) {
              await prefs.setString('user_state', jsonEncode(_profileData!.state.toJson()));
            }
            if (_profileData?.city != null) {
              await prefs.setString('user_city', jsonEncode(_profileData!.city.toJson()));
            }
            debugPrint("=== LOCATION DATA SAVED TO SHARED PREFERENCES ===");
          } catch (e) {
            debugPrint("Error saving location to SharedPreferences: $e");
          }

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
      } else if (response.statusCode == 401) {
        await SessionManager.handleSessionExpiry(response.statusCode);
        _isLoading = false;
        _errorMessage = 'Session expired. Please login again.';
        notifyListeners();
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
    String? companyName,
    String? companyNameUrdu,
    String? gstNo,
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

      final body = {
        'company_name': companyName ?? name,
        'company_name_urdu': companyNameUrdu ?? '',
        'user_name': name,
        'contact_number': phone,
        'address': address,
        'gst_no': gstNo ?? '',
        'country_id': countryId,
        'state_id': stateId,
        'city_id': cityId,
      };

      debugPrint("Update Profile Request Body: ${jsonEncode(body)}");

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/mobile/profile'),
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
              companyName: companyName ?? name,
              companyNameUrdu: companyNameUrdu ?? _profileData!.companyNameUrdu,
              gstNo: gstNo ?? _profileData!.gstNo,
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
      } else if (response.statusCode == 401) {
        await SessionManager.handleSessionExpiry(response.statusCode);
        _isLoading = false;
        _errorMessage = 'Session expired. Please login again.';
        notifyListeners();
        return false;
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

  /// Load profile data from SharedPreferences (useful for offline access)
  Future<void> loadProfileDataFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Parse location data from SharedPreferences
      LocationInfo city = LocationInfo(id: 0, name: 'N/A');
      LocationInfo state = LocationInfo(id: 0, name: 'N/A');
      LocationInfo country = LocationInfo(id: 0, name: 'N/A');
      
      try {
        final cityJson = prefs.getString('user_city');
        if (cityJson != null && cityJson.isNotEmpty) {
          final cityData = jsonDecode(cityJson);
          city = LocationInfo(
            id: cityData['id'] ?? 0,
            name: cityData['name'] ?? 'N/A',
          );
        }
      } catch (e) {
        debugPrint('Error parsing city from SharedPreferences: $e');
      }
      
      try {
        final stateJson = prefs.getString('user_state');
        if (stateJson != null && stateJson.isNotEmpty) {
          final stateData = jsonDecode(stateJson);
          state = LocationInfo(
            id: stateData['id'] ?? 0,
            name: stateData['name'] ?? 'N/A',
          );
        }
      } catch (e) {
        debugPrint('Error parsing state from SharedPreferences: $e');
      }
      
      try {
        final countryJson = prefs.getString('user_country');
        if (countryJson != null && countryJson.isNotEmpty) {
          final countryData = jsonDecode(countryJson);
          country = LocationInfo(
            id: countryData['id'] ?? 0,
            name: countryData['name'] ?? 'N/A',
          );
        }
      } catch (e) {
        debugPrint('Error parsing country from SharedPreferences: $e');
      }
      
      // If profile data exists but has no location, update it with location from SharedPreferences
      if (_profileData != null) {
        // Check if existing profile data has valid location IDs
        final hasValidLocation = _profileData!.country.id != 0 || 
                                  _profileData!.state.id != 0 || 
                                  _profileData!.city.id != 0;
        
        // If profile exists but has no location, update with SharedPreferences location
        if (!hasValidLocation && (country.id != 0 || state.id != 0 || city.id != 0)) {
          _profileData = RetailerProfileData(
            id: _profileData!.id,
            uuid: _profileData!.uuid,
            name: _profileData!.name,
            nameUrdu: _profileData!.nameUrdu,
            companyName: _profileData!.companyName,
            companyNameUrdu: _profileData!.companyNameUrdu,
            gstNo: _profileData!.gstNo,
            avatar: _profileData!.avatar,
            authkey: _profileData!.authkey,
            email: _profileData!.email,
            phone: _profileData!.phone,
            address: _profileData!.address,
            city: city,
            state: state,
            country: country,
            sinceMemberDate: _profileData!.sinceMemberDate,
          );
          
          debugPrint("=== PROFILE LOCATION UPDATED FROM SHARED PREFERENCES ===");
          debugPrint("Country: ${country.name} (ID: ${country.id})");
          debugPrint("State: ${state.name} (ID: ${state.id})");
          debugPrint("City: ${city.name} (ID: ${city.id})");
          debugPrint("=========================================================");
          
          notifyListeners();
        }
      } else {
        // Only set profile data if we don't already have it from API
        final userId = prefs.getString('user_id');
        if (userId != null) {
          _profileData = RetailerProfileData(
            id: int.tryParse(userId) ?? 0,
            uuid: prefs.getString('user_uuid') ?? '',
            name: prefs.getString('user_name') ?? 'N/A',
            nameUrdu: prefs.getString('user_name_urdu') ?? '',
            companyName: prefs.getString('user_name') ?? 'N/A', // Will be updated when API is called
            companyNameUrdu: '',
            gstNo: '',
            avatar: prefs.getString('user_avatar') ?? '',
            authkey: '',
            email: prefs.getString('user_email') ?? 'N/A',
            phone: prefs.getString('user_phone') ?? 'N/A',
            address: prefs.getString('user_address') ?? 'N/A',
            city: city,
            state: state,
            country: country,
            sinceMemberDate: '',
          );
          
          debugPrint("=== PROFILE DATA LOADED FROM SHARED PREFERENCES ===");
          debugPrint("Country: ${country.name} (ID: ${country.id})");
          debugPrint("State: ${state.name} (ID: ${state.id})");
          debugPrint("City: ${city.name} (ID: ${city.id})");
          debugPrint("====================================================");
          
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint("Error loading profile data from SharedPreferences: $e");
    }
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


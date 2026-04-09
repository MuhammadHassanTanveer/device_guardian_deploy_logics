import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../util/app_constants.dart';
import '../models/location_model.dart';

class RegistrationProvider with ChangeNotifier {
  // Loading states
  bool isLoading = false;
  bool isLoadingCountries = false;
  bool isLoadingStates = false;
  bool isLoadingCities = false;

  // Error message
  String? errorMessage;

  // Success state
  bool isRegistrationSuccess = false;

  // Location data - Countries, States, Cities
  List<CountryModel> countries = [];
  List<StateModel> states = [];
  List<CityModel> cities = [];

  // Selected location
  CountryModel? selectedCountry;
  StateModel? selectedState;
  CityModel? selectedCity;

  // Type dropdown options
  List<String> typeOptions = ['Distributor', 'FOS', 'Retailer'];
  String? selectedType;

  /// Fetch all countries from API
  Future<void> fetchCountries() async {
    try {
      isLoadingCountries = true;
      notifyListeners();

      final url = Uri.parse('${AppConstants.baseUrl}/countries');
      debugPrint('Fetching countries from: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Countries API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response formats
        List<dynamic> countryList = [];
        if (data is List) {
          countryList = data;
        } else if (data is Map) {
          countryList = data['data'] ?? data['Data'] ?? data['countries'] ?? [];
        }

        countries = countryList.map((e) => CountryModel.fromJson(e)).toList();
        debugPrint('Loaded ${countries.length} countries');
      } else {
        debugPrint('Failed to fetch countries: ${response.statusCode}');
        countries = [];
      }
    } catch (e) {
      debugPrint('Error fetching countries: $e');
      countries = [];
    } finally {
      isLoadingCountries = false;
      notifyListeners();
    }
  }

  /// Fetch states by country ID
  Future<void> fetchStates(int countryId) async {
    try {
      isLoadingStates = true;
      states = [];
      notifyListeners();

      final url = Uri.parse('${AppConstants.baseUrl}/states/$countryId');
      debugPrint('Fetching states from: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('States API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response formats
        List<dynamic> stateList = [];
        if (data is List) {
          stateList = data;
        } else if (data is Map) {
          stateList = data['data'] ?? data['Data'] ?? data['states'] ?? [];
        }

        states = stateList.map((e) => StateModel.fromJson(e)).toList();
        debugPrint('Loaded ${states.length} states for country $countryId');
      } else {
        debugPrint('Failed to fetch states: ${response.statusCode}');
        states = [];
      }
    } catch (e) {
      debugPrint('Error fetching states: $e');
      states = [];
    } finally {
      isLoadingStates = false;
      notifyListeners();
    }
  }

  /// Fetch cities by state ID
  Future<void> fetchCities(int stateId) async {
    try {
      isLoadingCities = true;
      cities = [];
      notifyListeners();

      final url = Uri.parse('${AppConstants.baseUrl}/cities/$stateId');
      debugPrint('Fetching cities from: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Cities API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response formats
        List<dynamic> cityList = [];
        if (data is List) {
          cityList = data;
        } else if (data is Map) {
          cityList = data['data'] ?? data['Data'] ?? data['cities'] ?? [];
        }

        cities = cityList.map((e) => CityModel.fromJson(e)).toList();
        debugPrint('Loaded ${cities.length} cities for state $stateId');
      } else {
        debugPrint('Failed to fetch cities: ${response.statusCode}');
        cities = [];
      }
    } catch (e) {
      debugPrint('Error fetching cities: $e');
      cities = [];
    } finally {
      isLoadingCities = false;
      notifyListeners();
    }
  }

  /// Set selected country and fetch states
  void setSelectedCountry(CountryModel? country) {
    selectedCountry = country;
    selectedState = null;
    selectedCity = null;
    states = [];
    cities = [];
    notifyListeners();

    if (country != null) {
      fetchStates(country.id);
    }
  }

  /// Set selected state and fetch cities
  void setSelectedState(StateModel? state) {
    selectedState = state;
    selectedCity = null;
    cities = [];
    notifyListeners();

    if (state != null) {
      fetchCities(state.id);
    }
  }

  /// Set selected city
  void setSelectedCity(CityModel? city) {
    selectedCity = city;
    notifyListeners();
  }

  /// Set selected type
  void setSelectedType(String? type) {
    selectedType = type;
    notifyListeners();
  }

  /// Clear all location selections
  void clearLocationSelections() {
    selectedCountry = null;
    selectedState = null;
    selectedCity = null;
    states = [];
    cities = [];
    notifyListeners();
  }

  /// Clear all data
  void clearAllData() {
    selectedCountry = null;
    selectedState = null;
    selectedCity = null;
    selectedType = null;
    states = [];
    cities = [];
    errorMessage = null;
    isRegistrationSuccess = false;
  }

  /// Register new user/admin
  Future<bool> registerUser({
    required String name,
    required String nameUrdu,
    required String phone,
    required String email,
    required String password,
    required String address,
    required String country,
    required String state,
    required String city,
    required String type,
    String? avatar,
    String? referenceCode,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      isRegistrationSuccess = false;
      notifyListeners();

      final url = Uri.parse('${AppConstants.baseUrl}/register_user_api');
      debugPrint('Registering user at: $url');

      final body = {
        'name': name,
        'name_urdu': nameUrdu,
        'phone': phone,
        'address': address,
        'country': country,
        'state': state,
        'city': city,
        'type': type,
        'avatar': avatar ?? '',
        'email': email,
        'password': password,
        'reference_code': referenceCode ?? '',
      };

      debugPrint('Registration request body: $body');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(body),
      );

      debugPrint('Registration API Response Status: ${response.statusCode}');
      debugPrint('Registration API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // Check for success in response
        if (data['success'] == true || data['status'] == true || data['message'] != null) {
          isRegistrationSuccess = true;
          notifyListeners();
          return true;
        } else {
          errorMessage = data['message'] ?? data['error'] ?? 'Registration failed';
          notifyListeners();
          return false;
        }
      } else if (response.statusCode == 422) {
        // Validation errors
        final data = json.decode(response.body);
        if (data['errors'] != null) {
          // Extract first error message
          final errors = data['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first;
          } else {
            errorMessage = firstError.toString();
          }
        } else {
          errorMessage = data['message'] ?? 'Validation failed';
        }
        notifyListeners();
        return false;
      } else {
        final data = json.decode(response.body);
        errorMessage = data['message'] ?? data['error'] ?? 'Registration failed. Please try again.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error during registration: $e');
      errorMessage = 'An error occurred. Please check your internet connection and try again.';
      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}


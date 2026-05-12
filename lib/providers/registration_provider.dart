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



  /// Fetch all countries from API
  Future<void> fetchCountries() async {
    try {
      isLoadingCountries = true;
      errorMessage = null;
      notifyListeners();

      final url = Uri.parse('${AppConstants.baseUrl}/mobile/countries');
      debugPrint('Fetching countries from: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout - Please check your internet connection');
        },
      );

      debugPrint('Countries API Response Status: ${response.statusCode}');
      debugPrint('Countries API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response formats
        List<dynamic> countryList = [];
        if (data is List) {
          countryList = data;
        } else if (data is Map) {
          // Try multiple possible keys
          countryList = data['data'] ??
                       data['Data'] ??
                       data['countries'] ??
                       data['result'] ??
                       data['results'] ??
                       [];
        }

        if (countryList.isEmpty) {
          debugPrint('Warning: Country list is empty. Response structure might have changed.');
          debugPrint('Full response: $data');
          errorMessage = 'No countries found in response';
        }

        countries = countryList.map((e) {
          try {
            return CountryModel.fromJson(e as Map<String, dynamic>);
          } catch (error) {
            debugPrint('Error parsing country: $e, Error: $error');
            return null;
          }
        }).whereType<CountryModel>().toList();

        debugPrint('Successfully loaded ${countries.length} countries');
      } else {
        debugPrint('Failed to fetch countries. Status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        countries = [];
        errorMessage = 'Failed to load countries. Status: ${response.statusCode}';
      }
    } on http.ClientException catch (e, stackTrace) {
      debugPrint('Network error fetching countries: $e');
      debugPrint('Stack trace: $stackTrace');
      countries = [];
      errorMessage = 'Network error: Cannot reach server. Please check your internet connection.';
    } on FormatException catch (e, stackTrace) {
      debugPrint('JSON parsing error: $e');
      debugPrint('Stack trace: $stackTrace');
      countries = [];
      errorMessage = 'Error parsing server response';
    } catch (e, stackTrace) {
      debugPrint('Error fetching countries: $e');
      debugPrint('Stack trace: $stackTrace');
      countries = [];
      errorMessage = 'Error loading countries: ${e.toString()}';
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

      final url = Uri.parse('${AppConstants.baseUrl}/mobile/countries/$countryId/states');
      debugPrint('Fetching states from: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('States API Response Status: ${response.statusCode}');
      debugPrint('States API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response formats
        List<dynamic> stateList = [];
        if (data is List) {
          stateList = data;
        } else if (data is Map) {
          // Try multiple possible keys
          stateList = data['data'] ??
                     data['Data'] ??
                     data['states'] ??
                     data['result'] ??
                     data['results'] ??
                     [];
        }

        if (stateList.isEmpty) {
          debugPrint('Warning: State list is empty for country $countryId. Response structure might have changed.');
          debugPrint('Full response: $data');
        }

        states = stateList.map((e) {
          try {
            return StateModel.fromJson(e as Map<String, dynamic>);
          } catch (error) {
            debugPrint('Error parsing state: $e, Error: $error');
            return null;
          }
        }).whereType<StateModel>().toList();

        debugPrint('Successfully loaded ${states.length} states for country $countryId');
      } else {
        debugPrint('Failed to fetch states. Status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        states = [];
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching states: $e');
      debugPrint('Stack trace: $stackTrace');
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

      final url = Uri.parse('${AppConstants.baseUrl}/mobile/states/$stateId/cities');
      debugPrint('Fetching cities from: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('Cities API Response Status: ${response.statusCode}');
      debugPrint('Cities API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response formats
        List<dynamic> cityList = [];
        if (data is List) {
          cityList = data;
        } else if (data is Map) {
          // Try multiple possible keys
          cityList = data['data'] ??
                    data['Data'] ??
                    data['cities'] ??
                    data['result'] ??
                    data['results'] ??
                    [];
        }

        if (cityList.isEmpty) {
          debugPrint('Warning: City list is empty for state $stateId. Response structure might have changed.');
          debugPrint('Full response: $data');
        }

        cities = cityList.map((e) {
          try {
            return CityModel.fromJson(e as Map<String, dynamic>);
          } catch (error) {
            debugPrint('Error parsing city: $e, Error: $error');
            return null;
          }
        }).whereType<CityModel>().toList();

        debugPrint('Successfully loaded ${cities.length} cities for state $stateId');
      } else {
        debugPrint('Failed to fetch cities. Status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        cities = [];
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching cities: $e');
      debugPrint('Stack trace: $stackTrace');
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
    states = [];
    cities = [];
    errorMessage = null;
    isRegistrationSuccess = false;
  }

  /// Register new user/admin
  Future<bool> registerUser({
    required String userName,
    required String companyName,
    String? companyNameUrdu,
    required String contactNumber,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String address,
    required String countryId,
    required String stateId,
    required String cityId,
    String? referenceCode,
  }) async {
    try {
      isLoading = true;
      errorMessage = null;
      isRegistrationSuccess = false;
      notifyListeners();

      final url = Uri.parse('${AppConstants.baseUrl}/mobile/register-retailer');
      debugPrint('Registering user at: $url');

      final body = {
        'user_name': userName,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'contact_number': contactNumber,
        'company_name': companyName,
        'country_id': countryId,
        'state_id': stateId,
        'city_id': cityId,
        'address': address,
      };

      // Add optional fields only if they are provided
      if (companyNameUrdu != null && companyNameUrdu.isNotEmpty) {
        body['company_name_urdu'] = companyNameUrdu;
      }
      if (referenceCode != null && referenceCode.isNotEmpty) {
        body['reference_code'] = referenceCode;
      }

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


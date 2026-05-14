import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../util/app_constants.dart';
import '../util/session_manager.dart';
import '../models/customer_model.dart';
import '../models/customer_emi_model.dart';
import '../models/location_model.dart';

class CustomerProvider with ChangeNotifier {
  final picker = ImagePicker();
  List<File> mobilePictures = [];
  List<File> documents = [];
  File? profilePicture; // Customer profile picture (single image)
  File? frontCnicPicture; // Front CNIC picture
  File? backCnicPicture; // Back CNIC picture

  // Public variables for customer list
  CustomersModel? customersModel;
  bool isLoading = false;

  // Location data - Countries, States, Cities
  List<CountryModel> countries = [];
  List<StateModel> states = [];
  List<CityModel> cities = [];
  bool isLoadingCountries = false;
  bool isLoadingStates = false;
  bool isLoadingCities = false;

  // Selected location IDs for edit mode
  CountryModel? selectedCountry;
  StateModel? selectedState;
  CityModel? selectedCity;

  // Pagination variables - following the sample pattern
  PaginatedCustomersModel? paginatedCustomersModel;
  List<Datum> paginatedCustomers = [];
  int pageIndex = 1;
  int totalPages = 1;
  bool? showMore;
  bool? showingMore;
  bool isLoadingMore = false;

  // Computed property for pagination - check if there are more pages to load
  // Uses pageIndex <= totalPages pattern from sample (totalPages = lastPage from API)
  bool get hasMorePages => pageIndex <= totalPages;

  // Reset pagination state
  void resetPagination() {
    paginatedCustomers = [];
    pageIndex = 1;
    totalPages = 1;
    showMore = null;
    showingMore = null;
    isLoadingMore = false;
  }

  // Clear customer data - called when refreshing
  void clearCustomerData() {
    paginatedCustomersModel = null;
    paginatedCustomers = [];
    pageIndex = 1;
    totalPages = 1;
    showMore = null;
    showingMore = null;
    notifyListeners();
  }

  // Show dialog to choose between gallery and camera
  Future<void> showImageSourceDialog(
    BuildContext context, {
    required bool isMobilePicture,
  }) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      if (source == ImageSource.gallery) {
        await pickImagesFromGallery(isMobilePicture: isMobilePicture);
      } else {
        await captureImageFromCamera(isMobilePicture: isMobilePicture);
      }
    }
  }

  // Pick multiple images from gallery
  Future<void> pickImagesFromGallery({required bool isMobilePicture}) async {
    final List<XFile> pickedFiles = await picker.pickMultiImage(
      maxWidth: 800, // Further reduced to minimize file size
      maxHeight: 800, // Further reduced to minimize file size
      imageQuality: 60, // Further reduced to minimize file size
    );

    if (pickedFiles.isNotEmpty) {
      if (isMobilePicture) {
        mobilePictures.addAll(pickedFiles.map((file) => File(file.path)));
      } else {
        documents.addAll(pickedFiles.map((file) => File(file.path)));
      }
      notifyListeners();
    }
  }

  // Capture image from camera (can capture multiple)
  Future<void> captureImageFromCamera({required bool isMobilePicture}) async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800, // Further reduced to minimize file size
      maxHeight: 800, // Further reduced to minimize file size
      imageQuality: 60, // Further reduced to minimize file size
    );

    if (pickedFile != null) {
      if (isMobilePicture) {
        mobilePictures.add(File(pickedFile.path));
      } else {
        documents.add(File(pickedFile.path));
      }
      notifyListeners();
    }
  }

  // Get total file size in MB
  double getTotalFileSizeMB() {
    double totalSize = 0;
    if (profilePicture != null) {
      totalSize += profilePicture!.lengthSync() / (1024 * 1024);
    }
    for (var file in mobilePictures) {
      totalSize += file.lengthSync() / (1024 * 1024); // Convert to MB
    }
    for (var file in documents) {
      totalSize += file.lengthSync() / (1024 * 1024); // Convert to MB
    }
    return totalSize;
  }

  void removeMobilePicture(int index) {
    mobilePictures.removeAt(index);
    notifyListeners();
  }

  void removeDocument(int index) {
    documents.removeAt(index);
    notifyListeners();
  }

  // Profile picture methods (single image)
  Future<void> showProfilePictureSourceDialog(BuildContext context) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      await pickProfilePicture(source);
    }
  }

  Future<void> pickProfilePicture(ImageSource source) async {
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      profilePicture = File(pickedFile.path);
      notifyListeners();
    }
  }

  void removeProfilePicture() {
    profilePicture = null;
    notifyListeners();
  }

  // Front CNIC picture methods
  Future<void> showFrontCnicSourceDialog(BuildContext context) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      await pickFrontCnicPicture(source);
    }
  }

  Future<void> pickFrontCnicPicture(ImageSource source) async {
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      frontCnicPicture = File(pickedFile.path);
      notifyListeners();
    }
  }

  void removeFrontCnicPicture() {
    frontCnicPicture = null;
    notifyListeners();
  }

  // Back CNIC picture methods
  Future<void> showBackCnicSourceDialog(BuildContext context) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      await pickBackCnicPicture(source);
    }
  }

  Future<void> pickBackCnicPicture(ImageSource source) async {
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      backCnicPicture = File(pickedFile.path);
      notifyListeners();
    }
  }

  void removeBackCnicPicture() {
    backCnicPicture = null;
    notifyListeners();
  }

  void clearAllData() {
    profilePicture = null;
    frontCnicPicture = null;
    backCnicPicture = null;
    mobilePictures.clear();
    documents.clear();
    // Don't call notifyListeners during dispose
  }

  // Old methods kept for backward compatibility (commented out)
  // List<File> capturedImages = [];
  // Future<void> captureImage() async {
  //   final pickedFile = await picker.pickImage(
  //     source: ImageSource.camera,
  //     maxWidth: 1800,
  //     maxHeight: 1800,
  //     imageQuality: 90,
  //   );
  //   if (pickedFile != null) {
  //     capturedImages.add(File(pickedFile.path));
  //     notifyListeners();
  //   }
  // }
  // void removeImage(int index) {
  //   capturedImages.removeAt(index);
  //   notifyListeners();
  // }

  int _imeiCount = 1;
  String _imei1 = '';
  String _imei2 = '';

  int get imeiCount => _imeiCount;
  String get imei1 => _imei1;
  String get imei2 => _imei2;

  bool get isValid {
    if (_imei1.isEmpty) return false;
    if (_imeiCount == 2 && _imei2.isEmpty) return false;
    return true;
  }

  void setImeiCount(int count) {
    _imeiCount = count;
    notifyListeners();
  }

  void setImei1(String value) {
    _imei1 = value;
    notifyListeners();
  }

  void setImei2(String value) {
    _imei2 = value;
    notifyListeners();
  }

  // Commented out Firebase registration function
  // Future<void> saveCustomerToFirebase({
  //   required String phone,
  //   required String name,
  //   required String altPhone,
  //   required int imeiCount,
  //   required String imei1,
  //   String? imei2,
  // }) async {
  //   final ref = FirebaseDatabase.instance.ref("customers").push();
  //   await ref.set({
  //     "phone": phone,
  //     "name": name,
  //     "alternatePhone": altPhone,
  //     "imeiCount": imeiCount,
  //     "imei1": imei1,
  //     "imei2": imei2 ?? "",
  //     "createdAt": DateTime.now().toIso8601String(),
  //   });
  // }

  // New API function to register user device with retry logic
  Future<Map<String, dynamic>> registerUserDevice({
    required String customerName,
    required String email,
    required String cnic,
    required String customerMobileNo,
    required String? imei1,
    String? imei2,
    required String address,
    required int countryId,
    required int cityId,
    required int stateId,
    String? mobileType,
    String? mobileModel,
    File? profilePicture,
    File? frontCnicPicture,
    File? backCnicPicture,
    required List<File> mobilePictures,
    required List<File>
    documents, // Keeping for backward compatibility but won't be sent
  }) async {
    const int maxRetries = 3;
    int retryCount = 0;

    // Get auth token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token') ?? '';

    if (authToken.isEmpty) {
      return {
        'success': false,
        'error': 'Authentication token not found. Please login again.',
      };
    }

    while (retryCount < maxRetries) {
      try {
        // New API endpoint
        final url = Uri.parse('${AppConstants.baseUrl}/mobile/customers');

        var request = http.MultipartRequest('POST', url);

        // Add headers with auth token
        // Note: Do NOT set Content-Type for multipart requests - the http package handles it automatically
        request.headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        });

        // Add text fields with new field names
        request.fields['customer_name'] = customerName;
        request.fields['contact_number'] = customerMobileNo;
        request.fields['email'] = email;
        request.fields['cnic_number'] = cnic;
        request.fields['address'] = address;
        request.fields['country_id'] = countryId.toString();
        request.fields['state_id'] = stateId.toString();
        request.fields['city_id'] = cityId.toString();

        // Add IMEI type based on whether imei2 is provided
        request.fields['imei_type'] = (imei2 != null && imei2.isNotEmpty)
            ? 'dual'
            : 'single';
        request.fields['imei_1'] = imei1 ?? '';

        // Only include imei_2 if it's provided (dual IMEI)
        if (imei2 != null && imei2.isNotEmpty) {
          request.fields['imei_2'] = imei2;
        }

        // Add mobile type and mobile model (lowercase for API compatibility)
        if (mobileType != null && mobileType.isNotEmpty) {
          request.fields['mobile_type'] = mobileType.toLowerCase();
        }
        if (mobileModel != null && mobileModel.isNotEmpty) {
          request.fields['mobile_model'] = mobileModel;
        }

        // DEBUG: Log the payload for ADD CUSTOMER
        debugPrint('=== ADD CUSTOMER PAYLOAD (NEW API) ===');
        debugPrint('URL: $url');
        request.fields.forEach((key, value) {
          debugPrint('$key: $value');
        });
        debugPrint('============================');

        // Add customer_image (profile picture)
        if (profilePicture != null) {
          try {
            var multipartFile = await http.MultipartFile.fromPath(
              'customer_image',
              profilePicture.path,
            );
            request.files.add(multipartFile);
            debugPrint('Added customer_image: ${profilePicture.path}');
          } catch (e) {
            debugPrint('Error adding customer_image: $e');
          }
        }

        // Add cnic_front_image
        if (frontCnicPicture != null) {
          try {
            var multipartFile = await http.MultipartFile.fromPath(
              'cnic_front_image',
              frontCnicPicture.path,
            );
            request.files.add(multipartFile);
            debugPrint('Added cnic_front_image: ${frontCnicPicture.path}');
          } catch (e) {
            debugPrint('Error adding cnic_front_image: $e');
          }
        }

        // Add cnic_back_image
        if (backCnicPicture != null) {
          try {
            var multipartFile = await http.MultipartFile.fromPath(
              'cnic_back_image',
              backCnicPicture.path,
            );
            request.files.add(multipartFile);
            debugPrint('Added cnic_back_image: ${backCnicPicture.path}');
          } catch (e) {
            debugPrint('Error adding cnic_back_image: $e');
          }
        }

        // Add mobile_images[] - multiple mobile pictures
        for (var i = 0; i < mobilePictures.length; i++) {
          var file = mobilePictures[i];
          try {
            var multipartFile = await http.MultipartFile.fromPath(
              'mobile_images[]',
              file.path,
            );
            request.files.add(multipartFile);
            debugPrint('Added mobile_images[$i]: ${file.path}');
          } catch (e) {
            debugPrint('Error adding mobile_images[$i]: $e');
          }
        }

        // Note: documents are NOT sent to the new API as per requirements

        // Calculate and log file sizes
        double totalSizeMB = getTotalFileSizeMB();
        debugPrint(
          'Sending request with ${profilePicture != null ? 1 : 0} profile picture and ${mobilePictures.length} mobile pictures',
        );
        debugPrint(
          'Request size: ${request.fields.length} fields, ${request.files.length} files',
        );
        debugPrint('Total file size: ${totalSizeMB.toStringAsFixed(2)} MB');

        // Warn if total size is too large (more than 10MB)
        if (totalSizeMB > 10) {
          debugPrint(
            'WARNING: Total file size (${totalSizeMB.toStringAsFixed(2)} MB) is large. This may cause connection issues.',
          );
        }

        // Send request with longer timeout for large file uploads
        // Note: The 408 error is server-side, meaning server is timing out
        // We need to send the request quickly, so we use a longer client timeout
        final streamedResponse = await request.send().timeout(
          const Duration(
            minutes: 10,
          ), // Very long timeout to allow large uploads
          onTimeout: () {
            throw Exception(
              'Request timeout: The server took too long to respond. Please check your internet connection and file sizes.',
            );
          },
        );

        final response = await http.Response.fromStream(streamedResponse)
            .timeout(
              const Duration(minutes: 2), // 2 minutes to read response
              onTimeout: () {
                throw Exception(
                  'Response timeout: Failed to read response from server',
                );
              },
            );

        debugPrint('API Response Status: ${response.statusCode}');
        debugPrint('API Response Body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          try {
            final responseData = json.decode(response.body);
            return {'success': true, 'data': responseData};
          } catch (e) {
            // If response is not JSON, return success with body
            return {
              'success': true,
              'data': {'message': response.body},
            };
          }
        } else if (response.statusCode == 401) {
          // Unauthorized - Token expired or invalid
          await SessionManager.handleSessionExpiry(response.statusCode);
          return SessionManager.sessionExpiredResponse();
        } else if (response.statusCode == 408) {
          return {
            'success': false,
            'error':
                'Request timeout: The server timed out waiting for the request. This may be due to large file sizes or slow internet connection. Please try:\n1. Reducing the number of images\n2. Using smaller image files\n3. Checking your internet connection speed',
          };
        } else if (response.statusCode == 422) {
          // Validation error - parse and display the actual errors
          debugPrint('=== 422 VALIDATION ERROR ===');
          debugPrint('Full response body: ${response.body}');
          try {
            final errorData = json.decode(response.body);
            String errorMessage = 'Validation failed:\n';

            // Handle Laravel validation error format
            if (errorData['errors'] != null && errorData['errors'] is Map) {
              final errors = errorData['errors'] as Map;
              errors.forEach((field, messages) {
                if (messages is List) {
                  for (var msg in messages) {
                    errorMessage += '• $msg\n';
                  }
                } else {
                  errorMessage += '• $field: $messages\n';
                }
              });
            } else if (errorData['message'] != null) {
              errorMessage = errorData['message'].toString();
            } else {
              errorMessage =
                  'Validation failed. Please check all required fields.';
            }

            debugPrint('Parsed error message: $errorMessage');
            return {'success': false, 'error': errorMessage.trim()};
          } catch (e) {
            debugPrint('Error parsing 422 response: $e');
            return {
              'success': false,
              'error': 'Validation failed: ${response.body}',
            };
          }
        } else {
          // Other error status codes
          debugPrint('=== API ERROR ${response.statusCode} ===');
          debugPrint('Full response body: ${response.body}');
          try {
            final errorData = json.decode(response.body);
            String errorMessage =
                errorData['message'] ?? 'Failed to register customer';
            return {'success': false, 'error': errorMessage};
          } catch (e) {
            return {
              'success': false,
              'error':
                  'Failed to register: ${response.statusCode} - ${response.body}',
            };
          }
        }
      } on SocketException catch (e) {
        retryCount++;
        debugPrint('SocketException (attempt $retryCount/$maxRetries): $e');
        if (retryCount >= maxRetries) {
          final totalSizeMB = getTotalFileSizeMB();
          String errorMsg = 'Connection failed after $maxRetries attempts. ';
          if (totalSizeMB > 10) {
            errorMsg +=
                'The total file size (${totalSizeMB.toStringAsFixed(2)} MB) may be too large. ';
            errorMsg +=
                'Please try:\n1. Reducing the number of images\n2. Using smaller image files\n3. Checking your internet connection';
          } else {
            errorMsg += 'Please check your internet connection and try again.';
          }
          return {'success': false, 'error': errorMsg};
        }
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: retryCount * 2));
      } on http.ClientException catch (e) {
        retryCount++;
        debugPrint('ClientException (attempt $retryCount/$maxRetries): $e');
        if (retryCount >= maxRetries) {
          final totalSizeMB = getTotalFileSizeMB();
          String errorMsg = 'Connection failed after $maxRetries attempts. ';
          if (totalSizeMB > 10) {
            errorMsg +=
                'The total file size (${totalSizeMB.toStringAsFixed(2)} MB) may be too large. ';
            errorMsg +=
                'Please try:\n1. Reducing the number of images\n2. Using smaller image files\n3. Checking your internet connection';
          } else {
            errorMsg += 'Please check your internet connection and try again.';
          }
          return {'success': false, 'error': errorMsg};
        }
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: retryCount * 2));
      } on Exception catch (e) {
        debugPrint('Exception: $e');
        // Don't retry for timeout or other exceptions
        return {'success': false, 'error': e.toString()};
      } catch (e) {
        debugPrint('Error registering user device: $e');
        return {'success': false, 'error': 'Unexpected error: ${e.toString()}'};
      }
    }

    return {
      'success': false,
      'error': 'Failed after $maxRetries attempts. Please try again later.',
    };
  }

  // Public function to update user device
  Future<Map<String, dynamic>> updateUserDevice({
    required int customerId,
    required String customerName,
    required String email,
    required String cnic,
    required String customerMobileNo,
    String? imei1,
    String? imei2,
    required String address,
    required int countryId,
    required int cityId,
    required int stateId,
    String? mobileType,
    String? mobileModel,
    File? profilePicture,
    File? frontCnicPicture,
    File? backCnicPicture,
    required List<File> mobilePictures,
    required List<File> documents,
  }) async {
    const int maxRetries = 3;
    int retryCount = 0;

    // Get auth token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token') ?? '';

    if (authToken.isEmpty) {
      return {
        'success': false,
        'error': 'Authentication token not found. Please login again.',
      };
    }

    while (retryCount < maxRetries) {
      try {
        // New API endpoint for updating customers
        final url = Uri.parse(
          '${AppConstants.baseUrl}/mobile/customers/$customerId',
        );

        debugPrint('Update Customer API URL: $url');

        var request = http.MultipartRequest('POST', url);

        // Add _method for Laravel to recognize this as PUT
        request.fields['_method'] = 'PUT';

        // Add headers with auth token
        // Note: Do NOT set Content-Type for multipart requests - the http package handles it automatically
        request.headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        });

        // Add text fields with new field names
        request.fields['customer_name'] = customerName;
        request.fields['contact_number'] = customerMobileNo;
        request.fields['email'] = email;
        request.fields['cnic_number'] = cnic;
        request.fields['address'] = address;
        request.fields['country_id'] = countryId.toString();
        request.fields['state_id'] = stateId.toString();
        request.fields['city_id'] = cityId.toString();

        // Add IMEI type based on whether imei2 is provided
        request.fields['imei_type'] = (imei2 != null && imei2.isNotEmpty)
            ? 'dual'
            : 'single';
        request.fields['imei_1'] = imei1 ?? '';

        // Only include imei_2 if it's provided
        if (imei2 != null && imei2.isNotEmpty) {
          request.fields['imei_2'] = imei2;
        }

        // Add mobile type and mobile model (lowercase for API compatibility)
        if (mobileType != null && mobileType.isNotEmpty) {
          request.fields['mobile_type'] = mobileType.toLowerCase();
        }
        if (mobileModel != null && mobileModel.isNotEmpty) {
          request.fields['mobile_model'] = mobileModel;
        }

        // DEBUG: Log the payload for UPDATE CUSTOMER
        debugPrint('=== UPDATE CUSTOMER PAYLOAD (NEW API) ===');
        debugPrint('URL: $url');
        debugPrint('Customer ID: $customerId');
        request.fields.forEach((key, value) {
          debugPrint('$key: $value');
        });
        debugPrint('===============================');

        // Add customer_image (profile picture)
        if (profilePicture != null) {
          try {
            var multipartFile = await http.MultipartFile.fromPath(
              'customer_image',
              profilePicture.path,
            );
            request.files.add(multipartFile);
            debugPrint('Added customer_image: ${profilePicture.path}');
          } catch (e) {
            debugPrint('Error adding customer_image: $e');
          }
        }

        // Add cnic_front_image
        if (frontCnicPicture != null) {
          try {
            var multipartFile = await http.MultipartFile.fromPath(
              'cnic_front_image',
              frontCnicPicture.path,
            );
            request.files.add(multipartFile);
            debugPrint('Added cnic_front_image: ${frontCnicPicture.path}');
          } catch (e) {
            debugPrint('Error adding cnic_front_image: $e');
          }
        }

        // Add cnic_back_image
        if (backCnicPicture != null) {
          try {
            var multipartFile = await http.MultipartFile.fromPath(
              'cnic_back_image',
              backCnicPicture.path,
            );
            request.files.add(multipartFile);
            debugPrint('Added cnic_back_image: ${backCnicPicture.path}');
          } catch (e) {
            debugPrint('Error adding cnic_back_image: $e');
          }
        }

        // DEBUG: Log image state before sending
        debugPrint('=== UPDATE IMAGE STATE DEBUG ===');
        debugPrint('Profile picture: ${profilePicture != null ? 'Yes' : 'No'}');
        debugPrint(
          'Existing mobile pictures: ${existingMobilePictures.length} items',
        );
        debugPrint(
          'New mobile pictures to upload: ${mobilePictures.length} files',
        );
        debugPrint(
          'Removed mobile pictures: ${removedMobilePictures.length} items',
        );
        debugPrint('================================');

        // Add existing mobile pictures paths (images that are not removed)
        if (existingMobilePictures.isNotEmpty) {
          for (var i = 0; i < existingMobilePictures.length; i++) {
            request.fields['existing_mobile_images[$i]'] =
                existingMobilePictures[i];
          }
          debugPrint(
            '✅ Keeping ${existingMobilePictures.length} existing mobile pictures',
          );
        } else {
          debugPrint('⚠️ No existing mobile pictures to keep');
        }

        // Add new mobile_images[] - multiple mobile pictures
        for (var i = 0; i < mobilePictures.length; i++) {
          var file = mobilePictures[i];
          try {
            var multipartFile = await http.MultipartFile.fromPath(
              'mobile_images[]',
              file.path,
            );
            request.files.add(multipartFile);
            debugPrint('Added mobile_images[$i]: ${file.path}');
          } catch (e) {
            debugPrint('Error adding mobile_images[$i]: $e');
          }
        }

        // Note: documents are NOT sent to the new API as per requirements

        // Add removed mobile images if any
        if (removedMobilePictures.isNotEmpty) {
          for (var i = 0; i < removedMobilePictures.length; i++) {
            request.fields['removed_mobile_images[$i]'] =
                removedMobilePictures[i];
          }
          debugPrint(
            '🗑️ Removing ${removedMobilePictures.length} mobile pictures',
          );
        }

        double totalSizeMB = getTotalFileSizeMB();
        debugPrint(
          'Updating customer with ${mobilePictures.length} new mobile pictures',
        );
        debugPrint('Removed: ${removedMobilePictures.length} mobile pictures');
        debugPrint('Total file size: ${totalSizeMB.toStringAsFixed(2)} MB');

        // DEBUG: Print COMPLETE payload
        debugPrint('');
        debugPrint(
          '╔═══════════════════════════════════════════════════════════════════',
        );
        debugPrint('║ UPDATE CUSTOMER API - COMPLETE PAYLOAD');
        debugPrint(
          '╠═══════════════════════════════════════════════════════════════════',
        );
        debugPrint('║ URL: ${url.toString()}');
        debugPrint('║ Method: POST');
        debugPrint(
          '╠═══════════════════════════════════════════════════════════════════',
        );
        debugPrint('║ HEADERS:');
        request.headers.forEach((key, value) {
          if (key == 'Authorization') {
            debugPrint(
              '║   $key: Bearer ${value.substring(7, value.length > 20 ? 27 : value.length)}...',
            );
          } else {
            debugPrint('║   $key: $value');
          }
        });
        debugPrint(
          '╠═══════════════════════════════════════════════════════════════════',
        );
        debugPrint('║ FORM FIELDS (${request.fields.length} total):');
        debugPrint(
          '╠═══════════════════════════════════════════════════════════════════',
        );

        // Print all fields in organized groups
        debugPrint('║ 📝 CUSTOMER INFORMATION:');
        [
          'customer_name',
          'email',
          'cnic_number',
          'contact_number',
          'address',
          'city_id',
          'state_id',
          'country_id',
        ].forEach((key) {
          if (request.fields.containsKey(key)) {
            debugPrint('║   $key: ${request.fields[key]}');
          }
        });

        debugPrint('║');
        debugPrint('║ 📱 DEVICE INFORMATION:');
        [
          'imei_1',
          'imei_2',
          'imei_type',
          'mobile_model',
          'mobile_type',
        ].forEach((key) {
          if (request.fields.containsKey(key)) {
            debugPrint('║   $key: ${request.fields[key]}');
          }
        });

        debugPrint('║');
        debugPrint('║ 🖼️ EXISTING MOBILE PICTURES (to keep):');
        var existingMobilePicsCount = 0;
        request.fields.forEach((key, value) {
          if (key.startsWith('existing_mobile_pictures[')) {
            debugPrint('║   $key: $value');
            existingMobilePicsCount++;
          }
        });
        if (existingMobilePicsCount == 0) {
          debugPrint('║   (none)');
        }

        debugPrint('║');
        debugPrint('║ 📄 EXISTING DOCUMENTS (to keep):');
        var existingDocsCount = 0;
        request.fields.forEach((key, value) {
          if (key.startsWith('existing_documents[')) {
            debugPrint('║   $key: $value');
            existingDocsCount++;
          }
        });
        if (existingDocsCount == 0) {
          debugPrint('║   (none)');
        }

        debugPrint('║');
        debugPrint('║ 🗑️ REMOVED MOBILE PICTURES (to delete):');
        var removedMobilePicsCount = 0;
        request.fields.forEach((key, value) {
          if (key.startsWith('removed_mobile_pictures[')) {
            debugPrint('║   $key: $value');
            removedMobilePicsCount++;
          }
        });
        if (removedMobilePicsCount == 0) {
          debugPrint('║   (none)');
        }

        debugPrint('║');
        debugPrint('║ 🗑️ REMOVED DOCUMENTS (to delete):');
        var removedDocsCount = 0;
        request.fields.forEach((key, value) {
          if (key.startsWith('removed_documents[')) {
            debugPrint('║   $key: $value');
            removedDocsCount++;
          }
        });
        if (removedDocsCount == 0) {
          debugPrint('║   (none)');
        }

        debugPrint(
          '╠═══════════════════════════════════════════════════════════════════',
        );
        debugPrint('║ FILES TO UPLOAD (${request.files.length} total):');
        debugPrint(
          '╠═══════════════════════════════════════════════════════════════════',
        );
        if (request.files.isEmpty) {
          debugPrint('║   (no new files to upload)');
        } else {
          for (var i = 0; i < request.files.length; i++) {
            var file = request.files[i];
            var fileSize = (file.length / 1024).toStringAsFixed(2);
            debugPrint(
              '║   [$i] ${file.field}: ${file.filename} (${fileSize} KB)',
            );
          }
        }
        debugPrint(
          '╠═══════════════════════════════════════════════════════════════════',
        );
        debugPrint('║ SUMMARY:');
        debugPrint('║   Total Form Fields: ${request.fields.length}');
        debugPrint('║   Total Files: ${request.files.length}');
        debugPrint('║   Total Size: ${totalSizeMB.toStringAsFixed(2)} MB');
        debugPrint(
          '║   Existing Images Kept: $existingMobilePicsCount mobile + $existingDocsCount docs',
        );
        debugPrint(
          '║   Images Removed: $removedMobilePicsCount mobile + $removedDocsCount docs',
        );
        debugPrint(
          '╚═══════════════════════════════════════════════════════════════════',
        );
        debugPrint('');

        if (totalSizeMB > 10) {
          debugPrint(
            'WARNING: Total file size (${totalSizeMB.toStringAsFixed(2)} MB) is large.',
          );
        }

        final streamedResponse = await request.send().timeout(
          const Duration(minutes: 10),
          onTimeout: () {
            throw Exception(
              'Request timeout: The server took too long to respond.',
            );
          },
        );

        final response = await http.Response.fromStream(streamedResponse)
            .timeout(
              const Duration(minutes: 2),
              onTimeout: () {
                throw Exception(
                  'Response timeout: Failed to read response from server',
                );
              },
            );

        debugPrint('Update API Response Status: ${response.statusCode}');
        debugPrint('Update API Response Body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          try {
            final responseData = json.decode(response.body);

            log('Update API success response data: $responseData');
            return {'success': true, 'data': responseData};
          } catch (e) {
            return {
              'success': true,
              'data': {'message': response.body},
            };
          }
        } else if (response.statusCode == 401) {
          await SessionManager.handleSessionExpiry(response.statusCode);
          return SessionManager.sessionExpiredResponse();
        } else if (response.statusCode == 408) {
          return {
            'success': false,
            'error': 'Request timeout. Please try reducing file sizes.',
          };
        } else if (response.statusCode == 422) {
          // Validation error - parse and display the actual errors
          debugPrint('=== 422 VALIDATION ERROR (UPDATE) ===');
          debugPrint('Full response body: ${response.body}');
          try {
            final errorData = json.decode(response.body);
            String errorMessage = 'Validation failed:\n';

            // Handle Laravel validation error format
            if (errorData['errors'] != null && errorData['errors'] is Map) {
              final errors = errorData['errors'] as Map;
              errors.forEach((field, messages) {
                if (messages is List) {
                  for (var msg in messages) {
                    errorMessage += '• $msg\n';
                  }
                } else {
                  errorMessage += '• $field: $messages\n';
                }
              });
            } else if (errorData['message'] != null) {
              errorMessage = errorData['message'].toString();
            } else {
              errorMessage =
                  'Validation failed. Please check all required fields.';
            }

            debugPrint('Parsed error message: $errorMessage');
            return {'success': false, 'error': errorMessage.trim()};
          } catch (e) {
            debugPrint('Error parsing 422 response: $e');
            return {
              'success': false,
              'error': 'Validation failed: ${response.body}',
            };
          }
        } else {
          // Other error status codes
          debugPrint('=== API ERROR ${response.statusCode} ===');
          debugPrint('Full response body: ${response.body}');
          try {
            final errorData = json.decode(response.body);
            String errorMessage =
                errorData['message'] ?? 'Failed to update customer';
            return {'success': false, 'error': errorMessage};
          } catch (e) {
            return {
              'success': false,
              'error':
                  'Failed to update: ${response.statusCode} - ${response.body}',
            };
          }
        }
      } on SocketException catch (e) {
        retryCount++;
        debugPrint('SocketException (attempt $retryCount/$maxRetries): $e');
        if (retryCount >= maxRetries) {
          return {
            'success': false,
            'error':
                'Connection failed. Please check your internet connection.',
          };
        }
        await Future.delayed(Duration(seconds: retryCount * 2));
      } on http.ClientException catch (e) {
        retryCount++;
        debugPrint('ClientException (attempt $retryCount/$maxRetries): $e');
        if (retryCount >= maxRetries) {
          return {
            'success': false,
            'error':
                'Connection failed. Please check your internet connection.',
          };
        }
        await Future.delayed(Duration(seconds: retryCount * 2));
      } on Exception catch (e) {
        debugPrint('Exception: $e');
        return {'success': false, 'error': e.toString()};
      } catch (e) {
        debugPrint('Error updating user device: $e');
        return {'success': false, 'error': 'Unexpected error: ${e.toString()}'};
      }
    }

    return {
      'success': false,
      'error': 'Failed after $maxRetries attempts. Please try again later.',
    };
  }

  // Public function to get single customer from API
  Datum? singleCustomer;
  List<String> existingMobilePictures = [];
  List<String> existingDocuments = [];
  List<String> removedMobilePictures = [];
  List<String> removedDocuments = [];

  // Public function to get single customer from API
  // GET: api/mobile/customers/{customerId}
  Future<void> getSingleCustomer(BuildContext context, int customerId) async {
    // Only show loading if we don't have data yet
    if (singleCustomer == null) {
      isLoading = true;
      notifyListeners();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token') ?? '';

      // New API endpoint: api/mobile/customers/{customerId}
      final url = '${AppConstants.baseUrl}/mobile/customers/$customerId';

      debugPrint("Single Customer API URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        debugPrint("Single Customer API success response");
        final jsonData = json.decode(response.body);

        // Support both old format (Data) and new format (data)
        final customerData = jsonData['Data'] ?? jsonData['data'];
        final isSuccess =
            jsonData['success'] == true ||
            jsonData['status'] == true ||
            customerData != null;

        if (isSuccess && customerData != null) {
          // Debug: Log raw location data from API
          debugPrint('=== RAW LOCATION DATA FROM API ===');
          debugPrint(
            'Raw country: ${customerData['country']} (type: ${customerData['country'].runtimeType})',
          );
          debugPrint(
            'Raw state: ${customerData['state']} (type: ${customerData['state'].runtimeType})',
          );
          debugPrint(
            'Raw city: ${customerData['city']} (type: ${customerData['city'].runtimeType})',
          );
          debugPrint(
            'Raw is_active: ${customerData['is_active']} (type: ${customerData['is_active'].runtimeType})',
          );
          debugPrint('==================================');

          singleCustomer = Datum.fromJson(customerData);

          // The customer list response currently includes unlock_code, while
          // some single-customer responses may omit it. Keep the model as the
          // source of truth by merging the cached list value when needed.
          if (singleCustomer!.unlockCode == null ||
              singleCustomer!.unlockCode!.isEmpty) {
            Datum? cachedCustomer;
            for (final customer in paginatedCustomers) {
              if (customer.id == customerId) {
                cachedCustomer = customer;
                break;
              }
            }

            if (cachedCustomer?.unlockCode != null &&
                cachedCustomer!.unlockCode!.isNotEmpty) {
              singleCustomer = singleCustomer!.copyWith(
                unlockCode: cachedCustomer.unlockCode,
              );
            }
          }

          // Debug: Log parsed location IDs
          debugPrint('=== PARSED LOCATION IDs ===');
          debugPrint('Parsed country ID: ${singleCustomer!.country}');
          debugPrint('Parsed state ID: ${singleCustomer!.state}');
          debugPrint('Parsed city ID: ${singleCustomer!.city}');
          debugPrint('Parsed isActive: ${singleCustomer!.isActive}');
          debugPrint('===========================');

          debugPrint('=== LOADING CUSTOMER IMAGES DEBUG ===');
          debugPrint('mobileImages list: ${singleCustomer!.mobileImages}');
          debugPrint(
            'Raw mobilePicture field: ${singleCustomer!.mobilePicture}',
          );
          debugPrint('Raw documents field: ${singleCustomer!.documents}');

          // Use mobileImages list from new API format first
          if (singleCustomer!.mobileImages.isNotEmpty) {
            existingMobilePictures = List<String>.from(
              singleCustomer!.mobileImages,
            );
            debugPrint(
              '✅ Using mobileImages list: ${existingMobilePictures.length} mobile pictures',
            );
            debugPrint('Mobile pictures: $existingMobilePictures');
          } else if (singleCustomer!.mobilePicture.isNotEmpty) {
            // Fallback to parsing mobilePicture as JSON string (old API format)
            try {
              final mobilePics = json.decode(singleCustomer!.mobilePicture);
              if (mobilePics is List) {
                existingMobilePictures = List<String>.from(mobilePics);
                debugPrint(
                  '✅ Parsed ${existingMobilePictures.length} mobile pictures from JSON string',
                );
                debugPrint('Mobile pictures: $existingMobilePictures');
              }
            } catch (e) {
              debugPrint("❌ Error parsing mobile pictures: $e");
              existingMobilePictures = [];
            }
          } else {
            debugPrint('⚠️ No mobile pictures found');
            existingMobilePictures = [];
          }

          if (singleCustomer!.documents.isNotEmpty) {
            try {
              final docs = json.decode(singleCustomer!.documents);
              if (docs is List) {
                existingDocuments = List<String>.from(docs);
                debugPrint('✅ Parsed ${existingDocuments.length} documents');
                debugPrint('Documents: $existingDocuments');
              }
            } catch (e) {
              debugPrint("❌ Error parsing documents: $e");
              existingDocuments = [];
            }
          } else {
            debugPrint('⚠️ documents field is empty');
            existingDocuments = [];
          }

          debugPrint(
            'Final state - existingMobilePictures: ${existingMobilePictures.length}',
          );
          debugPrint(
            'Final state - existingDocuments: ${existingDocuments.length}',
          );
          debugPrint('====================================');
        }
      } else if (response.statusCode == 401) {
        debugPrint("Single Customer API unauthorized 401: ${response.body}");
        await SessionManager.handleSessionExpiry(response.statusCode);
      } else {
        debugPrint(
          "Single Customer API error ${response.statusCode}: ${response.body}",
        );
      }
    } catch (e) {
      debugPrint('Error fetching single customer: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Public function to remove existing mobile picture
  void removeExistingMobilePicture(int index) {
    if (index < existingMobilePictures.length) {
      removedMobilePictures.add(existingMobilePictures[index]);
      existingMobilePictures.removeAt(index);
      notifyListeners();
    }
  }

  // Public function to remove existing document
  void removeExistingDocument(int index) {
    if (index < existingDocuments.length) {
      removedDocuments.add(existingDocuments[index]);
      existingDocuments.removeAt(index);
      notifyListeners();
    }
  }

  /// Update singleCustomer and notify listeners (used to clear existing images)
  void updateSingleCustomer(Datum? customer) {
    singleCustomer = customer;
    notifyListeners();
  }

  /// Clear profile image from singleCustomer
  void clearExistingProfileImage() {
    if (singleCustomer != null) {
      singleCustomer = singleCustomer!.copyWith(profileImage: '');
      notifyListeners();
    }
  }

  /// Clear front CNIC image from singleCustomer
  void clearExistingFrontCnicImage() {
    if (singleCustomer != null) {
      singleCustomer = singleCustomer!.copyWith(cnicFrontImage: '');
      notifyListeners();
    }
  }

  /// Clear back CNIC image from singleCustomer
  void clearExistingBackCnicImage() {
    if (singleCustomer != null) {
      singleCustomer = singleCustomer!.copyWith(cnicBackImage: '');
      notifyListeners();
    }
  }

  // Public function to clear edit data
  void clearEditData() {
    singleCustomer = null;
    existingMobilePictures.clear();
    existingDocuments.clear();
    removedMobilePictures.clear();
    removedDocuments.clear();
    // Don't call notifyListeners during dispose
  }

  // Clear all customer management screen data (called when opening new customer)
  void clearCustomerManagementData() {
    singleCustomer = null;
    singleUserDeviceStatus = null;
    singleUserDevicesError = null;
    customerEmiModel = null;
    emiError = null;
    existingMobilePictures.clear();
    existingDocuments.clear();
    removedMobilePictures.clear();
    removedDocuments.clear();
    notifyListeners();
  }

  // Current filter and search values for API calls
  String _currentFilter = 'all';
  String _currentSearch = '';
  String _currentMobileType = 'android'; // Default to android
  int _perPage = 10;

  // Getters for filter values
  String get currentFilter => _currentFilter;
  String get currentSearch => _currentSearch;
  String get currentMobileType => _currentMobileType;
  int get perPage => _perPage;

  // Setters for filter and search
  void setFilter(String filter) {
    _currentFilter = filter;
  }

  void setSearch(String search) {
    _currentSearch = search;
  }

  void setMobileType(String mobileType) {
    _currentMobileType = mobileType;
  }

  void setPerPage(int value) {
    _perPage = value;
  }

  // Public function to fetch customers from API - following sample pattern
  Future<bool> fetchCustomers(
    BuildContext context, {
    bool isRefresh = false,
    String? filter,
    String? search,
    String? mobileType,
  }) async {
    // Update filter, search, and mobileType if provided
    if (filter != null) {
      _currentFilter = filter;
    }
    if (search != null) {
      _currentSearch = search;
    }
    if (mobileType != null) {
      _currentMobileType = mobileType;
    }

    if (isRefresh) {
      pageIndex = 1;
    } else {
      if (pageIndex > totalPages) {
        return false;
      }
    }

    if (isRefresh) {
      isLoading = true;
      notifyListeners();
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Get auth token for authorized requests (may be empty; server will handle 401)
      final authToken = prefs.getString('auth_token') ?? '';

      debugPrint("=== Fetch Customers Debug ===");
      debugPrint(
        "Retrieved auth_token from SharedPreferences: ${authToken.isNotEmpty ? 'Token present (${authToken.length} chars)' : 'Token MISSING'}",
      );

      // Build the new API URL with query parameters
      final url =
          '${AppConstants.baseUrl}/mobile/customers?search=$_currentSearch&filter=$_currentFilter&mobile_type=$_currentMobileType&page=$pageIndex&per_page=$_perPage';

      debugPrint("Customer API URL: $url");
      debugPrint("Authorization header: Bearer $authToken");

      final response = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        debugPrint("Customer API success");
        debugPrint("=== FULL RESPONSE BODY ===");
        debugPrint(response.body);
        debugPrint("=== END RESPONSE BODY ===");
        try {
          final jsonData = json.decode(response.body);
          debugPrint("=== JSON Data Keys: ${jsonData.keys.toList()} ===");

          // Debug: Check if data field exists and what type it is
          final dataField = jsonData["Data"] ?? jsonData["data"];
          debugPrint("Data field type: ${dataField.runtimeType}");
          if (dataField is Map) {
            debugPrint("Data field keys: ${dataField.keys.toList()}");
          }

          paginatedCustomersModel = PaginatedCustomersModel.fromJson(jsonData);

          // Update pagination state from API response using the sample pattern
          if (isRefresh) {
            paginatedCustomers = paginatedCustomersModel!.data;
          } else {
            paginatedCustomers.addAll(paginatedCustomersModel!.data);
          }

          pageIndex++;
          totalPages = paginatedCustomersModel!.meta.lastPage;

          // Update showMore flag based on total vs loaded
          if (paginatedCustomersModel!.meta.total ==
              paginatedCustomers.length) {
            showMore = false;
          } else {
            showMore = true;
          }
          showingMore = false;

          // Also update legacy customersModel for backward compatibility
          customersModel = CustomersModel(
            success: paginatedCustomersModel!.success,
            message: paginatedCustomersModel!.message,
            data: paginatedCustomers,
          );

          debugPrint("=== Pagination State After Fetch ===");
          debugPrint("Customers loaded: ${paginatedCustomers.length}");
          debugPrint("Current page index: $pageIndex");
          debugPrint("Total pages: $totalPages");
          debugPrint("Total customers: ${paginatedCustomersModel!.meta.total}");
          debugPrint("Has more pages: $hasMorePages");
          debugPrint("Show more: $showMore");
          notifyListeners();
          return true;
        } catch (parseError) {
          debugPrint("Error parsing customer response: $parseError");
          debugPrint("Full response body: ${response.body}");
          customersModel = CustomersModel(
            success: false,
            message: 'Parse error',
            data: [],
          );
          return false;
        }
      } else if (response.statusCode == 401) {
        debugPrint("Customer API unauthorized 401: ${response.body}");
        await SessionManager.handleSessionExpiry(response.statusCode);
        customersModel = CustomersModel(
          success: false,
          message: 'Unauthorized',
          data: [],
        );
        return false;
      } else {
        debugPrint(
          "Customer API is not work ${response.statusCode} ${response.body}",
        );
        customersModel = CustomersModel(
          success: false,
          message: 'Failed ${response.statusCode}',
          data: [],
        );
        return false;
      }
    } catch (e) {
      debugPrint('Error fetching customers: $e');
      customersModel = CustomersModel(
        success: false,
        message: 'Exception',
        data: [],
      );
      return false;
    } finally {
      isLoading = false;
      showingMore = false;
      notifyListeners();
    }
  }

  // Load more customers for web button - following sample pattern
  void loadMoreCustomers(BuildContext context) {
    if (paginatedCustomersModel != null &&
        paginatedCustomersModel!.meta.currentPage <
            paginatedCustomersModel!.meta.lastPage) {
      pageIndex = paginatedCustomersModel!.meta.currentPage + 1;
      showingMore = true;
      fetchCustomers(context);
      notifyListeners();
    }
  }

  // Fetch more customers (for pagination - load next page) - same as fetchCustomers with isRefresh=false
  Future<bool> fetchMoreCustomers(BuildContext context) async {
    debugPrint("=== fetchMoreCustomers called ===");
    debugPrint(
      "isLoadingMore: $isLoadingMore, pageIndex: $pageIndex, totalPages: $totalPages",
    );

    // Check if already loading
    if (isLoadingMore) {
      debugPrint("Skipping fetchMoreCustomers - already loading");
      return false;
    }

    // Check if no more pages (pageIndex already incremented past totalPages)
    if (pageIndex > totalPages) {
      debugPrint(
        "Skipping fetchMoreCustomers - no more pages (pageIndex $pageIndex > totalPages $totalPages)",
      );
      return false;
    }

    isLoadingMore = true;
    showingMore = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token') ?? '';

      // Build the new API URL with query parameters
      final url =
          '${AppConstants.baseUrl}/mobile/customers?search=$_currentSearch&filter=$_currentFilter&mobile_type=$_currentMobileType&page=$pageIndex&per_page=$_perPage';

      debugPrint("Fetching more customers - page $pageIndex");
      debugPrint("URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        log(
          "Load more API Response: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}",
        );
        try {
          final jsonData = json.decode(response.body);
          paginatedCustomersModel = PaginatedCustomersModel.fromJson(jsonData);

          // Append new customers to existing list - following sample pattern
          paginatedCustomers.addAll(paginatedCustomersModel!.data);
          pageIndex++;
          totalPages = paginatedCustomersModel!.meta.lastPage;

          // Update showMore flag
          if (paginatedCustomersModel!.meta.total ==
              paginatedCustomers.length) {
            showMore = false;
          } else {
            showMore = true;
          }
          showingMore = false;

          // Update legacy customersModel for backward compatibility
          customersModel = CustomersModel(
            success: paginatedCustomersModel!.success,
            message: paginatedCustomersModel!.message,
            data: paginatedCustomers,
          );

          debugPrint("=== After Load More ===");
          debugPrint("New items: ${paginatedCustomersModel!.data.length}");
          debugPrint("Total loaded: ${paginatedCustomers.length}");
          debugPrint("Next page index: $pageIndex");
          debugPrint("Total pages (lastPage): $totalPages");
          debugPrint("Has more pages: ${pageIndex <= totalPages}");
          debugPrint("Show more: $showMore");
          return true;
        } catch (parseError) {
          debugPrint("Error parsing more customers response: $parseError");
          return false;
        }
      } else if (response.statusCode == 401) {
        debugPrint("Load more unauthorized 401");
        await SessionManager.handleSessionExpiry(response.statusCode);
        customersModel = CustomersModel(
          success: false,
          message: 'Unauthorized',
          data: paginatedCustomers,
        );
        return false;
      } else {
        debugPrint("Load more failed: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint('Error fetching more customers: $e');
      return false;
    } finally {
      isLoadingMore = false;
      showingMore = false;
      notifyListeners();
    }
  }

  // Getter for customers list from model
  List<Datum> get customers => customersModel?.data ?? [];

  // Getter for userDevices (same as customers for compatibility)
  List<Datum> get userDevices => customersModel?.data ?? [];

  // --- Device management (single customer) state ---
  bool isSingleUserDevicesLoading = false;
  String? singleUserDevicesError;
  String? singleUserDeviceStatus; // lock/unlock from API
  bool isSendingLockCommand = false;
  bool isSendingUnlockCommand = false;

  // Map to track loading state for each command type
  Map<String, bool> commandLoadingStates = {};

  bool isCommandLoading(String command) =>
      commandLoadingStates[command] ?? false;

  /// Fetch single user's devices/status for a customer id
  /// GET: api/mobile/customers/{customerId}
  /// [showLoading] - if false, won't show full screen loading (used for silent refresh after commands)
  Future<void> fetchSingleUserDevicesForCustomer(
    int customerId, {
    bool showLoading = false,
  }) async {
    if (showLoading && singleUserDeviceStatus == null) {
      isSingleUserDevicesLoading = true;
      singleUserDevicesError = null;
      notifyListeners();
    }

    try {
      // New API endpoint: api/mobile/customers/{customerId}
      final url = '${AppConstants.baseUrl}/mobile/customers/$customerId';
      // If this API is protected, include Bearer token (same token used elsewhere in app)
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token') ?? '';

      final headers = <String, String>{'Accept': 'application/json'};
      if (authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        // Support both old format (Data) and new format (data)
        final customerData = decoded['Data'] ?? decoded['data'];
        if (decoded is Map && customerData is Map) {
          singleUserDeviceStatus =
              customerData['status']?.toString() ?? 'unlock';
        } else {
          singleUserDeviceStatus = 'unlock';
        }
      } else if (response.statusCode == 401) {
        await SessionManager.handleSessionExpiry(response.statusCode);
        singleUserDevicesError =
            'Unauthorized (401). Please login again or ensure token is valid.';
      } else {
        singleUserDevicesError =
            'Failed to fetch status (${response.statusCode})';
      }
    } catch (e) {
      singleUserDevicesError = 'Error fetching status: $e';
    } finally {
      if (showLoading) {
        isSingleUserDevicesLoading = false;
      }
      notifyListeners();
    }
  }

  /// Send lock/unlock command for user (customer) then refresh device status
  /// POST: http://100.113.207.78:8001/api/senduserNotification
  /// body: user_id, status
  Future<bool> sendUserNotificationAndRefresh({
    required int customerId,
    required String status,
  }) async {
    // Set the loading state for this specific command
    commandLoadingStates[status] = true;

    // Keep backward compatibility with old loading states
    if (status.toLowerCase() == 'lock') {
      isSendingLockCommand = true;
    } else if (status.toLowerCase() == 'unlock') {
      isSendingUnlockCommand = true;
    }
    notifyListeners();

    try {
      final url = Uri.parse('${AppConstants.baseUrl}/senduserNotification');
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token') ?? '';

      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      if (authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.post(
        url,
        headers: headers,
        body: <String, String>{
          'user_id': customerId.toString(),
          'status': status,
        },
      );

      if (response.statusCode == 401) {
        await SessionManager.handleSessionExpiry(response.statusCode);
        return false;
      }

      final ok = response.statusCode == 200 || response.statusCode == 201;

      // Refresh after sending command (silently, without full screen loading)
      await fetchSingleUserDevicesForCustomer(customerId, showLoading: false);

      return ok;
    } catch (e) {
      singleUserDevicesError = 'Error sending command: $e';
      return false;
    } finally {
      // Reset the loading state for this specific command
      commandLoadingStates[status] = false;

      // Reset backward compatibility loading states
      if (status.toLowerCase() == 'lock') {
        isSendingLockCommand = false;
      } else if (status.toLowerCase() == 'unlock') {
        isSendingUnlockCommand = false;
      }
      notifyListeners();
    }
  }

  /// Send mobile notification using POST api/mobile/notifications/send
  /// @param customerId - customer ID
  /// @param status - notification status/message
  Future<bool> sendMobileNotification({
    required int customerId,
    required String status,
  }) async {
    // Set the loading state for this specific command
    commandLoadingStates['send_notification'] = true;
    notifyListeners();

    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}/mobile/notifications/send',
      );
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token') ?? '';

      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      };
      if (authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      debugPrint('========================================');
      debugPrint('Sending Mobile Notification');
      debugPrint('URL: $url');
      debugPrint('Headers: $headers');
      debugPrint('Customer ID: $customerId');
      debugPrint('Status: $status');
      debugPrint(
        'Auth Token: ${authToken.isNotEmpty ? "Present (${authToken.length} chars)" : "Missing"}',
      );
      debugPrint('========================================');

      // Using form-urlencoded format (like Postman default)
      final response = await http.post(
        url,
        headers: headers,
        body: <String, String>{
          'customer_id': customerId.toString(),
          'status': status,
        },
      );

      // Alternative: If API expects JSON format, replace above with:
      // final headers = <String, String>{
      //   'Accept': 'application/json',
      //   'Content-Type': 'application/json',
      // };
      // if (authToken.isNotEmpty) {
      //   headers['Authorization'] = 'Bearer $authToken';
      // }
      // final response = await http.post(
      //   url,
      //   headers: headers,
      //   body: jsonEncode({
      //     'customer_id': customerId,
      //     'status': status,
      //   }),
      // );

      debugPrint('========================================');
      debugPrint('Mobile Notification Response');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('Response Headers: ${response.headers}');
      debugPrint('========================================');

      if (response.statusCode == 401) {
        await SessionManager.handleSessionExpiry(response.statusCode);
        return false;
      }

      final ok = response.statusCode == 200 || response.statusCode == 201;

      if (!ok) {
        debugPrint('❌ Error: API returned status ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      } else {
        debugPrint('✅ Mobile notification sent successfully');
      }

      return ok;
    } catch (e, stackTrace) {
      debugPrint('❌ Exception sending mobile notification: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    } finally {
      // Reset the loading state
      commandLoadingStates['send_notification'] = false;
      notifyListeners();
    }
  }

  // Location fetch state
  bool isLocationLoading = false;
  String? locationError;
  double? currentLatitude;
  double? currentLongitude;
  bool hasLocationResponse = false;

  /// Fetch current location for a customer
  /// GET: api/mobile/customers/{customerId}/location
  Future<bool> fetchCustomerLocation(int customerId) async {
    isLocationLoading = true;
    locationError = null;
    hasLocationResponse = false;
    notifyListeners();

    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}/mobile/customers/$customerId/location',
      );
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token') ?? '';

      final headers = <String, String>{'Accept': 'application/json'};
      if (authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      debugPrint('Fetching location from: $url');

      final response = await http.get(url, headers: headers);

      debugPrint(
        'Location API Response: ${response.statusCode} ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Parse latitude and longitude from response
        // Adjust these keys based on actual API response structure
        if (data['success'] == true ||
            data['status'] == true ||
            data['latitude'] != null) {
          currentLatitude = _parseDouble(
            data['latitude'] ??
                data['lat'] ??
                data['data']?['latitude'] ??
                data['data']?['lat'],
          );
          currentLongitude = _parseDouble(
            data['longitude'] ??
                data['lng'] ??
                data['data']?['longitude'] ??
                data['data']?['lng'],
          );
          hasLocationResponse = true;
          debugPrint(
            'Location fetched: lat=$currentLatitude, lng=$currentLongitude',
          );
          return true;
        } else {
          locationError = data['message'] ?? 'Failed to get location';
          return false;
        }
      } else if (response.statusCode == 401) {
        await SessionManager.handleSessionExpiry(response.statusCode);
        locationError = 'Session expired. Please login again.';
        return false;
      } else {
        locationError = 'Failed to fetch location (${response.statusCode})';
        return false;
      }
    } catch (e) {
      debugPrint('Error fetching location: $e');
      locationError = 'Error fetching location: $e';
      return false;
    } finally {
      isLocationLoading = false;
      notifyListeners();
    }
  }

  // Helper to parse double from dynamic value
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Clear location data
  void clearLocationData() {
    currentLatitude = null;
    currentLongitude = null;
    hasLocationResponse = false;
    locationError = null;
    notifyListeners();
  }

  // SIM Details state
  bool isSimDetailsLoading = false;
  String? simDetailsError;
  Map<String, dynamic>? simDetailsData;

  /// Fetch SIM details for a customer
  /// GET: api/mobile/sim-details/customer/{customer_id}
  Future<bool> fetchSimDetails(int customerId) async {
    isSimDetailsLoading = true;
    simDetailsError = null;
    notifyListeners();

    try {
      final url = Uri.parse(
        '${AppConstants.baseUrl}/mobile/sim-details/customer/$customerId',
      );
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token') ?? '';

      final headers = <String, String>{'Accept': 'application/json'};
      if (authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      debugPrint('Fetching SIM details from: $url');

      final response = await http.get(url, headers: headers);

      debugPrint(
        'SIM Details API Response: ${response.statusCode} ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Store the full response data
        if (data['success'] == true ||
            data['status'] == true ||
            data['data'] != null) {
          simDetailsData = data['data'] is Map
              ? Map<String, dynamic>.from(data['data'])
              : data;
          debugPrint('SIM details fetched: $simDetailsData');
          return true;
        } else {
          simDetailsError = data['message'] ?? 'Failed to get SIM details';
          return false;
        }
      } else if (response.statusCode == 401) {
        await SessionManager.handleSessionExpiry(response.statusCode);
        simDetailsError = 'Session expired. Please login again.';
        return false;
      } else {
        simDetailsError =
            'Failed to fetch SIM details (${response.statusCode})';
        return false;
      }
    } catch (e) {
      debugPrint('Error fetching SIM details: $e');
      simDetailsError = 'Error fetching SIM details: $e';
      return false;
    } finally {
      isSimDetailsLoading = false;
      notifyListeners();
    }
  }

  // Clear SIM details data
  void clearSimDetailsData() {
    simDetailsData = null;
    simDetailsError = null;
    notifyListeners();
  }

  // PIN verification state
  bool isPinVerifying = false;

  // Customer EMI state
  CustomerEmiModel? customerEmiModel;
  bool isEmiLoading = false;
  String? emiError;
  bool isUpdatingEmiPayment = false;

  /// Fetch Customer EMI details
  /// GET: api/mobile/emis/{customerId}
  Future<bool> fetchCustomerEmi(int customerId) async {
    isEmiLoading = true;
    emiError = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token') ?? '';

      if (authToken.isEmpty) {
        emiError = 'Authentication token not found. Please login again.';
        return false;
      }

      final url = Uri.parse('${AppConstants.baseUrl}/mobile/emis/$customerId');

      debugPrint('Fetch Customer EMI URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      debugPrint('Fetch Customer EMI Response Status: ${response.statusCode}');
      debugPrint('Fetch Customer EMI Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        customerEmiModel = CustomerEmiModel.fromJson(responseData);
        return customerEmiModel?.success ?? false;
      } else if (response.statusCode == 401) {
        await SessionManager.handleSessionExpiry(response.statusCode);
        emiError = 'Session expired. Please login again.';
        return false;
      } else if (response.statusCode == 404) {
        customerEmiModel = CustomerEmiModel.empty(
          message: 'No EMI records found.',
        );
        return true;
      } else {
        try {
          final errorData = json.decode(response.body);
          emiError = errorData['message'] ?? 'Failed to fetch EMI details';
        } catch (e) {
          emiError = 'Failed to fetch EMI details: ${response.statusCode}';
        }
        return false;
      }
    } catch (e) {
      debugPrint('Error fetching customer EMI: $e');
      emiError = 'Network error: ${e.toString()}';
      return false;
    } finally {
      isEmiLoading = false;
      notifyListeners();
    }
  }

  /// Update EMI payment status
  /// POST: api/mobile/emis/details/{emiDetailId}/mark-paid
  Future<Map<String, dynamic>> updateEmiPaymentStatus({
    required String emiDtlId,
    required String paymentMethod,
    required String paymentDate,
    String? transactionId,
    File? receiptImage,
  }) async {
    isUpdatingEmiPayment = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token') ?? '';

      if (authToken.isEmpty) {
        return {
          'success': false,
          'error': 'Authentication token not found. Please login again.',
        };
      }

      final url = Uri.parse(
        '${AppConstants.baseUrl}/mobile/emis/details/$emiDtlId/mark-paid',
      );

      debugPrint('Update EMI Payment Status URL: $url');

      final normalizedPaymentMethod = paymentMethod.trim().toLowerCase();

      final request = http.MultipartRequest('POST', url)
        ..headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        })
        ..fields['payment_date'] = paymentDate
        ..fields['payment_method'] = normalizedPaymentMethod
        ..fields['transaction_id'] = transactionId ?? '';

      if (receiptImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('receiptimage', receiptImage.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint(
        'Update EMI Payment Status Fields: payment_date=$paymentDate, payment_method=$normalizedPaymentMethod, transaction_id=${transactionId ?? ''}, receiptimage=${receiptImage?.path ?? ''}',
      );

      debugPrint(
        'Update EMI Payment Status Response Status: ${response.statusCode}',
      );
      debugPrint('Update EMI Payment Status Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          return {
            'success': true,
            'data': responseData,
            'message':
                responseData['message'] ??
                'Payment status updated successfully',
          };
        } catch (e) {
          return {
            'success': true,
            'message': 'Payment status updated successfully',
          };
        }
      } else if (response.statusCode == 401) {
        await SessionManager.handleSessionExpiry(response.statusCode);
        return SessionManager.sessionExpiredResponse();
      } else {
        try {
          final errorData = json.decode(response.body);
          final errors = errorData['errors'];
          String? validationError;
          if (errors is Map && errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              validationError = firstError.first.toString();
            } else if (firstError != null) {
              validationError = firstError.toString();
            }
          }
          return {
            'success': false,
            'error':
                validationError ??
                errorData['message'] ??
                'Failed to update payment status',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Failed to update payment status: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      debugPrint('Error updating EMI payment status: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    } finally {
      isUpdatingEmiPayment = false;
      notifyListeners();
    }
  }

  /// Update Customer EMI (for marking as paid with payment date)
  /// POST: api/update_customer_emi
  Future<Map<String, dynamic>> updateCustomerEmi({
    required int customerId,
    required String emiId,
    required String emiDtlId,
    required String paymentMethod,
    required String paymentDate,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token') ?? '';

      if (authToken.isEmpty) {
        return {
          'success': false,
          'error': 'Authentication token not found. Please login again.',
        };
      }

      final url = Uri.parse('${AppConstants.baseUrl}/update_customer_emi');

      debugPrint('Update Customer EMI URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'customer_id': customerId,
          'emi_id': emiId,
          'emi_dtl_id': emiDtlId,
          'payment_method': paymentMethod,
          'payment_date': paymentDate,
        }),
      );

      debugPrint('Update Customer EMI Response Status: ${response.statusCode}');
      debugPrint('Update Customer EMI Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          return {
            'success': true,
            'data': responseData,
            'message': responseData['message'] ?? 'EMI updated successfully',
          };
        } catch (e) {
          return {'success': true, 'message': 'EMI updated successfully'};
        }
      } else if (response.statusCode == 401) {
        await SessionManager.handleSessionExpiry(response.statusCode);
        return SessionManager.sessionExpiredResponse();
      } else {
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'error':
                errorData['message'] ??
                'Failed to update EMI: ${response.statusCode}',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Failed to update EMI: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      debugPrint('Error updating customer EMI: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // Clear EMI data
  void clearEmiData() {
    customerEmiModel = null;
    emiError = null;
    notifyListeners();
  }

  // Re-activate customer state
  bool isReactivatingCustomer = false;

  /// Update customer is_active status
  /// GET: api/update_cutomer_is_active_status?customer_id=<id>&status=<status>
  Future<bool> updateCustomerIsActiveStatus(int customerId, int status) async {
    isReactivatingCustomer = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token') ?? '';

      final url = Uri.parse(
        '${AppConstants.baseUrl}/update_cutomer_is_active_status?customer_id=$customerId&status=$status',
      );

      debugPrint('Update Customer IsActive Status URL: $url');

      final headers = <String, String>{'Accept': 'application/json'};
      if (authToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.get(url, headers: headers);

      debugPrint(
        'Update IsActive Response: ${response.statusCode} ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint('Update IsActive API error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating isActive status: $e');
      return false;
    } finally {
      isReactivatingCustomer = false;
      notifyListeners();
    }
  }

  /// Verify PIN code before executing commands
  /// Checks entered PIN against the stored PIN in SharedPreferences
  Future<bool> verifyPinCode(String pinCode) async {
    isPinVerifying = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPinCode = prefs.getString('pin_code')?.trim() ?? '';
      final enteredPin = pinCode.trim();

      debugPrint('========== PIN VERIFICATION ==========');
      debugPrint('Entered PIN: "$enteredPin" (length: ${enteredPin.length})');
      debugPrint(
        'Stored PIN: "$storedPinCode" (length: ${storedPinCode.length})',
      );
      debugPrint('Stored PIN exists: ${storedPinCode.isNotEmpty}');

      if (storedPinCode.isEmpty) {
        debugPrint(
          'PIN verification failed: No PIN stored in SharedPreferences',
        );
        debugPrint('=======================================');
        return false;
      }

      final isMatch = enteredPin == storedPinCode;
      debugPrint('PIN Match Result: $isMatch');
      debugPrint('=======================================');

      if (isMatch) {
        debugPrint('PIN verification successful');
        return true;
      } else {
        debugPrint('PIN verification failed: PIN does not match');
        return false;
      }
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
      return false;
    } finally {
      isPinVerifying = false;
      notifyListeners();
    }
  }

  /// Insert Customer EMI details
  /// POST: api/mobile/emis
  Future<Map<String, dynamic>> insertCustomerEmi({
    required int customerId,
    required String purchaseDate,
    required String totalAmount,
    required String advanceAmount,
    required String totalMonths,
  }) async {
    // Get auth token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token') ?? '';

    if (authToken.isEmpty) {
      return {
        'success': false,
        'error': 'Authentication token not found. Please login again.',
      };
    }

    try {
      final url = Uri.parse('${AppConstants.baseUrl}/mobile/emis');

      debugPrint('Insert Customer EMI API URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'customer_id': customerId,
          'purchase_date': purchaseDate,
          'total_amount': totalAmount,
          'advance_amount': advanceAmount,
          'total_months': totalMonths,
        }),
      );

      debugPrint('Insert EMI API Response Status: ${response.statusCode}');
      debugPrint('Insert EMI API Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          return {
            'success': true,
            'data': responseData,
            'message':
                responseData['message'] ?? 'EMI details added successfully',
          };
        } catch (e) {
          return {
            'success': true,
            'data': {'message': response.body},
          };
        }
      } else if (response.statusCode == 401) {
        await SessionManager.handleSessionExpiry(response.statusCode);
        return SessionManager.sessionExpiredResponse();
      } else {
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'error':
                errorData['message'] ??
                'Failed to add EMI details: ${response.statusCode}',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Failed to add EMI details: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      debugPrint('Error inserting customer EMI: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  /// Delete Customer EMI
  /// DELETE: api/mobile/emis/{id}
  Future<Map<String, dynamic>> deleteCustomerEmi({
    required String emiId,
  }) async {
    // Get auth token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token') ?? '';

    if (authToken.isEmpty) {
      return {
        'success': false,
        'error': 'Authentication token not found. Please login again.',
      };
    }

    try {
      final url = Uri.parse('${AppConstants.baseUrl}/mobile/emis/$emiId');

      debugPrint('Delete Customer EMI API URL: $url');

      final response = await http.delete(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      debugPrint('Delete EMI API Response Status: ${response.statusCode}');
      debugPrint('Delete EMI API Response Body: ${response.body}');

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        try {
          final responseData = response.body.isNotEmpty
              ? json.decode(response.body)
              : <String, dynamic>{};
          return {
            'success': true,
            'data': responseData,
            'message': responseData['message'] ?? 'EMI deleted successfully',
          };
        } catch (e) {
          return {'success': true, 'message': 'EMI deleted successfully'};
        }
      } else if (response.statusCode == 401) {
        await SessionManager.handleSessionExpiry(response.statusCode);
        return SessionManager.sessionExpiredResponse();
      } else {
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'error':
                errorData['message'] ??
                'Failed to delete EMI: ${response.statusCode}',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Failed to delete EMI: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      debugPrint('Error deleting customer EMI: $e');
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  // ==================== LOCATION APIs ====================

  /// Clear location selections
  void clearLocationSelections() {
    selectedCountry = null;
    selectedState = null;
    selectedCity = null;
    states = [];
    cities = [];
    notifyListeners();
  }

  /// Set selected country and fetch states
  Future<void> setSelectedCountry(CountryModel? country) async {
    selectedCountry = country;
    selectedState = null;
    selectedCity = null;
    states = [];
    cities = [];
    notifyListeners();

    if (country != null) {
      await fetchStates(country.id);
    }
  }

  /// Set selected state and fetch cities
  Future<void> setSelectedState(StateModel? state) async {
    selectedState = state;
    selectedCity = null;
    cities = [];
    notifyListeners();

    if (state != null) {
      await fetchCities(state.id);
    }
  }

  /// Set selected city
  void setSelectedCity(CityModel? city) {
    selectedCity = city;
    notifyListeners();
  }

  /// Get country name by ID from loaded countries list
  String getCountryNameById(int countryId) {
    if (countryId <= 0) return 'N/A';
    try {
      final country = countries.firstWhere((c) => c.id == countryId);
      return country.name;
    } catch (e) {
      return 'N/A';
    }
  }

  /// Get state name by ID from loaded states list
  String getStateNameById(int stateId) {
    if (stateId <= 0) return 'N/A';
    try {
      final state = states.firstWhere((s) => s.id == stateId);
      return state.name;
    } catch (e) {
      return 'N/A';
    }
  }

  /// Get city name by ID from loaded cities list
  String getCityNameById(int cityId) {
    if (cityId <= 0) return 'N/A';
    try {
      final city = cities.firstWhere((c) => c.id == cityId);
      return city.name;
    } catch (e) {
      return 'N/A';
    }
  }

  /// Fetch all location data for a customer (country, state, city)
  Future<void> fetchLocationDataForCustomer(int countryId, int stateId) async {
    // Fetch countries first
    await fetchCountries();

    // If country is valid, fetch states
    if (countryId > 0) {
      await fetchStates(countryId);

      // If state is valid, fetch cities
      if (stateId > 0) {
        await fetchCities(stateId);
      }
    }
  }

  /// Fetch all countries from API
  Future<void> fetchCountries() async {
    try {
      isLoadingCountries = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final url = Uri.parse('${AppConstants.baseUrl}/mobile/countries');
      debugPrint('Fetching countries from: $url');
      debugPrint(
        'Auth token present: ${token.isNotEmpty ? "Yes (${token.length} chars)" : "No"}',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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
          countryList = data['data'] ?? data['Data'] ?? data['countries'] ?? [];
        }

        countries = countryList.map((e) => CountryModel.fromJson(e)).toList();
        debugPrint('Loaded ${countries.length} countries');
      } else if (response.statusCode == 401) {
        await SessionManager.handleSessionExpiry(response.statusCode);
        countries = [];
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

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final url = Uri.parse(
        '${AppConstants.baseUrl}/mobile/countries/$countryId/states',
      );
      debugPrint('Fetching states from: $url');
      debugPrint(
        'Auth token present: ${token.isNotEmpty ? "Yes (${token.length} chars)" : "No"}',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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
          stateList = data['data'] ?? data['Data'] ?? data['states'] ?? [];
        }

        states = stateList.map((e) => StateModel.fromJson(e)).toList();
        debugPrint('Loaded ${states.length} states for country $countryId');
      } else if (response.statusCode == 401) {
        await SessionManager.handleSessionExpiry(response.statusCode);
        states = [];
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

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final url = Uri.parse(
        '${AppConstants.baseUrl}/mobile/states/$stateId/cities',
      );
      debugPrint('Fetching cities from: $url');
      debugPrint(
        'Auth token present: ${token.isNotEmpty ? "Yes (${token.length} chars)" : "No"}',
      );

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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
          cityList = data['data'] ?? data['Data'] ?? data['cities'] ?? [];
        }

        cities = cityList.map((e) => CityModel.fromJson(e)).toList();
        debugPrint('Loaded ${cities.length} cities for state $stateId');
      } else if (response.statusCode == 401) {
        await SessionManager.handleSessionExpiry(response.statusCode);
        cities = [];
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

  /// Find and set location by names (for edit mode)
  /// This finds the country, state, city by name and selects them
  Future<void> setLocationByNames({
    required String countryName,
    required String stateName,
    required String cityName,
  }) async {
    debugPrint(
      'Setting location by names: Country=$countryName, State=$stateName, City=$cityName',
    );

    // Fetch countries if not already loaded
    if (countries.isEmpty) {
      await fetchCountries();
    }

    // Find and select country
    final country = countries.firstWhere(
      (c) => c.name.toLowerCase() == countryName.toLowerCase(),
      orElse: () => CountryModel(id: 0, name: ''),
    );

    if (country.id != 0) {
      selectedCountry = country;
      notifyListeners();

      // Fetch states for this country
      await fetchStates(country.id);

      // Find and select state
      final state = states.firstWhere(
        (s) => s.name.toLowerCase() == stateName.toLowerCase(),
        orElse: () => StateModel(id: 0, name: '', countryId: 0),
      );

      if (state.id != 0) {
        selectedState = state;
        notifyListeners();

        // Fetch cities for this state
        await fetchCities(state.id);

        // Find and select city
        final city = cities.firstWhere(
          (c) => c.name.toLowerCase() == cityName.toLowerCase(),
          orElse: () => CityModel(id: 0, name: '', stateId: 0),
        );

        if (city.id != 0) {
          selectedCity = city;
          notifyListeners();
        }
      }
    }

    debugPrint(
      'Location set - Country: ${selectedCountry?.name}, State: ${selectedState?.name}, City: ${selectedCity?.name}',
    );
  }

  /// Find and set location by IDs (for pre-selecting user's default location)
  /// This finds the country, state, city by their IDs and selects them
  Future<void> setLocationByIds({
    required int countryId,
    required int stateId,
    required int cityId,
  }) async {
    debugPrint('=== setLocationByIds START ===');
    debugPrint(
      'Input - Country ID: $countryId, State ID: $stateId, City ID: $cityId',
    );

    // Skip if all IDs are 0 or invalid
    if (countryId == 0 && stateId == 0 && cityId == 0) {
      debugPrint('All location IDs are 0, skipping pre-selection');
      return;
    }

    // Fetch countries if not already loaded
    if (countries.isEmpty) {
      debugPrint('Countries list is empty, fetching...');
      await fetchCountries();
    }

    debugPrint('Available countries: ${countries.length}');
    debugPrint('Country IDs available: ${countries.map((c) => c.id).toList()}');

    // Find and select country by ID
    CountryModel? country;
    try {
      country = countries.firstWhere((c) => c.id == countryId);
      debugPrint('Found country: ${country.name} (ID: ${country.id})');
    } catch (e) {
      debugPrint('Country with ID $countryId not found in list');
      country = null;
    }

    if (country != null && country.id != 0) {
      selectedCountry = country;
      notifyListeners();

      // Fetch states for this country
      debugPrint('Fetching states for country ID: ${country.id}');
      await fetchStates(country.id);
      debugPrint('Available states: ${states.length}');
      debugPrint('State IDs available: ${states.map((s) => s.id).toList()}');

      // Find and select state by ID
      StateModel? state;
      try {
        state = states.firstWhere((s) => s.id == stateId);
        debugPrint('Found state: ${state.name} (ID: ${state.id})');
      } catch (e) {
        debugPrint('State with ID $stateId not found in list');
        state = null;
      }

      if (state != null && state.id != 0) {
        selectedState = state;
        notifyListeners();

        // Fetch cities for this state
        debugPrint('Fetching cities for state ID: ${state.id}');
        await fetchCities(state.id);
        debugPrint('Available cities: ${cities.length}');
        debugPrint('City IDs available: ${cities.map((c) => c.id).toList()}');

        // Find and select city by ID
        CityModel? city;
        try {
          city = cities.firstWhere((c) => c.id == cityId);
          debugPrint('Found city: ${city.name} (ID: ${city.id})');
        } catch (e) {
          debugPrint('City with ID $cityId not found in list');
          city = null;
        }

        if (city != null && city.id != 0) {
          selectedCity = city;
          notifyListeners();
        }
      }
    }

    debugPrint('=== setLocationByIds END ===');
    debugPrint(
      'Final - Country: ${selectedCountry?.name}, State: ${selectedState?.name}, City: ${selectedCity?.name}',
    );
  }
}

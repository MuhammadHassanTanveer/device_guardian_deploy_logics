// Login API Response Model
//
// Parses the login API response:
// {
//   "success": true,  // or "status": true
//   "message": "Login successful",
//   "data": { ... }   // or "user": { ... }
// }

class LoginResponseModel {
  final bool status;
  final String message;
  final LoginUserData? data;

  LoginResponseModel({
    required this.status,
    required this.message,
    this.data,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    // Handle both 'success' and 'status' fields
    bool statusValue = json['success'] ?? json['status'] ?? false;

    // Handle both 'data' and 'user' fields for user data
    Map<String, dynamic>? userData = json['data'] ?? json['user'];

    return LoginResponseModel(
      status: statusValue,
      message: json['message']?.toString() ?? '',
      data: userData != null ? LoginUserData.fromJson(userData) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

/// Location info model for city, state, and country
class LocationInfo {
  final int id;
  final String name;

  LocationInfo({
    required this.id,
    required this.name,
  });

  factory LocationInfo.fromJson(dynamic json) {
    if (json == null) {
      return LocationInfo(id: 0, name: '');
    }
    if (json is Map<String, dynamic>) {
      return LocationInfo(
        id: _parseInt(json['id']),
        name: json['name']?.toString() ?? '',
      );
    }
    // Fallback for legacy format (just an int)
    if (json is int) {
      return LocationInfo(id: json, name: '');
    }
    if (json is String) {
      return LocationInfo(id: int.tryParse(json) ?? 0, name: '');
    }
    return LocationInfo(id: 0, name: '');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  /// Helper method to safely parse int from various types
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  String toString() => 'LocationInfo(id: $id, name: $name)';
}

class LoginUserData {
  final int userId;
  final String email;
  final String token;
  final int tokenId;
  final String uuid;
  final String name;
  final String avatar;
  final String role;
  final String phone;
  final String address;
  final String status;
  final LocationInfo city;
  final LocationInfo state;
  final LocationInfo country;
  final String type;
  final String nameUrdu;
  final String longitude;
  final String latitude;

  LoginUserData({
    required this.userId,
    required this.email,
    required this.token,
    this.tokenId = 0,
    required this.uuid,
    required this.name,
    required this.avatar,
    required this.role,
    required this.phone,
    required this.address,
    required this.status,
    required this.city,
    required this.state,
    required this.country,
    required this.type,
    required this.nameUrdu,
    required this.longitude,
    required this.latitude,
  });

  factory LoginUserData.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> userJson = json;
    if (json['user'] is Map<String, dynamic>) {
      userJson = Map<String, dynamic>.from(json['user'] as Map<String, dynamic>);
    }

    return LoginUserData(
      userId: _parseInt(userJson['user_id'] ?? userJson['id']),
      email: userJson['email']?.toString() ?? '',
      token: json['token']?.toString() ?? userJson['token']?.toString() ?? '',
      tokenId: _parseInt(json['token_id']),
      uuid: userJson['uuid']?.toString() ?? '',
      name: userJson['name']?.toString() ?? '',
      avatar: userJson['avatar']?.toString() ?? '',
      role: userJson['role']?.toString() ?? '',
      phone: userJson['phone']?.toString() ?? '',
      address: userJson['address']?.toString() ?? '',
      status: userJson['status']?.toString() ?? '',
      city: LocationInfo.fromJson(userJson['city']),
      state: LocationInfo.fromJson(userJson['state']),
      country: LocationInfo.fromJson(userJson['country']),
      type: userJson['type']?.toString() ?? '',
      nameUrdu: userJson['name_urdu']?.toString() ?? '',
      longitude: userJson['longitude']?.toString() ?? '',
      latitude: userJson['latitude']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'token': token,
      'token_id': tokenId,
      'uuid': uuid,
      'name': name,
      'avatar': avatar,
      'role': role,
      'phone': phone,
      'address': address,
      'status': status,
      'city': city.toJson(),
      'state': state.toJson(),
      'country': country.toJson(),
      'type': type,
      'name_urdu': nameUrdu,
      'longitude': longitude,
      'latitude': latitude,
    };
  }

  /// Helper method to safely parse int from various types
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

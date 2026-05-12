// Retailer Profile API Response Model
//
// Parses the get_retailer_profile API response:
// {
//   "success": true,
//   "message": "Retailer details send",
//   "data": { ... }
// }

import 'login_model.dart';

class RetailerProfileResponse {
  final bool success;
  final String message;
  final RetailerProfileData? data;

  RetailerProfileResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory RetailerProfileResponse.fromJson(Map<String, dynamic> json) {
    return RetailerProfileResponse(
      success: json['success'] ?? json['status'] ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null 
          ? RetailerProfileData.fromJson(json['data']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class RetailerProfileData {
  final int id;
  final String uuid;
  final String name;
  final String nameUrdu;
  final String companyName;
  final String companyNameUrdu;
  final String gstNo;
  final String avatar;
  final String authkey;
  final String email;
  final String phone;
  final String address;
  final LocationInfo city;
  final LocationInfo state;
  final LocationInfo country;
  final String sinceMemberDate;

  RetailerProfileData({
    required this.id,
    required this.uuid,
    required this.name,
    required this.nameUrdu,
    required this.companyName,
    required this.companyNameUrdu,
    required this.gstNo,
    required this.avatar,
    required this.authkey,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.sinceMemberDate,
  });

  factory RetailerProfileData.fromJson(Map<String, dynamic> json) {
    return RetailerProfileData(
      id: _parseInt(json['id']),
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? json['user_name']?.toString() ?? '',
      nameUrdu: json['name_urdu']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      companyNameUrdu: json['company_name_urdu']?.toString() ?? '',
      gstNo: json['gst_no']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      authkey: json['authkey']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['contact_number']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: LocationInfo.fromJson(json['city']),
      state: LocationInfo.fromJson(json['state']),
      country: LocationInfo.fromJson(json['country']),
      sinceMemberDate: json['since_member_date']?.toString() ?? json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'name': name,
      'name_urdu': nameUrdu,
      'company_name': companyName,
      'company_name_urdu': companyNameUrdu,
      'gst_no': gstNo,
      'avatar': avatar,
      'authkey': authkey,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city.toJson(),
      'state': state.toJson(),
      'country': country.toJson(),
      'since_member_date': sinceMemberDate,
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


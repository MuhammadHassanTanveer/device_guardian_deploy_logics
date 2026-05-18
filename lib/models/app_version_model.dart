import 'login_model.dart';

class AppInfoResponseModel {
  final bool status;
  final AppVersionModel? data;
  final CreatedByUserModel? createdByUser;

  AppInfoResponseModel({
    required this.status,
    this.data,
    this.createdByUser,
  });

  factory AppInfoResponseModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] ?? json['Data'] ?? json['app_info'];
    final rawCreatedBy =
        json['created_by_user'] ?? json['createdByUser'];

    return AppInfoResponseModel(
      status: json['success'] == true || json['status'] == true,
      data: rawData is Map<String, dynamic>
          ? AppVersionModel.fromJson(rawData)
          : null,
      createdByUser: rawCreatedBy is Map<String, dynamic>
          ? CreatedByUserModel.fromJson(rawCreatedBy)
          : null,
    );
  }
}

class CreatedByUserModel {
  final String userCode;
  final String companyName;
  final String? companyNameUrdu;
  final String userName;
  final String contactNumber;
  final String address;
  final LocationInfo state;
  final LocationInfo city;

  CreatedByUserModel({
    required this.userCode,
    required this.companyName,
    this.companyNameUrdu,
    required this.userName,
    required this.contactNumber,
    required this.address,
    required this.state,
    required this.city,
  });

  factory CreatedByUserModel.fromJson(Map<String, dynamic> json) {
    return CreatedByUserModel(
      userCode: json['user_code']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      companyNameUrdu: json['company_name_urdu']?.toString(),
      userName: json['user_name']?.toString() ?? '',
      contactNumber: json['contact_number']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      state: LocationInfo.fromJson(json['state']),
      city: LocationInfo.fromJson(json['city']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_code': userCode,
      'company_name': companyName,
      'company_name_urdu': companyNameUrdu,
      'user_name': userName,
      'contact_number': contactNumber,
      'address': address,
      'state': state.toJson(),
      'city': city.toJson(),
    };
  }
}

class AppVersionModel {
  final String id;
  final String appPath;
  final String appVersion;
  final String createdAt;
  final String updatedAt;
  final String appName;
  final String appDownloadUrl;
  final String firstQrCode;
  final String secondQrCode;
  final String salePhone;
  final String supportPhone;
  final String email;
  final String videoUrl;
  final String userRunningPhoneInstallationVideoUrl;
  final String retailerVideoUrl;
  final String iphoneVideoUrl;
  final String bankName;
  final String accountTitle;
  final String accountNo;

  AppVersionModel({
    required this.id,
    required this.appPath,
    required this.appVersion,
    required this.createdAt,
    required this.updatedAt,
    required this.appName,
    required this.appDownloadUrl,
    required this.firstQrCode,
    required this.secondQrCode,
    required this.salePhone,
    required this.supportPhone,
    required this.email,
    required this.videoUrl,
    required this.userRunningPhoneInstallationVideoUrl,
    required this.retailerVideoUrl,
    required this.iphoneVideoUrl,
    required this.bankName,
    required this.accountTitle,
    required this.accountNo,
  });

  factory AppVersionModel.fromJson(Map<String, dynamic> json) {
    return AppVersionModel(
      id: json['id']?.toString() ?? '',
      appPath: json['app_path']?.toString() ?? '',
      appVersion: json['app_version']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      appName: json['app_name']?.toString() ?? '',
      appDownloadUrl: json['app_download_url']?.toString() ?? '',
      firstQrCode: json['first_qr_code']?.toString() ?? '',
      secondQrCode: json['second_qr_code']?.toString() ?? '',
      salePhone: json['sale_phone']?.toString() ?? '',
      supportPhone: json['support_phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      videoUrl: json['video_url']?.toString() ?? '',
      userRunningPhoneInstallationVideoUrl:
          json['user_running_phone_installation_video_url']?.toString() ?? '',
      retailerVideoUrl: json['retailer_video_url']?.toString() ?? '',
      iphoneVideoUrl: json['iphone_video_url']?.toString() ?? '',
      bankName: json['bank_name']?.toString() ?? '',
      accountTitle: json['account_title']?.toString() ?? '',
      accountNo: json['acount_no']?.toString() ?? json['account_no']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'app_path': appPath,
      'app_version': appVersion,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'app_name': appName,
      'app_download_url': appDownloadUrl,
      'first_qr_code': firstQrCode,
      'second_qr_code': secondQrCode,
      'sale_phone': salePhone,
      'support_phone': supportPhone,
      'email': email,
      'video_url': videoUrl,
      'user_running_phone_installation_video_url':
          userRunningPhoneInstallationVideoUrl,
      'retailer_video_url': retailerVideoUrl,
      'iphone_video_url': iphoneVideoUrl,
      'bank_name': bankName,
      'account_title': accountTitle,
      'acount_no': accountNo,
    };
  }
}

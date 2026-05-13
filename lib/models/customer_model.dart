// To parse this JSON data, do
//
//     final customersModel = customersModelFromJson(jsonString);

import 'dart:convert';

CustomersModel customersModelFromJson(String str) => CustomersModel.fromJson(json.decode(str));

String customersModelToJson(CustomersModel data) => json.encode(data.toJson());

class CustomersModel {
  final bool success;
  final String message;
  final List<Datum> data;

  CustomersModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CustomersModel.fromJson(Map<String, dynamic> json) => CustomersModel(
    success: json["success"] ?? false,
    message: json["message"] ?? '',
    data: json["data"] != null 
        ? List<Datum>.from(json["data"].map((x) => Datum.fromJson(x)))
        : json["Data"] != null 
            ? List<Datum>.from(json["Data"].map((x) => Datum.fromJson(x)))
            : [],
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
  };
}

// Paginated response model for customer list with pagination support
class PaginatedCustomersModel {
  final bool success;
  final String message;
  final List<Datum> data;
  final CustomerMeta meta;

  PaginatedCustomersModel({
    required this.success,
    required this.message,
    required this.data,
    required this.meta,
  });

  factory PaginatedCustomersModel.fromJson(Map<String, dynamic> json) {
    // Handle the new nested response structure: { success, data: { current_page, data: [...], ... } }
    List<Datum> customerList = [];
    CustomerMeta metaData;
    
    final outerData = json["data"] ?? json["Data"];
    
    if (outerData is Map<String, dynamic>) {
      // New API structure: data contains pagination info and nested data array
      final nestedData = outerData["data"];
      if (nestedData is List) {
        customerList = List<Datum>.from(nestedData.map((x) => Datum.fromJson(x)));
      }
      
      // Extract meta from the outer data object
      metaData = CustomerMeta(
        currentPage: outerData["current_page"] ?? 1,
        lastPage: outerData["last_page"] ?? 1,
        perPage: outerData["per_page"] is int ? outerData["per_page"] : int.tryParse(outerData["per_page"]?.toString() ?? '10') ?? 10,
        total: outerData["total"] ?? 0,
        nextPageUrl: outerData["next_page_url"],
        prevPageUrl: outerData["prev_page_url"],
        from: outerData["from"],
        to: outerData["to"],
      );
    } else if (outerData is List) {
      // Old API structure: data is directly a list
      customerList = List<Datum>.from(outerData.map((x) => Datum.fromJson(x)));
      metaData = CustomerMeta(
        currentPage: 1,
        lastPage: 1,
        perPage: customerList.length,
        total: customerList.length,
        nextPageUrl: null,
        prevPageUrl: null,
      );
    } else {
      // Fallback: Handle meta field if present at root level
      if (json.containsKey("meta") && json["meta"] is Map) {
        metaData = CustomerMeta.fromJson(json["meta"]);
      } else {
        metaData = CustomerMeta(
          currentPage: 1,
          lastPage: 1,
          perPage: customerList.length,
          total: customerList.length,
          nextPageUrl: null,
          prevPageUrl: null,
        );
      }
    }
    
    return PaginatedCustomersModel(
      success: json["success"] ?? true,
      message: json["message"] ?? '',
      data: customerList,
      meta: metaData,
    );
  }

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "meta": meta.toJson(),
  };
}

// Meta model for pagination state
class CustomerMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final String? nextPageUrl;
  final String? prevPageUrl;
  final int? from;
  final int? to;

  CustomerMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.nextPageUrl,
    this.prevPageUrl,
    this.from,
    this.to,
  });

  factory CustomerMeta.fromJson(Map<String, dynamic> json) => CustomerMeta(
    currentPage: json["current_page"] ?? 1,
    lastPage: json["last_page"] ?? 1,
    perPage: json["per_page"] is int ? json["per_page"] : int.tryParse(json["per_page"]?.toString() ?? '10') ?? 10,
    total: json["total"] ?? 0,
    nextPageUrl: json["next_page_url"],
    prevPageUrl: json["prev_page_url"],
    from: json["from"],
    to: json["to"],
  );

  Map<String, dynamic> toJson() => {
    "current_page": currentPage,
    "last_page": lastPage,
    "per_page": perPage,
    "total": total,
    "next_page_url": nextPageUrl,
    "prev_page_url": prevPageUrl,
    "from": from,
    "to": to,
  };
}

// Links model for pagination navigation (kept for backward compatibility)
class CustomerLinks {
  CustomerLinks({
    required this.first,
    required this.last,
    required this.prev,
    required this.next,
  });

  String first;
  String last;
  dynamic prev;
  String next;

  factory CustomerLinks.fromJson(Map<String, dynamic> json) => CustomerLinks(
    first: json["first"] ?? "",
    last: json["last"] ?? "",
    prev: json["prev"] ?? "",
    next: json["next"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "first": first,
    "last": last,
    "prev": prev,
    "next": next,
  };
}

class Datum {
  final int id;
  final String? hashId;
  final String customerCode;
  final String customerName;
  final String customerMobileNo; // Maps to contact_number in new API
  final String email;
  final String cnic;
  final int country;
  final int state;
  final int city;
  final String? countryName;
  final String? stateName;
  final String? cityName;
  final String address;
  final String? googleMap;
  final String? loanBy;
  final String model;
  final String imei1;
  final String? imei2;
  final String deviceStatus;
  final String status;
  final String lockCode;
  final String? unlockCode; // New field from API
  final String activatedBy;
  final String mobilePicture;
  final String mobileType;
  final String? signature;
  final String documents;
  final String? note;
  final String? suggestion;
  final int createdBy;
  final String? createdByName;
  final String? createdByCode;
  final int fosId;
  final int retailerId;
  final int isDeleted;
  final String registerStatus;
  final String? registerTime;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int isActive;
  final bool lockStatus; // New field from API
  final bool actualLockStatus; // Actual lock status from device
  final String serialNo;
  final String fcmToken;
  // New fields
  final String actualDeviceStatus;
  final String? longitude;
  final String? latitude;
  final String actualDeviceStatusTime;
  final String simCount;
  final String? sim1NetworkName;
  final String? sim1Number;
  final String? sim1CountryIso;
  final String? sim2NetworkName;
  final String? sim2Number;
  final String? sim2CountryIso;
  final String? networkType;
  final String? mobileModel;
  final String uuid;
  final String cnicFrontImage;
  final String cnicBackImage;
  final String profileImage; // Maps to customer_image or profile_image
  final List<String> mobileImages; // New: array of mobile document images

  Datum({
    required this.id,
    this.hashId,
    required this.customerCode,
    required this.customerName,
    required this.customerMobileNo,
    required this.email,
    required this.cnic,
    required this.country,
    required this.state,
    required this.city,
    this.countryName,
    this.stateName,
    this.cityName,
    required this.address,
    this.googleMap,
    this.loanBy,
    required this.model,
    required this.imei1,
    this.imei2,
    required this.deviceStatus,
    required this.status,
    required this.lockCode,
    this.unlockCode,
    required this.activatedBy,
    required this.mobilePicture,
    required this.mobileType,
    this.signature,
    required this.documents,
    this.note,
    this.suggestion,
    required this.createdBy,
    this.createdByName,
    this.createdByCode,
    required this.fosId,
    required this.retailerId,
    required this.isDeleted,
    required this.registerStatus,
    this.registerTime,
    required this.createdAt,
    this.updatedAt,
    required this.isActive,
    required this.lockStatus,
    required this.actualLockStatus,
    required this.serialNo,
    required this.fcmToken,
    required this.actualDeviceStatus,
    this.longitude,
    this.latitude,
    required this.actualDeviceStatusTime,
    required this.simCount,
    this.sim1NetworkName,
    this.sim1Number,
    this.sim1CountryIso,
    this.sim2NetworkName,
    this.sim2Number,
    this.sim2CountryIso,
    this.networkType,
    this.mobileModel,
    required this.uuid,
    required this.cnicFrontImage,
    required this.cnicBackImage,
    required this.profileImage,
    this.mobileImages = const [], // Default to empty list
  });

  factory Datum.fromJson(Map<String, dynamic> json) {
    // Parse country - can be int, String, or Map with id/name
    int countryId = 0;
    String? countryName;
    if (json["country"] is Map) {
      countryId = json["country"]["id"] ?? 0;
      countryName = json["country"]["name"];
    } else if (json["country_id"] != null) {
      countryId = _parseInt(json["country_id"]);
      if (json["country"] is Map) {
        countryName = json["country"]["name"];
      }
    } else {
      countryId = _parseInt(json["country"]);
    }
    
    // Parse state - can be int, String, or Map with id/name
    int stateId = 0;
    String? stateName;
    if (json["state"] is Map) {
      stateId = json["state"]["id"] ?? 0;
      stateName = json["state"]["name"];
    } else if (json["state_id"] != null) {
      stateId = _parseInt(json["state_id"]);
      if (json["state"] is Map) {
        stateName = json["state"]["name"];
      }
    } else {
      stateId = _parseInt(json["state"]);
    }
    
    // Parse city - can be int, String, or Map with id/name
    int cityId = 0;
    String? cityName;
    if (json["city"] is Map) {
      cityId = json["city"]["id"] ?? 0;
      cityName = json["city"]["name"];
    } else if (json["city_id"] != null) {
      cityId = _parseInt(json["city_id"]);
      if (json["city"] is Map) {
        cityName = json["city"]["name"];
      }
    } else {
      cityId = _parseInt(json["city"]);
    }
    
    // Parse created_by - can be int or Map with user_name/user_code
    int createdById = 0;
    String? createdByName;
    String? createdByCode;
    if (json["created_by"] is Map) {
      createdByName = json["created_by"]["user_name"];
      createdByCode = json["created_by"]["user_code"];
    } else {
      createdById = _parseInt(json["created_by"]);
    }
    
    // Parse lock_status - can be bool or int
    bool lockStatusValue = false;
    if (json["lock_status"] is bool) {
      lockStatusValue = json["lock_status"];
    } else if (json["lock_status"] is int) {
      lockStatusValue = json["lock_status"] == 1;
    } else if (json["lock_status"] is String) {
      lockStatusValue = json["lock_status"].toLowerCase() == 'true' || json["lock_status"] == '1';
    }
    
    // Parse actual_lock_status - can be bool or int
    bool actualLockStatusValue = false;
    if (json["actual_lock_status"] is bool) {
      actualLockStatusValue = json["actual_lock_status"];
    } else if (json["actual_lock_status"] is int) {
      actualLockStatusValue = json["actual_lock_status"] == 1;
    } else if (json["actual_lock_status"] is String) {
      actualLockStatusValue = json["actual_lock_status"].toLowerCase() == 'true' || json["actual_lock_status"] == '1';
    }
    
    // Parse mobile_images array
    List<String> mobileImagesList = [];
    if (json["mobile_images"] != null && json["mobile_images"] is List) {
      mobileImagesList = List<String>.from(json["mobile_images"].map((x) => x.toString()));
    }
    
    return Datum(
      id: json["id"] ?? 0,
      hashId: json["hash_id"],
      customerCode: json["customer_code"] ?? '',
      customerName: json["customer_name"] ?? '',
      // Handle both old field (customer_mobile_no) and new field (contact_number)
      customerMobileNo: json["contact_number"] ?? json["customer_mobile_no"] ?? '',
      email: json["email"] ?? '',
      // Handle both cnic_number (new API) and cnic (old API)
      cnic: json["cnic_number"] ?? json["cnic"] ?? '',
      country: countryId,
      state: stateId,
      city: cityId,
      countryName: countryName,
      stateName: stateName,
      cityName: cityName,
      address: json["address"] ?? '',
      googleMap: json["google_map"],
      loanBy: json["loan_by"],
      model: json["model"] ?? '',
      imei1: json["imei_1"] ?? '',
      imei2: json["imei_2"],
      deviceStatus: json["device_status"] ?? '',
      status: json["status"] ?? '',
      lockCode: json["lock_code"] ?? '',
      unlockCode: json["unlock_code"],
      activatedBy: json["activated_by"] ?? '',
      mobilePicture: json["mobile_picture"] ?? '',
      mobileType: json["mobile_type"] ?? '',
      signature: json["signature"],
      documents: json["documents"] ?? '',
      note: json["note"],
      suggestion: json["suggestion"],
      createdBy: createdById,
      createdByName: createdByName,
      createdByCode: createdByCode,
      fosId: json["fos_id"] ?? 0,
      retailerId: json["retailer_id"] ?? 0,
      isDeleted: json["is_deleted"] ?? 0,
      registerStatus: json["register_status"] ?? '',
      registerTime: json["register_time"],
      createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : DateTime.now(),
      updatedAt: json["updated_at"] != null ? DateTime.parse(json["updated_at"]) : null,
      isActive: _parseIsActive(json["is_active"]),
      lockStatus: lockStatusValue,
      actualLockStatus: actualLockStatusValue,
      serialNo: json["serial_no"] ?? '',
      fcmToken: json["fcm_token"] ?? '',
      // New fields with null safety
      actualDeviceStatus: json["actual_device_status"] ?? '',
      longitude: json["longitude"]?.toString(),
      latitude: json["latitude"]?.toString(),
      actualDeviceStatusTime: json["actual_device_status_time"] ?? '',
      simCount: json["sim_count"] ?? '',
      sim1NetworkName: json["sim1_network_name"],
      sim1Number: json["sim1_number"],
      sim1CountryIso: json["sim1_country_iso"],
      sim2NetworkName: json["sim2_network_name"],
      sim2Number: json["sim2_number"],
      sim2CountryIso: json["sim2_country_iso"],
      networkType: json["network_type"],
      mobileModel: json["mobile_model"],
      uuid: json["uuid"] ?? '',
      cnicFrontImage: json["cnic_front_image"] ?? '',
      cnicBackImage: json["cnic_back_image"] ?? '',
      // Handle both customer_image (new API) and profile_image (old API)
      profileImage: json["customer_image"] ?? json["profile_image"] ?? '',
      mobileImages: mobileImagesList,
    );
  }

  // Helper to parse is_active which can be int, String, or null
  static int _parseIsActive(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true' || value == '1') return 1;
      return 0;
    }
    return 0;
  }

  // Helper to parse int from various types (int, String, null, or Map with 'id' key)
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    // Handle case where API returns an object like {"id": 1, "name": "Pakistan"}
    if (value is Map<String, dynamic>) {
      final id = value['id'];
      if (id is int) return id;
      if (id is String) return int.tryParse(id) ?? 0;
    }
    return 0;
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "hash_id": hashId,
    "customer_code": customerCode,
    "customer_name": customerName,
    "contact_number": customerMobileNo,
    "customer_mobile_no": customerMobileNo,
    "email": email,
    "cnic": cnic,
    "country": country,
    "country_id": country,
    "state": state,
    "state_id": state,
    "city": city,
    "city_id": city,
    "address": address,
    "google_map": googleMap,
    "loan_by": loanBy,
    "model": model,
    "imei_1": imei1,
    "imei_2": imei2,
    "device_status": deviceStatus,
    "status": status,
    "lock_code": lockCode,
    "unlock_code": unlockCode,
    "activated_by": activatedBy,
    "mobile_picture": mobilePicture,
    "mobile_type": mobileType,
    "signature": signature,
    "documents": documents,
    "note": note,
    "suggestion": suggestion,
    "created_by": createdBy,
    "fos_id": fosId,
    "retailer_id": retailerId,
    "is_deleted": isDeleted,
    "register_status": registerStatus,
    "register_time": registerTime,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "is_active": isActive,
    "lock_status": lockStatus,
    "actual_lock_status": actualLockStatus,
    "serial_no": serialNo,
    "fcm_token": fcmToken,
    "actual_device_status": actualDeviceStatus,
    "longitude": longitude,
    "latitude": latitude,
    "actual_device_status_time": actualDeviceStatusTime,
    "sim_count": simCount,
    "sim1_network_name": sim1NetworkName,
    "sim1_number": sim1Number,
    "sim1_country_iso": sim1CountryIso,
    "sim2_network_name": sim2NetworkName,
    "sim2_number": sim2Number,
    "sim2_country_iso": sim2CountryIso,
    "network_type": networkType,
    "mobile_model": mobileModel,
    "uuid": uuid,
    "cnic_front_image": cnicFrontImage,
    "cnic_back_image": cnicBackImage,
    "profile_image": profileImage,
    "customer_image": profileImage,
    "mobile_images": mobileImages,
  };

  /// Creates a copy of this Datum with the given fields replaced with new values
  Datum copyWith({
    int? id,
    String? hashId,
    String? customerCode,
    String? customerName,
    String? customerMobileNo,
    String? email,
    String? cnic,
    int? country,
    int? state,
    int? city,
    String? countryName,
    String? stateName,
    String? cityName,
    String? address,
    String? googleMap,
    String? loanBy,
    String? model,
    String? imei1,
    String? imei2,
    String? deviceStatus,
    String? status,
    String? lockCode,
    String? unlockCode,
    String? activatedBy,
    String? mobilePicture,
    String? mobileType,
    String? signature,
    String? documents,
    String? note,
    String? suggestion,
    int? createdBy,
    String? createdByName,
    String? createdByCode,
    int? fosId,
    int? retailerId,
    int? isDeleted,
    String? registerStatus,
    String? registerTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? isActive,
    bool? lockStatus,
    bool? actualLockStatus,
    String? serialNo,
    String? fcmToken,
    String? actualDeviceStatus,
    String? longitude,
    String? latitude,
    String? actualDeviceStatusTime,
    String? simCount,
    String? sim1NetworkName,
    String? sim1Number,
    String? sim1CountryIso,
    String? sim2NetworkName,
    String? sim2Number,
    String? sim2CountryIso,
    String? networkType,
    String? mobileModel,
    String? uuid,
    String? cnicFrontImage,
    String? cnicBackImage,
    String? profileImage,
    List<String>? mobileImages,
  }) {
    return Datum(
      id: id ?? this.id,
      hashId: hashId ?? this.hashId,
      customerCode: customerCode ?? this.customerCode,
      customerName: customerName ?? this.customerName,
      customerMobileNo: customerMobileNo ?? this.customerMobileNo,
      email: email ?? this.email,
      cnic: cnic ?? this.cnic,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      countryName: countryName ?? this.countryName,
      stateName: stateName ?? this.stateName,
      cityName: cityName ?? this.cityName,
      address: address ?? this.address,
      googleMap: googleMap ?? this.googleMap,
      loanBy: loanBy ?? this.loanBy,
      model: model ?? this.model,
      imei1: imei1 ?? this.imei1,
      imei2: imei2 ?? this.imei2,
      deviceStatus: deviceStatus ?? this.deviceStatus,
      status: status ?? this.status,
      lockCode: lockCode ?? this.lockCode,
      unlockCode: unlockCode ?? this.unlockCode,
      activatedBy: activatedBy ?? this.activatedBy,
      mobilePicture: mobilePicture ?? this.mobilePicture,
      mobileType: mobileType ?? this.mobileType,
      signature: signature ?? this.signature,
      documents: documents ?? this.documents,
      note: note ?? this.note,
      suggestion: suggestion ?? this.suggestion,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdByCode: createdByCode ?? this.createdByCode,
      fosId: fosId ?? this.fosId,
      retailerId: retailerId ?? this.retailerId,
      isDeleted: isDeleted ?? this.isDeleted,
      registerStatus: registerStatus ?? this.registerStatus,
      registerTime: registerTime ?? this.registerTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      lockStatus: lockStatus ?? this.lockStatus,
      actualLockStatus: actualLockStatus ?? this.actualLockStatus,
      serialNo: serialNo ?? this.serialNo,
      fcmToken: fcmToken ?? this.fcmToken,
      actualDeviceStatus: actualDeviceStatus ?? this.actualDeviceStatus,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      actualDeviceStatusTime: actualDeviceStatusTime ?? this.actualDeviceStatusTime,
      simCount: simCount ?? this.simCount,
      sim1NetworkName: sim1NetworkName ?? this.sim1NetworkName,
      sim1Number: sim1Number ?? this.sim1Number,
      sim1CountryIso: sim1CountryIso ?? this.sim1CountryIso,
      sim2NetworkName: sim2NetworkName ?? this.sim2NetworkName,
      sim2Number: sim2Number ?? this.sim2Number,
      sim2CountryIso: sim2CountryIso ?? this.sim2CountryIso,
      networkType: networkType ?? this.networkType,
      mobileModel: mobileModel ?? this.mobileModel,
      uuid: uuid ?? this.uuid,
      cnicFrontImage: cnicFrontImage ?? this.cnicFrontImage,
      cnicBackImage: cnicBackImage ?? this.cnicBackImage,
      profileImage: profileImage ?? this.profileImage,
      mobileImages: mobileImages ?? this.mobileImages,
    );
  }
}


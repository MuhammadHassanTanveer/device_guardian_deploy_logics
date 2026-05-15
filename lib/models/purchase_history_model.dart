// To parse this JSON data, do
//
//     final purchaseHistoryModel = purchaseHistoryModelFromJson(jsonString);

import 'dart:convert';

PurchaseHistoryModel purchaseHistoryModelFromJson(String str) => 
    PurchaseHistoryModel.fromJson(json.decode(str));

String purchaseHistoryModelToJson(PurchaseHistoryModel data) => 
    json.encode(data.toJson());

class PurchaseHistoryModel {
  final bool success;
  final String message;
  final List<PurchaseHistoryItem> data;
  final PurchaseHistoryMeta meta;

  PurchaseHistoryModel({
    required this.success,
    required this.message,
    required this.data,
    required this.meta,
  });

  factory PurchaseHistoryModel.fromJson(Map<String, dynamic> json) {
    List<PurchaseHistoryItem> historyList = [];
    PurchaseHistoryMeta metaData;

    final outerData = json["data"] ?? json["Data"];

    if (outerData is Map<String, dynamic>) {
      // Nested pagination: { data: { current_page, last_page, data: [...] } }
      final nestedData = outerData["data"];
      if (nestedData is List) {
        historyList = List<PurchaseHistoryItem>.from(
          nestedData.map((x) => PurchaseHistoryItem.fromJson(x)),
        );
      }

      metaData = PurchaseHistoryMeta(
        currentPage: _parseInt(outerData["current_page"], 1),
        lastPage: _parseInt(outerData["last_page"], 1),
        perPage: _parseInt(outerData["per_page"], 10),
        total: _parseInt(outerData["total"], historyList.length),
        nextPageUrl: outerData["next_page_url"]?.toString(),
        prevPageUrl: outerData["prev_page_url"]?.toString(),
      );
    } else if (outerData is List) {
      historyList = List<PurchaseHistoryItem>.from(
        outerData.map((x) => PurchaseHistoryItem.fromJson(x)),
      );
      metaData = PurchaseHistoryMeta(
        currentPage: 1,
        lastPage: 1,
        perPage: historyList.length,
        total: historyList.length,
        nextPageUrl: null,
        prevPageUrl: null,
      );
    } else if (json.containsKey("meta") && json["meta"] is Map) {
      metaData = PurchaseHistoryMeta.fromJson(json["meta"]);
    } else {
      metaData = PurchaseHistoryMeta(
        currentPage: 1,
        lastPage: 1,
        perPage: historyList.length,
        total: historyList.length,
        nextPageUrl: null,
        prevPageUrl: null,
      );
    }

    return PurchaseHistoryModel(
      success: (json["success"] ?? json["status"] ?? true) != false,
      message: json["message"]?.toString() ?? '',
      data: historyList,
      meta: metaData,
    );
  }

  static int _parseInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "meta": meta.toJson(),
  };
}

// Meta model for pagination state
class PurchaseHistoryMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final String? nextPageUrl;
  final String? prevPageUrl;

  PurchaseHistoryMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.nextPageUrl,
    this.prevPageUrl,
  });

  factory PurchaseHistoryMeta.fromJson(Map<String, dynamic> json) => PurchaseHistoryMeta(
    currentPage: PurchaseHistoryModel._parseInt(json["current_page"], 1),
    lastPage: PurchaseHistoryModel._parseInt(json["last_page"], 1),
    perPage: PurchaseHistoryModel._parseInt(json["per_page"], 10),
    total: PurchaseHistoryModel._parseInt(json["total"], 0),
    nextPageUrl: json["next_page_url"]?.toString(),
    prevPageUrl: json["prev_page_url"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "current_page": currentPage,
    "last_page": lastPage,
    "per_page": perPage,
    "total": total,
    "next_page_url": nextPageUrl,
    "prev_page_url": prevPageUrl,
  };
}

// Individual purchase history item
class PurchaseHistoryItem {
  final int id;
  final int quantity;
  final double amount;
  final double pricePerKey;
  final String keyType;
  final String status;
  final String transactionId;
  final String? paymentProof;
  final String? paymentProofUrl;
  final DateTime requestDate;
  final DateTime? approvalTime;

  PurchaseHistoryItem({
    required this.id,
    required this.quantity,
    required this.amount,
    required this.pricePerKey,
    required this.keyType,
    required this.status,
    required this.transactionId,
    this.paymentProof,
    this.paymentProofUrl,
    required this.requestDate,
    this.approvalTime,
  });

  factory PurchaseHistoryItem.fromJson(Map<String, dynamic> json) => PurchaseHistoryItem(
    id: json["id"] ?? 0,
    quantity: _parseInt(json["qty"] ?? json["quantity"]),
    amount: _parseDouble(json["amount"] ?? json["total_amount"]),
    pricePerKey: _parseDouble(json["price"] ?? json["price_per_key"]),
    keyType: json["key_type"]?.toString() ?? '',
    status: json["approval_status"]?.toString() ?? json["status"]?.toString() ?? 'Pending',
    transactionId: json["transaction_id"]?.toString() ?? '',
    paymentProof: json["payment_proof"]?.toString(),
    paymentProofUrl: json["payment_proof_url"]?.toString(),
    requestDate: json["request_date"] != null 
        ? DateTime.tryParse(json["request_date"].toString()) ?? DateTime.now()
        : json["created_at"] != null 
            ? DateTime.tryParse(json["created_at"].toString()) ?? DateTime.now()
            : DateTime.now(),
    approvalTime: json["approval_time"] != null && json["approval_time"] != "0000-00-00 00:00:00"
        ? DateTime.tryParse(json["approval_time"].toString())
        : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "qty": quantity,
    "amount": amount,
    "price": pricePerKey,
    "key_type": keyType,
    "approval_status": status,
    "transaction_id": transactionId,
    "payment_proof": paymentProof,
    "payment_proof_url": paymentProofUrl,
    "request_date": requestDate.toIso8601String(),
    "approval_time": approvalTime?.toIso8601String(),
  };

  // Helper method to parse int from various types
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Helper method to parse double from various types
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Formatted date string for display
  String get formattedDate {
    return '${requestDate.day.toString().padLeft(2, '0')} ${_getMonthName(requestDate.month)} ${requestDate.year}';
  }

  String get formattedShortDate {
    return '${requestDate.day.toString().padLeft(2, '0')} ${_getMonthShortName(requestDate.month)}';
  }

  static String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  static String _getMonthShortName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}




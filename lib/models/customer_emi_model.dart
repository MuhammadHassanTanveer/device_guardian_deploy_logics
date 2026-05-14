class CustomerEmiModel {
  final bool success;
  final String message;
  final CustomerEmiData? data;

  CustomerEmiModel({required this.success, required this.message, this.data});

  factory CustomerEmiModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] ?? json['Data'];

    return CustomerEmiModel(
      success:
          json['success'] == true || json['status'] == true || rawData != null,
      message: json['message'] ?? '',
      data: rawData != null ? CustomerEmiData.fromJson(rawData) : null,
    );
  }

  factory CustomerEmiModel.empty({String message = ''}) {
    return CustomerEmiModel(
      success: true,
      message: message,
      data: CustomerEmiData(customerEmiDetails: const []),
    );
  }
}

class CustomerEmiData {
  final CustomerEmi? customerEmi;
  final List<CustomerEmiDetail> customerEmiDetails;

  CustomerEmiData({this.customerEmi, required this.customerEmiDetails});

  factory CustomerEmiData.fromJson(dynamic json) {
    if (json is List) {
      if (json.isEmpty) {
        return CustomerEmiData(customerEmiDetails: const []);
      }

      final firstItem = _asMap(json.first);
      final customerEmi = _looksLikeCustomerEmi(firstItem)
          ? CustomerEmi.fromJson(firstItem)
          : null;
      final detailItems = _extractDetails(firstItem);

      return CustomerEmiData(
        customerEmi: customerEmi,
        customerEmiDetails: detailItems.isNotEmpty
            ? detailItems.map(CustomerEmiDetail.fromJson).toList()
            : json
                  .map(_asMap)
                  .where(_looksLikeEmiDetail)
                  .map(CustomerEmiDetail.fromJson)
                  .toList(),
      );
    }

    if (json is! Map<String, dynamic>) {
      return CustomerEmiData(customerEmiDetails: const []);
    }

    final nestedData = json['data'] ?? json['Data'];
    if (nestedData != null && nestedData != json) {
      return CustomerEmiData.fromJson(nestedData);
    }

    final customerEmiJson = _asMap(
      json['customer_emi'] ??
          json['customerEmi'] ??
          json['emi'] ??
          json['emi_master'] ??
          (_looksLikeCustomerEmi(json) ? json : null),
    );
    final detailItems = _extractDetails(json);

    return CustomerEmiData(
      customerEmi: customerEmiJson.isNotEmpty
          ? CustomerEmi.fromJson(customerEmiJson)
          : null,
      customerEmiDetails: detailItems.map(CustomerEmiDetail.fromJson).toList(),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _extractDetails(Map<String, dynamic> json) {
    final rawDetails =
        json['customer_emi_details'] ??
        json['customerEmiDetails'] ??
        json['emi_details'] ??
        json['emiDetails'] ??
        json['details'] ??
        json['installments'] ??
        json['payments'];

    if (rawDetails is List) {
      return rawDetails.map(_asMap).where((item) => item.isNotEmpty).toList();
    }

    final nestedEmi = _asMap(
      json['customer_emi'] ?? json['customerEmi'] ?? json['emi'],
    );
    if (nestedEmi.isNotEmpty && nestedEmi != json) {
      return _extractDetails(nestedEmi);
    }

    return const [];
  }

  static bool _looksLikeCustomerEmi(Map<String, dynamic> json) {
    return json.containsKey('purchase_date') ||
        json.containsKey('total_amount') ||
        json.containsKey('advance_amount') ||
        json.containsKey('total_months');
  }

  static bool _looksLikeEmiDetail(Map<String, dynamic> json) {
    return json.containsKey('emi_date') ||
        json.containsKey('due_date') ||
        json.containsKey('payment_date') ||
        json.containsKey('is_paid') ||
        json.containsKey('status');
  }
}

class CustomerEmi {
  final String emiId;
  final String customerId;
  final String purchaseDate;
  final String totalAmount;
  final String advanceAmount;
  final String totalMonths;
  final String monthlyAmount;
  final String? remarks;
  final String isAutoLock;
  final String createdAt;
  final String updatedAt;

  CustomerEmi({
    required this.emiId,
    required this.customerId,
    required this.purchaseDate,
    required this.totalAmount,
    required this.advanceAmount,
    required this.totalMonths,
    required this.monthlyAmount,
    this.remarks,
    required this.isAutoLock,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerEmi.fromJson(Map<String, dynamic> json) {
    return CustomerEmi(
      emiId: (json['emi_id'] ?? json['id'])?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      purchaseDate: json['purchase_date']?.toString() ?? '',
      totalAmount: json['total_amount']?.toString() ?? '0',
      advanceAmount: json['advance_amount']?.toString() ?? '0',
      totalMonths: json['total_months']?.toString() ?? '0',
      monthlyAmount:
          (json['monthly_amount'] ??
                  json['emi_amount'] ??
                  json['installment_amount'] ??
                  json['amount'])
              ?.toString() ??
          '0',
      remarks: json['remarks']?.toString(),
      isAutoLock: json['is_auto_lock']?.toString() ?? '0',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  // Get parsed values
  double get totalAmountParsed => double.tryParse(totalAmount) ?? 0;
  double get advanceAmountParsed => double.tryParse(advanceAmount) ?? 0;
  double get monthlyAmountParsed {
    final parsedMonthlyAmount = double.tryParse(monthlyAmount) ?? 0;
    if (parsedMonthlyAmount > 0) return parsedMonthlyAmount;

    final months = totalMonthsParsed;
    if (months <= 0) return 0;

    return (totalAmountParsed - advanceAmountParsed) / months;
  }

  int get totalMonthsParsed => int.tryParse(totalMonths) ?? 0;
}

class CustomerEmiDetail {
  final String emiDtlId;
  final String emiId;
  final String customerId;
  final String emiDate;
  final String monthlyAmount;
  final String paymentMethod;
  final String isPaid;
  final String remarks;
  final String isAutoLock;
  final String createdAt;
  final String updatedAt;
  final String paymentDate;

  CustomerEmiDetail({
    required this.emiDtlId,
    required this.emiId,
    required this.customerId,
    required this.emiDate,
    required this.monthlyAmount,
    required this.paymentMethod,
    required this.isPaid,
    required this.remarks,
    required this.isAutoLock,
    required this.createdAt,
    required this.updatedAt,
    required this.paymentDate,
  });

  factory CustomerEmiDetail.fromJson(Map<String, dynamic> json) {
    return CustomerEmiDetail(
      emiDtlId:
          (json['emi_dtl_id'] ?? json['emi_detail_id'] ?? json['id'])
              ?.toString() ??
          '',
      emiId: json['emi_id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      emiDate:
          (json['emi_date'] ?? json['due_date'] ?? json['date'])?.toString() ??
          '',
      monthlyAmount:
          (json['monthly_amount'] ??
                  json['emi_amount'] ??
                  json['installment_amount'] ??
                  json['amount'])
              ?.toString() ??
          '0',
      paymentMethod: json['payment_method']?.toString() ?? '',
      isPaid: _parsePaidStatus(
        json['is_paid'] ?? json['paid'] ?? json['status'],
      ),
      remarks: json['remarks']?.toString() ?? '',
      isAutoLock: json['is_auto_lock']?.toString() ?? '0',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      paymentDate: json['payment_date']?.toString() ?? '',
    );
  }

  static String _parsePaidStatus(dynamic value) {
    if (value == null) return '0';
    if (value is bool) return value ? '1' : '0';
    final parsedValue = value.toString().toLowerCase();
    if (parsedValue == '1' ||
        parsedValue == 'paid' ||
        parsedValue == 'true' ||
        parsedValue == 'completed') {
      return '1';
    }
    return '0';
  }

  // Check if the EMI is paid
  bool get isPaidStatus => isPaid == '1';

  // Get parsed monthly amount
  double get monthlyAmountParsed => double.tryParse(monthlyAmount) ?? 0;

  // Check if payment date is valid (not empty or "0000-00-00")
  bool get hasValidPaymentDate =>
      paymentDate.isNotEmpty && paymentDate != '0000-00-00';
}

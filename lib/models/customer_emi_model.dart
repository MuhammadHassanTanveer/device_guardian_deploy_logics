class CustomerEmiModel {
  final bool success;
  final String message;
  final CustomerEmiData? data;

  CustomerEmiModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory CustomerEmiModel.fromJson(Map<String, dynamic> json) {
    return CustomerEmiModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? CustomerEmiData.fromJson(json['data']) : null,
    );
  }
}

class CustomerEmiData {
  final CustomerEmi? customerEmi;
  final List<CustomerEmiDetail> customerEmiDetails;

  CustomerEmiData({
    this.customerEmi,
    required this.customerEmiDetails,
  });

  factory CustomerEmiData.fromJson(Map<String, dynamic> json) {
    return CustomerEmiData(
      customerEmi: json['customer_emi'] != null 
          ? CustomerEmi.fromJson(json['customer_emi']) 
          : null,
      customerEmiDetails: json['customer_emi_details'] != null
          ? (json['customer_emi_details'] as List)
              .map((e) => CustomerEmiDetail.fromJson(e))
              .toList()
          : [],
    );
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
      emiId: json['emi_id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      purchaseDate: json['purchase_date']?.toString() ?? '',
      totalAmount: json['total_amount']?.toString() ?? '0',
      advanceAmount: json['advance_amount']?.toString() ?? '0',
      totalMonths: json['total_months']?.toString() ?? '0',
      monthlyAmount: json['monthly_amount']?.toString() ?? '0',
      remarks: json['remarks']?.toString(),
      isAutoLock: json['is_auto_lock']?.toString() ?? '0',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  // Get parsed values
  double get totalAmountParsed => double.tryParse(totalAmount) ?? 0;
  double get advanceAmountParsed => double.tryParse(advanceAmount) ?? 0;
  double get monthlyAmountParsed => double.tryParse(monthlyAmount) ?? 0;
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
      emiDtlId: json['emi_dtl_id']?.toString() ?? '',
      emiId: json['emi_id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      emiDate: json['emi_date']?.toString() ?? '',
      monthlyAmount: json['monthly_amount']?.toString() ?? '0',
      paymentMethod: json['payment_method']?.toString() ?? '',
      isPaid: json['is_paid']?.toString() ?? '0',
      remarks: json['remarks']?.toString() ?? '',
      isAutoLock: json['is_auto_lock']?.toString() ?? '0',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      paymentDate: json['payment_date']?.toString() ?? '',
    );
  }

  // Check if the EMI is paid
  bool get isPaidStatus => isPaid == '1';
  
  // Get parsed monthly amount
  double get monthlyAmountParsed => double.tryParse(monthlyAmount) ?? 0;
  
  // Check if payment date is valid (not empty or "0000-00-00")
  bool get hasValidPaymentDate => paymentDate.isNotEmpty && paymentDate != '0000-00-00';
}



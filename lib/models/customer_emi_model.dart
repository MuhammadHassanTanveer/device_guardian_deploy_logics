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
  final int? dueDay;
  final int? lockDay;
  final int? startMonth;
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
    this.dueDay,
    this.lockDay,
    this.startMonth,
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
      isAutoLock: _parseAutoLock(
        json['is_auto_lock'] ?? json['enable_auto_lock'],
      ),
      dueDay: _parseDay(json['due_day']),
      lockDay: _parseDay(json['lock_day']),
      startMonth: _parseDay(json['start_month']),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  static String _parseAutoLock(dynamic value) {
    if (value == null) return '0';
    if (value is bool) return value ? '1' : '0';
    final parsed = value.toString().toLowerCase();
    if (parsed == '1' || parsed == 'true') return '1';
    return '0';
  }

  static int? _parseDay(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  bool get isAutoLockEnabled => isAutoLock == '1';

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
  final String lockDate;
  final String monthlyAmount;
  final String paymentMethod;
  final String isPaid;
  final String status;
  final String remarks;
  final String isAutoLock;
  final String createdAt;
  final String updatedAt;
  final String paymentDate;
  final bool shouldLockDevice;

  CustomerEmiDetail({
    required this.emiDtlId,
    required this.emiId,
    required this.customerId,
    required this.emiDate,
    required this.lockDate,
    required this.monthlyAmount,
    required this.paymentMethod,
    required this.isPaid,
    required this.status,
    required this.remarks,
    required this.isAutoLock,
    required this.createdAt,
    required this.updatedAt,
    required this.paymentDate,
    this.shouldLockDevice = false,
  });

  factory CustomerEmiDetail.fromJson(Map<String, dynamic> json) {
    final paidStatus = _parsePaidStatus(
      json['is_paid'] ?? json['paid'],
    );
    final rawStatus = json['status']?.toString().toLowerCase() ?? '';
    final emiDate =
        (json['emi_date'] ?? json['due_date'] ?? json['date'])?.toString() ??
        '';

    return CustomerEmiDetail(
      emiDtlId:
          (json['emi_dtl_id'] ??
                  json['emi_detail_id'] ??
                  json['detail_id'] ??
                  json['id'])
              ?.toString() ??
          '',
      emiId: json['emi_id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      emiDate: emiDate,
      lockDate: json['lock_date']?.toString() ?? '',
      monthlyAmount:
          (json['monthly_amount'] ??
                  json['emi_amount'] ??
                  json['installment_amount'] ??
                  json['amount'])
              ?.toString() ??
          '0',
      paymentMethod: json['payment_method']?.toString() ?? '',
      isPaid: paidStatus,
      status: _resolveStatus(rawStatus, paidStatus, emiDate),
      remarks: json['remarks']?.toString() ?? '',
      isAutoLock: CustomerEmi._parseAutoLock(json['is_auto_lock']),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      paymentDate: json['payment_date']?.toString() ?? '',
      shouldLockDevice: json['should_lock_device'] == true,
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

  static String _resolveStatus(
    String rawStatus,
    String paidStatus,
    String emiDate,
  ) {
    if (paidStatus == '1' || rawStatus == 'paid') return 'paid';
    if (rawStatus == 'overdue') return 'overdue';
    if (rawStatus == 'pending') return 'pending';

    if (emiDate.isNotEmpty) {
      try {
        final due = DateTime.parse(emiDate);
        final today = DateTime.now();
        final dueDay = DateTime(due.year, due.month, due.day);
        final todayDay = DateTime(today.year, today.month, today.day);
        if (todayDay.isAfter(dueDay)) return 'overdue';
      } catch (_) {}
    }

    return paidStatus == '1' ? 'paid' : 'pending';
  }

  // Check if the EMI is paid
  bool get isPaidStatus => isPaid == '1';

  bool get isOverdue => status == 'overdue';

  bool get isPending => status == 'pending';

  // Get parsed monthly amount
  double get monthlyAmountParsed => double.tryParse(monthlyAmount) ?? 0;

  // Check if payment date is valid (not empty or "0000-00-00")
  bool get hasValidPaymentDate =>
      paymentDate.isNotEmpty && paymentDate != '0000-00-00';
}

class EmiLockDatesModel {
  final bool success;
  final String message;
  final EmiLockDatesData? data;

  EmiLockDatesModel({
    required this.success,
    required this.message,
    this.data,
  });

  factory EmiLockDatesModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return EmiLockDatesModel(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: rawData is Map<String, dynamic>
          ? EmiLockDatesData.fromJson(rawData)
          : null,
    );
  }
}

class EmiLockDatesData {
  final int customerId;
  final String customerName;
  final int? emiId;
  final int? dueDay;
  final int? lockDay;
  final int? startMonth;
  final bool enableAutoLock;
  final bool deviceShouldBeLocked;
  final List<EmiLockInstallment> installments;

  EmiLockDatesData({
    required this.customerId,
    required this.customerName,
    this.emiId,
    this.dueDay,
    this.lockDay,
    this.startMonth,
    required this.enableAutoLock,
    required this.deviceShouldBeLocked,
    required this.installments,
  });

  factory EmiLockDatesData.fromJson(Map<String, dynamic> json) {
    final rawInstallments = json['installments'];
    return EmiLockDatesData(
      customerId: int.tryParse(json['customer_id']?.toString() ?? '') ?? 0,
      customerName: json['customer_name']?.toString() ?? '',
      emiId: int.tryParse(json['emi_id']?.toString() ?? ''),
      dueDay: int.tryParse(json['due_day']?.toString() ?? ''),
      lockDay: int.tryParse(json['lock_day']?.toString() ?? ''),
      startMonth: int.tryParse(json['start_month']?.toString() ?? ''),
      enableAutoLock: _parseBool(
        json['enable_auto_lock'] ?? json['is_auto_lock'],
      ),
      deviceShouldBeLocked: json['device_should_be_locked'] == true,
      installments: rawInstallments is List
          ? rawInstallments
                .map(
                  (item) => EmiLockInstallment.fromJson(
                    CustomerEmiData._asMap(item),
                  ),
                )
                .toList()
          : const [],
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    final parsed = value.toString().toLowerCase();
    return parsed == '1' || parsed == 'true';
  }
}

class EmiLockInstallment {
  final int installmentNumber;
  final int detailId;
  final String dueDate;
  final String lockDate;
  final String status;
  final bool isPaid;
  final bool shouldLockDevice;
  final String monthlyAmount;

  EmiLockInstallment({
    required this.installmentNumber,
    required this.detailId,
    required this.dueDate,
    required this.lockDate,
    required this.status,
    required this.isPaid,
    required this.shouldLockDevice,
    required this.monthlyAmount,
  });

  factory EmiLockInstallment.fromJson(Map<String, dynamic> json) {
    return EmiLockInstallment(
      installmentNumber:
          int.tryParse(json['installment_number']?.toString() ?? '') ?? 0,
      detailId: int.tryParse(json['detail_id']?.toString() ?? '') ?? 0,
      dueDate: json['due_date']?.toString() ?? '',
      lockDate: json['lock_date']?.toString() ?? '',
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      isPaid: json['is_paid'] == true || json['is_paid']?.toString() == '1',
      shouldLockDevice: json['should_lock_device'] == true,
      monthlyAmount: json['monthly_amount']?.toString() ?? '0',
    );
  }
}

class EmiScheduleHelper {
  EmiScheduleHelper._();

  static const List<String> monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> shortMonthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String monthName(int month) {
    if (month < 1 || month > 12) return 'Unknown';
    return monthNames[month - 1];
  }

  static int suggestStartMonth(DateTime purchaseDate) {
    final monthsToAdd = purchaseDate.day > 20 ? 2 : 1;
    return DateTime(
      purchaseDate.year,
      purchaseDate.month + monthsToAdd,
      1,
    ).month;
  }

  static DateTime resolveFirstDueDate(
    DateTime purchaseDate,
    int startMonth,
    int dueDay,
  ) {
    var year = purchaseDate.year;
    final day = _clampDay(year, startMonth, dueDay);
    var dueDate = DateTime(year, startMonth, day);

    final purchaseDay = DateTime(
      purchaseDate.year,
      purchaseDate.month,
      purchaseDate.day,
    );
    if (dueDate.isBefore(purchaseDay)) {
      year += 1;
      dueDate = DateTime(year, startMonth, _clampDay(year, startMonth, dueDay));
    }
    return dueDate;
  }

  static String formatFirstDuePreview(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = shortMonthNames[date.month - 1];
    return 'First installment: $day $month ${date.year}';
  }

  static int _clampDay(int year, int month, int dueDay) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    return dueDay < daysInMonth ? dueDay : daysInMonth;
  }
}

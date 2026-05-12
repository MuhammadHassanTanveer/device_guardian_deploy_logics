/// Model for customer counts response from /mobile/customers/counts endpoint
class CustomerCountsModel {
  final int total;
  final int locked;
  final int unlocked;
  final int inactive;
  final String creditIphone;
  final String creditAndroid;

  CustomerCountsModel({
    required this.total,
    required this.locked,
    required this.unlocked,
    required this.inactive,
    required this.creditIphone,
    required this.creditAndroid,
  });

  factory CustomerCountsModel.fromJson(Map<String, dynamic> json) {
    return CustomerCountsModel(
      total: _parseInt(json['total']),
      locked: _parseInt(json['lock'] ?? json['locked']),
      unlocked: _parseInt(json['unlock'] ?? json['unlocked']),
      inactive: _parseInt(json['inactive']),
      creditIphone: json['credite_iphone']?.toString() ??
                    json['credit_iphone']?.toString() ?? '0',
      creditAndroid: json['credite_android']?.toString() ??
                     json['credit_android']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'lock': locked,
      'unlock': unlocked,
      'inactive': inactive,
      'credite_iphone': creditIphone,
      'credite_android': creditAndroid,
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
  String toString() {
    return 'CustomerCountsModel(total: $total, locked: $locked, unlocked: $unlocked, inactive: $inactive, creditIphone: $creditIphone, creditAndroid: $creditAndroid)';
  }
}


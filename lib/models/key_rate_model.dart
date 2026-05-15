class KeyRateModel {
  final int quantity;
  final double pricePerKey;
  final double totalAmount;
  final String keyType;

  KeyRateModel({
    required this.quantity,
    required this.pricePerKey,
    required this.totalAmount,
    required this.keyType,
  });

  factory KeyRateModel.fromJson(
    Map<String, dynamic> json, {
    String keyType = 'Android',
  }) {
    return KeyRateModel(
      quantity: _parseInt(json['qty']),
      pricePerKey: _parseDouble(json['price']),
      totalAmount: _parseDouble(json['amount']),
      keyType: json['key_type']?.toString() ?? keyType,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'qty': quantity,
      'price': pricePerKey,
      'amount': totalAmount,
      'key_type': keyType,
    };
  }
}



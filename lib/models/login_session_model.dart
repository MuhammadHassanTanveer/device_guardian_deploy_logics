class LoginSession {
  final int sessionId;
  final String deviceName;
  final String deviceType;
  final String ipAddress;
  final String userAgent;
  final String? lastUsedAt;
  final String? createdAt;
  final bool isCurrent;

  LoginSession({
    required this.sessionId,
    required this.deviceName,
    required this.deviceType,
    this.ipAddress = '',
    this.userAgent = '',
    this.lastUsedAt,
    this.createdAt,
    required this.isCurrent,
  });

  /// Legacy sessions without device metadata use this placeholder name.
  bool get isLegacyPlaceholder {
    final name = deviceName.trim().toLowerCase();
    return name == 'auth-token' || name.isEmpty;
  }

  factory LoginSession.fromJson(Map<String, dynamic> json) {
    return LoginSession(
      sessionId: _parseInt(json['session_id']),
      deviceName: json['device_name']?.toString() ?? '',
      deviceType: json['device_type']?.toString() ?? '',
      ipAddress: json['ip_address']?.toString() ?? '',
      userAgent: json['user_agent']?.toString() ?? '',
      lastUsedAt: json['last_used_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      isCurrent: json['is_current'] == true,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class LoginSessionsResponse {
  final bool success;
  final String message;
  final List<LoginSession> sessions;

  LoginSessionsResponse({
    required this.success,
    required this.message,
    required this.sessions,
  });

  factory LoginSessionsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final sessionsList = <LoginSession>[];

    if (data is Map<String, dynamic>) {
      final raw = data['sessions'];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map<String, dynamic>) {
            sessionsList.add(LoginSession.fromJson(item));
          }
        }
      }
    }

    return LoginSessionsResponse(
      success: json['success'] == true || json['status'] == true,
      message: json['message']?.toString() ?? '',
      sessions: sessionsList,
    );
  }
}

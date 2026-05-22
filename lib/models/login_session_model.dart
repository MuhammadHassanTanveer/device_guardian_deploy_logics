class LoginSession {
  final int sessionId;
  final String deviceName;
  final String deviceType;
  final String client;
  final String clientLabel;
  final bool isActive;
  final bool isWeb;
  final bool isMobileApp;
  final String ipAddress;
  final String userAgent;
  final String? lastUsedAt;
  final String? createdAt;
  final bool isCurrent;

  LoginSession({
    required this.sessionId,
    required this.deviceName,
    required this.deviceType,
    this.client = '',
    this.clientLabel = '',
    this.isActive = true,
    this.isWeb = false,
    this.isMobileApp = false,
    this.ipAddress = '',
    this.userAgent = '',
    this.lastUsedAt,
    this.createdAt,
    required this.isCurrent,
  });

  /// Legacy sessions without device metadata.
  bool get isLegacyPlaceholder {
    final name = deviceName.trim().toLowerCase();
    return name == 'auth-token';
  }

  String get displaySubtitle {
    if (clientLabel.isNotEmpty) return clientLabel;
    if (deviceType.isNotEmpty) return deviceType;
    return client;
  }

  factory LoginSession.fromJson(Map<String, dynamic> json) {
    return LoginSession(
      sessionId: _parseInt(json['session_id']),
      deviceName: _stringOrEmpty(json['device_name'], fallback: 'Unknown device'),
      deviceType: _stringOrEmpty(json['device_type']),
      client: _stringOrEmpty(json['client']),
      clientLabel: _stringOrEmpty(json['client_label']),
      isActive: json['is_active'] != false,
      isWeb: json['is_web'] == true,
      isMobileApp: json['is_mobile_app'] == true,
      ipAddress: _stringOrEmpty(json['ip_address']),
      userAgent: _stringOrEmpty(json['user_agent']),
      lastUsedAt: json['last_used_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      isCurrent: json['is_current'] == true,
    );
  }

  static String _stringOrEmpty(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return fallback;
    return text;
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

    if (data is Map) {
      final raw = data['sessions'];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            sessionsList.add(
              LoginSession.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      }
    }

    sessionsList.sort((a, b) {
      if (a.isCurrent != b.isCurrent) {
        return a.isCurrent ? -1 : 1;
      }
      final aTime = DateTime.tryParse(a.lastUsedAt ?? '') ?? DateTime(1970);
      final bTime = DateTime.tryParse(b.lastUsedAt ?? '') ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });

    return LoginSessionsResponse(
      success: json['success'] == true || json['status'] == true,
      message: json['message']?.toString() ?? '',
      sessions: sessionsList,
    );
  }
}

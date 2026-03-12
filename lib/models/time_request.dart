// ─────────────────────────────────────────────
//  models/time_request.dart
// ─────────────────────────────────────────────

enum TimeRequestStatus { pending, approved, denied, expired }
enum TimeRequestDuration { fifteenMin, thirtyMin, oneHour }

extension TimeRequestDurationExt on TimeRequestDuration {
  int get minutes {
    switch (this) {
      case TimeRequestDuration.fifteenMin: return 15;
      case TimeRequestDuration.thirtyMin: return 30;
      case TimeRequestDuration.oneHour: return 60;
    }
  }

  String get label {
    switch (this) {
      case TimeRequestDuration.fifteenMin: return '15 min';
      case TimeRequestDuration.thirtyMin: return '30 min';
      case TimeRequestDuration.oneHour: return '1 hour';
    }
  }

  String get emoji {
    switch (this) {
      case TimeRequestDuration.fifteenMin: return '⚡';
      case TimeRequestDuration.thirtyMin: return '⏱';
      case TimeRequestDuration.oneHour: return '🕐';
    }
  }
}

class TimeRequest {
  final String id;
  final String childId;
  final String childName;
  final String parentUid;
  final String appName;
  final String packageName;
  final String appIconColor; // hex for display
  final int requestedMinutes;
  final String? childNote;   // optional "please mom, almost done with level"
  final TimeRequestStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;  // auto-expires after 10 min if no response
  final DateTime? respondedAt;
  final int? grantedMinutes; // parent can override the requested amount

  const TimeRequest({
    required this.id,
    required this.childId,
    required this.childName,
    required this.parentUid,
    required this.appName,
    required this.packageName,
    required this.appIconColor,
    required this.requestedMinutes,
    this.childNote,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.respondedAt,
    this.grantedMinutes,
  });

  bool get isPending => status == TimeRequestStatus.pending;
  bool get isExpired => expiresAt.isBefore(DateTime.now()) && isPending;

  String get timeRemainingLabel {
    if (!isPending) return '';
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    return '${remaining.inMinutes}m ${remaining.inSeconds % 60}s left';
  }

  factory TimeRequest.fromFirestore(Map<String, dynamic> data, String id) {
    return TimeRequest(
      id: id,
      childId: data['childId'] ?? '',
      childName: data['childName'] ?? '',
      parentUid: data['parentUid'] ?? '',
      appName: data['appName'] ?? '',
      packageName: data['packageName'] ?? '',
      appIconColor: data['appIconColor'] ?? '#1A56DB',
      requestedMinutes: data['requestedMinutes'] ?? 15,
      childNote: data['childNote'],
      status: TimeRequestStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => TimeRequestStatus.pending,
      ),
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as dynamic)?.toDate() ??
          DateTime.now().add(const Duration(minutes: 10)),
      respondedAt: (data['respondedAt'] as dynamic)?.toDate(),
      grantedMinutes: data['grantedMinutes'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'childId': childId,
    'childName': childName,
    'parentUid': parentUid,
    'appName': appName,
    'packageName': packageName,
    'appIconColor': appIconColor,
    'requestedMinutes': requestedMinutes,
    'childNote': childNote,
    'status': status.name,
    'createdAt': createdAt,
    'expiresAt': expiresAt,
    'respondedAt': respondedAt,
    'grantedMinutes': grantedMinutes,
  };
}

// ─────────────────────────────────────────────
//  models/app_limit.dart
// ─────────────────────────────────────────────
class AppLimit {
  final String packageName;
  final String appName;
  final String appIconColor;
  final int dailyLimitMinutes;   // 0 = blocked entirely
  final bool isEnabled;
  final bool allowTimeRequests;  // child can ask for more time
  final List<int> allowedDaysOfWeek; // 1=Mon...7=Sun, empty=all days
  final int? bedtimeLockHour;        // e.g. 21 = block after 9 PM
  final int minutesUsedToday;

  const AppLimit({
    required this.packageName,
    required this.appName,
    required this.appIconColor,
    required this.dailyLimitMinutes,
    required this.isEnabled,
    required this.allowTimeRequests,
    required this.allowedDaysOfWeek,
    this.bedtimeLockHour,
    required this.minutesUsedToday,
  });

  bool get isMaxed => minutesUsedToday >= dailyLimitMinutes && dailyLimitMinutes > 0;
  bool get isBlocked => dailyLimitMinutes == 0 && isEnabled;

  double get usagePercent =>
      dailyLimitMinutes > 0 ? (minutesUsedToday / dailyLimitMinutes).clamp(0.0, 1.0) : 0;

  String get formattedLimit {
    if (dailyLimitMinutes == 0) return 'Blocked';
    if (dailyLimitMinutes >= 60) {
      final h = dailyLimitMinutes ~/ 60;
      final m = dailyLimitMinutes % 60;
      return m > 0 ? '${h}h ${m}m' : '${h}h';
    }
    return '${dailyLimitMinutes}m';
  }

  String get formattedUsed {
    if (minutesUsedToday < 60) return '${minutesUsedToday}m';
    final h = minutesUsedToday ~/ 60;
    final m = minutesUsedToday % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  factory AppLimit.fromFirestore(Map<String, dynamic> data) {
    return AppLimit(
      packageName: data['packageName'] ?? '',
      appName: data['appName'] ?? '',
      appIconColor: data['appIconColor'] ?? '#1A56DB',
      dailyLimitMinutes: data['dailyLimitMinutes'] ?? 60,
      isEnabled: data['isEnabled'] ?? true,
      allowTimeRequests: data['allowTimeRequests'] ?? true,
      allowedDaysOfWeek: List<int>.from(data['allowedDaysOfWeek'] ?? []),
      bedtimeLockHour: data['bedtimeLockHour'],
      minutesUsedToday: data['minutesUsedToday'] ?? 0,
    );
  }
}

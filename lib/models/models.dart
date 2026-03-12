// ─────────────────────────────────────────────
//  models/child_profile.dart
// ─────────────────────────────────────────────
class ChildProfile {
  final String id;
  final String name;
  final int age;
  final String deviceId;
  final String deviceName;
  final String deviceOs; // 'android' | 'ios'
  final String avatarUrl;
  final bool isOnline;
  final String lastLocation;
  final DateTime lastSeen;
  final double batteryLevel;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.deviceId,
    required this.deviceName,
    required this.deviceOs,
    required this.avatarUrl,
    required this.isOnline,
    required this.lastLocation,
    required this.lastSeen,
    required this.batteryLevel,
  });

  factory ChildProfile.fromFirestore(Map<String, dynamic> data, String id) {
    return ChildProfile(
      id: id,
      name: data['name'] ?? '',
      age: data['age'] ?? 0,
      deviceId: data['deviceId'] ?? '',
      deviceName: data['deviceName'] ?? '',
      deviceOs: data['deviceOs'] ?? 'android',
      avatarUrl: data['avatarUrl'] ?? '',
      isOnline: data['isOnline'] ?? false,
      lastLocation: data['lastLocation'] ?? '',
      lastSeen: (data['lastSeen'] as dynamic)?.toDate() ?? DateTime.now(),
      batteryLevel: (data['batteryLevel'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'age': age,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'deviceOs': deviceOs,
    'avatarUrl': avatarUrl,
    'isOnline': isOnline,
    'lastLocation': lastLocation,
    'lastSeen': lastSeen,
    'batteryLevel': batteryLevel,
  };
}

// ─────────────────────────────────────────────
//  models/parent_account.dart
// ─────────────────────────────────────────────
class ParentAccount {
  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final SubscriptionStatus subscription;
  final DateTime createdAt;
  final List<String> childIds;

  const ParentAccount({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.subscription,
    required this.createdAt,
    required this.childIds,
  });

  factory ParentAccount.fromFirestore(Map<String, dynamic> data, String uid) {
    return ParentAccount(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      subscription: SubscriptionStatus.fromString(data['subscription'] ?? 'trial'),
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      childIds: List<String>.from(data['childIds'] ?? []),
    );
  }
}

enum SubscriptionStatus {
  trial,
  active,
  expired,
  cancelled;

  static SubscriptionStatus fromString(String s) {
    return SubscriptionStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => SubscriptionStatus.trial,
    );
  }

  bool get isActive => this == active || this == trial;
}

// ─────────────────────────────────────────────
//  models/geo_fence.dart
// ─────────────────────────────────────────────
class GeoFence {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final double radiusMeters;
  final bool isActive;
  final String icon; // 'home' | 'school' | 'custom'

  const GeoFence({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
    required this.isActive,
    required this.icon,
  });
}

// ─────────────────────────────────────────────
//  models/app_usage.dart
// ─────────────────────────────────────────────
class AppUsage {
  final String appName;
  final String packageName;
  final int minutesUsed;
  final int dailyLimitMinutes;
  final bool isBlocked;
  final String iconUrl;

  const AppUsage({
    required this.appName,
    required this.packageName,
    required this.minutesUsed,
    required this.dailyLimitMinutes,
    required this.isBlocked,
    required this.iconUrl,
  });

  double get usagePercent =>
      dailyLimitMinutes > 0 ? minutesUsed / dailyLimitMinutes : 0;

  String get formattedTime {
    if (minutesUsed < 60) return '${minutesUsed}m';
    final h = minutesUsed ~/ 60;
    final m = minutesUsed % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }
}

// ─────────────────────────────────────────────
//  models/alert.dart
// ─────────────────────────────────────────────
enum AlertType { geoFence, appLimit, message, location, sos, web }

class GuardianAlert {
  final String id;
  final AlertType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final bool isRead;
  final String childId;

  const GuardianAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.isRead,
    required this.childId,
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

class ChildService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ── Generate 6-digit pairing code ─────────────
  // FIX: Now also creates the child document in Firestore so the child app
  // can update it during pairing. childId is stored in the pairing code doc.
  Future<String> createChildPairingCode({
    required String childName,
    required int childAge,
  }) async {
    final code = _generateCode();

    // 1. Create the child document first so child app can .update() it
    final childRef = _db.collection('children').doc();
    await childRef.set({
      'name': childName,
      'age': childAge,
      'parentUid': _uid,
      'isOnline': false,
      'lastLocation': '',
      'batteryLevel': 0.0,
      'deviceId': '',
      'deviceName': '',
      'deviceOs': 'android',
      'avatarUrl': '',
      'lastSeen': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. Create pairing code with childId reference
    await _db.collection('pairing_codes').doc(code).set({
      'code': code,
      'parentUid': _uid,
      'childId': childRef.id,   // FIX: include childId
      'childName': childName,
      'childAge': childAge,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: 15)),
      ),
      'used': false,
    });

    return code;
  }

  // ── Listen for pairing completion ─────────────
  // FIX: Watch for 'used == true' only — deviceId is on the children doc
  Stream<bool> watchPairingCode(String code) {
    return _db.collection('pairing_codes').doc(code).snapshots().map((doc) {
      if (!doc.exists) return false;
      return doc.data()!['used'] == true;
    });
  }

  // ── Fetch all children for parent ─────────────
  Stream<List<ChildProfile>> watchChildren() {
    return _db
        .collection('children')
        .where('parentUid', isEqualTo: _uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChildProfile.fromFirestore(d.data(), d.id))
            .toList());
  }

  // ── Get app usage for a child ──────────────────
  Future<List<AppUsage>> getAppUsage(String childId) async {
    final snap = await _db
        .collection('children')
        .doc(childId)
        .collection('app_usage')
        .orderBy('minutesUsed', descending: true)
        .limit(10)
        .get();

    return snap.docs.map((d) {
      final data = d.data();
      return AppUsage(
        appName: data['appName'] ?? '',
        packageName: data['packageName'] ?? '',
        minutesUsed: data['minutesUsed'] ?? 0,
        dailyLimitMinutes: data['dailyLimitMinutes'] ?? 0,
        isBlocked: data['isBlocked'] ?? false,
        iconUrl: data['iconUrl'] ?? '',
      );
    }).toList();
  }

  // ── Set app limit ──────────────────────────────
  Future<void> setAppLimit({
    required String childId,
    required String packageName,
    required String appName,
    required int limitMinutes,
    bool allowTimeRequests = true,
  }) async {
    await _db
        .collection('children')
        .doc(childId)
        .collection('appLimits')
        .doc(packageName)
        .set({
      'packageName': packageName,
      'appName': appName,
      'dailyLimitMinutes': limitMinutes,
      'isEnabled': true,
      'allowTimeRequests': allowTimeRequests,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Watch app limits for a child (real-time) ───
  Stream<List<Map<String, dynamic>>> watchAppLimits(String childId) {
    return _db
        .collection('children')
        .doc(childId)
        .collection('appLimits')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  // ── Geo-fences ─────────────────────────────────
  Future<List<GeoFence>> getGeoFences(String childId) async {
    final snap = await _db
        .collection('children')
        .doc(childId)
        .collection('geo_fences')
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      return GeoFence(
        id: d.id,
        name: data['name'] ?? '',
        lat: (data['lat'] as num).toDouble(),
        lng: (data['lng'] as num).toDouble(),
        radiusMeters: (data['radiusMeters'] as num).toDouble(),
        isActive: data['isActive'] ?? true,
        icon: data['icon'] ?? 'custom',
      );
    }).toList();
  }

  Future<void> addGeoFence(String childId, GeoFence fence) async {
    await _db
        .collection('children')
        .doc(childId)
        .collection('geo_fences')
        .add({
      'name': fence.name,
      'lat': fence.lat,
      'lng': fence.lng,
      'radiusMeters': fence.radiusMeters,
      'isActive': fence.isActive,
      'icon': fence.icon,
    });
  }

  // ── Remote commands ────────────────────────────
  Future<void> sendSirenCommand(String childId) async {
    await _db.collection('child_commands').add({
      'childId': childId,
      'type': 'siren',
      'timestamp': FieldValue.serverTimestamp(),
      'executed': false,
    });
  }

  Future<void> startListenSession(String childId) async {
    await _db.collection('child_commands').add({
      'childId': childId,
      'type': 'listen_start',
      'timestamp': FieldValue.serverTimestamp(),
      'executed': false,
    });
  }

  Future<void> stopListenSession(String childId) async {
    await _db.collection('child_commands').add({
      'childId': childId,
      'type': 'listen_stop',
      'timestamp': FieldValue.serverTimestamp(),
      'executed': false,
    });
  }

  // ── Alerts ─────────────────────────────────────
  Stream<List<GuardianAlert>> watchAlerts() {
    return _db
        .collection('alerts')
        .where('parentUid', isEqualTo: _uid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              return GuardianAlert(
                id: d.id,
                type: AlertType.values.firstWhere(
                  (e) => e.name == (data['type'] ?? 'location'),
                  orElse: () => AlertType.location,
                ),
                title: data['title'] ?? '',
                subtitle: data['subtitle'] ?? '',
                timestamp: (data['timestamp'] as Timestamp).toDate(),
                isRead: data['isRead'] ?? false,
                childId: data['childId'] ?? '',
              );
            }).toList());
  }

  String _generateCode() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ((now % 900000) + 100000).toString();
  }
}

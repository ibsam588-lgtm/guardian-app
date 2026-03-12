import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/time_request.dart';

class TimeRequestService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ── Child sends a request ──────────────────────
  // Called from the CHILD APP when their time runs out
  Future<String> sendTimeRequest({
    required String childId,
    required String childName,
    required String parentUid,
    required String appName,
    required String packageName,
    required String appIconColor,
    required int requestedMinutes,
    String? childNote,
  }) async {
    final doc = await _db.collection('time_requests').add({
      'childId': childId,
      'childName': childName,
      'parentUid': parentUid,
      'appName': appName,
      'packageName': packageName,
      'appIconColor': appIconColor,
      'requestedMinutes': requestedMinutes,
      'childNote': childNote,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: 10)),
      ),
    });

    // Also send FCM push notification to parent
    // (This is done via Firebase Cloud Function in production)
    // The function triggers on new time_requests doc creation

    return doc.id;
  }

  // ── Parent: watch incoming requests ───────────
  Stream<List<TimeRequest>> watchPendingRequests() {
    return _db
        .collection('time_requests')
        .where('parentUid', isEqualTo: _uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TimeRequest.fromFirestore(d.data(), d.id))
            .toList());
  }

  // ── Parent: watch ALL requests (history) ──────
  Stream<List<TimeRequest>> watchAllRequests({int limit = 30}) {
    return _db
        .collection('time_requests')
        .where('parentUid', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TimeRequest.fromFirestore(d.data(), d.id))
            .toList());
  }

  // ── Parent: approve ───────────────────────────
  Future<void> approveRequest(TimeRequest request, {int? customMinutes}) async {
    final granted = customMinutes ?? request.requestedMinutes;
    await _db.collection('time_requests').doc(request.id).update({
      'status': 'approved',
      'respondedAt': FieldValue.serverTimestamp(),
      'grantedMinutes': granted,
    });

    // Also update the child's app_limits to temporarily add the granted minutes
    await _db
        .collection('children')
        .doc(request.childId)
        .collection('app_limits')
        .doc(request.packageName)
        .update({
      'temporaryExtensionMinutes': FieldValue.increment(granted),
      'extensionGrantedAt': FieldValue.serverTimestamp(),
      'extensionExpiresAt': Timestamp.fromDate(
        DateTime.now().add(Duration(minutes: granted)),
      ),
    });
  }

  // ── Parent: deny ──────────────────────────────
  Future<void> denyRequest(String requestId) async {
    await _db.collection('time_requests').doc(requestId).update({
      'status': 'denied',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Parent: save app limit ─────────────────────
  Future<void> saveAppLimit({
    required String childId,
    required String packageName,
    required String appName,
    required String appIconColor,
    required int dailyLimitMinutes,
    required bool isEnabled,
    required bool allowTimeRequests,
    int? bedtimeLockHour,
    List<int> allowedDaysOfWeek = const [],
  }) async {
    await _db
        .collection('children')
        .doc(childId)
        .collection('app_limits')
        .doc(packageName)
        .set({
      'packageName': packageName,
      'appName': appName,
      'appIconColor': appIconColor,
      'dailyLimitMinutes': dailyLimitMinutes,
      'isEnabled': isEnabled,
      'allowTimeRequests': allowTimeRequests,
      'bedtimeLockHour': bedtimeLockHour,
      'allowedDaysOfWeek': allowedDaysOfWeek,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ── Stream app limits for a child ─────────────
  Stream<List<AppLimit>> watchAppLimits(String childId) {
    return _db
        .collection('children')
        .doc(childId)
        .collection('app_limits')
        .snapshots()
        .asyncMap((snap) async {
      final usageSnap = await _db
          .collection('children')
          .doc(childId)
          .collection('app_usage')
          .get();

      final usageMap = <String, int>{};
      for (final doc in usageSnap.docs) {
        usageMap[doc.id] = doc.data()['minutesUsed'] ?? 0;
      }

      return snap.docs.map((d) {
        final data = {...d.data(), 'minutesUsedToday': usageMap[d.id] ?? 0};
        return AppLimit.fromFirestore(data);
      }).toList();
    });
  }
}

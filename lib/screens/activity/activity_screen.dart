import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../screens/home/home_screen.dart';
import '../activity/app_limits_screen.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _ActivityHeader(),
          Expanded(
            child: _ChildActivityBody(),
          ),
        ],
      ),
      bottomNavigationBar: const GuardianBottomNav(currentIndex: 2),
    );
  }
}

// ── Header ──────────────────────────────────────
class _ActivityHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20, right: 20, bottom: 16,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('Activity', style: TextStyle(
              color: Colors.white, fontSize: 22,
              fontWeight: FontWeight.w800, fontFamily: 'Nunito',
            )),
          ),
          Icon(Icons.phone_android_outlined, color: Colors.white.withValues(alpha: 0.7)),
        ],
      ),
    );
  }
}

// ── Main body — loads children then shows activity ──
class _ChildActivityBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Not signed in'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('children')
          .where('parentUid', isEqualTo: uid)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final children = snap.data!.docs;
        if (children.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.child_care, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                const Text('No children added yet',
                  style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Add a child from the Home screen to monitor activity',
                  style: TextStyle(color: AppColors.textMuted, fontFamily: 'Nunito'),
                  textAlign: TextAlign.center),
              ],
            ),
          );
        }

        // Use first child by default
        final child = children.first;
        final childId = child.id;
        final childData = child.data() as Map<String, dynamic>;
        final childName = childData['name'] as String? ?? 'Child';

        return SingleChildScrollView(
          child: Column(
            children: [
              _AppLimitsSummary(childId: childId, childName: childName),
              _AppUsageCard(childId: childId, childName: childName),
              const SizedBox(height: 90),
            ],
          ),
        );
      },
    );
  }
}

// ── App Limits Summary card ──────────────────────
class _AppLimitsSummary extends StatelessWidget {
  final String childId, childName;
  const _AppLimitsSummary({required this.childId, required this.childName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('children')
          .doc(childId)
          .collection('appLimits')
          .snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];
        final blockedCount = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return (data['dailyLimitMinutes'] as int? ?? 60) == 0 && (data['isEnabled'] as bool? ?? true);
        }).length;

        return Card(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('$childName\'s App Limits', style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Nunito',
                    )),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AppLimitsScreen(childId: childId, childName: childName),
                      )),
                      child: const Text('Manage', style: TextStyle(
                        color: AppColors.blue, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Nunito',
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (docs.isEmpty)
                  const Text('No limits set — tap Manage to add app limits',
                    style: TextStyle(color: AppColors.textMuted, fontFamily: 'Nunito', fontSize: 13))
                else
                  Text('${docs.length} apps monitored · $blockedCount blocked',
                    style: const TextStyle(color: AppColors.textMuted, fontFamily: 'Nunito', fontSize: 13)),
                if (docs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...docs.take(3).map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final name = d['appName'] as String? ?? doc.id;
                    final limit = d['dailyLimitMinutes'] as int? ?? 60;
                    final isBlocked = limit == 0 && (d['isEnabled'] as bool? ?? true);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: isBlocked ? AppColors.redLight : AppColors.blueLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(fontWeight: FontWeight.w800,
                                color: isBlocked ? AppColors.red : AppColors.blue),
                            )),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(name, style: const TextStyle(
                            fontFamily: 'Nunito', fontWeight: FontWeight.w600, fontSize: 13))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isBlocked ? AppColors.redLight : AppColors.blueLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isBlocked ? 'Blocked' : '${limit}m/day',
                              style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: isBlocked ? AppColors.red : AppColors.blue),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (docs.length > 3)
                    Text('+ ${docs.length - 3} more',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'Nunito')),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── App Usage from Firestore ────────────────────
class _AppUsageCard extends StatelessWidget {
  final String childId, childName;
  const _AppUsageCard({required this.childId, required this.childName});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('children')
          .doc(childId)
          .collection('app_usage')
          .orderBy('minutesUsed', descending: true)
          .limit(8)
          .snapshots(),
      builder: (ctx, snap) {
        final docs = snap.data?.docs ?? [];

        return Card(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('APP USAGE', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted,
                      fontFamily: 'Nunito', letterSpacing: 0.5,
                    )),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AppLimitsScreen(childId: childId, childName: childName),
                      )),
                      child: const Text('Set Limits', style: TextStyle(
                        color: AppColors.blue, fontSize: 12,
                        fontWeight: FontWeight.w700, fontFamily: 'Nunito',
                      )),
                    ),
                  ],
                ),
                if (!snap.hasData)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ))
                else if (docs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'App usage data appears here once the child device\nhas the GuardIan Child app running.',
                      style: TextStyle(color: AppColors.textMuted, fontFamily: 'Nunito', fontSize: 13),
                    ),
                  )
                else
                  ...docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final name = d['appName'] as String? ?? doc.id;
                    final used = d['minutesUsed'] as int? ?? 0;
                    final limit = d['dailyLimitMinutes'] as int? ?? 60;
                    final pct = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;
                    final isMaxed = limit > 0 && used >= limit;
                    final color = isMaxed ? AppColors.red : AppColors.blue;
                    final bg = isMaxed ? AppColors.redLight : AppColors.blueLight;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                                child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontFamily: 'Nunito', fontSize: 14)),
                                  Text(
                                    limit > 0 ? '${_fmt(used)} of ${_fmt(limit)} used' : '${_fmt(used)} today',
                                    style: const TextStyle(
                                      color: AppColors.textMuted, fontFamily: 'Nunito', fontSize: 12)),
                                ],
                              )),
                              if (isMaxed)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(6)),
                                  child: const Text('Limit reached', style: TextStyle(
                                    color: AppColors.red, fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'Nunito')),
                                ),
                            ],
                          ),
                          if (limit > 0) ...[
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor: AppColors.border,
                                valueColor: AlwaysStoppedAnimation(color),
                                minHeight: 5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmt(int mins) {
    if (mins < 60) return '${mins}m';
    return '${mins ~/ 60}h${mins % 60 > 0 ? ' ${mins % 60}m' : ''}';
  }
}

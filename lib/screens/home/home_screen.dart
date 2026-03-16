import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/child_service.dart';
import '../../models/models.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('children')
          .where('parentUid', isEqualTo: uid)
          .limit(5)
          .snapshots(),
      builder: (ctx, snap) {
        final hasData = snap.hasData;
        final children = snap.data?.docs ?? [];
        final hasChildren = children.isNotEmpty;

        // First child for display
        final firstChild = hasChildren
            ? ChildProfile.fromFirestore(
                children.first.data() as Map<String, dynamic>, children.first.id)
            : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(children: [
            _GuardianHeader(child: firstChild),
            Expanded(
              child: !hasData
                ? const Center(child: CircularProgressIndicator())
                : !hasChildren
                  ? _NoChildPrompt()
                  : SingleChildScrollView(
                      child: Column(children: [
                        _MapPreviewCard(child: firstChild!),
                        _StatusRow(child: firstChild),
                        _QuickActionsGrid(childId: firstChild.id),
                        _RecentAlerts(uid: uid),
                        const SizedBox(height: 90),
                      ]),
                    ),
            ),
          ]),
          bottomNavigationBar: const GuardianBottomNav(currentIndex: 0),
        );
      },
    );
  }
}

// ── No-child prompt ────────────────────────────────────────────────────────
class _NoChildPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 90, height: 90,
            decoration: const BoxDecoration(color: AppColors.blueLight, shape: BoxShape.circle),
            child: const Icon(Icons.child_care, color: AppColors.blue, size: 48),
          ),
          const SizedBox(height: 24),
          const Text('Welcome to GuardIan!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                fontFamily: 'Nunito', color: AppColors.navy)),
          const SizedBox(height: 12),
          const Text(
            'Add your child\'s device to start monitoring their safety.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.textMuted,
                fontFamily: 'Nunito', height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/onboarding/setup'),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Child Device',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'The GuardIan Child app must be installed on your child\'s phone.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted.withValues(alpha: 0.7),
                fontFamily: 'Nunito'),
          ),
        ]),
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────
class _GuardianHeader extends StatelessWidget {
  final ChildProfile? child;
  const _GuardianHeader({required this.child});

  @override
  Widget build(BuildContext context) {
    final displayName = FirebaseAuth.instance.currentUser?.displayName ?? 'Parent';

    return Container(
      color: AppColors.navy,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20, right: 20, bottom: 16,
      ),
      child: Column(children: [
        Row(children: [
          RichText(text: const TextSpan(children: [
            TextSpan(text: 'Guard', style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Nunito')),
            TextSpan(text: 'Ian', style: TextStyle(
              color: Color(0xFF60A5FA), fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Nunito')),
          ])),
          const Spacer(),
          // Settings icon
          IconButton(
            onPressed: () => _showSettingsMenu(context),
            icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
            tooltip: displayName,
          ),
          Stack(children: [
            IconButton(
              onPressed: () => context.go('/alerts'),
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            ),
          ]),
        ]),

        const SizedBox(height: 12),

        // Child chip — real data or "Add child" prompt
        if (child != null)
          _ChildChip(child: child!)
        else
          GestureDetector(
            onTap: () => context.go('/onboarding/setup'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.add_circle_outline, color: Colors.white60, size: 20),
                const SizedBox(width: 8),
                const Text('Tap to add your child\'s device',
                  style: TextStyle(color: Colors.white70, fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
          ),
      ]),
    );
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SettingsSheet(),
    );
  }
}

class _ChildChip extends StatelessWidget {
  final ChildProfile child;
  const _ChildChip({required this.child});

  @override
  Widget build(BuildContext context) {
    final initial = child.name.isNotEmpty ? child.name[0].toUpperCase() : '?';
    final isOnline = child.isOnline;
    final location = child.lastLocation.isNotEmpty ? child.lastLocation : 'Location unknown';
    final shortLocation = location.split(',').first.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 30, height: 30,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFFA78BFA)]),
          ),
          child: Center(child: Text(initial, style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w800, fontFamily: 'Nunito'))),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${child.name}, ${child.age}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700,
                  fontFamily: 'Nunito', fontSize: 14),
              overflow: TextOverflow.ellipsis),
            Row(children: [
              Container(width: 7, height: 7,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.green : Colors.grey,
                  shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Flexible(child: Text(
                isOnline ? 'Online · $shortLocation' : 'Offline',
                style: const TextStyle(color: Colors.white60, fontFamily: 'Nunito', fontSize: 12),
                overflow: TextOverflow.ellipsis)),
            ]),
          ]),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.keyboard_arrow_down, color: Colors.white60, size: 18),
      ]),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
          decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        CircleAvatar(radius: 28, backgroundColor: AppColors.blueLight,
          child: Text(
            (user?.displayName ?? user?.email ?? '?')[0].toUpperCase(),
            style: const TextStyle(color: AppColors.blue, fontSize: 24, fontWeight: FontWeight.w700))),
        const SizedBox(height: 12),
        Text(user?.displayName ?? user?.email ?? 'Parent',
          style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 16)),
        Text(user?.email ?? '',
          style: const TextStyle(color: AppColors.textMuted, fontFamily: 'Nunito', fontSize: 13)),
        const SizedBox(height: 20),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.add_circle_outline, color: AppColors.blue),
          title: const Text('Add Another Child', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
          onTap: () { Navigator.pop(context); context.go('/onboarding/setup'); },
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.red),
          title: const Text('Sign Out', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600, color: AppColors.red)),
          onTap: () async {
            Navigator.pop(context);
            await FirebaseAuth.instance.signOut();
          },
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

// ── Map Preview ────────────────────────────────────────────────────────────
class _MapPreviewCard extends StatelessWidget {
  final ChildProfile child;
  const _MapPreviewCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final hasLocation = child.lastLat != null && child.lastLng != null;
    final shortLoc = child.lastLocation.isNotEmpty
        ? child.lastLocation.split(',').first.trim()
        : hasLocation
            ? '${child.lastLat!.toStringAsFixed(3)}, ${child.lastLng!.toStringAsFixed(3)}'
            : 'Waiting for location…';

    return GestureDetector(
      onTap: () => context.go('/location', extra: child.id),
      child: Container(
        height: 200,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFDBEAFE), Color(0xFFEDE9FE)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Stack(children: [
          CustomPaint(painter: _GridPainter(), size: Size.infinite),
          Center(
            child: Stack(alignment: Alignment.center, children: [
              Container(width: 80, height: 80,
                decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.15), shape: BoxShape.circle)),
              Container(width: 50, height: 50,
                decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: 0.25), shape: BoxShape.circle)),
              Container(width: 28, height: 28,
                decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
                child: const Icon(Icons.person, color: Colors.white, size: 16)),
            ]),
          ),
          Positioned(bottom: 12, left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(10)),
              child: Text(shortLoc,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito', color: AppColors.navy),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            )),
          Positioned(bottom: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.blue, borderRadius: BorderRadius.circular(10)),
              child: const Text('Full Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  fontFamily: 'Nunito', color: Colors.white)),
            )),
          if (!child.isOnline)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20)),
              child: const Center(child: Text('Offline', style: TextStyle(
                color: Colors.white, fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 16))),
            ),
        ]),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF4B5563).withValues(alpha: 0.15)..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += step) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
  @override bool shouldRepaint(_) => false;
}

// ── Status Row ─────────────────────────────────────────────────────────────
class _StatusRow extends StatelessWidget {
  final ChildProfile child;
  const _StatusRow({required this.child});

  @override
  Widget build(BuildContext context) {
    final battery = '${(child.batteryLevel * 100).round()}%';
    final locStatus = child.isOnline ? 'Online' : 'Offline';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('children').doc(child.id)
            .collection('app_usage').limit(1).snapshots(),
        builder: (ctx, usageSnap) {
          final usageCount = usageSnap.data?.docs.length ?? 0;
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('alerts')
                .where('parentUid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .where('isRead', isEqualTo: false)
                .limit(10).snapshots(),
            builder: (ctx2, alertSnap) {
              final alertCount = alertSnap.data?.docs.length ?? 0;
              return Row(children: [
                _StatCard(value: locStatus, label: 'Location',
                    color: child.isOnline ? AppColors.green : AppColors.textMuted,
                    bg: child.isOnline ? AppColors.greenLight : AppColors.background,
                    icon: Icons.location_on_outlined),
                const SizedBox(width: 10),
                _StatCard(value: battery, label: 'Battery',
                    color: child.batteryLevel > 0.2 ? AppColors.blue : AppColors.red,
                    bg: child.batteryLevel > 0.2 ? AppColors.blueLight : AppColors.redLight,
                    icon: Icons.battery_std_outlined),
                const SizedBox(width: 10),
                _StatCard(value: usageCount > 0 ? '$usageCount' : '--', label: 'Apps',
                    color: AppColors.amber, bg: AppColors.amberLight,
                    icon: Icons.phone_android_outlined),
                const SizedBox(width: 10),
                _StatCard(
                    value: alertCount > 0 ? '$alertCount' : '0',
                    label: 'Alerts',
                    color: alertCount > 0 ? AppColors.red : AppColors.green,
                    bg: alertCount > 0 ? AppColors.redLight : AppColors.greenLight,
                    icon: alertCount > 0 ? Icons.warning_amber_outlined : Icons.check_circle_outline),
              ]);
            },
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final Color color, bg;
  final IconData icon;
  const _StatCard({required this.value, required this.label,
      required this.color, required this.bg, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.surface,
            borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 32, height: 32,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 17)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
              color: color, fontFamily: 'Nunito')),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted,
              fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ── Quick Actions ──────────────────────────────────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  final String childId;
  const _QuickActionsGrid({required this.childId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(children: [
        _QAButton(label: 'Add Child', icon: Icons.person_add_outlined,
            color: AppColors.purple, bg: AppColors.purpleLight,
            onTap: () => context.go('/onboarding/setup')),
        const SizedBox(width: 10),
        _QAButton(label: 'Emergency', icon: Icons.warning_outlined,
            color: AppColors.red, bg: AppColors.redLight,
            onTap: () => context.go('/emergency')),
        const SizedBox(width: 10),
        _QAButton(label: 'Ring Siren', icon: Icons.campaign_outlined,
            color: AppColors.amber, bg: AppColors.amberLight,
            onTap: () => _showSirenDialog(context)),
        const SizedBox(width: 10),
        _QAButton(label: 'App Lock', icon: Icons.lock_outline,
            color: AppColors.blue, bg: AppColors.blueLight,
            onTap: () => _showPinDialog(context)),
      ]),
    );
  }

  void _showSirenDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Ring Siren', style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
      content: const Text('This will ring the child device at full volume, even if on silent.',
        style: TextStyle(fontFamily: 'Nunito')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(fontFamily: 'Nunito', color: AppColors.textMuted))),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ChildService().sendSirenCommand(childId);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Siren command sent!'), backgroundColor: AppColors.amber));
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber),
          child: const Text('Ring Now'),
        ),
      ],
    ));
  }

  void _showPinDialog(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent, builder: (_) => const _PinLockSheet());
  }
}

class _QAButton extends StatelessWidget {
  final String label; final IconData icon; final Color color, bg; final VoidCallback onTap;
  const _QAButton({required this.label, required this.icon, required this.color, required this.bg, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border)),
          child: Column(children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18)),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary, fontFamily: 'Nunito'),
              textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}

// ── Alerts List ────────────────────────────────────────────────────────────
class _RecentAlerts extends StatelessWidget {
  final String uid;
  const _RecentAlerts({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Recent Alerts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: AppColors.textMuted, fontFamily: 'Nunito', letterSpacing: 0.5)),
            const Spacer(),
            TextButton(
              onPressed: () => context.go('/alerts'),
              child: const Text('See All', style: TextStyle(color: AppColors.blue, fontSize: 12,
                  fontWeight: FontWeight.w700, fontFamily: 'Nunito'))),
          ]),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('alerts')
                .where('parentUid', isEqualTo: uid)
                .orderBy('timestamp', descending: true)
                .limit(5)
                .snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              final docs = snap.data!.docs;
              if (docs.isEmpty) return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No alerts yet — all safe! 🎉',
                  style: TextStyle(color: AppColors.textMuted, fontFamily: 'Nunito')));
              return Column(children: docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final type = d['type'] ?? 'location';
                final isWarning = type.contains('fence') || type.contains('limit');
                final color = isWarning ? AppColors.amber : AppColors.blue;
                final bg = isWarning ? AppColors.amberLight : AppColors.blueLight;
                final ts = (d['timestamp'] as Timestamp?)?.toDate();
                final timeAgo = ts != null ? _timeAgo(ts) : '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.notifications_outlined, color: color, size: 18)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700,
                          fontSize: 13, fontFamily: 'Nunito')),
                      Text(d['subtitle'] ?? '', style: const TextStyle(color: AppColors.textMuted,
                          fontSize: 11, fontFamily: 'Nunito')),
                    ])),
                    Text(timeAgo, style: const TextStyle(color: AppColors.textMuted, fontSize: 11,
                        fontFamily: 'Nunito')),
                  ]),
                );
              }).toList());
            },
          ),
        ]),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── App-Lock PIN Sheet ──────────────────────────────────────────────────────
class _PinLockSheet extends StatefulWidget {
  const _PinLockSheet();
  @override State<_PinLockSheet> createState() => _PinLockSheetState();
}
class _PinLockSheetState extends State<_PinLockSheet> {
  final _ctrl = TextEditingController();
  String _msg = 'Enter a PIN to lock the GuardIan app';
  bool _obscure = true;
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  void _submit() {
    if (_ctrl.text.trim().length < 4) { setState(() => _msg = 'PIN must be at least 4 digits'); return; }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App lock PIN saved')));
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('App Lock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Nunito')),
        const SizedBox(height: 8),
        Text(_msg, style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontFamily: 'Nunito')),
        const SizedBox(height: 16),
        TextField(
          controller: _ctrl, keyboardType: TextInputType.number,
          obscureText: _obscure, maxLength: 8,
          decoration: InputDecoration(
            hintText: '••••', counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscure = !_obscure))),
        ),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Set PIN', style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700, fontFamily: 'Nunito')))),
      ]),
    );
  }
}

// ── Bottom Nav ─────────────────────────────────────────────────────────────
class GuardianBottomNav extends StatelessWidget {
  final int currentIndex;
  const GuardianBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 4),
      child: Row(children: [
        _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home,
            label: 'Home', index: 0, current: currentIndex,
            onTap: () => context.go('/home')),
        _NavItem(icon: Icons.location_on_outlined, activeIcon: Icons.location_on,
            label: 'Location', index: 1, current: currentIndex,
            onTap: () => _goToLocation(context)),
        _NavItem(icon: Icons.phone_android_outlined, activeIcon: Icons.phone_android,
            label: 'Activity', index: 2, current: currentIndex,
            onTap: () => context.go('/activity')),
        _NavItem(icon: Icons.message_outlined, activeIcon: Icons.message,
            label: 'Comms', index: 3, current: currentIndex,
            onTap: () => context.go('/comms')),
        _NavItem(icon: Icons.warning_amber_outlined, activeIcon: Icons.warning_amber,
            label: 'Safety', index: 4, current: currentIndex,
            onTap: () => context.go('/emergency')),
      ]),
    );
  }

  void _goToLocation(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('children').where('parentUid', isEqualTo: uid).limit(1).get();
    if (snap.docs.isNotEmpty && context.mounted) {
      context.go('/location', extra: snap.docs.first.id);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No child device paired yet. Add one from Home.')));
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon; final String label;
  final int index, current; final VoidCallback onTap;
  const _NavItem({required this.icon, required this.activeIcon, required this.label,
      required this.index, required this.current, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final active = current == index;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(active ? activeIcon : icon,
                color: active ? AppColors.blue : AppColors.textMuted, size: 22),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                fontFamily: 'Nunito', color: active ? AppColors.blue : AppColors.textMuted)),
          ]),
        ),
      ),
    );
  }
}

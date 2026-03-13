import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart' show GuardianBottomNav;

class LocationScreen extends StatefulWidget {
  final String childId;
  const LocationScreen({super.key, required this.childId});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  StreamSubscription? _sub;
  ChildProfile? _child;
  final List<_LocationPoint> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _sub = FirebaseFirestore.instance
        .collection('children')
        .doc(widget.childId)
        .snapshots()
        .listen((snap) {
      if (snap.exists && mounted) {
        final child = ChildProfile.fromFirestore(snap.data()!, snap.id);
        setState(() {
          _child = child;
          _loading = false;
          if (child.lastLat != null && child.lastLng != null) {
            final pt = _LocationPoint(
              lat: child.lastLat!,
              lng: child.lastLng!,
              address: child.lastLocation,
              time: DateTime.now(),
            );
            if (_history.isEmpty ||
                _history.first.lat != pt.lat ||
                _history.first.lng != pt.lng) {
              _history.insert(0, pt);
              if (_history.length > 20) _history.removeLast();
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _openInMaps() {
    if (_child?.lastLat == null) return;
    launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=${_child!.lastLat},${_child!.lastLng}'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_child != null ? "${_child!.name}'s Location" : 'Live Location'),
        backgroundColor: AppColors.navy,
        automaticallyImplyLeading: false,
        actions: [
          if (_child?.lastLat != null)
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded),
              tooltip: 'Open in Google Maps',
              onPressed: _openInMaps,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: const GuardianBottomNav(currentIndex: 1),
    );
  }

  Widget _buildBody() {
    final child = _child!;
    final hasCoords = child.lastLat != null && child.lastLng != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusCard(child: child),
          const SizedBox(height: 16),
          if (hasCoords) ...[
            _MapCard(child: child, onOpenMaps: _openInMaps),
            const SizedBox(height: 16),
          ] else ...[
            _NoLocationCard(child: child),
            const SizedBox(height: 16),
          ],
          if (_history.isNotEmpty) ...[
            const Text('Location History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppColors.navy, fontFamily: 'Nunito')),
            const SizedBox(height: 10),
            ..._history.map((pt) => _HistoryTile(point: pt)),
          ],
        ],
      ),
    );
  }
}

// ─── Status Card ─────────────────────────────────────────────────────────────
class _StatusCard extends StatelessWidget {
  final ChildProfile child;
  const _StatusCard({required this.child});

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  Color _batteryColor(double v) {
    if (v > 0.5) return const Color(0xFF43D6A0);
    if (v > 0.2) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final online = child.isOnline;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)]),
      child: Row(children: [
        CircleAvatar(radius: 24,
          backgroundColor: (online ? const Color(0xFF43D6A0) : Colors.grey).withValues(alpha: 0.15),
          child: Icon(Icons.child_care_rounded, size: 26,
              color: online ? const Color(0xFF43D6A0) : Colors.grey)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(child.name, style: const TextStyle(fontWeight: FontWeight.w700,
              fontSize: 16, fontFamily: 'Nunito')),
          Row(children: [
            Container(width: 7, height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: online ? const Color(0xFF43D6A0) : Colors.grey)),
            const SizedBox(width: 5),
            Text(online ? 'Online · ${_timeAgo(child.lastSeen)}' : 'Offline · ${_timeAgo(child.lastSeen)}',
                style: TextStyle(fontSize: 12, fontFamily: 'Nunito',
                    color: online ? const Color(0xFF43D6A0) : AppColors.textMuted)),
          ]),
        ])),
        Column(children: [
          Icon(Icons.battery_std_rounded, size: 18, color: _batteryColor(child.batteryLevel)),
          Text('${(child.batteryLevel * 100).round()}%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  fontFamily: 'Nunito', color: _batteryColor(child.batteryLevel))),
        ]),
      ]),
    );
  }
}

// ─── Map Card ────────────────────────────────────────────────────────────────
class _MapCard extends StatelessWidget {
  final ChildProfile child;
  final VoidCallback onOpenMaps;
  const _MapCard({required this.child, required this.onOpenMaps});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: onOpenMaps,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 200, width: double.infinity,
              color: const Color(0xFFE8EFE8),
              child: Stack(alignment: Alignment.center, children: [
                CustomPaint(size: const Size(double.infinity, 200), painter: _GridPainter()),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.navy, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.navy.withValues(alpha: 0.4), blurRadius: 12)]),
                    child: const Icon(Icons.child_care_rounded, color: Colors.white, size: 22)),
                  Container(width: 2, height: 10, color: AppColors.navy),
                  Container(width: 8, height: 4,
                      decoration: BoxDecoration(color: AppColors.navy.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4))),
                ]),
                Positioned(bottom: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.open_in_new_rounded, size: 12, color: AppColors.navy),
                      SizedBox(width: 4),
                      Text('Open Maps', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: AppColors.navy, fontFamily: 'Nunito')),
                    ]),
                  )),
              ]),
            ),
          ),
        ),
        Padding(padding: const EdgeInsets.all(14),
          child: Row(children: [
            const Icon(Icons.location_on_rounded, color: AppColors.amber, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                child.lastLocation.isNotEmpty ? child.lastLocation
                    : '${child.lastLat!.toStringAsFixed(5)}, ${child.lastLng!.toStringAsFixed(5)}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Nunito'),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              Text('${child.lastLat!.toStringAsFixed(5)}, ${child.lastLng!.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Nunito')),
            ])),
          ])),
      ]),
    );
  }
}

// ─── No Location Card ────────────────────────────────────────────────────────
class _NoLocationCard extends StatelessWidget {
  final ChildProfile child;
  const _NoLocationCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)]),
      child: Column(children: [
        Icon(Icons.location_off_rounded, size: 48, color: Colors.grey.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        const Text('Location unavailable',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Nunito')),
        const SizedBox(height: 6),
        Text(child.isOnline ? 'Waiting for GPS signal…'
            : '${child.name} is offline. Location updates when they come back online.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontFamily: 'Nunito')),
      ]),
    );
  }
}

// ─── History Tile ────────────────────────────────────────────────────────────
class _HistoryTile extends StatelessWidget {
  final _LocationPoint point;
  const _HistoryTile({required this.point});
  @override
  Widget build(BuildContext context) {
    final d = DateTime.now().difference(point.time);
    final t = d.inMinutes < 1 ? 'Just now'
        : d.inMinutes < 60 ? '${d.inMinutes}m ago' : '${d.inHours}h ago';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)]),
      child: Row(children: [
        Container(width: 8, height: 8,
            decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(point.address.isNotEmpty ? point.address
              : '${point.lat.toStringAsFixed(4)}, ${point.lng.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, fontFamily: 'Nunito'),
              overflow: TextOverflow.ellipsis)),
        Text(t, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Nunito')),
      ]),
    );
  }
}

class _LocationPoint {
  final double lat, lng;
  final String address;
  final DateTime time;
  const _LocationPoint({required this.lat, required this.lng, required this.address, required this.time});
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFCCDDCC)..strokeWidth = 0.8;
    for (double x = 0; x < size.width; x += 30) canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    for (double y = 0; y < size.height; y += 30) canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    final r = Paint()..color = Colors.white..strokeWidth = 7;
    canvas.drawLine(Offset(0, size.height * 0.38), Offset(size.width, size.height * 0.48), r);
    canvas.drawLine(Offset(size.width * 0.58, 0), Offset(size.width * 0.53, size.height), r);
  }
  @override bool shouldRepaint(_) => false;
}

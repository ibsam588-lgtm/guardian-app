import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _mapController;
  bool _loading = true;

  static const _defaultCamera = CameraPosition(
    target: LatLng(37.7749, -122.4194), // SF fallback
    zoom: 13,
  );

  @override
  void initState() {
    super.initState();
    if (widget.childId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
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
        });
        // Move map camera to new location
        if (child.lastLat != null && child.lastLng != null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(child.lastLat!, child.lastLng!)),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _mapController?.dispose();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
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
          : widget.childId.isEmpty
              ? _NoChildView()
              : _buildBody(),
      bottomNavigationBar: const GuardianBottomNav(currentIndex: 1),
    );
  }

  Widget _buildBody() {
    if (_child == null) return const Center(child: CircularProgressIndicator());
    final child = _child!;
    final hasCoords = child.lastLat != null && child.lastLng != null;

    return Column(children: [
      // ── Google Map ──────────────────────────────────────────────────
      SizedBox(
        height: 300,
        child: Stack(children: [
          GoogleMap(
            initialCameraPosition: hasCoords
                ? CameraPosition(
                    target: LatLng(child.lastLat!, child.lastLng!),
                    zoom: 15)
                : _defaultCamera,
            onMapCreated: (c) => _mapController = c,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: hasCoords ? {
              Marker(
                markerId: const MarkerId('child'),
                position: LatLng(child.lastLat!, child.lastLng!),
                infoWindow: InfoWindow(title: child.name, snippet: child.lastLocation),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              ),
            } : {},
          ),
          if (!hasCoords)
            Positioned.fill(child: Container(
              color: Colors.black26,
              child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.location_off_rounded, color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text('Waiting for GPS…', style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 14)),
              ])),
            )),
          // Zoom controls (manual)
          Positioned(right: 12, bottom: 12, child: Column(children: [
            _MapBtn(Icons.add, () => _mapController?.animateCamera(CameraUpdate.zoomIn())),
            const SizedBox(height: 4),
            _MapBtn(Icons.remove, () => _mapController?.animateCamera(CameraUpdate.zoomOut())),
          ])),
          // Open maps button
          if (hasCoords)
            Positioned(left: 12, bottom: 12,
              child: GestureDetector(
                onTap: _openInMaps,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)]),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.open_in_new_rounded, size: 14, color: AppColors.navy),
                    SizedBox(width: 6),
                    Text('Open Maps', style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.w700, color: AppColors.navy, fontFamily: 'Nunito')),
                  ]),
                ),
              )),
        ]),
      ),

      // ── Info cards ──────────────────────────────────────────────────
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _StatusCard(child: child),
          if (hasCoords) ...[
            const SizedBox(height: 12),
            _AddressCard(child: child, onOpenMaps: _openInMaps),
          ],
          const SizedBox(height: 80),
        ]),
      )),
    ]);
  }
}

class _MapBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapBtn(this.icon, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4)]),
        child: Icon(icon, size: 20, color: AppColors.navy),
      ),
    );
  }
}

class _NoChildView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.location_off_outlined, size: 64, color: AppColors.textMuted),
        SizedBox(height: 16),
        Text('No child device linked', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w700)),
        SizedBox(height: 8),
        Text('Add a child device from the Home screen first.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontFamily: 'Nunito')),
      ]),
    ));
  }
}

class _StatusCard extends StatelessWidget {
  final ChildProfile child;
  const _StatusCard({required this.child});
  @override
  Widget build(BuildContext context) {
    final online = child.isOnline;
    final battColor = child.batteryLevel > 0.5 ? AppColors.green
        : child.batteryLevel > 0.2 ? AppColors.amber : AppColors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)]),
      child: Row(children: [
        CircleAvatar(radius: 24,
          backgroundColor: (online ? AppColors.green : Colors.grey).withValues(alpha: 0.15),
          child: Icon(Icons.child_care_rounded, size: 26,
              color: online ? AppColors.green : Colors.grey)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(child.name, style: const TextStyle(fontWeight: FontWeight.w700,
              fontSize: 16, fontFamily: 'Nunito')),
          Row(children: [
            Container(width: 7, height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: online ? AppColors.green : Colors.grey)),
            const SizedBox(width: 5),
            Text(online ? 'Online' : 'Offline · last seen ${_ago(child.lastSeen)}',
                style: TextStyle(fontSize: 12, fontFamily: 'Nunito',
                    color: online ? AppColors.green : AppColors.textMuted)),
          ]),
        ])),
        Column(children: [
          Icon(Icons.battery_std_rounded, size: 18, color: battColor),
          Text('${(child.batteryLevel * 100).round()}%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  fontFamily: 'Nunito', color: battColor)),
        ]),
      ]),
    );
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

class _AddressCard extends StatelessWidget {
  final ChildProfile child;
  final VoidCallback onOpenMaps;
  const _AddressCard({required this.child, required this.onOpenMaps});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)]),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.amberLight, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.location_on_rounded, color: AppColors.amber, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            child.lastLocation.isNotEmpty ? child.lastLocation
                : '${child.lastLat!.toStringAsFixed(5)}, ${child.lastLng!.toStringAsFixed(5)}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Nunito'),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          Text('${child.lastLat!.toStringAsFixed(5)}, ${child.lastLng!.toStringAsFixed(5)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'Nunito')),
        ])),
        IconButton(
          icon: const Icon(Icons.open_in_new_rounded, color: AppColors.navy, size: 18),
          onPressed: onOpenMaps),
      ]),
    );
  }
}

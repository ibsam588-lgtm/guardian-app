import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../services/child_service.dart';

/// Full screen for managing all app limits for a child
class AppLimitsScreen extends StatelessWidget {
  final String childId;
  final String childName;

  const AppLimitsScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('$childName\'s App Limits'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAppSheet(context),
        backgroundColor: AppColors.blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add App', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          _BannerTip(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('children')
                  .doc(childId)
                  .collection('appLimits')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.apps_rounded, size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        const Text(
                          'No app limits set yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap + Add App to set limits on your child\'s apps',
                          style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return _AppLimitTile(
                      docId: docs[i].id,
                      data: data,
                      childId: childId,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAppSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAppSheet(childId: childId),
    );
  }
}

// ── Banner tip ──────────────────────────────────────────────────────────────
class _BannerTip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppColors.blue, borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Set time limits for each app. Your child can request extra time if allowed.',
              style: TextStyle(
                fontSize: 12, color: AppColors.blue,
                fontWeight: FontWeight.w600, height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Per-app tile ───────────────────────────────────────────────────────────
class _AppLimitTile extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String childId;

  const _AppLimitTile({required this.docId, required this.data, required this.childId});

  @override
  Widget build(BuildContext context) {
    final appName = data['appName'] as String? ?? docId;
    final limitMinutes = data['dailyLimitMinutes'] as int? ?? 60;
    final isEnabled = data['isEnabled'] as bool? ?? true;
    final allowRequests = data['allowTimeRequests'] as bool? ?? true;
    final isBlocked = isEnabled && limitMinutes == 0;

    final color = isBlocked ? AppColors.red : AppColors.blue;

    return GestureDetector(
      onTap: () => _showEditSheet(context, appName, limitMinutes, isEnabled, allowRequests),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isBlocked ? AppColors.red.withValues(alpha: 0.4) : AppColors.border,
            width: isBlocked ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  appName.isNotEmpty ? appName[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  if (!isEnabled)
                    const Text('Disabled', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
                  else if (isBlocked)
                    _StatusPill('Blocked', AppColors.red, AppColors.redLight)
                  else
                    Text(
                      '${limitMinutes}m / day${allowRequests ? ' • requests allowed' : ''}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, String appName, int limitMinutes, bool isEnabled, bool allowRequests) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditLimitSheet(
        childId: childId,
        packageName: docId,
        appName: appName,
        currentLimit: limitMinutes,
        isEnabled: isEnabled,
        allowRequests: allowRequests,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color fg, bg;
  const _StatusPill(this.label, this.fg, this.bg);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Add App Sheet ─────────────────────────────────────────────────────────
class _AddAppSheet extends StatefulWidget {
  final String childId;
  const _AddAppSheet({required this.childId});
  @override
  State<_AddAppSheet> createState() => _AddAppSheetState();
}

class _AddAppSheetState extends State<_AddAppSheet> {
  final _nameCtrl = TextEditingController();
  final _pkgCtrl = TextEditingController();
  int _limitMinutes = 60;
  bool _allowRequests = true;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pkgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add App Limit', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'App Name (e.g. YouTube)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pkgCtrl,
              decoration: const InputDecoration(
                labelText: 'Package Name (e.g. com.google.android.youtube)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Daily limit:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _limitMinutes.toDouble(),
                    min: 0,
                    max: 480,
                    divisions: 32,
                    label: _limitMinutes == 0 ? 'Blocked' : '${_limitMinutes}m',
                    onChanged: (v) => setState(() => _limitMinutes = v.round()),
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    _limitMinutes == 0 ? 'Blocked' : '${_limitMinutes}m',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            SwitchListTile(
              value: _allowRequests,
              onChanged: (v) => setState(() => _allowRequests = v),
              title: const Text('Allow time requests', style: TextStyle(fontWeight: FontWeight.w600)),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final pkg = _pkgCtrl.text.trim().isNotEmpty
        ? _pkgCtrl.text.trim()
        : _nameCtrl.text.trim().toLowerCase().replaceAll(' ', '_');

    await ChildService().setAppLimit(
      childId: widget.childId,
      packageName: pkg,
      appName: _nameCtrl.text.trim(),
      limitMinutes: _limitMinutes,
      allowTimeRequests: _allowRequests,
    );
    if (mounted) Navigator.pop(context);
  }
}

// ── Edit Limit Sheet ──────────────────────────────────────────────────────
class _EditLimitSheet extends StatefulWidget {
  final String childId, packageName, appName;
  final int currentLimit;
  final bool isEnabled, allowRequests;
  const _EditLimitSheet({
    required this.childId, required this.packageName, required this.appName,
    required this.currentLimit, required this.isEnabled, required this.allowRequests,
  });
  @override
  State<_EditLimitSheet> createState() => _EditLimitSheetState();
}

class _EditLimitSheetState extends State<_EditLimitSheet> {
  late int _limitMinutes;
  late bool _isEnabled;
  late bool _allowRequests;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _limitMinutes = widget.currentLimit;
    _isEnabled = widget.isEnabled;
    _allowRequests = widget.allowRequests;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(widget.appName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.red),
                  onPressed: _delete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(widget.packageName, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 20),
            SwitchListTile(
              value: _isEnabled,
              onChanged: (v) => setState(() => _isEnabled = v),
              title: const Text('Limit enabled', style: TextStyle(fontWeight: FontWeight.w600)),
              contentPadding: EdgeInsets.zero,
            ),
            if (_isEnabled) ...[
              Row(
                children: [
                  const Text('Daily limit:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: _limitMinutes.toDouble(),
                      min: 0,
                      max: 480,
                      divisions: 32,
                      label: _limitMinutes == 0 ? 'Blocked' : '${_limitMinutes}m',
                      onChanged: (v) => setState(() => _limitMinutes = v.round()),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Text(
                      _limitMinutes == 0 ? 'Blocked' : '${_limitMinutes}m',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                value: _allowRequests,
                onChanged: (v) => setState(() => _allowRequests = v),
                title: const Text('Allow time requests', style: TextStyle(fontWeight: FontWeight.w600)),
                contentPadding: EdgeInsets.zero,
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await FirebaseFirestore.instance
        .collection('children')
        .doc(widget.childId)
        .collection('appLimits')
        .doc(widget.packageName)
        .set({
      'appName': widget.appName,
      'packageName': widget.packageName,
      'dailyLimitMinutes': _limitMinutes,
      'isEnabled': _isEnabled,
      'allowTimeRequests': _allowRequests,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    await FirebaseFirestore.instance
        .collection('children')
        .doc(widget.childId)
        .collection('appLimits')
        .doc(widget.packageName)
        .delete();
    if (mounted) Navigator.pop(context);
  }
}

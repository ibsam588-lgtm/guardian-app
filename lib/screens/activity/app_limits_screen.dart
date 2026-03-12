import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/time_request_service.dart';

/// Full screen for managing all app limits for a child
class AppLimitsScreen extends StatelessWidget {
  final String childId;
  final String childName;

  const AppLimitsScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  // Dummy app list (in real app: fetched from child device via Firestore)
  static final _mockApps = [
    _AppMock('TikTok', 'com.zhiliaoapp.musically', '#EF4444', 120, 120, true),
    _AppMock('YouTube', 'com.google.android.youtube', '#FF0000', 45, 90, true),
    _AppMock('Roblox', 'com.roblox.client', '#8B5CF6', 30, 60, true),
    _AppMock('Instagram', 'com.instagram.android', '#E1306C', 0, 60, false),
    _AppMock('WhatsApp', 'com.whatsapp', '#25D366', 22, 0, true),
    _AppMock('Minecraft', 'com.mojang.minecraftpe', '#6D9B3A', 20, 45, true),
    _AppMock('Snapchat', 'com.snapchat.android', '#FFFC00', 10, 30, true),
    _AppMock('Discord', 'com.discord', '#5865F2', 15, 45, true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('$childName\'s App Limits'),
        backgroundColor: AppColors.navy,
      ),
      body: ListView(
        children: [
          _BannerTip(),
          const SizedBox(height: 8),
          ..._mockApps.map((app) => _AppLimitTile(
            app: app,
            childId: childId,
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _AppMock {
  final String name, packageName, color;
  final int usedMinutes, limitMinutes;
  final bool hasLimit;
  const _AppMock(this.name, this.packageName, this.color,
      this.usedMinutes, this.limitMinutes, this.hasLimit);
}

class _BannerTip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blueLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.blue.withOpacity(0.25)),
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
              'Tap any app to set limits. Enable "Allow time requests" so Emma can ask you for extra minutes when needed.',
              style: TextStyle(
                fontSize: 12, color: AppColors.blue,
                fontFamily: 'Nunito', fontWeight: FontWeight.w600, height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Per-app tile with tap-to-edit
// ─────────────────────────────────────────────
class _AppLimitTile extends StatelessWidget {
  final _AppMock app;
  final String childId;

  const _AppLimitTile({required this.app, required this.childId});

  Color get _color => _hexColor(app.color);
  Color get _bg => _color.withOpacity(0.1);

  @override
  Widget build(BuildContext context) {
    final isMaxed = app.hasLimit && app.limitMinutes > 0 && app.usedMinutes >= app.limitMinutes;
    final isBlocked = app.hasLimit && app.limitMinutes == 0;

    return GestureDetector(
      onTap: () => _showEditSheet(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMaxed ? AppColors.red.withOpacity(0.4) : AppColors.border,
            width: isMaxed ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // App icon
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: _bg, borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(app.name[0], style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: _color, fontFamily: 'Nunito',
                    )),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.name, style: const TextStyle(
                        fontWeight: FontWeight.w700, fontFamily: 'Nunito', fontSize: 15,
                      )),
                      const SizedBox(height: 2),
                      if (!app.hasLimit)
                        const Text('No limit set', style: TextStyle(
                          color: AppColors.textMuted, fontFamily: 'Nunito', fontSize: 12,
                        ))
                      else if (isBlocked)
                        _StatusPill('Blocked', AppColors.red, AppColors.redLight)
                      else if (isMaxed)
                        _StatusPill('Limit reached', AppColors.red, AppColors.redLight)
                      else
                        Text(
                          '${_fmtMins(app.usedMinutes)} of ${_fmtMins(app.limitMinutes)} used',
                          style: const TextStyle(
                            color: AppColors.textMuted, fontFamily: 'Nunito', fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),

                // Edit chevron
                const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
              ],
            ),

            // Progress bar (only when limit is set and not blocked)
            if (app.hasLimit && app.limitMinutes > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (app.usedMinutes / app.limitMinutes).clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation(isMaxed ? AppColors.red : _color),
                  minHeight: 6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AppLimitEditSheet(app: app, childId: childId),
    );
  }

  String _fmtMins(int m) {
    if (m == 0) return '0m';
    if (m < 60) return '${m}m';
    final h = m ~/ 60;
    final rem = m % 60;
    return rem > 0 ? '${h}h ${rem}m' : '${h}h';
  }
}

Widget _StatusPill(String label, Color color, Color bg) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(
      color: color, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Nunito',
    )),
  );
}

// ─────────────────────────────────────────────
//  Bottom Sheet: Edit app limit
// ─────────────────────────────────────────────
class _AppLimitEditSheet extends StatefulWidget {
  final _AppMock app;
  final String childId;
  const _AppLimitEditSheet({required this.app, required this.childId});

  @override
  State<_AppLimitEditSheet> createState() => _AppLimitEditSheetState();
}

class _AppLimitEditSheetState extends State<_AppLimitEditSheet> {
  late bool _hasLimit;
  late bool _isBlocked;
  late bool _allowRequests;
  late double _limitHours;
  late double _limitMins;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _hasLimit = widget.app.hasLimit;
    _isBlocked = widget.app.limitMinutes == 0 && widget.app.hasLimit;
    _allowRequests = true;
    final total = widget.app.limitMinutes > 0 ? widget.app.limitMinutes : 60;
    _limitHours = (total ~/ 60).toDouble();
    _limitMins = ((total % 60) ~/ 15 * 15).toDouble(); // round to 15-min steps
  }

  int get _totalLimitMins => (_limitHours * 60 + _limitMins).toInt();

  Future<void> _save() async {
    setState(() => _saving = true);
    final svc = TimeRequestService();
    await svc.saveAppLimit(
      childId: widget.childId,
      packageName: widget.app.packageName,
      appName: widget.app.name,
      appIconColor: widget.app.color,
      dailyLimitMinutes: _isBlocked ? 0 : (_hasLimit ? _totalLimitMins : 0),
      isEnabled: _hasLimit,
      allowTimeRequests: _allowRequests,
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${widget.app.name} limit saved!'),
        backgroundColor: AppColors.green,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _hexColor(widget.app.color);
    final bg = color.withOpacity(0.1);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24, right: 24, top: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 20),

          // App header
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(widget.app.name[0], style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: color, fontFamily: 'Nunito',
                ))),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.app.name, style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Nunito',
                  )),
                  const Text('Set daily time limit', style: TextStyle(
                    color: AppColors.textMuted, fontFamily: 'Nunito', fontSize: 13,
                  )),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Enable limit toggle
          _SheetToggle(
            title: 'Enable time limit',
            subtitle: 'Restrict daily usage for this app',
            value: _hasLimit,
            onChanged: (v) => setState(() => _hasLimit = v),
          ),

          if (_hasLimit) ...[
            const SizedBox(height: 16),

            // Block entirely toggle
            _SheetToggle(
              title: 'Block entirely',
              subtitle: 'App is completely inaccessible',
              value: _isBlocked,
              activeColor: AppColors.red,
              onChanged: (v) => setState(() => _isBlocked = v),
            ),

            if (!_isBlocked) ...[
              const SizedBox(height: 20),

              // Time picker
              const Text('Daily limit', style: TextStyle(
                fontWeight: FontWeight.w700, fontFamily: 'Nunito', fontSize: 14,
              )),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // Hours slider
                    _SliderRow(
                      label: 'Hours',
                      value: _limitHours,
                      min: 0, max: 8, divisions: 8,
                      displayValue: '${_limitHours.toInt()}h',
                      color: color,
                      onChanged: (v) => setState(() => _limitHours = v),
                    ),
                    const SizedBox(height: 12),
                    // Minutes slider
                    _SliderRow(
                      label: 'Minutes',
                      value: _limitMins,
                      min: 0, max: 45, divisions: 3,
                      displayValue: '${_limitMins.toInt()}m',
                      color: color,
                      onChanged: (v) => setState(() => _limitMins = v),
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total daily limit', style: TextStyle(
                          fontWeight: FontWeight.w700, fontFamily: 'Nunito', fontSize: 13,
                        )),
                        Text(
                          _totalLimitMins == 0
                              ? 'No limit'
                              : _fmtMins(_totalLimitMins),
                          style: TextStyle(
                            fontWeight: FontWeight.w800, fontFamily: 'Nunito',
                            fontSize: 16, color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Quick presets
              const Text('Quick presets', style: TextStyle(
                fontWeight: FontWeight.w700, fontFamily: 'Nunito', fontSize: 14,
              )),
              const SizedBox(height: 8),
              Row(
                children: [15, 30, 45, 60, 90, 120].map((min) => GestureDetector(
                  onTap: () => setState(() {
                    _limitHours = (min ~/ 60).toDouble();
                    _limitMins = (min % 60).toDouble();
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _totalLimitMins == min ? color : AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _totalLimitMins == min ? color : AppColors.border,
                      ),
                    ),
                    child: Text(_fmtMins(min), style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _totalLimitMins == min ? Colors.white : AppColors.textMuted,
                    )),
                  ),
                )).toList(),
              ),

              const SizedBox(height: 20),

              // Allow time requests
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _allowRequests ? AppColors.greenLight : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _allowRequests
                        ? AppColors.green.withOpacity(0.4)
                        : AppColors.border,
                  ),
                ),
                child: _SheetToggle(
                  title: 'Allow time requests',
                  subtitle: 'Emma can ask you for extra time when limit is reached',
                  value: _allowRequests,
                  activeColor: AppColors.green,
                  onChanged: (v) => setState(() => _allowRequests = v),
                  noBorder: true,
                ),
              ),
            ],
          ],

          const SizedBox(height: 24),

          // Save button
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 22, width: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Save Limit'),
          ),
        ],
      ),
    );
  }

  String _fmtMins(int m) {
    if (m < 60) return '${m}m';
    final h = m ~/ 60;
    final rem = m % 60;
    return rem > 0 ? '${h}h ${rem}m' : '${h}h';
  }
}

// ─────────────────────────────────────────────
//  Reusable widgets
// ─────────────────────────────────────────────
class _SheetToggle extends StatelessWidget {
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;
  final bool noBorder;

  const _SheetToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.activeColor = AppColors.blue,
    this.noBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                fontWeight: FontWeight.w700, fontFamily: 'Nunito', fontSize: 14,
              )),
              Text(subtitle, style: const TextStyle(
                color: AppColors.textMuted, fontFamily: 'Nunito', fontSize: 12,
              )),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged, activeColor: activeColor),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label, displayValue;
  final double value, min, max;
  final int divisions;
  final Color color;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label, required this.value, required this.min,
    required this.max, required this.divisions, required this.displayValue,
    required this.color, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: const TextStyle(
            color: AppColors.textMuted, fontFamily: 'Nunito',
            fontSize: 12, fontWeight: FontWeight.w600,
          )),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: AppColors.border,
              overlayColor: color.withOpacity(0.15),
              trackHeight: 4,
            ),
            child: Slider(
              value: value, min: min, max: max,
              divisions: divisions, onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 38,
          child: Text(displayValue, textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w800, fontFamily: 'Nunito',
                fontSize: 13, color: color,
              )),
        ),
      ],
    );
  }
}

Color _hexColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

// Barrel export
const surfaceSecondary = AppColors.surfaceSecondary;

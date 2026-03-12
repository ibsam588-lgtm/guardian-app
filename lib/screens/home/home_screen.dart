import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../models/models.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _GuardianHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _MapPreviewCard(),
                  _StatusRow(),
                  _QuickActionsGrid(),
                  _RecentAlerts(),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _BottomNav(currentIndex: 0),
    );
  }
}

// ── Header ─────────────────────────────────────
class _GuardianHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20, right: 20, bottom: 16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Guard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    TextSpan(
                      text: 'Ian',
                      style: TextStyle(
                        color: Color(0xFF60A5FA),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Stack(
                children: [
                  IconButton(
                    onPressed: () => context.go('/alerts'),
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  ),
                  Positioned(
                    right: 8, top: 8,
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.navy, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Child chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF60A5FA), Color(0xFFA78BFA)],
                    ),
                  ),
                  child: const Center(
                    child: Text('E', style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Nunito',
                    )),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emma, 12',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Nunito',
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7, height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Online · School area',
                          style: TextStyle(
                            color: Colors.white60,
                            fontFamily: 'Nunito',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white60, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Map Preview ────────────────────────────────
class _MapPreviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/location'),
      child: Container(
        height: 200,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFDBEAFE), Color(0xFFEDE9FE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Grid background
            CustomPaint(painter: _GridPainter(), size: Size.infinite),

            // Pulse + pin
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 28, height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),

            // Labels
            Positioned(
              bottom: 12, left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Sunridge Academy · 0.3 mi',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                    color: AppColors.navy,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Full Map',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4B5563).withOpacity(0.15)
      ..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Status Row ─────────────────────────────────
class _StatusRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _StatCard(value: 'Safe', label: 'Location',
              color: AppColors.blue, bg: AppColors.blueLight,
              icon: Icons.location_on_outlined),
          const SizedBox(width: 10),
          _StatCard(value: '4h 12m', label: 'Screen',
              color: AppColors.amber, bg: AppColors.amberLight,
              icon: Icons.phone_android_outlined),
          const SizedBox(width: 10),
          _StatCard(value: '2', label: 'Calls',
              color: AppColors.green, bg: AppColors.greenLight,
              icon: Icons.call_outlined),
          const SizedBox(width: 10),
          _StatCard(value: '1', label: 'Alert',
              color: AppColors.red, bg: AppColors.redLight,
              icon: Icons.warning_amber_outlined),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final Color color, bg;
  final IconData icon;
  const _StatCard({
    required this.value, required this.label,
    required this.color, required this.bg, required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w800,
              color: color, fontFamily: 'Nunito',
            )),
            Text(label, style: const TextStyle(
              fontSize: 10, color: AppColors.textMuted,
              fontFamily: 'Nunito', fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }
}

// ── Quick Actions ──────────────────────────────
class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _QAButton(
            label: 'Listen Live',
            icon: Icons.mic_outlined,
            color: AppColors.purple,
            bg: AppColors.purpleLight,
            onTap: () => context.go('/listen'),
          ),
          const SizedBox(width: 10),
          _QAButton(
            label: 'Emergency',
            icon: Icons.warning_outlined,
            color: AppColors.red,
            bg: AppColors.redLight,
            onTap: () => context.go('/emergency'),
          ),
          const SizedBox(width: 10),
          _QAButton(
            label: 'Ring Siren',
            icon: Icons.campaign_outlined,
            color: AppColors.amber,
            bg: AppColors.amberLight,
            onTap: () => _showSirenDialog(context),
          ),
          const SizedBox(width: 10),
          _QAButton(
            label: 'App Lock',
            icon: Icons.lock_outline,
            color: AppColors.blue,
            bg: AppColors.blueLight,
            onTap: () => _showPinDialog(context),
          ),
        ],
      ),
    );
  }

  void _showSirenDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ring Siren',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        content: const Text(
          'This will ring Emma\'s phone at full volume, even if on silent. Use this to locate her nearby.',
          style: TextStyle(fontFamily: 'Nunito'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'Nunito', color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Siren activated on Emma\'s phone!'),
                  backgroundColor: AppColors.amber,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              minimumSize: const Size(100, 42),
            ),
            child: const Text('Ring Now'),
          ),
        ],
      ),
    );
  }

  void _showPinDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PinLockSheet(),
    );
  }
}

class _QAButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color, bg;
  final VoidCallback onTap;
  const _QAButton({
    required this.label, required this.icon,
    required this.color, required this.bg, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 6),
              Text(label, style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary, fontFamily: 'Nunito',
              ), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Alerts List ────────────────────────────────
class _RecentAlerts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final alerts = [
      _AlertData('Left school geo-fence', 'Boundary breach · Unverified',
          AppColors.red, AppColors.redLight, Icons.fence, '2m ago'),
      _AlertData('TikTok 2hr limit reached', 'App blocked automatically',
          AppColors.amber, AppColors.amberLight, Icons.timer_off_outlined, '1h ago'),
      _AlertData('Arrived at school', '8:24 AM check-in confirmed',
          AppColors.blue, AppColors.blueLight, Icons.location_on_outlined, '3h ago'),
    ];

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Recent Alerts', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.textMuted, fontFamily: 'Nunito',
                  letterSpacing: 0.5,
                )),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.redLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('1 new', style: TextStyle(
                    color: AppColors.red, fontSize: 11,
                    fontWeight: FontWeight.w700, fontFamily: 'Nunito',
                  )),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...alerts.map((a) => _AlertItem(data: a)),
          ],
        ),
      ),
    );
  }
}

class _AlertData {
  final String title, subtitle, time;
  final Color color, bg;
  final IconData icon;
  const _AlertData(this.title, this.subtitle, this.color, this.bg, this.icon, this.time);
}

class _AlertItem extends StatelessWidget {
  final _AlertData data;
  const _AlertItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: data.bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(data.icon, color: data.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: const TextStyle(
                  fontWeight: FontWeight.w700, fontFamily: 'Nunito', fontSize: 13,
                )),
                Text(data.subtitle, style: const TextStyle(
                  color: AppColors.textMuted, fontFamily: 'Nunito', fontSize: 11,
                )),
              ],
            ),
          ),
          Text(data.time, style: const TextStyle(
            color: AppColors.textMuted, fontSize: 11, fontFamily: 'Nunito',
          )),
        ],
      ),
    );
  }
}

// ── PIN Lock Bottom Sheet ──────────────────────
class _PinLockSheet extends StatefulWidget {
  const _PinLockSheet();

  @override
  State<_PinLockSheet> createState() => _PinLockSheetState();
}

class _PinLockSheetState extends State<_PinLockSheet> {
  String _pin = '';
  String? _message;

  void _onKey(String k) {
    if (_pin.length >= 4) return;
    setState(() => _pin += k);
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_pin == '1234') {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unlocked! Settings accessible.')),
          );
        } else {
          setState(() { _pin = ''; _message = 'Wrong PIN. Try again.'; });
        }
      });
    }
  }

  void _del() => setState(() { if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1); });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24, right: 24, top: 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Parent Lock', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Nunito',
          )),
          const SizedBox(height: 6),
          const Text('Enter your 4-digit PIN', style: TextStyle(
            color: AppColors.textMuted, fontFamily: 'Nunito',
          )),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) => Container(
              width: 16, height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < _pin.length ? AppColors.blue : AppColors.border,
              ),
            )),
          ),
          if (_message != null) ...[
            const SizedBox(height: 10),
            Text(_message!, style: const TextStyle(color: AppColors.red, fontFamily: 'Nunito', fontSize: 13)),
          ],
          const SizedBox(height: 24),
          ...[[1,2,3],[4,5,6],[7,8,9]].map((row) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((n) => _PinKey(
                label: '$n',
                onTap: () => _onKey('$n'),
              )).toList(),
            ),
          )),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 80 + 16),
              _PinKey(label: '0', onTap: () => _onKey('0')),
              const SizedBox(width: 16),
              _PinKey(
                label: '⌫',
                onTap: _del,
                isAction: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PinKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isAction;
  const _PinKey({required this.label, required this.onTap, this.isAction = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80, height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isAction ? Colors.transparent : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(14),
          border: isAction ? null : Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(label, style: TextStyle(
            fontSize: isAction ? 18 : 22,
            fontWeight: FontWeight.w700,
            color: isAction ? AppColors.textMuted : AppColors.textPrimary,
            fontFamily: 'Nunito',
          )),
        ),
      ),
    );
  }
}

// ── Bottom Nav ─────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, Icons.home, 'Home', '/home'),
      (Icons.location_on_outlined, Icons.location_on, 'Location', '/location'),
      (Icons.phone_android_outlined, Icons.phone_android, 'Activity', '/activity'),
      (Icons.message_outlined, Icons.message, 'Comms', '/comms'),
      (Icons.warning_amber_outlined, Icons.warning_amber, 'Safety', '/emergency'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 4,
      ),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final active = currentIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => context.go(item.$4),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      active ? item.$2 : item.$1,
                      color: active ? AppColors.blue : AppColors.textMuted,
                      size: 22,
                    ),
                    const SizedBox(height: 3),
                    Text(item.$3, style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                      color: active ? AppColors.blue : AppColors.textMuted,
                    )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

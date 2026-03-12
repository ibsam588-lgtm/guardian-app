import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart' show GuardianBottomNav;

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  // ignore: unused_field
  bool _sosTriggered = false;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _triggerSOS() {
    setState(() => _sosTriggered = true);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.redLight, borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning, color: AppColors.red, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('SOS Triggered!', style: TextStyle(
              fontFamily: 'Nunito', fontWeight: FontWeight.w800,
            )),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emma\'s location sent to:', style: TextStyle(
              fontFamily: 'Nunito', fontWeight: FontWeight.w700,
            )),
            SizedBox(height: 8),
            _ContactAlert(name: 'Mom (You)', status: 'Calling now...'),
            _ContactAlert(name: 'Dad', status: 'SMS sent'),
            _ContactAlert(name: 'Grandma', status: 'SMS sent'),
            SizedBox(height: 12),
            Text('Location: Sunridge Academy, 3rd & Oak',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 13,
                    color: AppColors.textMuted)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _sosTriggered = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green, minimumSize: const Size(120, 42)),
            child: const Text('Acknowledged'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency & Safety'),
        backgroundColor: AppColors.navy,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // SOS card
            Card(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('CHILD PANIC BUTTON', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted,
                      fontFamily: 'Nunito', letterSpacing: 1,
                    )),
                    const SizedBox(height: 24),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, __) => Container(
                            width: 180, height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.red.withOpacity(
                                  0.05 + 0.05 * (1 - _pulse.value)),
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, __) => Container(
                            width: 160, height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.red.withOpacity(
                                  0.08 + 0.07 * (1 - _pulse.value)),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _triggerSOS,
                          child: Container(
                            width: 130, height: 130,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.red,
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.warning, color: Colors.white, size: 40),
                                SizedBox(height: 4),
                                Text('SOS', style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Nunito',
                                )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Emma holds this button 3 seconds to alert you & emergency contacts instantly with her GPS location',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted,
                        fontFamily: 'Nunito', height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Emergency contacts
            Card(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('EMERGENCY CONTACTS', style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted,
                          fontFamily: 'Nunito', letterSpacing: 0.5,
                        )),
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          child: const Text('+ Add', style: TextStyle(
                            color: AppColors.blue, fontWeight: FontWeight.w700,
                            fontFamily: 'Nunito', fontSize: 12,
                          )),
                        ),
                      ],
                    ),
                    _ContactCard('M', 'Mom (Primary)', '(410) 555-0101', '1st',
                        AppColors.green, AppColors.greenLight),
                    const SizedBox(height: 8),
                    _ContactCard('D', 'Dad', '(410) 555-0102', '2nd',
                        AppColors.blue, AppColors.blueLight),
                    const SizedBox(height: 8),
                    _ContactCard('G', 'Grandma', '(410) 555-0105', '3rd',
                        AppColors.textMuted, AppColors.surfaceSecondary),
                  ],
                ),
              ),
            ),

            // Safety controls
            _SafetyControlsCard(),
            const SizedBox(height: 90),
          ],
        ),
      ),
      bottomNavigationBar: const GuardianBottomNav(currentIndex: 4),
    );
  }
}

Widget _ContactCard(String initial, String name, String phone, String order,
    Color color, Color bg) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: bg, borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(child: Text(initial, style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w700,
            fontFamily: 'Nunito', fontSize: 14,
          ))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(
                fontWeight: FontWeight.w700, fontFamily: 'Nunito', fontSize: 13,
              )),
              Text(phone, style: const TextStyle(
                color: AppColors.textMuted, fontFamily: 'Nunito', fontSize: 11,
              )),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20),
          ),
          child: Text(order, style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Nunito',
          )),
        ),
      ],
    ),
  );
}

class _SafetyControlsCard extends StatefulWidget {
  @override
  State<_SafetyControlsCard> createState() => _SafetyControlsCardState();
}

class _SafetyControlsCardState extends State<_SafetyControlsCard> {
  bool _siren = false;
  bool _autoCall = true;
  bool _checkin = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PARENT CONTROLS', style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted,
              fontFamily: 'Nunito', letterSpacing: 0.5,
            )),
            const SizedBox(height: 12),
            _ToggleRow(title: 'Remote Siren',
                sub: 'Ring Emma\'s phone even on silent',
                value: _siren,
                onChanged: (v) => setState(() => _siren = v)),
            _ToggleRow(title: 'Auto-call on SOS',
                sub: 'Automatically call you when SOS triggered',
                value: _autoCall,
                onChanged: (v) => setState(() => _autoCall = v)),
            _ToggleRow(title: 'Check-in reminders',
                sub: 'Emma gets location ping every 2 hours',
                value: _checkin,
                onChanged: (v) => setState(() => _checkin = v),
                last: true),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title, sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;
  const _ToggleRow({
    required this.title, required this.sub,
    required this.value, required this.onChanged, this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: last ? null : const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Row(
        children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                fontWeight: FontWeight.w700, fontFamily: 'Nunito', fontSize: 14,
              )),
              Text(sub, style: const TextStyle(
                color: AppColors.textMuted, fontFamily: 'Nunito', fontSize: 12,
              )),
            ],
          )),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.blue),
        ],
      ),
    );
  }
}

class _ContactAlert extends StatelessWidget {
  final String name, status;
  const _ContactAlert({required this.name, required this.status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.green, size: 16),
          const SizedBox(width: 8),
          Text(name, style: const TextStyle(
            fontFamily: 'Nunito', fontWeight: FontWeight.w600, fontSize: 13,
          )),
          const Spacer(),
          Text(status, style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 11, color: AppColors.textMuted,
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Listen Screen (ambient audio)
// ─────────────────────────────────────────────

class ListenScreen extends StatefulWidget {
  const ListenScreen({super.key});

  @override
  State<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends State<ListenScreen>
    with TickerProviderStateMixin {
  bool _isListening = false;
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Listen Live'),
        backgroundColor: AppColors.navy,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _waveCtrl,
                          builder: (_, __) => Container(
                            width: 190, height: 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: (_isListening ? AppColors.red : AppColors.purple)
                                    .withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _waveCtrl,
                          builder: (_, __) => Container(
                            width: 155, height: 155,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: (_isListening ? AppColors.red : AppColors.purple)
                                    .withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening
                                ? AppColors.redLight
                                : AppColors.purpleLight,
                            border: Border.all(
                              color: _isListening ? AppColors.red : AppColors.purple,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.mic,
                            color: _isListening ? AppColors.red : AppColors.purple,
                            size: 48,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isListening ? 'Listening live...' : 'Tap to Listen',
                      style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Opens a discreet microphone on Emma\'s phone so you can hear her surroundings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12, color: AppColors.textMuted,
                        fontFamily: 'Nunito', height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 160, height: 48,
                      child: ElevatedButton(
                        onPressed: () => setState(() => _isListening = !_isListening),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isListening ? AppColors.red : AppColors.purple,
                        ),
                        child: Text(_isListening ? 'Stop' : 'Start Listening'),
                      ),
                    ),

                    if (_isListening) ...[
                      const SizedBox(height: 20),
                      _AudioWaveform(animation: _waveCtrl),
                      const SizedBox(height: 8),
                      const Text('Connected · Emma\'s surroundings',
                          style: TextStyle(
                            color: AppColors.green, fontSize: 12,
                            fontWeight: FontWeight.w700, fontFamily: 'Nunito',
                          )),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _AudioWaveform extends StatelessWidget {
  final Animation<double> animation;
  const _AudioWaveform({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(24, (i) {
            final factor = (i % 4 == 0) ? 0.9 : (i % 3 == 0) ? 0.6 : 0.4;
            final anim = (animation.value + i * 0.1) % 1.0;
            final h = 6.0 + 32 * factor * (0.3 + 0.7 * anim);
            return Container(
              width: 5,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        );
      },
    );
  }
}

const surfaceSecondary = AppColors.surfaceSecondary;

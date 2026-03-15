import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/child_service.dart';
import '../../theme/app_theme.dart';

// ─────────────────────────────────────────────
//  Step 1: Parent Profile Setup
// ─────────────────────────────────────────────
class ParentSetupScreen extends StatefulWidget {
  const ParentSetupScreen({super.key});

  @override
  State<ParentSetupScreen> createState() => _ParentSetupScreenState();
}

class _ParentSetupScreenState extends State<ParentSetupScreen> {
  final _childNameCtrl = TextEditingController();
  int _childAge = 10;
  bool _loading = false;
  String? _pairingCode;
  final _childService = ChildService();

  Future<void> _generateCode() async {
    if (_childNameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);

    final code = await _childService.createChildPairingCode(
      childName: _childNameCtrl.text.trim(),
      childAge: _childAge,
    );

    setState(() {
      _pairingCode = code;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _pairingCode == null
            ? _buildSetupForm(context)
            : _buildPairingCodeScreen(context),
      ),
    );
  }

  Widget _buildSetupForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          _StepIndicator(step: 1, total: 3),
          const SizedBox(height: 28),

          Text("Let's set up\nyour child's profile",
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'We\'ll create a pairing code to install the child app on their device.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 32),

          // Child avatar placeholder
          Center(
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.blue, width: 2),
                  ),
                  child: const Icon(Icons.child_care, color: AppColors.blue, size: 40),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {},
                  child: const Text('Add photo (optional)',
                      style: TextStyle(color: AppColors.blue, fontFamily: 'Nunito')),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          TextFormField(
            controller: _childNameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: "Child's first name",
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),

          const SizedBox(height: 20),

          Text("Child's age",
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          // Age selector
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 14, // ages 4–17
              itemBuilder: (ctx, i) {
                final age = i + 4;
                final selected = age == _childAge;
                return GestureDetector(
                  onTap: () => setState(() => _childAge = age),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.blue : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.blue : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$age',
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 36),

          ElevatedButton(
            onPressed: _loading ? null : _generateCode,
            child: _loading
                ? const SizedBox(
                    height: 22, width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
                : const Text('Generate Pairing Code'),
          ),
        ],
      ),
    );
  }

  Widget _buildPairingCodeScreen(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _StepIndicator(step: 2, total: 3),
          const SizedBox(height: 28),

          Text('Install the child app',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Follow these steps on ${_childNameCtrl.text}\'s phone:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),

          const SizedBox(height: 28),

          // Pairing code display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'PAIRING CODE',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Nunito',
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _pairingCode!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Nunito',
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Valid for 15 minutes',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Step-by-step instructions
          _InstallStep(
            number: 1,
            icon: Icons.download_outlined,
            title: 'Download GuardIan Child App',
            subtitle: 'Search "GuardIan Child" on Google Play or App Store',
          ),
          _InstallStep(
            number: 2,
            icon: Icons.pin_outlined,
            title: 'Enter the pairing code above',
            subtitle: 'Open the child app and type in the 6-digit code',
          ),
          _InstallStep(
            number: 3,
            icon: Icons.check_circle_outline,
            title: 'Grant permissions',
            subtitle: 'Allow location, notifications, and accessibility access',
          ),
          _InstallStep(
            number: 4,
            icon: Icons.link,
            title: 'Devices link automatically',
            subtitle: 'You\'ll see Emma appear on your dashboard',
          ),

          const SizedBox(height: 28),

          ElevatedButton(
            onPressed: () => context.go('/onboarding/subscription'),
            child: const Text('Continue to Subscription'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _pairingCode = null),
            child: const Text('Generate a new code',
                style: TextStyle(color: AppColors.textMuted, fontFamily: 'Nunito')),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Subscription / Paywall Screen
// ─────────────────────────────────────────────
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Shield icon
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield, color: Colors.white, size: 42),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'GuardIan Pro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Complete protection for your family',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 15,
                        fontFamily: 'Nunito',
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Feature list
                    ...[
                      ('GPS Live Tracking', Icons.location_on),
                      ('Geo-Fence Alerts', Icons.fence),
                      ('Screen Time & App Limits', Icons.timer),
                      ('Web Monitoring', Icons.language),
                      ('Call & Message Monitoring', Icons.message),
                      ('Remote Siren', Icons.notifications_active),
                      ('Live Ambient Listening', Icons.mic),
                      ('SOS Emergency Button', Icons.emergency),
                    ].map((item) => _FeatureRow(label: item.$1, icon: item.$2)),

                    const SizedBox(height: 32),

                    // Pricing card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '\$',
                                style: TextStyle(
                                  color: AppColors.blue,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                              const Text(
                                '2.99',
                                style: TextStyle(
                                  color: AppColors.blue,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Nunito',
                                  height: 1,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(top: 28),
                                child: Text(
                                  '/month',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 14,
                                    fontFamily: 'Nunito',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.greenLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '7-day FREE trial — no charge today',
                              style: TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Nunito',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () => context.go('/home'),
                              child: const Text('Start Free Trial'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Cancel anytime. No hidden fees.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(
                          color: Colors.white38,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Shared widgets
// ─────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int step;
  final int total;
  const _StepIndicator({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(child: Container(
            height: 2,
            color: i ~/ 2 < step - 1 ? AppColors.blue : AppColors.border,
          ));
        }
        final dotStep = i ~/ 2 + 1;
        final done = dotStep < step;
        final active = dotStep == step;
        return Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done || active ? AppColors.blue : AppColors.surface,
            border: Border.all(
              color: done || active ? AppColors.blue : AppColors.border,
              width: 2,
            ),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : Text(
                    '$dotStep',
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Nunito',
                      fontSize: 12,
                    ),
                  ),
          ),
        );
      }),
    );
  }
}

class _InstallStep extends StatelessWidget {
  final int number;
  final IconData icon;
  final String title;
  final String subtitle;
  const _InstallStep({
    required this.number, required this.icon,
    required this.title, required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.blueLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.blue, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    )),
                Text(subtitle,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: AppColors.textMuted,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FeatureRow({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white70, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'Nunito',
              fontSize: 14,
            ),
          ),
          const Spacer(),
          const Icon(Icons.check_circle, color: AppColors.green, size: 18),
        ],
      ),
    );
  }
}

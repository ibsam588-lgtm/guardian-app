import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/onboarding/onboarding_screens.dart';
import 'screens/home/home_screen.dart';
import 'screens/activity/activity_screen.dart';
import 'screens/emergency/emergency_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const GuardIanApp());
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),

    // Onboarding
    GoRoute(
      path: '/onboarding/setup',
      builder: (_, __) => const ParentSetupScreen(),
    ),
    GoRoute(
      path: '/onboarding/subscription',
      builder: (_, __) => const SubscriptionScreen(),
    ),

    // Main app
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/location',
      builder: (_, __) => const _LocationScreen(),
    ),
    GoRoute(
      path: '/activity',
      builder: (_, __) => const ActivityScreen(),
    ),
    GoRoute(
      path: '/comms',
      builder: (_, __) => const _CommsScreen(),
    ),
    GoRoute(
      path: '/emergency',
      builder: (_, __) => const EmergencyScreen(),
    ),
    GoRoute(
      path: '/listen',
      builder: (_, __) => const ListenScreen(),
    ),
  ],
);

class GuardIanApp extends StatelessWidget {
  const GuardIanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GuardIan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}

// ─── Placeholder screens (filled from own files in full project) ───────────

class _LocationScreen extends StatelessWidget {
  const _LocationScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Live Location'),
        backgroundColor: AppColors.navy,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('Live GPS Map', style: TextStyle(
              fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 8),
            const Text(
              'google_maps_flutter widget renders here\nwith real-time child location pin',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontFamily: 'Nunito'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(160, 44)),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const GuardianBottomNav(currentIndex: 1),
    );
  }
}

class _CommsScreen extends StatelessWidget {
  const _CommsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calls & Messages'),
        backgroundColor: AppColors.navy,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.message_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('Communications Monitor', style: TextStyle(
              fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 8),
            const Text(
              'Call logs, message previews,\nand AI-flagged content appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontFamily: 'Nunito'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const GuardianBottomNav(currentIndex: 3),
    );
  }
}

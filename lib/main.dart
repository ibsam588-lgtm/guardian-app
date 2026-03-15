import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'screens/location/location_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const GuardIanApp());
}

// Auth-aware router — redirects to /home if already logged in
final _router = GoRouter(
  initialLocation: '/login',
  // Refresh the router whenever auth state changes
  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  ),
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final isOnAuth = state.matchedLocation == '/login' ||
        state.matchedLocation == '/signup';
    final isOnOnboarding = state.matchedLocation.startsWith('/onboarding');

    // If logged in and on login/signup, go home
    if (isLoggedIn && isOnAuth) return '/home';
    // If not logged in and trying to access app, go to login
    if (!isLoggedIn && !isOnAuth && !isOnOnboarding) return '/login';
    return null;
  },
  routes: [
    GoRoute(path: '/login',  builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(path: '/onboarding/setup',        builder: (_, __) => const ParentSetupScreen()),
    GoRoute(path: '/onboarding/subscription', builder: (_, __) => const SubscriptionScreen()),
    GoRoute(path: '/home',     builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/activity', builder: (_, __) => const ActivityScreen()),
    GoRoute(path: '/emergency', builder: (_, __) => const EmergencyScreen()),
    GoRoute(
      path: '/location',
      builder: (_, state) => LocationScreen(childId: state.extra as String? ?? ''),
    ),
    GoRoute(path: '/comms',  builder: (_, __) => const _CommsScreen()),
    GoRoute(path: '/listen', builder: (_, __) => const _CommsScreen()),
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

/// Bridges a Stream to a Listenable so GoRouter refreshes on auth changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// ─── Placeholder screens ───────────────────────
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
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.message_outlined, size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('Communications Monitor', style: TextStyle(
              fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w700,
            )),
            SizedBox(height: 8),
            Text(
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

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
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

final _router = GoRouter(
  initialLocation: '/login',
  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  ),
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final loc = state.matchedLocation;
    final isOnAuth = loc == '/login' || loc == '/signup' || loc == '/forgot-password';
    final isOnOnboarding = loc.startsWith('/onboarding');
    if (isLoggedIn && isOnAuth) return '/home';
    if (!isLoggedIn && !isOnAuth && !isOnOnboarding) return '/login';
    return null;
  },
  routes: [
    GoRoute(path: '/login',           builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup',          builder: (_, __) => const SignupScreen()),
    GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(path: '/onboarding/setup',        builder: (_, __) => const ParentSetupScreen()),
    GoRoute(path: '/onboarding/subscription', builder: (_, __) => const SubscriptionScreen()),
    GoRoute(path: '/home',      builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/activity',  builder: (_, __) => const ActivityScreen()),
    GoRoute(path: '/emergency', builder: (_, __) => const EmergencyScreen()),
    GoRoute(
      path: '/location',
      builder: (_, state) => LocationScreen(childId: state.extra as String? ?? ''),
    ),
    GoRoute(path: '/alerts',  builder: (_, __) => const _AlertsScreen()),
    GoRoute(path: '/comms',   builder: (_, __) => const _CommsScreen()),
    GoRoute(path: '/listen',  builder: (_, __) => const _CommsScreen()),
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

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final _sub;
  @override void dispose() { _sub.cancel(); super.dispose(); }
}

// ── Alerts screen ──────────────────────────────────────────────────────────
class _AlertsScreen extends StatelessWidget {
  const _AlertsScreen();
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Alerts'),
        backgroundColor: AppColors.navy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: uid == null
        ? const Center(child: Text('Not signed in'))
        : StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
            .collection('alerts')
            .where('parentUid', isEqualTo: uid)
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            if (docs.isEmpty) return const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check_circle_outline, size: 64, color: AppColors.green),
                SizedBox(height: 16),
                Text('No alerts yet — all safe!', style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w700)),
              ]));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                final isWarn = (d['type'] ?? '').contains('fence') || (d['type'] ?? '').contains('limit');
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Container(width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isWarn ? AppColors.amberLight : AppColors.blueLight,
                        borderRadius: BorderRadius.circular(10)),
                      child: Icon(isWarn ? Icons.warning_amber_rounded : Icons.notifications_outlined,
                          color: isWarn ? AppColors.amber : AppColors.blue)),
                    title: Text(d['title'] ?? '',
                        style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
                    subtitle: Text(d['subtitle'] ?? '',
                        style: const TextStyle(fontFamily: 'Nunito')),
                  ),
                );
              },
            );
          },
        ),
      bottomNavigationBar: const GuardianBottomNav(currentIndex: -1),
    );
  }
}

// ── Comms screen ────────────────────────────────────────────────────────────
class _CommsScreen extends StatelessWidget {
  const _CommsScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Calls & Messages'),
          backgroundColor: AppColors.navy, automaticallyImplyLeading: false),
      body: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.message_outlined, size: 64, color: AppColors.textMuted),
        SizedBox(height: 16),
        Text('Communications Monitor', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w700)),
        SizedBox(height: 8),
        Text('Coming soon', style: TextStyle(color: AppColors.textMuted, fontFamily: 'Nunito')),
      ])),
      bottomNavigationBar: const GuardianBottomNav(currentIndex: 3),
    );
  }
}

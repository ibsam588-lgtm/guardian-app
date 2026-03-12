// lib/config/secrets.example.dart
//
// SETUP INSTRUCTIONS:
// 1. Copy this file to lib/config/secrets.dart
// 2. Fill in your real keys
// 3. secrets.dart is gitignored — never commit it
//
// Run:  cp lib/config/secrets.example.dart lib/config/secrets.dart

class Secrets {
  // ── RevenueCat ─────────────────────────────
  // Get from: https://app.revenuecat.com → API Keys
  static const revenueCatAndroidKey = 'YOUR_REVENUECAT_ANDROID_KEY';
  static const revenueCatIosKey     = 'YOUR_REVENUECAT_IOS_KEY';

  // ── Google Maps ────────────────────────────
  // Get from: https://console.cloud.google.com → Maps SDK for Android/iOS
  static const googleMapsAndroidKey = 'YOUR_GOOGLE_MAPS_ANDROID_KEY';
  static const googleMapsIosKey     = 'YOUR_GOOGLE_MAPS_IOS_KEY';

  // ── Firebase ───────────────────────────────
  // DO NOT put firebase keys here.
  // Instead, place these files directly in your project:
  //   Android → android/app/google-services.json
  //   iOS     → ios/Runner/GoogleService-Info.plist
  // Download from: https://console.firebase.google.com
}

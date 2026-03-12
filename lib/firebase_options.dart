// Generated from google-services.json for guardian-e28d4
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web. '
        'Reconfigure your app using the Firebase CLI.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS. '
          'Add GoogleService-Info.plist to enable iOS support.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCSgmed57xmEAJm2zKbyIGc5LvX_zYg6Hg',
    appId: '1:913378360413:android:efcc9c9a1e89e8a270e1b4',
    messagingSenderId: '913378360413',
    projectId: 'guardian-e28d4',
    storageBucket: 'guardian-e28d4.firebasestorage.app',
  );
}

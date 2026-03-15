import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not supported');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Platform not supported');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCSgmed57xmEAJm2zKbyIGc5LvX_zYg6Hg',
    appId: '1:913378360413:android:7569b8ffd5a8ff2570e1b4',
    messagingSenderId: '913378360413',
    projectId: 'guardian-e28d4',
    storageBucket: 'guardian-e28d4.firebasestorage.app',
  );
}

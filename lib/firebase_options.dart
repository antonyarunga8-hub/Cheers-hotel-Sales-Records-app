// Generated from Firebase Console — cheers-hotel-c5f47
// Web app: Cheers Hotel POS

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return web; // Windows uses same config as web for Firestore
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // ──── WEB ────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDDv8CwVxEKAkqaj5CmZkk2YglH64jd4qE',
    authDomain: 'cheers-hotel-c5f47.firebaseapp.com',
    projectId: 'cheers-hotel-c5f47',
    storageBucket: 'cheers-hotel-c5f47.firebasestorage.app',
    messagingSenderId: '379932426570',
    appId: '1:379932426570:web:0f668aa961c30815bb01b3',
    measurementId: 'G-QPV3VH3CKH',
  );

  // ──── ANDROID (same project, add Android app in console later) ────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDDv8CwVxEKAkqaj5CmZkk2YglH64jd4qE',
    appId: '1:379932426570:web:0f668aa961c30815bb01b3',
    messagingSenderId: '379932426570',
    projectId: 'cheers-hotel-c5f47',
    storageBucket: 'cheers-hotel-c5f47.firebasestorage.app',
  );

  // ──── iOS (same project, add iOS app in console later) ────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDDv8CwVxEKAkqaj5CmZkk2YglH64jd4qE',
    appId: '1:379932426570:web:0f668aa961c30815bb01b3',
    messagingSenderId: '379932426570',
    projectId: 'cheers-hotel-c5f47',
    storageBucket: 'cheers-hotel-c5f47.firebasestorage.app',
    iosBundleId: 'com.cheershotel.app',
  );
}

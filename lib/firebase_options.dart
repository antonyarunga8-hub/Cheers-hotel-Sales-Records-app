// Firebase project: cheers-hotel-bf5ce
// Auth: Anonymous enabled
// Firestore: Default database, test mode

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return web;
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDDyKRMo6KbbrZwPg6YpVC-qCLp0iV5LEc',
    authDomain: 'cheers-hotel-bf5ce.firebaseapp.com',
    projectId: 'cheers-hotel-bf5ce',
    storageBucket: 'cheers-hotel-bf5ce.firebasestorage.app',
    messagingSenderId: '574024389328',
    appId: '1:574024389328:web:b490d142f28881143204d5',
    measurementId: 'G-224H95L4EN',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDDyKRMo6KbbrZwPg6YpVC-qCLp0iV5LEc',
    appId: '1:574024389328:web:b490d142f28881143204d5',
    messagingSenderId: '574024389328',
    projectId: 'cheers-hotel-bf5ce',
    storageBucket: 'cheers-hotel-bf5ce.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDDyKRMo6KbbrZwPg6YpVC-qCLp0iV5LEc',
    appId: '1:574024389328:web:b490d142f28881143204d5',
    messagingSenderId: '574024389328',
    projectId: 'cheers-hotel-bf5ce',
    storageBucket: 'cheers-hotel-bf5ce.firebasestorage.app',
    iosBundleId: 'com.cheershotel.app',
  );
}

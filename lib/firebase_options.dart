// GENERATED PLACEHOLDER — DO NOT USE IN PRODUCTION.
//
// Replace this entire file by running, from the project root:
//   flutterfire configure --project=<your-firebase-project-id>
//
// That command generates a real firebase_options.dart wired to your actual
// Firebase project (Web/Android/iOS/Windows app configs). This placeholder
// only exists so the project compiles/lints before that step is run.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web is not configured for Cheers Hotel App V1. '
        'Run flutterfire configure to add a web target if needed.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform. '
          'Run flutterfire configure.',
        );
    }
  }

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    appId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    projectId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    storageBucket: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    appId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    projectId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    storageBucket: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    appId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    projectId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    storageBucket: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE_OUTPUT',
    iosBundleId: 'com.cheershotel.app',
  );
}

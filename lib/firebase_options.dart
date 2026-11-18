// File generated for M.I.R.N POWER Management System
// Project ID: mirn-power-system
// Statutory Tax ID: 515892104 (Jerusalem, IL)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static const String projectId = 'mirn-power-system';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web Firebase Options (Live Production)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCgIRRJ1JUrevIS8JDBzVHuF5XmSCAsZxU',
    appId: '1:567114559597:web:8908dad67f7f10be854f64',
    messagingSenderId: '567114559597',
    projectId: 'mirn-power-system',
    authDomain: 'mirn-power-system.firebaseapp.com',
    storageBucket: 'mirn-power-system.firebasestorage.app',
    measurementId: 'G-P7KZ1QQXK0',
  );

  // Android Firebase Options
  // Note: uses standard Google Services configuration for Android.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCgIRRJ1JUrevIS8JDBzVHuF5XmSCAsZxU',
    appId: '1:567114559597:android:8908dad67f7f10be854f64',
    messagingSenderId: '567114559597',
    projectId: 'mirn-power-system',
    storageBucket: 'mirn-power-system.firebasestorage.app',
  );

  // iOS Firebase Options
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCgIRRJ1JUrevIS8JDBzVHuF5XmSCAsZxU',
    appId: '1:567114559597:ios:8908dad67f7f10be854f64',
    messagingSenderId: '567114559597',
    projectId: 'mirn-power-system',
    storageBucket: 'mirn-power-system.firebasestorage.app',
    iosBundleId: 'com.mirn.powersystem',
  );

  // Windows / Desktop Firebase Options
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCgIRRJ1JUrevIS8JDBzVHuF5XmSCAsZxU',
    appId: '1:567114559597:web:8908dad67f7f10be854f64',
    messagingSenderId: '567114559597',
    projectId: 'mirn-power-system',
    authDomain: 'mirn-power-system.firebaseapp.com',
    storageBucket: 'mirn-power-system.firebasestorage.app',
    measurementId: 'G-P7KZ1QQXK0',
  );
}

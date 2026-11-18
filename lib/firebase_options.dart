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
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Web Firebase Options
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSy_YOUR_WEB_API_KEY_HERE',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: projectId,
    authDomain: '$projectId.firebaseapp.com',
    storageBucket: '$projectId.firebasestorage.app',
  );

  // Android Firebase Options
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSy_YOUR_ANDROID_API_KEY_HERE',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: projectId,
    storageBucket: '$projectId.firebasestorage.app',
  );

  // Windows / Desktop Firebase Options
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSy_YOUR_WINDOWS_API_KEY_HERE',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: projectId,
    authDomain: '$projectId.firebaseapp.com',
    storageBucket: '$projectId.firebasestorage.app',
  );
}

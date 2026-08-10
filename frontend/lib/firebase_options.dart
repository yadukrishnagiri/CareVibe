import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD_7_XfcMHV08jYLvogOVJ1eF6NC8vlV34',
    appId: '1:1066923811249:web:077151167859c04d131d90',
    messagingSenderId: '1066923811249',
    projectId: 'vibecare-f9225',
    authDomain: 'vibecare-f9225.firebaseapp.com',
    storageBucket: 'vibecare-f9225.firebasestorage.app',
    measurementId: 'G-HEK3KMVGV5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC23c_2ti6UcxtezPhFrdhFpvdXUNK1LOY',
    appId: '1:1066923811249:android:f9359730f78a9a4c131d90',
    messagingSenderId: '1066923811249',
    projectId: 'vibecare-f9225',
    storageBucket: 'vibecare-f9225.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC23c_2ti6UcxtezPhFrdhFpvdXUNK1LOY',
    appId: '1:1066923811249:android:f9359730f78a9a4c131d90',
    messagingSenderId: '1066923811249',
    projectId: 'vibecare-f9225',
    storageBucket: 'vibecare-f9225.firebasestorage.app',
    iosBundleId: 'com.carevibe.patient',
  );
}

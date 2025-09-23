// Configuración temporal de Firebase para testing
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Configuración temporal de Firebase para testing
class TempFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return web; // Fallback a web
    }
  }

  // Configuración temporal para web - usando configuración de prueba
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCGE9TrLvHAIwuXn0o6jqFSw5RhS0HDtg8',
    appId: '1:804273724178:web:c5955a1f657884c0e7f1cb',
    messagingSenderId: '804273724178',
    projectId: 'apptaxi-f2190',
    authDomain: 'apptaxi-f2190.firebaseapp.com',
    storageBucket: 'apptaxi-f2190.firebasestorage.app',
    measurementId: 'G-3D8R30TYTM',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCGE9TrLvHAIwuXn0o6jqFSw5RhS0HDtg8',
    appId: '1:804273724178:android:c5955a1f657884c0e7f1cb',
    messagingSenderId: '804273724178',
    projectId: 'apptaxi-f2190',
    storageBucket: 'apptaxi-f2190.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCGE9TrLvHAIwuXn0o6jqFSw5RhS0HDtg8',
    appId: '1:804273724178:ios:c5955a1f657884c0e7f1cb',
    messagingSenderId: '804273724178',
    projectId: 'apptaxi-f2190',
    storageBucket: 'apptaxi-f2190.firebasestorage.app',
    iosBundleId: 'com.example.calendarioFamiliar',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCGE9TrLvHAIwuXn0o6jqFSw5RhS0HDtg8',
    appId: '1:804273724178:ios:c5955a1f657884c0e7f1cb',
    messagingSenderId: '804273724178',
    projectId: 'apptaxi-f2190',
    storageBucket: 'apptaxi-f2190.firebasestorage.app',
    iosBundleId: 'com.example.calendarioFamiliar',
  );
}

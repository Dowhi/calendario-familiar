// CONFIGURACIÓN FIREBASE REAL - Proyecto: apptaxi-f2190
// Claves extraídas de la consola de Firebase

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // CONFIGURACIÓN REAL DEL PROYECTO APPTAXI-F2190
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD_dHKJyrAOPt3xpBsCU7W_lj8G9qKKAwE',
    appId: '1:804273724178:web:1cb45dc889866ee2e7f1cb',
    messagingSenderId: '804273724178',
    projectId: 'apptaxi-f2190',
    authDomain: 'apptaxi-f2190.firebaseapp.com',
    storageBucket: 'apptaxi-f2190.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD_dHKJyrAOPt3xpBsCU7W_lj8G9qKKAwE',
    appId: '1:804273724178:android:7e8c68a174ca93bce7f1cb',
    messagingSenderId: '804273724178',
    projectId: 'apptaxi-f2190',
    storageBucket: 'apptaxi-f2190.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD_dHKJyrAOPt3xpBsCU7W_lj8G9qKKAwE',
    appId: '1:804273724178:ios:1cb45dc889866ee2e7f1cb',
    messagingSenderId: '804273724178',
    projectId: 'apptaxi-f2190',
    storageBucket: 'apptaxi-f2190.appspot.com',
    iosClientId: 'TU_IOS_CLIENT_ID_AQUI', // Opcional para iOS
    iosBundleId: 'com.juancarlos.calendariofamiliar',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD_dHKJyrAOPt3xpBsCU7W_lj8G9qKKAwE',
    appId: '1:804273724178:ios:1cb45dc889866ee2e7f1cb',
    messagingSenderId: '804273724178',
    projectId: 'apptaxi-f2190',
    storageBucket: 'apptaxi-f2190.appspot.com',
    iosClientId: 'TU_IOS_CLIENT_ID_AQUI', // Opcional para macOS
    iosBundleId: 'com.juancarlos.calendariofamiliar',
  );
}




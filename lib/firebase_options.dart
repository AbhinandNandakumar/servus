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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB0_r7RfUQW9Dnt8sUsOqjv7_NBVow_Yx4',
    appId: '1:183908441320:web:67013c4820c1628fe5bd5d',
    messagingSenderId: '183908441320',
    projectId: 'servus-43e5f',
    authDomain: 'servus-43e5f.firebaseapp.com',
    storageBucket: 'servus-43e5f.firebasestorage.app',
    measurementId: 'G-CZ1R9HHRW3',
  );

  // Placeholder for Android - will need to add google-services.json later
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB0_r7RfUQW9Dnt8sUsOqjv7_NBVow_Yx4',
    appId: '1:183908441320:web:67013c4820c1628fe5bd5d',
    messagingSenderId: '183908441320',
    projectId: 'servus-43e5f',
    storageBucket: 'servus-43e5f.firebasestorage.app',
  );

  // Placeholder for iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB0_r7RfUQW9Dnt8sUsOqjv7_NBVow_Yx4',
    appId: '1:183908441320:web:67013c4820c1628fe5bd5d',
    messagingSenderId: '183908441320',
    projectId: 'servus-43e5f',
    storageBucket: 'servus-43e5f.firebasestorage.app',
  );

  // Placeholder for macOS
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB0_r7RfUQW9Dnt8sUsOqjv7_NBVow_Yx4',
    appId: '1:183908441320:web:67013c4820c1628fe5bd5d',
    messagingSenderId: '183908441320',
    projectId: 'servus-43e5f',
    storageBucket: 'servus-43e5f.firebasestorage.app',
  );

  // Placeholder for Windows
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB0_r7RfUQW9Dnt8sUsOqjv7_NBVow_Yx4',
    appId: '1:183908441320:web:67013c4820c1628fe5bd5d',
    messagingSenderId: '183908441320',
    projectId: 'servus-43e5f',
    storageBucket: 'servus-43e5f.firebasestorage.app',
  );
}

// File generated for Firebase configuration.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
    apiKey: 'AIzaSyAj5So1ivlz6ktB5rq83buHa5pYJ6LbUn0',
    appId: '1:228852164791:web:fe7168250ff884e8514532',
    messagingSenderId: '228852164791',
    projectId: 'quickparcel-f0b4e',
    authDomain: 'quickparcel-f0b4e.firebaseapp.com',
    storageBucket: 'quickparcel-f0b4e.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAj5So1ivlz6ktB5rq83buHa5pYJ6LbUn0',
    appId: '1:228852164791:android:fe7168250ff884e8514532',
    messagingSenderId: '228852164791',
    projectId: 'quickparcel-f0b4e',
    storageBucket: 'quickparcel-f0b4e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAj5So1ivlz6ktB5rq83buHa5pYJ6LbUn0',
    appId: '1:228852164791:ios:fe7168250ff884e8514532',
    messagingSenderId: '228852164791',
    projectId: 'quickparcel-f0b4e',
    storageBucket: 'quickparcel-f0b4e.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAj5So1ivlz6ktB5rq83buHa5pYJ6LbUn0',
    appId: '1:228852164791:ios:fe7168250ff884e8514532',
    messagingSenderId: '228852164791',
    projectId: 'quickparcel-f0b4e',
    storageBucket: 'quickparcel-f0b4e.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAj5So1ivlz6ktB5rq83buHa5pYJ6LbUn0',
    appId: '1:228852164791:web:fe7168250ff884e8514532',
    messagingSenderId: '228852164791',
    projectId: 'quickparcel-f0b4e',
    authDomain: 'quickparcel-f0b4e.firebaseapp.com',
    storageBucket: 'quickparcel-f0b4e.firebasestorage.app',
  );
}

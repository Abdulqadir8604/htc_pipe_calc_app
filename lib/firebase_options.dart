import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
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
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDCq8cqjiY84WLyTm2708Dm2Yr9Z0Y4w1Y',
    appId: '1:955653181762:android:e7ba040cd78ce8bf4ff8db',
    messagingSenderId: '955653181762',
    projectId: 'htc-powerapp',
    storageBucket: 'htc-powerapp.appspot.com',
    databaseURL: 'https://htc-powerapp-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBtsRdLyHRR0w_nHNYxW7jwrNjgtJhxT4M',
    appId: '1:955653181762:ios:bebdbde35e398c0c4ff8db',
    messagingSenderId: '955653181762',
    projectId: 'htc-powerapp',
    storageBucket: 'htc-powerapp.appspot.com',
    databaseURL: 'https://htc-powerapp-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDCq8cqjiY84WLyTm2708Dm2Yr9Z0Y4w1Y',
    appId: '1:955653181762:web:0d8e53773e47439d4ff8db',
    messagingSenderId: '955653181762',
    projectId: 'htc-powerapp',
    storageBucket: 'htc-powerapp.appspot.com',
    databaseURL: 'https://htc-powerapp-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBtsRdLyHRR0w_nHNYxW7jwrNjgtJhxT4M',
    appId: '1:955653181762:ios:bebdbde35e398c0c4ff8db',
    messagingSenderId: '955653181762',
    projectId: 'htc-powerapp',
    storageBucket: 'htc-powerapp.appspot.com',
    databaseURL: 'https://htc-powerapp-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDCq8cqjiY84WLyTm2708Dm2Yr9Z0Y4w1Y',
    appId: '1:955653181762:web:0d8e53773e47439d4ff8db',
    messagingSenderId: '955653181762',
    projectId: 'htc-powerapp',
    storageBucket: 'htc-powerapp.appspot.com',
    databaseURL: 'https://htc-powerapp-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyDCq8cqjiY84WLyTm2708Dm2Yr9Z0Y4w1Y',
    appId: '1:955653181762:web:0d8e53773e47439d4ff8db',
    messagingSenderId: '955653181762',
    projectId: 'htc-powerapp',
    storageBucket: 'htc-powerapp.appspot.com',
    databaseURL: 'https://htc-powerapp-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
}
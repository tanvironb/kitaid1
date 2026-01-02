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
    apiKey: 'AIzaSyD39vWAMWX3EtLzHJhOyHZMZjAo-_42T3A',
    appId: '1:1000588119240:web:c289c938b3b730113c29fd',
    messagingSenderId: '1000588119240',
    projectId: 'kitaid-777d4',
    authDomain: 'kitaid-777d4.firebaseapp.com',
    storageBucket: 'kitaid-777d4.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBnX5jdDGJXobv3bswLWKAGMOGcEmVQL-s',
    appId: '1:1000588119240:android:2b23700efa146bda3c29fd',
    messagingSenderId: '1000588119240',
    projectId: 'kitaid-777d4',
    storageBucket: 'kitaid-777d4.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCUk10EIgfUOt4mnfhwPVlkipLd3-pqTUI',
    appId: '1:1000588119240:ios:e4393d4cc9fe5be03c29fd',
    messagingSenderId: '1000588119240',
    projectId: 'kitaid-777d4',
    storageBucket: 'kitaid-777d4.firebasestorage.app',
    iosBundleId: 'com.example.kitaid1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCUk10EIgfUOt4mnfhwPVlkipLd3-pqTUI',
    appId: '1:1000588119240:ios:e4393d4cc9fe5be03c29fd',
    messagingSenderId: '1000588119240',
    projectId: 'kitaid-777d4',
    storageBucket: 'kitaid-777d4.firebasestorage.app',
    iosBundleId: 'com.example.kitaid1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD39vWAMWX3EtLzHJhOyHZMZjAo-_42T3A',
    appId: '1:1000588119240:web:f2107fa855c73c1e3c29fd',
    messagingSenderId: '1000588119240',
    projectId: 'kitaid-777d4',
    authDomain: 'kitaid-777d4.firebaseapp.com',
    storageBucket: 'kitaid-777d4.firebasestorage.app',
  );
}

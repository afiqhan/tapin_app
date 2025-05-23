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
    apiKey: 'AIzaSyChNjBJcN5Ig5pXKpitXOUJxzVIn7gXAVA',
    appId: '1:733701309308:web:1b7896c9c090959e221af9',
    messagingSenderId: '733701309308',
    projectId: 'tapin-e798d',
    authDomain: 'tapin-e798d.firebaseapp.com',
    databaseURL: 'https://tapin-e798d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'tapin-e798d.firebasestorage.app',
    measurementId: 'G-RS752LCP07',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBFqrSw9EgAxdJWwRR_Vz8aZa4VMzAxqZw',
    appId: '1:733701309308:android:e88cb6433317d37f221af9',
    messagingSenderId: '733701309308',
    projectId: 'tapin-e798d',
    databaseURL: 'https://tapin-e798d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'tapin-e798d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAH0_BGN4qkuHb3xsVrEmnrypVyTv6AE2g',
    appId: '1:733701309308:ios:0e7956ccd015ecc1221af9',
    messagingSenderId: '733701309308',
    projectId: 'tapin-e798d',
    databaseURL: 'https://tapin-e798d-default-rtdb.asia-southeast1.fire asedatabase.app',
    storageBucket: 'tapin-e798d.firebasestorage.app',
    iosBundleId: 'com.example.tapinApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAH0_BGN4qkuHb3xsVrEmnrypVyTv6AE2g',
    appId: '1:733701309308:ios:0e7956ccd015ecc1221af9',
    messagingSenderId: '733701309308',
    projectId: 'tapin-e798d',
    databaseURL: 'https://tapin-e798d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'tapin-e798d.firebasestorage.app',
    iosBundleId: 'com.example.tapinApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyChNjBJcN5Ig5pXKpitXOUJxzVIn7gXAVA',
    appId: '1:733701309308:web:dfd1584868d5d921221af9',
    messagingSenderId: '733701309308',
    projectId: 'tapin-e798d',
    authDomain: 'tapin-e798d.firebaseapp.com',
    databaseURL: 'https://tapin-e798d-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'tapin-e798d.firebasestorage.app',
    measurementId: 'G-RQZRKD21L2',
  );
}
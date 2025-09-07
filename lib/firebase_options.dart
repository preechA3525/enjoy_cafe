// File: lib/firebase_options.dart
// GENERATED FILE - DO NOT EDIT DIRECTLY

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
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDq6o9T4GRSyomTMRqLmKw4ohZkHcqgfIY",
    appId: "1:560481219554:web:f63d9164f929a64fdebfbb",
    messagingSenderId: "560481219554",
    projectId: "point-system-dc140",
    authDomain: "point-system-dc140.firebaseapp.com",
    storageBucket: "point-system-dc140.appspot.com",
    databaseURL: "https://point-system-dc140-default-rtdb.firebaseio.com",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyDq6o9T4GRSyomTMRqLmKw4ohZkHcqgfIY",
    appId: "1:560481219554:android:f63d9164f929a64fdebfbb",
    messagingSenderId: "560481219554",
    projectId: "point-system-dc140",
    storageBucket: "point-system-dc140.appspot.com",
    databaseURL: "https://point-system-dc140-default-rtdb.firebaseio.com",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyDq6o9T4GRSyomTMRqLmKw4ohZkHcqgfIY",
    appId: "1:560481219554:ios:f63d9164f929a64fdebfbb",
    messagingSenderId: "560481219554",
    projectId: "point-system-dc140",
    storageBucket: "point-system-dc140.appspot.com",
    iosClientId:
        "560481219554-xxxxxxx.apps.googleusercontent.com", // ถ้ามีให้ใส่
    iosBundleId: "com.example.enjoy_cafe", // แก้ให้ตรง bundle id ของโปรเจกต์คุณ
    databaseURL: "https://point-system-dc140-default-rtdb.firebaseio.com",
  );
}

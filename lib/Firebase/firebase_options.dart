
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCHR0HkhaQF3PTpX0RnDArixaOb9cEILdA',
    appId: '1:884473393144:web:358cf07515c42b544f700d',
    messagingSenderId: '884473393144',
    projectId: 'miniorderbook',
    authDomain: 'miniorderbook.firebaseapp.com',
    storageBucket: 'miniorderbook.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBVzmBRqf2SDYqBnDPt1FLO_xIG-mY2fDo',
    appId: '1:884473393144:android:541e52582d01c4004f700d',
    messagingSenderId: '884473393144',
    projectId: 'miniorderbook',
    storageBucket: 'miniorderbook.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBXrkSqXdoLWOwmio4mMhelzB-icvRm1_o',
    appId: '1:884473393144:ios:3ad1b744674643824f700d',
    messagingSenderId: '884473393144',
    projectId: 'miniorderbook',
    storageBucket: 'miniorderbook.appspot.com',
    iosClientId: '884473393144-vlif9ageb43rjeff2tvqlbs0lquo88mr.apps.googleusercontent.com',
    iosBundleId: 'com.shebaschool.minipos.minipos',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBXrkSqXdoLWOwmio4mMhelzB-icvRm1_o',
    appId: '1:884473393144:ios:3ad1b744674643824f700d',
    messagingSenderId: '884473393144',
    projectId: 'miniorderbook',
    storageBucket: 'miniorderbook.appspot.com',
    iosClientId: '884473393144-vlif9ageb43rjeff2tvqlbs0lquo88mr.apps.googleusercontent.com',
    iosBundleId: 'com.shebaschool.minipos.minipos',
  );
}


import 'package:deviceguardianadmin/providers/customer_provider.dart';
import 'package:deviceguardianadmin/providers/home_provider.dart';
import 'package:deviceguardianadmin/providers/login_provider.dart';
import 'package:deviceguardianadmin/providers/profile_provider.dart';
import 'package:deviceguardianadmin/providers/purchase_history_provider.dart';
import 'package:deviceguardianadmin/providers/registration_provider.dart';
import 'package:deviceguardianadmin/screens/splash_screen.dart';
import 'package:deviceguardianadmin/theme/light_theme.dart';
import 'package:deviceguardianadmin/util/notification_services.dart';
import 'package:deviceguardianadmin/util/session_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message)async {
  await Firebase.initializeApp();
}

NotificationServices notificationServices = NotificationServices();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  //
  // print("notification section start");
  // // Request notification permissions
  // notificationServices.requestNotificationPermission();
  // notificationServices.forgroundMessage();
  //
  // // Get device token asynchronously without blocking app start
  // notificationServices.getDeviceToken().then((token) {
  //   print("fcm token: $token");
  // }).catchError((error) {
  //   print("Error getting FCM token: $error");
  // });
  //
  // //new firebase setup
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => CustomerProvider(),),
        ChangeNotifierProvider(create: (ctx) => LoginProvider(),),
        ChangeNotifierProvider(create: (ctx) => ProfileProvider(),),
        ChangeNotifierProvider(create: (ctx) => HomeProvider(),),
        ChangeNotifierProvider(create: (ctx) => RegistrationProvider(),),
        ChangeNotifierProvider(create: (ctx) => PurchaseHistoryProvider(),),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Device Guardian Admin',
        theme: light,
        home: SplashScreen(),
      ),
    );
  }
}

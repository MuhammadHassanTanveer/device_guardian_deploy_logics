import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';


class NotificationServices {

  //initialising firebase message plugin
  FirebaseMessaging messaging = FirebaseMessaging.instance ;

  //initialising firebase message plugin
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin  = FlutterLocalNotificationsPlugin();



  //function to initialise flutter local notification plugin to show notifications for android when app is active
  void initLocalNotifications(BuildContext context, RemoteMessage message)async{
    var androidInitializationSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var iosInitializationSettings = const DarwinInitializationSettings();

    var initializationSetting = InitializationSettings(
        android: androidInitializationSettings ,
        iOS: iosInitializationSettings
    );

    await _flutterLocalNotificationsPlugin.initialize(
        initializationSetting,
      onDidReceiveNotificationResponse: (payload){
          // handle interaction when app is active for android
          handleMessage(context, message);
      }
    );
  }


  // Update firebaseInit to use the new method
  // void firebaseInit(BuildContext context) {
  //   FirebaseMessaging.onMessage.listen((message) async {
  //     RemoteNotification? notification = message.notification;
  //     AndroidNotification? android = message.notification?.android;
  //
  //     if (notification != null && android != null) {
  //       if (kDebugMode) {
  //         print("Foreground Notification Received:");
  //         print("Title: ${notification.title}");
  //         print("Body: ${notification.body}");
  //         print("Data: ${message.data}");
  //       }
  //
  //       if (Platform.isIOS) {
  //         forgroundMessage();
  //       }
  //
  //       // Use the new method that checks lock status
  //     }
  //   });
  // }

  void firebaseInit(BuildContext context) {
    FirebaseMessaging.onMessage.listen((message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        if (kDebugMode) {
          print("Foreground Notification Received:");
          print("Title: ${notification.title}");
          print("Body: ${notification.body}");
          print("Data: ${message.data}");
        }

        if(Platform.isIOS){
          forgroundMessage();
        }
        // Show the notification manually using local notifications
        initLocalNotifications(context, message);
        showNotification(message);
        // _incrementBadgeCount();
      }
    });
  }

  void requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: true,
        criticalAlert: true,
        sound: true ,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('user granted permission');
      }
    }
    else {

      //appsetting.AppSettings.openNotificationSettings();
      if (kDebugMode) {
        print('user denied permission');
      }
    }
  }

  // function to show visible notification when app is active
  Future<void> showNotification(RemoteMessage message)async{

    AndroidNotificationChannel channel = AndroidNotificationChannel(
      message.notification!.android!.channelId.toString(),
      message.notification!.android!.channelId.toString() ,
      importance: Importance.max  ,
      showBadge: true ,
      playSound: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel); // Register the channel

     AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      channel.id.toString(),
      channel.name.toString() ,
      channelDescription: 'your channel description',
      importance: Importance.high,
      priority: Priority.high ,
      playSound: true,
      ticker: 'ticker' ,
         sound: channel.sound
    );

    const DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails(
      presentAlert: true ,
      presentBadge: true ,
      presentSound: true,
      presentBanner: true,
      presentList: true
    ) ;

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails
    );

    Future.delayed(Duration.zero , (){
      _flutterLocalNotificationsPlugin.show(
          0,
          message.notification!.title.toString(),
          message.notification!.body.toString(),
          notificationDetails ,
      );
    });

  }

  //function to get device token on which we will send the notifications
  Future<String> getDeviceToken() async {
    String? token = await messaging.getToken();
    debugPrint("fcmToken $token");
    return token!;
  }

  void isTokenRefresh()async{
    messaging.onTokenRefresh.listen((event) {
      event.toString();
      if (kDebugMode) {
        print('refresh');
      }
    });
  }

  //handle tap on notification when app is in background or terminated
  Future<void> setupInteractMessage(BuildContext context)async{

    // when app is terminated
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if(initialMessage != null){
      handleMessage(context, initialMessage);
    }


    //when app ins background
    FirebaseMessaging.onMessageOpenedApp.listen((event) {
      handleMessage(context, event);
    });

  }

  void handleMessage(BuildContext context, RemoteMessage message) {

    print("handlle meassage ${message.data['type']}");
    print("handlle meassage ${message.data['id']}");

    // if (message.data['type'] =='Order'){
    //   Navigator.of(context).push(MaterialPageRoute(builder: (context) => ReservationDetailsScreen(
    //     reservationId: message.data['id']!,
    //   ),));
    // } else if(message.data['type'] =='Admin'){
    //   Navigator.push(context,
    //       MaterialPageRoute(builder: (context) => const NotificationScreen() ),);
    // }else if(message.data['type'] =='Product Detail'){
    //   Navigator.push(context,
    //     MaterialPageRoute(builder: (context) => ProductDetailScreen(productId: message.data['id'], isSoldProduct: 'no',),),);
    // }
  }


  Future forgroundMessage() async {
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }


}
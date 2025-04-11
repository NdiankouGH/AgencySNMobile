import 'package:agencysn/core/config/app_routes.dart';
import 'package:agencysn/core/config/theme.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Demander la permission pour recevoir des notifications
  NotificationSettings settings = await messaging.requestPermission();
  print("User granted permission: ${settings.authorizationStatus}");

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Message data: ${message.data}');
    // Si l'application est au premier plan, affichez une notification personnalisée
    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
   return MaterialApp(
     title: 'AgencySN',
     theme: appTheme,
     initialRoute: AppRoutes.home,
     onGenerateRoute: AppRoutes.generateRoute,
   );
  }
}
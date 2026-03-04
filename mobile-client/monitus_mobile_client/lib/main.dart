import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/registration_provider.dart';
import 'screens/registration_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:monitus_mobile_client/services/database_helper.dart';

// Background Service for Location Update Cycle using Workmanager
import 'package:workmanager/workmanager.dart';
import 'services/background_service.dart'; 

// Background mesage handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is ready for the background process
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

// Define Foreground Notification
Future<void> _showForegroundNotification(RemoteMessage message) async {
  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'high_importance_channel', // Match the ID you defined in main.dart
    'Emergency Alerts',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  await notificationsPlugin.show(
    id: message.hashCode,          
    title: message.notification?.title, 
    body: message.notification?.body,  
    notificationDetails: const NotificationDetails(android: androidDetails), // Labelled 'notificationDetails'
    payload: 'alert_data',  
  );
}

void main() async{
  // Ensure the initialisation of Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase
  try{
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Request Permissions
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // Print FCM Token
    String? token = await FirebaseMessaging.instance.getToken(); 
    debugPrint("FCM Token: $token");

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground Listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint("--- SOMETHING ARRIVED ---");

      debugPrint('Foreground message received: ${message.notification?.title}');

      if (message.notification != null) {
        _showForegroundNotification(message);

       await DatabaseHelper.instance.insertAlert({
          'title': message.notification?.title ?? 'No Title',
          'body': message.notification?.body ?? 'No Body',
          'alert_type': message.data['alert_type'] ?? 'general', // Extracting the extra data that sent from Laravel
          'received_at': DateTime.now().toString(),
      });
        debugPrint('Alert stored to Local database.');

        // ADD TEST CALL FOR MOBILE DATA PERSISTANCE TESTING (WILL REMOVE IT LATER)
        await DatabaseHelper.instance.testDatabase();
      }

      
    });         
  } catch (e){
    debugPrint("Firebase initialisation failed! $e");
  }


  Workmanager().initialize(callbackDispatcher);

  // Schedule a 10-minute location update cycle
  Workmanager().registerPeriodicTask(
    "monitus_location_sync", 
    "locationUpdateTask",
    frequency: Duration(minutes: 15), // Android min frequency is 15 mins
    initialDelay: Duration(seconds: 10), 
    constraints: Constraints(
      networkType: NetworkType.connected, // Saves battery by not trying without internet
    )
  );

  // Define High-Importance Channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'Emergency Alerts',
    description: 'This channel is used for critical emergency notifications.',
    importance: Importance.max,
    playSound: true
  );

  // Create the channel on the device
  final FlutterLocalNotificationsPlugin flutterLocalNotificationPlugin =
    FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
  

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegistrationProvider()),
      ],
      child: const MonitusApp(),
    ),
  );
}

class MonitusApp extends StatelessWidget {
  const MonitusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitus',
      home: RegistrationScreen(),
    );
  }
}


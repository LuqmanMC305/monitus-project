import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/registration_provider.dart';
import 'screens/registration_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Background Service for Location Update Cycle using Workmanager
import 'package:workmanager/workmanager.dart';
import 'services/background_service.dart'; 


void main() async{
  // Ensure the initialisation of Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher);

  // Schedule a 10-minute location update cycle
  Workmanager().registerOneOffTask(
    "immediate_verify", 
    "locationUpdateTask",
    initialDelay: Duration(seconds: 5), // Android min frequency is 15 mins
  );

  // Initialise Firebase
  try{
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
  } catch (e){
    debugPrint("Firebase initialisation failed! $e");
  }

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
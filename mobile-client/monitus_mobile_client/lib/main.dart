import 'package:flutter/material.dart';
import 'package:monitus_mobile_client/screens/main_wrapper_screen.dart';
import 'package:provider/provider.dart';
import 'providers/registration_provider.dart';
import 'providers/community_provider.dart';
import 'screens/registration_screen.dart';
import 'services/translation_service.dart';
import 'services/alert_notifier.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:monitus_mobile_client/services/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'dart:ui';

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

  ApiConfig.current = Environment.local;

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
      debugPrint("FULL MESSAGE DATA: ${message.data}");
      debugPrint("--- SOMETHING ARRIVED ---");

      // New Alerts
      if (message.data['status'] == 'NEW_ALERT') {
        debugPrint("Incoming Live Notification Payload: ${message.data}");

          if (message.notification != null) {
            _showForegroundNotification(message);

            String originalBody = message.notification?.body ?? 'No Body';
            String targetLang = PlatformDispatcher.instance.locale.languageCode; // Get phone language
            String translatedText = originalBody; // Default to original

            // Trigger Translation only if not English
            if(targetLang != 'en'){
              debugPrint("Translating to $targetLang...");
              translatedText = await TranslationService().translateAlert(originalBody);
            }

            await DatabaseHelper.instance.insertAlert({
                'title': message.notification?.title ?? 'No Title',
                'body': message.notification?.body ?? 'No Body',
                'translated_body': translatedText, 
                'language_code': targetLang,
                'alert_type': message.data['alert_type'] ?? 'general', // Extracting the extra data that sent from Laravel

                // --- New Geospatial Handshake ---
                'latitude': double.tryParse(message.data['latitude']?.toString() ?? '') ?? 0.0,
                'longitude': double.tryParse(message.data['longitude']?.toString() ?? '') ?? 0.0,
                'radius': double.tryParse(message.data['radius']?.toString() ?? '') ?? 500.00, //Default radius size of 500m
                // --------------------------------

                'received_at': DateTime.now().toIso8601String(),
                'status': 'active',
            });
            debugPrint('Alert (Translated) stored to Local database.');

            // ADD TEST CALL FOR MOBILE DATA PERSISTANCE TESTING (WILL REMOVE IT LATER)
            await DatabaseHelper.instance.testDatabase();

            // CRITICAL: Wake up both your Map and History views without manual pull downs!
            AlertNotifier.notifyRefresh();
          }
      }

      // Resolve Alert
     if (message.data['type'] == 'RESOLVE_ALERT') {
      String? rawTitle = message.data['alert_title'];
      String? alertTitle = rawTitle?.trim(); 
      
      if (alertTitle != null && alertTitle.isNotEmpty) {
        final db = await DatabaseHelper.instance.database;
        
        List<Map<String, dynamic>> matchingAlerts = await db.query(
          'alerts',
          where: 'title LIKE ? AND (status != ? OR status IS NULL)',
          whereArgs: [alertTitle, 'resolved'],
        );

        // ======== 🔍 EXPLICIT LIST DIAGNOSTICS ========
        debugPrint("Checking SQLite results for title: '$alertTitle'");
        debugPrint("Matching Alerts List Length: ${matchingAlerts.length}");
        debugPrint("Raw Matching Alerts List Content: $matchingAlerts");
        // =============================================

        if (matchingAlerts.isNotEmpty) {
          int localId = matchingAlerts.first['id']; 
          await DatabaseHelper.instance.updateAlertStatusById(localId, 'resolved');
          debugPrint("Handshake Success: Corrected Local ID '$localId' marked as resolved.");
          AlertNotifier.notifyRefresh(); 
        } else {
          debugPrint("Handshake Warning: Bypassed code because matchingAlerts is EMPTY.");
        }
      }
      return; 
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

  // Check for saved mobile user identity
  final prefs = await SharedPreferences.getInstance();
  final String? savedUserId = prefs.getString('saved_user_id');
  final int? lastActivity = prefs.getInt('last_activity');

  bool sessionValid = false;

  debugPrint("Checking Mobile User Identity: ${savedUserId ?? 'No User Found'}");

  if (savedUserId != null && savedUserId != "0" && lastActivity != null) {
    // Timeout definition (e.g., 30 days in milliseconds)
    const int thirtyDays = 30 * 24 * 60 * 60 * 1000;
    int currentTime = DateTime.now().millisecondsSinceEpoch;

    if ((currentTime - lastActivity) < thirtyDays) {
      sessionValid = true;
      // Refresh timestamp so they get another 30 days from today
      await prefs.setInt('last_activity', currentTime);
    } else {
      // Session expired: Clear the data
      await prefs.remove('saved_user_id');
      await prefs.remove('last_activity');
    }
  } else if (savedUserId == "0") await prefs.remove('saved_user_id'); // wipe "0"

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegistrationProvider()),
        
        // Ensures that the "Pending" or "Approved" states are consistent across the app
        ChangeNotifierProvider(create: (_) => CommunityProvider()), 
      ],
      child: MonitusApp(isLoggedIn: sessionValid),
    ),
  );
}

class MonitusApp extends StatelessWidget {
  final bool isLoggedIn;
  const MonitusApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monitus',
      debugShowCheckedModeBanner: false,
      // LOGIC: If ID exists, go to MainWrapper; else, Register
      home: isLoggedIn ? const MainWrapper() : const RegistrationScreen(),
    );
  }
}


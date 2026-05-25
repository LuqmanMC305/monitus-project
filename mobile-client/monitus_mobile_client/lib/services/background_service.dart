import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:monitus_mobile_client/config/storage_keys.dart';
import 'package:workmanager/workmanager.dart';
import 'registration_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    debugPrint("CALLBACK DISPATCHER INITIALISED");
    // This 'taskName' will be "locationUpdateTask"
    if (taskName == "locationUpdateTask") {
      try {
        // Initialise Storage and Force a reload from disk
        final prefs = await SharedPreferences.getInstance();
        await prefs.reload(); // Ensures background isolate sees the newest login
        
        final String? savedUserId = prefs.getString(StorageKeys.appUserId);

        debugPrint("BACKGROUND TASK STARTED");
        debugPrint("BACKGROUND USER ID: $savedUserId");

        // 2. GUARD CLAUSE: Stop if no user or "0" is found
        if (savedUserId == null || savedUserId == "0" || savedUserId.isEmpty) {
          debugPrint("Monitus Background: Sync blocked - No valid User ID found.");
          return Future.value(true); // Complete task without hitting Laravel
        }

        // Initialise Firebase for background isolate
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        final service = RegistrationService();
        // Periodically reports coordinates to backend
        await service.registerUser(null, null); 

        // Define the plugin instance and name it 'notifications'
        final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

        // Trigger a local notification for verification
        const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'high_importance_channel', // Match the ID in main.dart
          'Emergency Alerts',
          importance: Importance.low, // Low Importance = doesn't make noise every 15 mins
          priority: Priority.low,
          icon: '@mipmap/ic_launcher',
          );

        const NotificationDetails notificationDetails = NotificationDetails(
          android: androidDetails,
        );
        await notifications.show(
          id: 0,
          title:'Monitus Sync',
          body:'Location updated successfully in background.',
          notificationDetails: notificationDetails,
          payload: 'sync_data',
        );
        
        return Future.value(true); // Task succeeded
      } catch (err) {
        // Log the error for debugging 
        debugPrint("Background Sync Failed: $err"); 
        
        return Future.value(false); // Task failed, OS will retry
      }
    }
    return Future.value(true);
  });
}
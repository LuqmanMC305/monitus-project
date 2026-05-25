import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/storage_keys.dart';
import '../providers/community_provider.dart';
import 'database_helper.dart';
import 'translation_service.dart';
import 'alert_notifier.dart';

// Declare Navigator Key for firebase listening admin community approval
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Background mesage handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is ready for the background process
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");

  // 🟢 CHANGED: Use the uniform string key name inside background isolates
  final prefs = await SharedPreferences.getInstance();
  final String? appUserId = prefs.getString(StorageKeys.appUserId);
  
  if (appUserId == null || appUserId.isEmpty || appUserId == 'null') {
    debugPrint("I/flutter (Background Isolate): Checking Mobile User Identity: No User Found");
    return;
  }
  
  debugPrint("Handling a background message: ${message.messageId} for User ID: $appUserId");
}

class FirebaseMessagingService{
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initializeNotificationPipeline() async {
    // 1. Request Permissions
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    String? token = await FirebaseMessaging.instance.getToken(); 
    debugPrint("FCM Token: $token");

    // 2. Assign handlers
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    _setupForegroundListener();
    await _createNotificationChannel();
  }

  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint("FULL MESSAGE DATA: ${message.data}");
      debugPrint("--- SOMETHING ARRIVED ---");

      // Community Status Update
      if (message.data['type'] == 'COMMUNITY_STATUS_UPDATE') {
        debugPrint("Admin Approval detected for community request.");
        if (navigatorKey.currentContext != null) {
          Provider.of<CommunityProvider>(navigatorKey.currentContext!, listen: false).loadCommunities();
        }
      }

      // New Alerts
      if (message.data['status'] == 'NEW_ALERT') {
        debugPrint("Incoming Live Notification Payload: ${message.data}");

        if (message.notification != null) {
          _showForegroundNotification(message);

          String originalBody = message.notification?.body ?? 'No Body';
          String targetLang = PlatformDispatcher.instance.locale.languageCode;
          String translatedText = originalBody;

          if (targetLang != 'en') {
            debugPrint("Translating to $targetLang...");
            translatedText = await TranslationService().translateAlert(originalBody);
          }

          await DatabaseHelper.instance.insertAlert({
            'title': message.notification?.title ?? 'No Title',
            'body': message.notification?.body ?? 'No Body',
            'translated_body': translatedText, 
            'language_code': targetLang,
            'alert_type': message.data['alert_type'] ?? 'general',
            'latitude': double.tryParse(message.data['latitude']?.toString() ?? '') ?? 0.0,
            'longitude': double.tryParse(message.data['longitude']?.toString() ?? '') ?? 0.0,
            'radius': double.tryParse(message.data['radius']?.toString() ?? '') ?? 500.00,
            'received_at': DateTime.now().toIso8601String(),
            'status': 'active',
          });
          debugPrint('Alert (Translated) stored to Local database.');
          await DatabaseHelper.instance.testDatabase();
          AlertNotifier.notifyRefresh();
        }
      }

      // Resolve Alert
      if (message.data['type'] == 'RESOLVE_ALERT') {
        String? alertTitle = message.data['alert_title']?.toString().trim(); 
        
        if (alertTitle != null && alertTitle.isNotEmpty) {
          final db = await DatabaseHelper.instance.database;
          List<Map<String, dynamic>> matchingAlerts = await db.query(
            'alerts',
            where: 'title LIKE ? AND (status != ? OR status IS NULL)',
            whereArgs: [alertTitle, 'resolved'],
          );

          if (matchingAlerts.isNotEmpty) {
            int localId = matchingAlerts.first['id']; 
            await DatabaseHelper.instance.updateAlertStatusById(localId, 'resolved');
            AlertNotifier.notifyRefresh(); 
          }
        }
      }
    });
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Emergency Alerts',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    await _localNotificationsPlugin.show(
      id: message.hashCode,          
      title: message.notification?.title, 
      body: message.notification?.body,  
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: 'alert_data',  
    );
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Emergency Alerts',
      description: 'This channel is used for critical emergency notifications.',
      importance: Importance.max,
      playSound: true
    );
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Service & Config Clean Extractions
import 'firebase_options.dart';
import 'config/api_config.dart';
import 'config/storage_keys.dart';
import 'services/session_manager.dart';
import 'services/firebase_messaging_service.dart';
import 'services/background_task_service.dart';

// Providers & Views
import 'providers/registration_provider.dart';
import 'providers/community_provider.dart';
import 'screens/main_wrapper_screen.dart';
import 'screens/registration_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ApiConfig.current = Environment.local;

  // 1. Initialise Core Cloud Engine infrastructure 
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseMessagingService().initializeNotificationPipeline();
  } catch (e) {
    debugPrint("Firebase initialization failed! $e");
  }

  // 2. Fire Async Background Automation Workers
  BackgroundTaskService().initializeTasks();

  // 3. Read & Validate User Session
  final bool isSessionValid = await SessionManager.validateUserSession();
  
  final prefs = await SharedPreferences.getInstance();
  final String? savedAppUserId = prefs.getString(StorageKeys.appUserId);
  final String? savedMobileUserId = prefs.getString(StorageKeys.mobileUserId);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RegistrationProvider()),
        ChangeNotifierProvider(create: (_) {
          final provider = CommunityProvider();
          if (savedAppUserId != null && savedAppUserId.isNotEmpty && savedAppUserId != "0" && savedAppUserId != "null" &&
              savedMobileUserId != null && savedMobileUserId.isNotEmpty && savedMobileUserId != "0" && savedMobileUserId != "null") {
            
            final int? cleanAppUserId = int.tryParse(savedAppUserId);
            final int? cleanMobileUserId = int.tryParse(savedMobileUserId);

            if (cleanAppUserId != null && cleanMobileUserId != null) {
              provider.setCurrentUser(cleanAppUserId, cleanMobileUserId);
            }
          }
          return provider;
        }),
      ],
      child: MonitusApp(isLoggedIn: isSessionValid),
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
      navigatorKey: navigatorKey, // References the extracted service global key safely
      home: isLoggedIn ? const MainWrapper() : const RegistrationScreen(),
    );
  }
}
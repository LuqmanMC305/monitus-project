import 'package:workmanager/workmanager.dart';
import 'background_service.dart'; // Import your original callbackDispatcher

class BackgroundTaskService {
  static final BackgroundTaskService _instance = BackgroundTaskService._internal();
  factory BackgroundTaskService() => _instance;
  BackgroundTaskService._internal();

  void initializeTasks() {
    Workmanager().initialize(callbackDispatcher);
    
    Workmanager().registerPeriodicTask(
      "monitus_location_sync", 
      "locationUpdateTask",
      frequency: const Duration(minutes: 15), 
      initialDelay: const Duration(seconds: 10), 
      constraints: Constraints(
        networkType: NetworkType.connected,
      )
    );
  }
}
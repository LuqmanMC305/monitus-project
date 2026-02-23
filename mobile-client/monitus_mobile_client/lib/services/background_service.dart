import 'package:workmanager/workmanager.dart';
import 'registration_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // This 'taskName' will be "locationUpdateTask"
    if (taskName == "locationUpdateTask") {
      try {
        final service = RegistrationService();
        
        // Periodically reports coordinates to backend
        await service.registerUser(); 
        
        return Future.value(true); // Task succeeded
      } catch (err) {
        // Log the error for debugging 
        print("Background Task Failed: $err"); 
        
        return Future.value(false); // Task failed, OS will retry
      }
    }
    return Future.value(true);
  });
}
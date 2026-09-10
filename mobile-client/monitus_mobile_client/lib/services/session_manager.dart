import 'package:shared_preferences/shared_preferences.dart';
import '../config/storage_keys.dart';

class SessionManager {
  static Future<bool> validateUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedAppUserId = prefs.getString(StorageKeys.appUserId);
    final int? lastActivity = prefs.getInt('last_activity');

    if (savedAppUserId != null && 
        savedAppUserId.isNotEmpty && 
        savedAppUserId != "null" && 
        savedAppUserId != "0" && 
        lastActivity != null) {
      
      const int thirtyDays = 30 * 24 * 60 * 60 * 1000;
      int currentTime = DateTime.now().millisecondsSinceEpoch;

      if ((currentTime - lastActivity) < thirtyDays) {
        await prefs.setInt('last_activity', currentTime);
        return true;
      } else {
        await prefs.remove(StorageKeys.appUserId);
        await prefs.remove(StorageKeys.mobileUserId);
        await prefs.remove('last_activity');
      }
    } else if (savedAppUserId == "0") {
      await prefs.remove(StorageKeys.appUserId);
    }
    return false;
  }
}
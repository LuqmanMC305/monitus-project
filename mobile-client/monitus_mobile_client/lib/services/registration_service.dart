import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../config/api_config.dart';
import 'dart:io' show Platform;


class RegistrationService {

  /*
  // Endpoint 1: For registering User Account (app_users table)
  final _registerApiUrl = Uri.parse('https://monitus-laravel-backend-49hltibe.on-forge.com/api/app-register');

   // Endpoint 2: For login User Account (app_users table)
  final _loginApiUrl = Uri.parse('https://monitus-laravel-backend-49hltibe.on-forge.com/api/app-login');

  // Endpoint 3: For syncing Device data (mobile_users table)
  final _apiUrl = Uri.parse('https://monitus-laravel-backend-49hltibe.on-forge.com/api/register-mobile');
  */

  Future<bool> createAccount(String name, String email, String password) async{
    try{
      final response = await http.post(
        ApiConfig.register(),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 201){
        final data =jsonDecode(response.body);

        // Save app_user_id that is returned from Laravel
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_user_id', data['app_user_id'].toString());
        await prefs.setString('user_name', data['name'] ?? name);

        // Save the "Last Activity" timestamp
        await prefs.setInt('last_activity', DateTime.now().microsecondsSinceEpoch);

        debugPrint("Account Created: User ${data['app_user_id']} saved locally. ");
        return true;
      }
        debugPrint("SERVER ERROR BODY: ${response.body}");
        return false;
    } catch (e){
      debugPrint("Error: $e");
      return false;
    }
  }
  Future<void> registerUser(double? manualLat, double? manualLng) async {
    try{
      // Fetch the FCM Token
      String? fcmToken = await FirebaseMessaging.instance.getToken();

       // Fetch the Current Location 
      Position position = await determinePosition();
      double lat = position.latitude;
      double lng = position.longitude;

      debugPrint("CURRENT COORDINATES: Latitude: ${lat}, Longitude: ${lng}");

      // Fetch REAL USER ID from mobile storage
      final prefs = await SharedPreferences.getInstance();
      String realUserID = prefs.getString('saved_user_id') ?? '0';

      // Initialise placeholder device ID
      String uniqueDeviceId = "unknown_device";

      try{
         if(kIsWeb){
          // SAFETY: Web browsers don't have a unique hardware ID unlike phones
          uniqueDeviceId = "web_browser_client";
          debugPrint("Running on Web: Device ID set to placeholder.");
         } else {
            // Get unique mobile device id
            DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

            if(Platform.isAndroid){
            AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
            uniqueDeviceId = androidInfo.id; 
          } else if (Platform.isIOS){
            IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
            uniqueDeviceId = iosInfo.identifierForVendor ?? "unknown_ios";
          }
        }  
      } catch (e){
        debugPrint("Failed to get device info: $e");
      }
      
      // Prepare Data Package
      Map<String, dynamic> data = {
        'user_id': realUserID,
        'fcm_token': fcmToken ?? '',
        'device_id': uniqueDeviceId, 
        'latitude': lat,
        'longitude': lng
      };
      
      debugPrint("Attempting to sync at: ${DateTime.now()}");

      // 4. Send the Single POST request to Laravel 
      final response = await http.post(
        ApiConfig.registerMobile(),
        headers: {
          'Content-Type': 'application/json', 
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 5));

      // Print Sync Status
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Sync Success: Token and Location sent to Laravel");
        
        final prefs = await SharedPreferences.getInstance();
        String currentUserName = prefs.getString('user_name') ?? 'User';

        debugPrint("Dashboard Check: Current user is '$currentUserName'");
        debugPrint("Identity Saved: User $realUserID is ready for Dashboard.");
      }
      else debugPrint("Sync Failed: ${response.statusCode}"); 

    } catch (e) { debugPrint("Error during sync: $e"); }
      
  }

  Future<bool> login(String email, String password) async {
    try {
      // Replace with your actual Laravel login endpoint URL
      final response = await http.post(
        ApiConfig.login(),
        headers: {
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        }, 
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract mobile_user_id
        final String userId = data['mobile_user_id'].toString();
        final String userName = data['name'] ?? 'User';
        
        // Save Mobile User Token for Auth
        final String token = data['access_token'];
        debugPrint("Token is: ${token}");

        // Persist the ID and name so the rest of the app knows who is logged in
        final prefs = await SharedPreferences.getInstance();

        // Save the token so CommunityService can find it
        await prefs.setString('auth-token', token);

        await prefs.setString('saved_user_id', userId); // Saved 7 instead of 36
        await prefs.setString('user_name', userName);
        await prefs.setInt('last_activity', DateTime.now().millisecondsSinceEpoch);
        
        debugPrint("Login Successful: User $userId");
        return true;
      } else {
        debugPrint("Login Failed: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Login Connection Error: $e");
      return false;
    }
}
    
  // Standard Geolocator permission handler
  static Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Location permissions are denied');
    }
    
    return await Geolocator.getCurrentPosition();
  }
}
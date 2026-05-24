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

  /// Creates a new user account profile in the app_users table
  Future<bool> createAccount(String name, String email, String password) async {
    try {
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

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        //  Explicitly preserve this as the unique account credential reference
        final String appUserId = data['app_user_id']?.toString() ?? '';
        await prefs.setString('saved_app_user_id', appUserId);
        await prefs.setString('user_name', data['name'] ?? name);

        //  Swapped from microseconds to uniform millisecond epochs
        await prefs.setInt('last_activity', DateTime.now().millisecondsSinceEpoch);

        debugPrint("Account Created: App User ID $appUserId cached locally.");
        return true;
      }
      
      debugPrint("SERVER ERROR BODY: ${response.body}");
      return false;
    } catch (e) {
      debugPrint("Error: $e");
      return false;
    }
  }

  /// Synchronizes hardware attributes and coordinates to the mobile_users table
  Future<void> registerUser(double? manualLat, double? manualLng) async {
    try {
      // Fetch the FCM Token
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // Fetch the Current Location 
      Position position = await determinePosition();
      double lat = position.latitude;
      double lng = position.longitude;

      debugPrint("CURRENT COORDINATES: Latitude: $lat, Longitude: $lng");

      final prefs = await SharedPreferences.getInstance();
      
      // 🟢 FIX 3: Correctly extract the authentic App User database primary key
      String realAppUserID = prefs.getString('saved_app_user_id') ?? '0';

      // Initialise placeholder device ID
      String uniqueDeviceId = "unknown_device";

      try {
        if (kIsWeb) {
          uniqueDeviceId = "web_browser_client";
          debugPrint("Running on Web: Device ID set to placeholder.");
        } else {
          DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

          if (Platform.isAndroid) {
            AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
            uniqueDeviceId = androidInfo.id; 
          } else if (Platform.isIOS) {
            IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
            uniqueDeviceId = iosInfo.identifierForVendor ?? "unknown_ios";
          }
        }  
      } catch (e) {
        debugPrint("Failed to get device info: $e");
      }
      
      // Prepare Data Package (Matches what MobileUserController expects)
      Map<String, dynamic> data = {
        'user_id': realAppUserID,
        'fcm_token': fcmToken ?? '',
        'device_id': uniqueDeviceId, 
        'latitude': lat,
        'longitude': lng
      };
      
      debugPrint("Attempting to sync at: ${DateTime.now()}");

      // Send the Single POST request to Laravel 
      final response = await http.post(
        ApiConfig.registerMobile(),
        headers: {
          'Content-Type': 'application/json', 
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Sync Success: Token and Location sent to Laravel");
        
        final responseData = jsonDecode(response.body);
        
        //  Safely record the newly initialized hardware pivot index identifier
        if (responseData['data'] != null && responseData['data']['id'] != null) {
          await prefs.setString('saved_mobile_user_id', responseData['data']['id'].toString());
        }

        String currentUserName = prefs.getString('user_name') ?? 'User';
        debugPrint("Dashboard Check: Current user is '$currentUserName'");
        debugPrint("Identity Saved: User $realAppUserID is ready for Dashboard.");
      } else {
        debugPrint("Sync Failed: ${response.statusCode} - ${response.body}"); 
      }

    } catch (e) { 
      debugPrint("Error during sync: $e"); 
    }
  }

  /// Authenticates an existing application session profile
  Future<bool> login(String email, String password) async {
    try {
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
        final prefs = await SharedPreferences.getInstance();

        //  Isolate and explicitly store both properties individually
        final String appUserId = data['app_user_id']?.toString() ?? '';
        final String mobileUserId = data['mobile_user_id']?.toString() ?? '';
        final String userName = data['name'] ?? 'User';
        final String token = data['access_token'] ?? '';
        
        debugPrint("Token is: $token");

        // Save session tokens cleanly
        await prefs.setString('auth-token', token);
        await prefs.setString('saved_app_user_id', appUserId);
        await prefs.setString('saved_mobile_user_id', mobileUserId);
        await prefs.setString('user_name', userName);
        
        // Match registration timing mechanics precisely 
        await prefs.setInt('last_activity', DateTime.now().millisecondsSinceEpoch);
        
        debugPrint("Login Successful: App User ID $appUserId, Mobile User ID $mobileUserId");
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
    
  /// Standard Geolocator permission handler
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
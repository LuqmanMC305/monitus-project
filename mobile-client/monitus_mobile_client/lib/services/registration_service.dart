import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;


class RegistrationService {
  // Endpoint 1: For creating User Account (app_users table)
  final _accountApiUrl = Uri.parse('https://adria-vexatious-unrigidly.ngrok-free.dev/api/app-register');

  // Endpoint 2: For syncing Device data (mobile_users table)
  final _apiUrl = Uri.parse('https://adria-vexatious-unrigidly.ngrok-free.dev/api/register-mobile');

  Future<bool> createAccount(String name, String email, String password) async{
    try{
      final response = await http.post(
        _accountApiUrl,
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
        'device_id': uniqueDeviceId, // Ideally get a real unique ID (Hardcoded for now)
        'latitude': lat,
        'longitude': lng
      };
      
      debugPrint("Attempting to sync at: ${DateTime.now()}");

      // 4. Send the Single POST request to Laravel 
      final response = await http.post(
        _apiUrl,
        headers: {
          'Content-Type': 'application/json', 
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          },
        body: jsonEncode(data),
      );

      // Print Sync Status
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Sync Success: Token and Location sent to Laravel");

        // Extract ID from server's response (JSON -> String)
        var responseData = jsonDecode(response.body);

        // Save the unique user data permanently
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_user_id', responseData['id'].toString());

        debugPrint("Identity Saved: User ${responseData['id']} is stored persistently.");

      }
      else debugPrint("Sync Failed: ${response.statusCode}"); 

    } catch (e) { debugPrint("Error during sync: $e"); }
      
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
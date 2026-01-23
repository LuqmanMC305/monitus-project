import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class RegistrationService {
  // Replace with your local IP address (not localhost if using physical device)
  final String _apiUrl = "http://192.168.0.196:8000/api/register-mobile";

  Future<void> registerUser() async {
    try {
      // 1. Fetch the FCM Token
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      
      // 2. Fetch the Current Location
      Position position = await _determinePosition();

      // 3. Prepare the Data Package
      Map<String, dynamic> data = {
        'fcm_token': fcmToken,
        'device_id': 'mobile_device_001', // Ideally get a real unique ID (Hardcoded for now)
        'latitude': position.latitude,
        'longitude': position.longitude,
      };

      // 4. Send to Laravel API
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(data),
      );
      
      if (response.statusCode == 201) {
        if(kDebugMode){
          debugPrint("Registration Success: ${response.body}");
        }
      } else {
        if(kDebugMode){
          debugPrint("Registration Failed: ${response.statusCode}");
        }
      }
    } catch (e) {
      debugPrint("Error during registration: $e");
    }
  }

  // Standard Geolocator permission handler
  Future<Position> _determinePosition() async {
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
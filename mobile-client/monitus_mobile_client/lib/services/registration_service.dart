import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';



class RegistrationService {

  // Parse URL
  final _apiUrl = Uri.parse('http://192.168.0.195:8000/api/register-mobile');

  Future<void> registerUser(double? manualLat, double? manualLng) async {
    try{
      // Fetch the FCM Token
      String? fcmToken = await FirebaseMessaging.instance.getToken();

       // Fetch the Current Location 
      Position position = await _determinePosition();
      double lat = position.latitude;
      double lng = position.longitude;

      // Prepare Data Package
      Map<String, dynamic> data = {
        'user_id': '5',
        'fcm_token': fcmToken ?? '',
        'device_id': 'mobile_device_001', // Ideally get a real unique ID (Hardcoded for now)
        'latitude': lat,
        'longitude': lng
      };
      
      debugPrint("Attempting to sync at: ${DateTime.now()}");

      // 4. Send the Single POST request to Laravel 
      final response = await http.post(
        _apiUrl,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(data),
      );

      // Print Sync Status
      if (response.statusCode == 200 || response.statusCode == 201) debugPrint("Sync Success: Token and Location sent to Laravel");
      else debugPrint("Sync Failed: ${response.statusCode}"); 

    } catch (e) { debugPrint("Error during sync: $e"); }
      
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
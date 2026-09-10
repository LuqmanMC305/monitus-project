import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/storage_keys.dart';


class ReportService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<bool> submitIncidentReport({
    required int appUserId,
    required String description,
    required LatLng location,
    File? imageFile,
  }) async {
    try {

      // Fetch the token dynamically
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(StorageKeys.authToken);

      // DEBUG: Check your console log to ensure your active login token is resolved
      debugPrint('--- TOKEN IN REPORT SERVICE: $token ---');

      // 🟢 Assemble the multi-part data map wrapper
      Map<String, dynamic> formDataMap = {
        'app_user_id': appUserId,
        'incident_description': description,
        'latitude': location.latitude,
        'longitude': location.longitude,
      };

      // If the citizen captured a camera photo, attach the file binary stream stream data
      if (imageFile != null) {
        String fileName = imageFile.path.split('/').last;
        formDataMap['image'] = await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        );
      }

      FormData formData = FormData.fromMap(formDataMap);

      // Execute HTTP POST Request to your Laravel API endpoint
      Response response = await _dio.post(ApiConfig.requestAlert().toString(), data: formData);
      /*

       NEW HTTP POST REQUEST 
      Response response = await _dio.post(
        '/reports', 
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'ngrok-skip-browser-warning': 'true', // Keeps local Ngrok tunnels happy!
          },
        ),
      );
      return response.statusCode == 201;

      */
      if (response.statusCode == 201) {
        debugPrint("Server Success Response: ${response.data}");
        return true;
      }
      return false;
    } on DioException catch (e) {
      debugPrint("Dio Submission Failure: ${e.message} | Response: ${e.response?.data}");
      return false;
    } catch (e) {
      debugPrint("Unexpected network error occurred: $e");
      return false;
    }
  }
}
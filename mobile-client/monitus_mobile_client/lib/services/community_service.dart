import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../config/storage_keys.dart';

class CommunityService {
  
  // Fetch available communities (for the Discovery Screen)
  Future<List<dynamic>> fetchCommunities() async {
    final prefs = await SharedPreferences.getInstance();

    // 🟢 CHANGED: Using uniform token storage keys matching active login states
    final token = prefs.getString(StorageKeys.authToken);

    // DEBUG: Check your terminal. If this says 'null', your login failed to save it.
    print('--- TOKEN IN COMMUNITY SCREEN: $token ---');

    final response = await http.get(
      ApiConfig.loadCommunity(), 
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      print('Failed status code: ${response.statusCode}');
      throw Exception('Failed to load communities');
    }
  }

  //  The Join Request logic now accepts the authenticated user's ID context
  Future<Map<String, dynamic>> joinCommunity({required int communityId, required int appUserId}) async {
    final prefs = await SharedPreferences.getInstance();

    // Unified bearer key check
    final token = prefs.getString(StorageKeys.authToken);

    final response = await http.post(
      ApiConfig.joinCommunity(),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      //  Passing 'user_id' so Laravel can parse the parameter securely
      body: jsonEncode({
        'community_id': communityId,
        'user_id': appUserId, 
      }),
    );

    // Parse the JSON body from Laravel for status 
    final data = jsonDecode(response.body);
    
    print("JOIN STATUS: ${response.statusCode}");
    print("JOIN BODY: ${response.body}");
    return {
      'success': response.statusCode >= 200 && response.statusCode < 300,
      'message': data['message'] ?? 'An error occurred',
    };
  }
}
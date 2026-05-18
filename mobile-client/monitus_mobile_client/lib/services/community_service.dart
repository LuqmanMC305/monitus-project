import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';



class CommunityService{

    /*
    // Replace with  actual local/production IP
    final String baseUrl = 'https://monitus-laravel-backend-49hltibe.on-forge.com/api';
    */

    // Fetch available communities (for the Discovery Screen)
    Future<List<dynamic>> fetchCommunities() async {
      final prefs = await SharedPreferences.getInstance();

      // Use 'auth-token' to match your Login code
      final token = prefs.getString('auth-token');

      // DEBUG: Check your terminal. If this says 'null', your login failed to save it.
      print('--- SENDING TOKEN: $token ---');

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
        print(response.statusCode);
        throw Exception('Failed to load communities');
        
      }
    }

  // The Join Request logic
  Future<Map<String, dynamic>> joinCommunity(int communityId) async {
    final prefs = await SharedPreferences.getInstance();

    // Use 'auth-token' to match your Login code
    final token = prefs.getString('auth-token');

    final response = await http.post(
      ApiConfig.joinCommunity(),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode({
        'community_id': communityId,
      }),
    );

    // Parse the JSON body from Laravel for status 
    final data = jsonDecode(response.body);
    return {
      'success': response.statusCode >= 200 && response.statusCode < 300,
      'message': data['message'] ?? 'An error occurred',
    };

  }

}
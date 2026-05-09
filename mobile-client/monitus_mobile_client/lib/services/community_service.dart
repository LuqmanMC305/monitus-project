import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';



class CommunityService{
    // Replace with your actual local/production IP
    final url = Uri.parse('http://your-api-url/api/communities/join');

    // Fetch available communities (for the Discovery Screen)
    Future<List<dynamic>> fetchCommunities() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/communities'), 
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['data'];
      } else {
        throw Exception('Failed to load communities');
      }
    }

    // The Join Request logic
  Future<Map<String, dynamic>> joinCommunity(int communityId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.post(
      Uri.parse('$baseUrl/communities/join'),
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
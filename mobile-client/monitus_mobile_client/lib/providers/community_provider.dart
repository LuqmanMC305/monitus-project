import 'package:flutter/material.dart';
import '../services/community_service.dart';

class CommunityProvider with ChangeNotifier {
  final CommunityService _service = CommunityService();
  
  List<dynamic> _communities = [];
  bool _isLoading = false;

  List<dynamic> get communities => _communities;
  bool get isLoading => _isLoading;

  // Fetch the list of available communities for the UI
  Future<void> loadCommunities() async {
    _isLoading = true;
    notifyListeners();

    try {
      _communities = await _service.fetchCommunities();
    } catch (e) {
      debugPrint("Error fetching communities: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Handle the "Join" button click
  Future<Map<String, dynamic>> requestToJoin(int communityId) async {
    return await _service.joinCommunity(communityId);
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/community_service.dart';

class CommunityProvider with ChangeNotifier {
  final CommunityService _service = CommunityService();

  
  // 🟢 CHANGED: Tracking explicit ID archetypes cleanly to align with the database layers
  int? _currentAppUserId;
  int? _currentMobileUserId; 
  
  List<dynamic> _communities = [];
  bool _isLoading = false;

  List<dynamic> get communities => _communities;
  bool get isLoading => _isLoading;
  int? get currentAppUserId => _currentAppUserId;
  int? get currentMobileUserId => _currentMobileUserId;

  /// Synchronizes user profile markers across frontend state memory
  void setCurrentUser(int appUserId, int mobileUserId) {
    _currentAppUserId = appUserId;
    _currentMobileUserId = mobileUserId;
    
    debugPrint("🎯 Provider Initialized: App=$appUserId Mobile=$mobileUserId");
    notifyListeners(); 
  }

  /// 🟢 NEW: DEFENSIVE SAFETY NET
  /// Restores identification parameters from disk cache automatically if memory clears out.
  Future<bool> ensureUserContext() async {
    if (_currentAppUserId != null && _currentAppUserId != 0) {
      return true; // Memory state is already perfectly healthy
    }

    debugPrint("🔄 Provider context is null. Executing fallback SharedPreferences lookup...");
    final prefs = await SharedPreferences.getInstance();
    
    final String? savedAppIdStr = prefs.getString('saved_app_user_id');
    final String? savedMobileIdStr = prefs.getString('saved_mobile_user_id');

    if (savedAppIdStr != null && savedAppIdStr.isNotEmpty && savedAppIdStr != 'null') {
      _currentAppUserId = int.tryParse(savedAppIdStr);
      _currentMobileUserId = int.tryParse(savedMobileIdStr ?? '');
      
      debugPrint("✅ State Automatically Restored: AppUser: $_currentAppUserId, MobileUser: $_currentMobileUserId");

      return _currentAppUserId != null;
    }

    debugPrint("⚠️ Critical State Error: Missing identification parameters on local disk storage.");
    return false;
  }

  // Fetch the list of available communities for the UI
  Future<void> loadCommunities() async {
    // 🟢 CHANGED: Run defensive safety-net fallback verification checks first
    await ensureUserContext();
    debugPrint("Active User ID in Provider: $_currentAppUserId");

    if (_currentAppUserId == null || _currentAppUserId == 0) {
      debugPrint("🛑 Aborting loadCommunities: No valid user profile context available.");
      return;
    }

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
    // 🟢 CHANGED: Ensure credentials are valid and present before communicating with backend APIs
    final hasValidContext = await ensureUserContext();
    if (!hasValidContext) {
      return {
        'success': false,
        'message': 'Cannot request join: Identity state context missing.'
      };
    }

    // 🟢 FIX: Copy the provider state into a strict local variable!
    // Even if a widget rebuild hits and clears out the class variable mid-request, 
    // 'localAppUserId' is safe inside this method scope and cannot be wiped out.
    final int localAppUserId = _currentAppUserId!;

    debugPrint("📬 Posting Join Request for Community: $communityId by App User: $localAppUserId");
    
    // Pass BOTH variables downstream into your newly updated service layer architecture
    return await _service.joinCommunity(
      communityId: communityId,
      appUserId: localAppUserId,
    );
  }
}
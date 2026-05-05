import 'package:flutter/material.dart';
import '../services/registration_service.dart';

class RegistrationProvider extends ChangeNotifier {
  final RegistrationService _service = RegistrationService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  // Getters to let the UI read the state
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSuccess => _isSuccess;

  // Handles the full sequence: Create Account -> Sync Device
  Future<void> handleRegistration({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _isSuccess = false;
    notifyListeners(); // Tells the UI to show the loading spinner

    try {
      // Create user account in Laravel app_users table
      bool accountCreated = await _service.createAccount(name, email, password);

      if(accountCreated){
        // Sync hardware (FCM, GPS) to mobile_users table
        // registerUser automatically fetches the saved_user_id from storage
        await _service.registerUser(null, null);
        _isSuccess = true;
        debugPrint("Identity Foundation Verified: Account created and Hardware synced.");
      } else {
        _errorMessage = "Account creation failed. Please try again.";
      }
    } catch (e) {
      _errorMessage = "Connection error: ${e.toString()}";
      debugPrint("Registration Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners(); // Tells the UI to stop the spinner and show the result
    }
  }
  
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _isSuccess = false;
    
    // Tells the UI to rebuild and show the form again.
    notifyListeners(); 
  }

  Future<void> handleLogin({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Call new login API
      bool loginSuccess = await _service.login(email, password);
      if (loginSuccess) {
        // 2. Reuse existing hardware sync
        await _service.registerUser(null, null); 
        _isSuccess = true;
      }
    } catch (e) {
      _errorMessage = "Login failed: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}
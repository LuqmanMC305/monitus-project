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

  Future<void> handleRegistration() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Tells the UI to show the loading spinner

    try {
      await _service.registerUser();
      _isSuccess = true;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners(); // Tells the UI to stop the spinner and show the result
    }
  }
}
import 'package:flutter/material.dart';

class AlertNotifier {
  // Global value notifier to broadcast refresh triggers across screens
  static final ValueNotifier<bool> refreshTrigger = ValueNotifier<bool>(false);

  static void notifyRefresh() {
    refreshTrigger.value = !refreshTrigger.value;
  }
}
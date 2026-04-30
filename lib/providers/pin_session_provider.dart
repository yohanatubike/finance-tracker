import 'package:flutter/foundation.dart';

import '../services/security_service.dart';

/// Handles PIN presence, unlock state, and first-time setup.
class PinSessionProvider extends ChangeNotifier {
  PinSessionProvider() {
    initialize();
  }

  final SecurityService _security = SecurityService.instance;

  bool loading = true;
  bool needsSetup = false;
  bool isUnlocked = false;

  Future<void> initialize() async {
    loading = true;
    notifyListeners();
    final has = await _security.hasPin();
    needsSetup = !has;
    isUnlocked = false;
    loading = false;
    notifyListeners();
  }

  Future<bool> verifyAndUnlock(String pin) async {
    final ok = await _security.verifyPin(pin);
    if (ok) {
      isUnlocked = true;
      notifyListeners();
    }
    return ok;
  }

  Future<void> completeSetup(String pin) async {
    await _security.setPin(pin);
    needsSetup = false;
    isUnlocked = true;
    notifyListeners();
  }

  void lock() {
    if (!needsSetup) {
      isUnlocked = false;
      notifyListeners();
    }
  }

  Future<bool> changePin(String oldPin, String newPin) async {
    if (!await _security.verifyPin(oldPin)) return false;
    await _security.setPin(newPin);
    notifyListeners();
    return true;
  }
}

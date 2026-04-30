import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores only a salted SHA-256 hash of the PIN (never the PIN itself).
/// Uses [SharedPreferences] so no extra native plugin registration is required.
class SecurityService {
  SecurityService._();
  static final SecurityService instance = SecurityService._();

  static const _kHash = 'pf_pin_sha256_v1';
  static const _kSalt = 'pf_pin_salt_v1';

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getString(_kHash);
    return h != null && h.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = _randomSalt();
    final hash = _hash(pin, salt);
    await prefs.setString(_kSalt, salt);
    await prefs.setString(_kHash, hash);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final salt = prefs.getString(_kSalt);
    final stored = prefs.getString(_kHash);
    if (salt == null || stored == null) return false;
    return _hash(pin, salt) == stored;
  }

  static String _randomSalt() {
    final bytes = List<int>.generate(24, (_) => Random.secure().nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String _hash(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }
}

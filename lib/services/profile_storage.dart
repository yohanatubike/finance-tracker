import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';

class ProfileStorage {
  ProfileStorage._();
  static final ProfileStorage instance = ProfileStorage._();

  static const _keyProfileJson = 'user_profile_json_v1';

  Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyProfileJson);
    if (raw == null || raw.isEmpty) return UserProfile.empty;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile.fromJson(map);
    } catch (_) {
      return UserProfile.empty;
    }
  }

  Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyProfileJson,
      jsonEncode(profile.toJson()),
    );
  }
}

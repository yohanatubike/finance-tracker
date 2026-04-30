import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../services/profile_storage.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider() {
    load();
  }

  UserProfile _profile = UserProfile.empty;

  UserProfile get profile => _profile;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    _profile = await ProfileStorage.instance.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> save(UserProfile profile) async {
    _profile = profile;
    await ProfileStorage.instance.save(profile);
    notifyListeners();
  }

  String get greetingName {
    final n = _profile.displayName.trim();
    return n.isEmpty ? 'there' : n.split(RegExp(r'\s+')).first;
  }

  String get shortDisplayLine {
    final n = _profile.displayName.trim();
    return n.isEmpty ? 'Tap to add profile' : n;
  }
}

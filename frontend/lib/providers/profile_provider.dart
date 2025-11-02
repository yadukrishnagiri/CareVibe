import 'package:flutter/foundation.dart';

import '../services/profile_api.dart';
import 'session_provider.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider(this._session);

  final SessionProvider _session;

  UserProfileDto? _profile;
  bool _loading = false;
  String? _error;

  UserProfileDto? get profile => _profile;
  bool get loading => _loading;
  String? get error => _error;

  bool get isComplete => (_profile?.age != null) && (_profile?.gender != null) && (_profile?.heightCm != null);

  Future<void> load() async {
    if (_session.jwt == null) return;
    _loading = true; _error = null; notifyListeners();
    try {
      _profile = await ProfileApi.fetchMyProfile(_session.jwt!);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> save(UserProfileDto dto) async {
    if (_session.jwt == null) return;
    _loading = true; _error = null; notifyListeners();
    try {
      _profile = await ProfileApi.upsertMyProfile(_session.jwt!, dto);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false; notifyListeners();
    }
  }
}



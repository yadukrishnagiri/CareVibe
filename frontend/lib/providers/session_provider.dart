import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SessionProvider extends ChangeNotifier {
  String? _backendToken;
  User? _firebaseUser;
  bool _isDemoMode = false;
  Map<String, dynamic>? _demoUserInfo;

  String? get jwt => _backendToken;
  User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _backendToken != null && (_firebaseUser != null || _isDemoMode);
  bool get isDemoMode => _isDemoMode;
  Map<String, dynamic>? get demoUserInfo => _demoUserInfo;

  void updateSession({required String backendToken, required User firebaseUser}) {
    _backendToken = backendToken;
    _firebaseUser = firebaseUser;
    _isDemoMode = false;
    _demoUserInfo = null;
    notifyListeners();
  }

  void updateDemoSession({required String backendToken, required Map<String, dynamic> userInfo}) {
    _backendToken = backendToken;
    _firebaseUser = null;
    _isDemoMode = true;
    _demoUserInfo = userInfo;
    notifyListeners();
  }

  void clear() {
    _backendToken = null;
    _firebaseUser = null;
    _isDemoMode = false;
    _demoUserInfo = null;
    notifyListeners();
  }
}


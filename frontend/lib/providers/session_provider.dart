import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SessionProvider extends ChangeNotifier {
  String? _backendToken;
  User? _firebaseUser;

  String? get jwt => _backendToken;
  User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _backendToken != null && _firebaseUser != null;

  void updateSession({required String backendToken, required User firebaseUser}) {
    _backendToken = backendToken;
    _firebaseUser = firebaseUser;
    notifyListeners();
  }

  void clear() {
    _backendToken = null;
    _firebaseUser = null;
    notifyListeners();
  }
}


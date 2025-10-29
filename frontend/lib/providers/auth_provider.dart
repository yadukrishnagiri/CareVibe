import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../services/api.dart';
import 'session_provider.dart';

class AuthProvider {
  AuthProvider(this.sessionProvider);

  final SessionProvider sessionProvider;

  Future<void> signInWithGoogleAndFetchJwt() async {
    String? idToken;

    if (kIsWeb) {
      // Web: use popup-based sign-in
      final cred = await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      idToken = await cred.user!.getIdToken();
    } else {
      // Android: use GoogleSignIn → Firebase credential
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) throw Exception('Google sign-in canceled');
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      idToken = await FirebaseAuth.instance.currentUser!.getIdToken();
    }

    if (idToken == null || idToken!.isEmpty) {
      throw Exception('Failed to obtain Firebase ID token');
    }

    // Exchange Firebase ID token for backend JWT
    final r = await http.post(
      Uri.parse('$apiBase/auth/firebase'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    if (r.statusCode != 200) {
      throw Exception('Auth failed: ${r.body}');
    }
    final token = jsonDecode(r.body)['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('Auth failed: backend did not return a token');
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw Exception('Firebase user not available after login');
    }

    sessionProvider.updateSession(backendToken: token, firebaseUser: firebaseUser);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
    sessionProvider.clear();
  }
}



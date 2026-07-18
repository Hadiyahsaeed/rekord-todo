
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    // Keep our state in sync with Firebase real-time auth changes
    _authService.userStream.listen((User? newUser) {
      _user = newUser;
      notifyListeners();
    });
  }

  // Handle Login
  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _authService.signIn(email, password);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  // Handle Sign Up
  Future<void> signUp(String email, String password, String name) async {
    _setLoading(true);
    try {
      _user = await _authService.signUp(email, password, name);
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
    _setLoading(false);
  }

  // Handle Log Out
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
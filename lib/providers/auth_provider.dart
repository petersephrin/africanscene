import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();

  UserModel? _user;
  bool _isLoading = true;
  bool _hasOnboarded = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get hasOnboarded => _hasOnboarded;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _hasOnboarded = prefs.getBool('africascene_onboarded') ?? false;

    // Listen to Firebase Auth state
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        _user = await _authService.getUserProfile(firebaseUser.uid);
      } else {
        _user = null;
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final user = await _authService.signInWithEmail(email, password);
      _user = user;
      _isLoading = false;
      notifyListeners();
      if (_user == null) {
        return 'Could not retrieve user account.';
      }
      return null; // Success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _authService.sendPasswordReset(email);
      return null; // Success
    } catch (e) {
      return e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim();
    }
  }

  Future<void> completeOnboarding() async {
    _hasOnboarded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('africascene_onboarded', true);
    notifyListeners();
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? specialization,
    String? department,
  }) async {
    if (_user == null) return;
    final updated = _user!.copyWith(
      firstName: firstName,
      lastName: lastName,
      name: '$firstName $lastName'.trim(),
      phone: phone,
      specialization: specialization,
      department: department,
    );
    await _authService.updateUserProfile(updated);
    _user = updated;
    notifyListeners();
  }

  bool hasPermission(UserRole requiredRole) {
    if (_user == null) return false;
    return _user!.role == requiredRole || _user!.role == UserRole.superAdmin;
  }
}

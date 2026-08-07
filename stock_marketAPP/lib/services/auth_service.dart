import 'package:flutter/foundation.dart';
import 'package:untitled_5/models/user_model.dart';
import 'package:untitled_5/services/api_client.dart';

class AuthService extends ChangeNotifier {
  final ApiClient _api = ApiClient.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _lastError;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get lastError => _lastError;

  /// Loads any saved token and, if present, fetches the current user from
  /// the backend so a logged-in session survives an app restart.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _api.loadToken();
      if (_api.hasToken) {
        final resp = await _api.get('/auth/me');
        if (resp.ok) {
          _currentUser = UserModel.fromJson(resp.data['user']);
        } else {
          // Token expired/invalid - clear it.
          await _api.setToken(null);
        }
      }
    } catch (e) {
      debugPrint('Failed to initialize auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _lastError = null;
    try {
      final resp = await _api.post('/auth/login', {'email': email, 'password': password});
      if (!resp.ok) {
        _lastError = resp.errorMessage;
        return false;
      }
      await _api.setToken(resp.data['token'] as String);
      _currentUser = UserModel.fromJson(resp.data['user']);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      _lastError = 'Login failed: $e';
      return false;
    }
  }

  Future<bool> signup(String email, String password, String name, String riskProfile) async {
    _lastError = null;
    try {
      final resp = await _api.post('/auth/signup', {
        'email': email,
        'password': password,
        'name': name,
        'riskProfile': riskProfile,
      });
      if (!resp.ok) {
        _lastError = resp.errorMessage;
        return false;
      }
      await _api.setToken(resp.data['token'] as String);
      _currentUser = UserModel.fromJson(resp.data['user']);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Signup error: $e');
      _lastError = 'Signup failed: $e';
      return false;
    }
  }

  /// Re-fetches the current user from the backend, e.g. after a trade
  /// changes the virtual balance server-side.
  Future<void> refreshUser() async {
    if (!_api.hasToken) return;
    try {
      final resp = await _api.get('/auth/me');
      if (resp.ok) {
        _currentUser = UserModel.fromJson(resp.data['user']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Refresh user error: $e');
    }
  }

  Future<void> updateProfile({String? name, String? riskProfile}) async {
    if (_currentUser == null) return;
    try {
      final resp = await _api.put('/auth/profile', {
        if (name != null) 'name': name,
        if (riskProfile != null) 'riskProfile': riskProfile,
      });
      if (resp.ok) {
        _currentUser = UserModel.fromJson(resp.data['user']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
    }
  }

  Future<void> updateAvatar(String? avatarData) async {
    if (_currentUser == null) return;
    try {
      final resp = await _api.put('/auth/avatar', {'avatarData': avatarData});
      if (resp.ok) {
        _currentUser = UserModel.fromJson(resp.data['user']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Update avatar error: $e');
    }
  }

  Future<void> logout() async {
    await _api.setToken(null);
    _currentUser = null;
    notifyListeners();
  }
}

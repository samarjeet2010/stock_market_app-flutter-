import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:untitled_5/models/user_model.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  static const String _userKey = 'current_user';
  static const String _usersKey = 'all_users';

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
      }
    } catch (e) {
      debugPrint('Failed to initialize auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);

      if (usersJson == null) return false;

      final usersList = List<Map<String, dynamic>>.from(jsonDecode(usersJson));
      final userMap = usersList.firstWhere(
            (u) => u['email'] == email && u['password'] == password,
        orElse: () => {},
      );

      if (userMap.isEmpty) return false;

      userMap.remove('password');
      _currentUser = UserModel.fromJson(userMap);
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> signup(String email, String password, String name, String riskProfile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_usersKey);
      final usersList = usersJson != null ? List<Map<String, dynamic>>.from(jsonDecode(usersJson)) : [];

      if (usersList.any((u) => u['email'] == email)) {
        return false;
      }

      final newUser = UserModel(
        userId: const Uuid().v4(),
        email: email,
        name: name,
        virtualBalance: 100000.0,
        riskProfile: riskProfile,
        avatarData: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final userMap = newUser.toJson();
      userMap['password'] = password;
      usersList.add(userMap);

      await prefs.setString(_usersKey, jsonEncode(usersList));

      userMap.remove('password');
      _currentUser = UserModel.fromJson(userMap);
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Signup error: $e');
      return false;
    }
  }

  Future<void> updateBalance(double newBalance) async {
    if (_currentUser == null) return;

    try {
      _currentUser = _currentUser!.copyWith(
        virtualBalance: newBalance,
        updatedAt: DateTime.now(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));

      final usersJson = prefs.getString(_usersKey);
      if (usersJson != null) {
        final usersList = List<Map<String, dynamic>>.from(jsonDecode(usersJson));
        final index = usersList.indexWhere((u) => u['userId'] == _currentUser!.userId);
        if (index != -1) {
          final password = usersList[index]['password'];
          usersList[index] = _currentUser!.toJson();
          usersList[index]['password'] = password;
          await prefs.setString(_usersKey, jsonEncode(usersList));
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Update balance error: $e');
    }
  }

  Future<void> updateProfile({String? name, String? riskProfile}) async {
    if (_currentUser == null) return;
    try {
      _currentUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        riskProfile: riskProfile ?? _currentUser!.riskProfile,
        updatedAt: DateTime.now(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));

      final usersJson = prefs.getString(_usersKey);
      if (usersJson != null) {
        final usersList = List<Map<String, dynamic>>.from(jsonDecode(usersJson));
        final index = usersList.indexWhere((u) => u['userId'] == _currentUser!.userId);
        if (index != -1) {
          final password = usersList[index]['password'];
          usersList[index] = _currentUser!.toJson();
          usersList[index]['password'] = password;
          await prefs.setString(_usersKey, jsonEncode(usersList));
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Update profile error: $e');
    }
  }

  Future<void> updateAvatar(String? avatarData) async {
    if (_currentUser == null) return;
    try {
      _currentUser = _currentUser!.copyWith(
        avatarData: avatarData,
        updatedAt: DateTime.now(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));

      final usersJson = prefs.getString(_usersKey);
      if (usersJson != null) {
        final usersList = List<Map<String, dynamic>>.from(jsonDecode(usersJson));
        final index = usersList.indexWhere((u) => u['userId'] == _currentUser!.userId);
        if (index != -1) {
          final password = usersList[index]['password'];
          usersList[index] = _currentUser!.toJson();
          usersList[index]['password'] = password;
          await prefs.setString(_usersKey, jsonEncode(usersList));
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Update avatar error: $e');
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Thin HTTP client used by every service to talk to the MarketSage backend.
///
/// Change [baseUrl] if your backend isn't running on localhost:3000, or set
/// it at runtime via [ApiClient.overrideBaseUrl] (e.g. from a settings screen).
class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();

  static const String _tokenKey = 'auth_token';
  String? _token;
  String? _baseUrlOverride;

  /// Default backend base URL per platform.
  /// - Android emulator can't reach "localhost" on the host machine, so it
  ///   uses the special 10.0.2.2 alias instead.
  /// - iOS simulator / web / desktop can use localhost directly.
  /// Update this if you deploy the backend somewhere else (e.g. a real host
  /// or a cloud URL), or call [overrideBaseUrl].
  String get baseUrl {
    if (_baseUrlOverride != null) return _baseUrlOverride!;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'https://stock-market-app-flutter.onrender.com/';
    }
    return 'https://stock-market-app-flutter.onrender.com/';
  }

  void overrideBaseUrl(String url) {
    _baseUrlOverride = url;
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  bool get hasToken => _token != null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<ApiResponse> get(String path) async {
    try {
      final resp = await http.get(Uri.parse('$baseUrl$path'), headers: _headers);
      return _handle(resp);
    } catch (e) {
      return ApiResponse(ok: false, statusCode: 0, data: {'error': 'Network error: $e'});
    }
  }

  Future<ApiResponse> post(String path, [Map<String, dynamic>? body]) async {
    try {
      final resp = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body ?? {}),
      );
      return _handle(resp);
    } catch (e) {
      return ApiResponse(ok: false, statusCode: 0, data: {'error': 'Network error: $e'});
    }
  }

  Future<ApiResponse> put(String path, [Map<String, dynamic>? body]) async {
    try {
      final resp = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body ?? {}),
      );
      return _handle(resp);
    } catch (e) {
      return ApiResponse(ok: false, statusCode: 0, data: {'error': 'Network error: $e'});
    }
  }

  Future<ApiResponse> delete(String path) async {
    try {
      final resp = await http.delete(Uri.parse('$baseUrl$path'), headers: _headers);
      return _handle(resp);
    } catch (e) {
      return ApiResponse(ok: false, statusCode: 0, data: {'error': 'Network error: $e'});
    }
  }

  ApiResponse _handle(http.Response resp) {
    Map<String, dynamic> data = {};
    try {
      if (resp.body.isNotEmpty) {
        data = jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {
      data = {'error': 'Invalid response from server'};
    }
    final ok = resp.statusCode >= 200 && resp.statusCode < 300;
    return ApiResponse(ok: ok, statusCode: resp.statusCode, data: data);
  }
}

class ApiResponse {
  final bool ok;
  final int statusCode;
  final Map<String, dynamic> data;

  ApiResponse({required this.ok, required this.statusCode, required this.data});

  String get errorMessage => (data['error'] ?? data['message'] ?? 'Something went wrong').toString();
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

const _tokenKey = 'ketta_admin_token';

class ApiService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String? _token;

  String? get token => _token;

  ApiService() {
    _token = _prefs?.getString(_tokenKey);
  }

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> setToken(String token) async {
    _token = token;
    await _ensurePrefs();
    await _prefs!.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    await _ensurePrefs();
    await _prefs!.remove(_tokenKey);
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}$path'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getList(String path) async {
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}$path'),
      headers: _headers,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    throw Exception(response.body);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${AppConstants.apiUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('${AppConstants.apiUrl}$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.apiUrl}$path'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {'message': 'ok'};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    throw Exception(body['error'] ?? 'Request failed');
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

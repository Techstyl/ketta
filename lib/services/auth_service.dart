import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api;

  AuthService(this._api);

  Future<AppUser> signUp(String username, String password, String userType,
      {String? fullName, String? phone, String? location}) async {
    final data = await _api.post('/auth/register', {
      'username': username,
      'password': password,
      'userType': userType,
      if (fullName != null) 'fullName': fullName,
      if (phone != null) 'phone': phone,
      if (location != null) 'location': location,
    });
    await _api.setToken(data['token'] as String);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> login(String username, String password) async {
    final data = await _api.post('/auth/login', {
      'username': username,
      'password': password,
    });
    await _api.setToken(data['token'] as String);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _api.clearToken();
  }

  Future<AppUser?> getCurrentUser() async {
    try {
      final data = await _api.get('/auth/me');
      return AppUser.fromJson(data);
    } catch (e) {
      return null;
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final api = ref.read(apiServiceProvider);
  return AuthService(api);
});

final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final authService = ref.read(authServiceProvider);
  return authService.getCurrentUser();
});

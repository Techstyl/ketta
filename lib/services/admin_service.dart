import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';
import '../models/user.dart';

class AdminService {
  final ApiService _api;

  AdminService(this._api);

  Future<void> setShutdown(bool value, {String message = ''}) async {
    await _api.post('/admin/shutdown', {'value': value, 'message': message});
  }

  Future<bool> isShutdown() async {
    try {
      final data = await _api.get('/admin/shutdown');
      return data['value'] == true || data['value'] == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<String> getShutdownMessage() async {
    try {
      final data = await _api.get('/admin/shutdown');
      return data['message'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> setForceUpdate(String version) async {
    await _api.post('/admin/force-update', {'version': version});
  }

  Future<String?> getForceUpdateVersion() async {
    try {
      final data = await _api.get('/admin/force-update');
      return data['version'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<List<AppUser>> getAllUsers() async {
    final data = await _api.getList('/admin/users');
    return data.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteUser(String userId) async {
    await _api.delete('/admin/users/$userId');
  }
}

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(ref.read(apiServiceProvider));
});

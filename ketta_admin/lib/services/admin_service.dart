import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';
import '../models/user.dart';
import '../models/product.dart';

class AdminService {
  final ApiService _api;

  AdminService(this._api);

  Future<Map<String, dynamic>> login(String username, String password) async {
    final data = await _api.post('/auth/login', {'username': username, 'password': password});
    return data;
  }

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

  Future<Map<String, int>> getStats() async {
    final data = await _api.get('/admin/stats');
    return {
      'users': data['users'] as int? ?? 0,
      'products': data['products'] as int? ?? 0,
      'active': data['active'] as int? ?? 0,
      'sold': data['sold'] as int? ?? 0,
      'inquiries': data['inquiries'] as int? ?? 0,
    };
  }

  Future<List<AppUser>> getAllUsers() async {
    final data = await _api.getList('/admin/users');
    return data.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteUser(String userId) async {
    await _api.delete('/admin/users/$userId');
  }

  Future<List<Product>> getAllProducts() async {
    final data = await _api.getList('/admin/products');
    return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteProduct(String productId) async {
    await _api.delete('/admin/products/$productId');
  }
}

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(ref.read(apiServiceProvider));
});

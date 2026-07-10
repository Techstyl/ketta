import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _api;

  ProductService(this._api);

  Future<List<Product>> getProducts({String? category, String? search}) async {
    final params = <String>[];
    if (category != null) params.add('category=$category');
    if (search != null && search.isNotEmpty) params.add('search=${Uri.encodeComponent(search)}');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final data = await _api.getList('/products$query');
    return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Product>> getMyProducts() async {
    final data = await _api.getList('/products/my');
    return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createProduct(Map<String, dynamic> productData, {List<Map<String, dynamic>>? images}) async {
    if (images != null && images.isNotEmpty) {
      final fields = productData.map((k, v) => MapEntry(k, v is List ? jsonEncode(v) : v.toString()));
      await _api.postMultipart('/products', fields, files: images);
    } else {
      await _api.post('/products', productData);
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> updates, {List<Map<String, dynamic>>? images}) async {
    if (images != null && images.isNotEmpty) {
      final fields = updates.map((k, v) => MapEntry(k, v is List ? jsonEncode(v) : v.toString()));
      await _api.putMultipart('/products/$id', fields, files: images);
    } else {
      await _api.put('/products/$id', updates);
    }
  }

  Future<void> deleteProduct(String id) async {
    await _api.delete('/products/$id');
  }

  Future<int> getProductCount() async {
    final products = await getMyProducts();
    return products.length;
  }

  Future<int> getActiveCount() async {
    final products = await getMyProducts();
    return products.where((p) => p.status == 'active').length;
  }

  Future<int> getSoldCount() async {
    final products = await getMyProducts();
    return products.where((p) => p.status == 'sold').length;
  }

  Future<void> markAsSold(String productId) async {
    await _api.put('/products/$productId/sold', {});
  }

}

final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService(ref.read(apiServiceProvider));
});
final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  return ref.read(productServiceProvider).getProducts();
});

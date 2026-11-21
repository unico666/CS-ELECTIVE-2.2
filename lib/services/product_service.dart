import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors.dart';
import '../models/product.dart';

class ProductService {
  ProductService(this._client);

  final SupabaseClient _client;

  Future<List<Product>> fetchAll() async {
    final rows = await _client
        .from('products')
        .select('*, categories(name)')
        .order('name');
    return rows.map<Product>((row) => Product.fromMap(row)).toList();
  }

  Future<void> create(Map<String, dynamic> data) async {
    await _client.from('products').insert(data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    final rows = await _client.from('products').update(data).eq('id', id).select();
    if (rows.isEmpty) {
      throw const AppException('Update was not applied.', permissionDenied: true);
    }
  }

  Future<void> delete(String id) async {
    final rows = await _client.from('products').delete().eq('id', id).select();
    if (rows.isEmpty) {
      throw const AppException('Delete was not applied.', permissionDenied: true);
    }
  }
}

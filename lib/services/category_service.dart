import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors.dart';
import '../models/category.dart';

class CategoryService {
  CategoryService(this._client);

  final SupabaseClient _client;

  Future<List<Category>> fetchAll() async {
    final rows = await _client.from('categories').select().order('name');
    return rows.map<Category>((row) => Category.fromMap(row)).toList();
  }

  Future<void> create(String name) async {
    await _client.from('categories').insert({'name': name});
  }

  Future<void> update(int id, String name) async {
    final rows = await _client
        .from('categories')
        .update({'name': name})
        .eq('id', id)
        .select();
    if (rows.isEmpty) {
      throw const AppException('Update was not applied.', permissionDenied: true);
    }
  }

  Future<void> delete(int id) async {
    final rows = await _client.from('categories').delete().eq('id', id).select();
    if (rows.isEmpty) {
      throw const AppException('Delete was not applied.', permissionDenied: true);
    }
  }
}

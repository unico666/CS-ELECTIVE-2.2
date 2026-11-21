import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors.dart';
import '../models/app_order.dart';
import '../models/cart_item.dart';

class OrderService {
  OrderService(this._client);

  final SupabaseClient _client;

  Future<PlacedOrder> placeOrder(List<CartItem> items) async {
    final result = await _client.rpc('place_order', params: {
      'items': items
          .map((item) => {
                'product_id': item.product.id,
                'quantity': item.quantity,
              })
          .toList(),
    });
    final map = Map<String, dynamic>.from(result as Map);
    return PlacedOrder(
      orderId: (map['order_id'] as num).toInt(),
      total: (map['total'] as num).toDouble(),
    );
  }

  Future<List<AppOrder>> fetchMine(String userId) async {
    final rows = await _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return rows.map<AppOrder>((row) => AppOrder.fromMap(row)).toList();
  }

  Future<List<AppOrder>> fetchAll() async {
    final rows = await _client
        .from('orders')
        .select('*, profiles(email), order_items(*)')
        .order('created_at', ascending: false);
    return rows.map<AppOrder>((row) => AppOrder.fromMap(row)).toList();
  }

  Future<void> updateStatus(int orderId, String status) async {
    final rows = await _client
        .from('orders')
        .update({'status': status})
        .eq('id', orderId)
        .select();
    if (rows.isEmpty) {
      throw const AppException('Update was not applied.', permissionDenied: true);
    }
  }
}

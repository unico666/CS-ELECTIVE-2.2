import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_order.dart';
import 'auth_providers.dart';
import 'service_providers.dart';

final myOrdersProvider = FutureProvider.autoDispose<List<AppOrder>>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId == null) return const [];
  return ref.watch(orderServiceProvider).fetchMine(userId);
});

final allOrdersProvider = FutureProvider.autoDispose<List<AppOrder>>((ref) {
  ref.watch(userIdProvider);
  return ref.watch(orderServiceProvider).fetchAll();
});

class OrderActions {
  OrderActions(this._ref);

  final Ref _ref;

  Future<void> updateStatus(int orderId, String status) async {
    await _ref.read(orderServiceProvider).updateStatus(orderId, status);
    _ref.invalidate(allOrdersProvider);
  }
}

final orderActionsProvider = Provider<OrderActions>((ref) {
  return OrderActions(ref);
});

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_order.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import 'auth_providers.dart';
import 'order_providers.dart';
import 'product_providers.dart';
import 'service_providers.dart';

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    ref.watch(userIdProvider);
    return const [];
  }

  String? add(Product product) {
    if (product.stock <= 0) return '${product.name} is out of stock';
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      state = [...state, CartItem(product: product, quantity: 1)];
      return null;
    }
    return setQuantity(product.id, state[index].quantity + 1);
  }

  String? setQuantity(String productId, int quantity) {
    final index = state.indexWhere((item) => item.product.id == productId);
    if (index == -1) return null;
    final item = state[index];
    if (quantity <= 0) {
      remove(productId);
      return null;
    }
    if (quantity > item.product.stock) {
      return 'Only ${item.product.stock} of ${item.product.name} available';
    }
    final updated = [...state];
    updated[index] = item.copyWith(quantity: quantity);
    state = updated;
    return null;
  }

  void remove(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clear() {
    state = const [];
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, item) => sum + item.quantity);
});

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).fold(0.0, (sum, item) => sum + item.lineTotal);
});

class CheckoutController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<PlacedOrder> checkout() async {
    final items = ref.read(cartProvider);
    state = const AsyncLoading();
    try {
      final placed = await ref.read(orderServiceProvider).placeOrder(items);
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(productsProvider);
      ref.invalidate(myOrdersProvider);
      state = const AsyncData(null);
      return placed;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final checkoutProvider = AsyncNotifierProvider<CheckoutController, void>(
  CheckoutController.new,
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/category.dart';
import '../models/product.dart';
import 'auth_providers.dart';
import 'service_providers.dart';

enum ProductSort { nameAsc, priceLow, priceHigh }

final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) {
  ref.watch(userIdProvider);
  return ref.watch(productServiceProvider).fetchAll();
});

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) {
  ref.watch(userIdProvider);
  return ref.watch(categoryServiceProvider).fetchAll();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final selectedCategoryProvider = StateProvider<int?>((ref) => null);

final inStockOnlyProvider = StateProvider<bool>((ref) => false);

final sortProvider = StateProvider<ProductSort>((ref) => ProductSort.nameAsc);

final filteredProductsProvider =
    Provider.autoDispose<AsyncValue<List<Product>>>((ref) {
  final products = ref.watch(productsProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final categoryId = ref.watch(selectedCategoryProvider);
  final inStockOnly = ref.watch(inStockOnlyProvider);
  final sort = ref.watch(sortProvider);

  return products.whenData((list) {
    final result = list.where((product) {
      if (query.isNotEmpty && !product.name.toLowerCase().contains(query)) {
        return false;
      }
      if (categoryId != null && product.categoryId != categoryId) return false;
      if (inStockOnly && !product.inStock) return false;
      return true;
    }).toList();

    switch (sort) {
      case ProductSort.nameAsc:
        result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case ProductSort.priceLow:
        result.sort((a, b) => a.price.compareTo(b.price));
      case ProductSort.priceHigh:
        result.sort((a, b) => b.price.compareTo(a.price));
    }
    return result;
  });
});

class ProductActions {
  ProductActions(this._ref);

  final Ref _ref;

  Future<void> save({
    String? id,
    required Map<String, dynamic> data,
    XFile? image,
  }) async {
    final payload = Map<String, dynamic>.from(data);
    if (image != null) {
      payload['image_url'] =
          await _ref.read(storageServiceProvider).uploadProductImage(image);
    }
    final service = _ref.read(productServiceProvider);
    if (id == null) {
      await service.create(payload);
    } else {
      await service.update(id, payload);
    }
    _ref.invalidate(productsProvider);
  }

  Future<void> delete(String id) async {
    await _ref.read(productServiceProvider).delete(id);
    _ref.invalidate(productsProvider);
  }
}

final productActionsProvider = Provider<ProductActions>((ref) {
  return ProductActions(ref);
});

class CategoryActions {
  CategoryActions(this._ref);

  final Ref _ref;

  Future<void> create(String name) async {
    await _ref.read(categoryServiceProvider).create(name);
    _ref.invalidate(categoriesProvider);
  }

  Future<void> rename(int id, String name) async {
    await _ref.read(categoryServiceProvider).update(id, name);
    _ref.invalidate(categoriesProvider);
    _ref.invalidate(productsProvider);
  }

  Future<void> delete(int id) async {
    await _ref.read(categoryServiceProvider).delete(id);
    if (_ref.read(selectedCategoryProvider) == id) {
      _ref.read(selectedCategoryProvider.notifier).state = null;
    }
    _ref.invalidate(categoriesProvider);
    _ref.invalidate(productsProvider);
  }
}

final categoryActionsProvider = Provider<CategoryActions>((ref) {
  return CategoryActions(ref);
});

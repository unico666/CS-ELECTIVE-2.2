import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../providers/product_providers.dart';
import '../widgets/product_card.dart';
import '../widgets/state_views.dart';

class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({super.key, required this.isAdmin});

  final bool isAdmin;

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _sortLabel(ProductSort sort) {
    switch (sort) {
      case ProductSort.nameAsc:
        return 'Name (A-Z)';
      case ProductSort.priceLow:
        return 'Price: low to high';
      case ProductSort.priceHigh:
        return 'Price: high to low';
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(filteredProductsProvider);
    final categories = ref.watch(categoriesProvider);
    final selected = ref.watch(selectedCategoryProvider);
    final inStockOnly = ref.watch(inStockOnlyProvider);
    final sort = ref.watch(sortProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: 'Search products',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                        setState(() {});
                      },
                    ),
            ),
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value;
              setState(() {});
            },
          ),
        ),
        categories.maybeWhen(
          data: (list) => SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: selected == null,
                    onSelected: (_) =>
                        ref.read(selectedCategoryProvider.notifier).state = null,
                  ),
                ),
                for (final category in list)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(category.name),
                      selected: selected == category.id,
                      onSelected: (_) => ref
                          .read(selectedCategoryProvider.notifier)
                          .state = category.id,
                    ),
                  ),
              ],
            ),
          ),
          orElse: () => const SizedBox(height: 44),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              FilterChip(
                label: const Text('In stock only'),
                selected: inStockOnly,
                onSelected: (value) =>
                    ref.read(inStockOnlyProvider.notifier).state = value,
              ),
              const Spacer(),
              PopupMenuButton<ProductSort>(
                tooltip: 'Sort',
                initialValue: sort,
                onSelected: (value) => ref.read(sortProvider.notifier).state = value,
                itemBuilder: (_) => [
                  for (final option in ProductSort.values)
                    PopupMenuItem(value: option, child: Text(_sortLabel(option))),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sort, size: 20),
                      const SizedBox(width: 4),
                      Text(_sortLabel(sort)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(productsProvider);
              ref.invalidate(categoriesProvider);
              await ref.read(productsProvider.future);
            },
            child: AsyncValueView<List<Product>>(
              value: products,
              onRetry: () => ref.invalidate(productsProvider),
              emptyMessage: 'No products match your filters.',
              emptyIcon: Icons.search_off,
              builder: (list) => ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(top: 4, bottom: 88),
                itemCount: list.length,
                itemBuilder: (_, index) =>
                    ProductCard(product: list[index], isAdmin: widget.isAdmin),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

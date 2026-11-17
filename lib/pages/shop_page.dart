import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: Column(
        children: [
          // ---------- PRICE SLIDER ----------
          if (p.maxPrice > p.minPrice)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price: ₱${p.previewRange.start.round()} - ₱${p.previewRange.end.round()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RangeSlider(
                    min: p.minPrice,
                    max: p.maxPrice,
                    values: p.previewRange,
                    labels: RangeLabels(
                      '₱${p.previewRange.start.round()}',
                      '₱${p.previewRange.end.round()}',
                    ),
                    onChanged: (v) =>
                        context.read<ProductProvider>().updatePreview(v),
                    onChangeEnd: (v) =>
                        context.read<ProductProvider>().applyPriceFilter(v),
                  ),
                ],
              ),
            ),

          // ---------- PRODUCT GRID ----------
          Expanded(
            child: p.isLoading
                ? const Center(child: CircularProgressIndicator())
                : p.error != null
                ? Center(child: Text('Error: ${p.error}'))
                : p.products.isEmpty
                ? const Center(child: Text('No products in this price range'))
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: p.products.length,
                    itemBuilder: (context, i) {
                      final item = p.products[i];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: item.imageUrl != null
                                  ? Image.network(
                                      item.imageUrl!,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.image_not_supported),
                                    )
                                  : const Center(
                                      child: Icon(Icons.shopping_bag),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text('₱${item.price.toStringAsFixed(2)}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // ---------- PAGINATION CONTROLS ----------
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: p.hasPrev && !p.isLoading
                      ? () => context.read<ProductProvider>().prevPage()
                      : null,
                ),
                Text('Page ${p.currentPage + 1} of ${p.totalPages}'),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: p.hasNext && !p.isLoading
                      ? () => context.read<ProductProvider>().nextPage()
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

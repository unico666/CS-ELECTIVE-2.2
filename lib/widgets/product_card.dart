import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors.dart';
import '../core/ui.dart';
import '../models/product.dart';
import '../pages/product_form_page.dart';
import '../providers/cart_provider.dart';
import '../providers/product_providers.dart';

class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product, required this.isAdmin});

  final Product product;
  final bool isAdmin;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(productActionsProvider).delete(product.id);
      if (context.mounted) showMessage(context, '"${product.name}" deleted');
    } catch (error) {
      if (context.mounted) showMessage(context, friendlyError(error));
    }
  }

  void _addToCart(BuildContext context, WidgetRef ref) {
    final problem = ref.read(cartProvider.notifier).add(product);
    showMessage(context, problem ?? '${product.name} added to cart');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final image = product.imageUrl == null
        ? Container(
            color: scheme.surfaceContainerHighest,
            child: Icon(Icons.local_cafe_outlined, size: 40, color: scheme.outline),
          )
        : Image.network(
            product.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: scheme.surfaceContainerHighest,
              child: Icon(Icons.broken_image_outlined, color: scheme.outline),
            ),
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 130),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 110, child: image),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (product.categoryName != null)
                        Text(
                          product.categoryName!,
                          style: theme.textTheme.bodySmall?.copyWith(color: scheme.primary),
                        ),
                      if ((product.description ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            product.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            formatMoney(product.price),
                            style: theme.textTheme.titleMedium?.copyWith(color: scheme.primary),
                          ),
                          const Spacer(),
                          Text(
                            product.inStock ? '${product.stock} in stock' : 'Out of stock',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: product.inStock ? scheme.outline : scheme.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (isAdmin)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProductFormPage(product: product),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: Icon(Icons.delete_outline, color: scheme.error),
                              onPressed: () => _confirmDelete(context, ref),
                            ),
                          ],
                        )
                      else
                        FilledButton.icon(
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                          onPressed: product.inStock ? () => _addToCart(context, ref) : null,
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Add to cart'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

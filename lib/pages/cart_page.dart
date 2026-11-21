import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors.dart';
import '../core/ui.dart';
import '../providers/cart_provider.dart';
import '../widgets/state_views.dart';
import 'checkout_confirmation_page.dart';

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    try {
      final placed = await ref.read(checkoutProvider.notifier).checkout();
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CheckoutConfirmationPage(order: placed),
        ),
      );
    } catch (error) {
      if (context.mounted) showMessage(context, friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final count = ref.watch(cartCountProvider);
    final total = ref.watch(cartTotalProvider);
    final checkingOut = ref.watch(checkoutProvider).isLoading;
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return const EmptyView(
        message: 'Your cart is empty. Add something from the menu.',
        icon: Icons.shopping_cart_outlined,
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final item = items[index];
              final product = item.product;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name, style: theme.textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text('${formatMoney(product.price)} each'),
                            const SizedBox(height: 2),
                            Text(
                              formatMoney(item.lineTotal),
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Decrease',
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => ref
                            .read(cartProvider.notifier)
                            .setQuantity(product.id, item.quantity - 1),
                      ),
                      Text('${item.quantity}', style: theme.textTheme.titleMedium),
                      IconButton(
                        tooltip: 'Increase',
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: item.quantity >= product.stock
                            ? null
                            : () {
                                final problem = ref
                                    .read(cartProvider.notifier)
                                    .setQuantity(product.id, item.quantity + 1);
                                if (problem != null) showMessage(context, problem);
                              },
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                        onPressed: () =>
                            ref.read(cartProvider.notifier).remove(product.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Items'),
                    Text('$count'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: theme.textTheme.titleLarge),
                    Text(formatMoney(total), style: theme.textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: checkingOut ? null : () => _checkout(context, ref),
                  icon: checkingOut
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Checkout'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

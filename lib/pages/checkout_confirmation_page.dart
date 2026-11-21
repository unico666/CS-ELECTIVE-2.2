import 'package:flutter/material.dart';

import '../core/ui.dart';
import '../models/app_order.dart';

class CheckoutConfirmationPage extends StatelessWidget {
  const CheckoutConfirmationPage({super.key, required this.order});

  final PlacedOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 96, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text('Order placed!', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Order #${order.orderId}', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Total paid: ${formatMoney(order.total)}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Back to menu'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

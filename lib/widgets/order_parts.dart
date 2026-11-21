import 'package:flutter/material.dart';

import '../core/ui.dart';
import '../models/app_order.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color background;
    Color foreground;
    switch (status) {
      case 'done':
        background = scheme.primaryContainer;
        foreground = scheme.onPrimaryContainer;
      case 'cancelled':
        background = scheme.errorContainer;
        foreground = scheme.onErrorContainer;
      default:
        background = scheme.tertiaryContainer;
        foreground = scheme.onTertiaryContainer;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class OrderItemsList extends StatelessWidget {
  const OrderItemsList({super.key, required this.items});

  final List<OrderItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(child: Text('${item.quantity} × ${item.productName}')),
                Text(formatMoney(item.unitPrice * item.quantity)),
              ],
            ),
          ),
      ],
    );
  }
}

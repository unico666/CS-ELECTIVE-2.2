import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ui.dart';
import '../models/app_order.dart';
import '../providers/order_providers.dart';
import '../widgets/order_parts.dart';
import '../widgets/state_views.dart';

class OrderHistoryPage extends ConsumerWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myOrdersProvider);
        await ref.read(myOrdersProvider.future);
      },
      child: AsyncValueView<List<AppOrder>>(
        value: orders,
        onRetry: () => ref.invalidate(myOrdersProvider),
        emptyMessage: 'You have not placed any orders yet.',
        emptyIcon: Icons.receipt_long_outlined,
        builder: (list) => ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, index) {
            final order = list[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                shape: const Border(),
                title: Row(
                  children: [
                    Expanded(child: Text('Order #${order.id}')),
                    StatusChip(status: order.status),
                  ],
                ),
                subtitle: Text('${formatDate(order.createdAt)} · ${formatMoney(order.total)}'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [OrderItemsList(items: order.items)],
              ),
            );
          },
        ),
      ),
    );
  }
}

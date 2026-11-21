import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors.dart';
import '../core/ui.dart';
import '../models/app_order.dart';
import '../providers/order_providers.dart';
import '../widgets/order_parts.dart';
import '../widgets/state_views.dart';

class AdminOrdersPage extends ConsumerWidget {
  const AdminOrdersPage({super.key});

  static const _statuses = ['pending', 'done', 'cancelled'];

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    AppOrder order,
    String status,
  ) async {
    try {
      await ref.read(orderActionsProvider).updateStatus(order.id, status);
      if (context.mounted) showMessage(context, 'Order #${order.id} marked $status');
    } catch (error) {
      if (context.mounted) showMessage(context, friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(allOrdersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allOrdersProvider);
        await ref.read(allOrdersProvider.future);
      },
      child: AsyncValueView<List<AppOrder>>(
        value: orders,
        onRetry: () => ref.invalidate(allOrdersProvider),
        emptyMessage: 'No orders have been placed yet.',
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
                subtitle: Text(
                  '${order.customerEmail ?? 'Unknown customer'}\n'
                  '${formatDate(order.createdAt)} · ${formatMoney(order.total)}',
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [
                  OrderItemsList(items: order.items),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Status'),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: order.status,
                        items: [
                          for (final status in _statuses)
                            DropdownMenuItem(value: status, child: Text(status)),
                        ],
                        onChanged: (value) {
                          if (value != null && value != order.status) {
                            _changeStatus(context, ref, order, value);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

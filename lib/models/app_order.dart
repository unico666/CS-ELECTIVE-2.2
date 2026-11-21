class OrderItem {
  const OrderItem({
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  final String productName;
  final double unitPrice;
  final int quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productName: map['product_name'] as String,
      unitPrice: (map['unit_price'] as num).toDouble(),
      quantity: (map['quantity'] as num).toInt(),
    );
  }
}

class AppOrder {
  const AppOrder({
    required this.id,
    required this.userId,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.items,
    this.customerEmail,
  });

  final int id;
  final String userId;
  final double total;
  final String status;
  final DateTime createdAt;
  final List<OrderItem> items;
  final String? customerEmail;

  factory AppOrder.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map?;
    final rawItems = (map['order_items'] as List?) ?? const [];
    return AppOrder(
      id: (map['id'] as num).toInt(),
      userId: map['user_id'] as String,
      total: (map['total'] as num).toDouble(),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      customerEmail: profile?['email'] as String?,
      items: rawItems
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class PlacedOrder {
  const PlacedOrder({required this.orderId, required this.total});

  final int orderId;
  final double total;
}

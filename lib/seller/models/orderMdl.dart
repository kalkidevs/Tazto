// lib/models/order.dart
enum OrderStatus { pending, confirmed, shipped, delivered }

class Order {
  final String id;
  final String storeId;
  final String productId;
  final int quantity;
  final DateTime orderDate;
  final OrderStatus status;

  Order({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.quantity,
    required this.orderDate,
    required this.status,
  });
}

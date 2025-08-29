// lib/models/order.dart
import 'package:tazto/customer/models/cart_itemMdl.dart';

enum OrderStatus { pending, confirmed, shipped, delivered }

class Order {
  final String id;
  final List<CartItem> items;
  final double total;
  final DateTime date;
  OrderStatus status;

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.date,
    this.status = OrderStatus.pending,
  });
}

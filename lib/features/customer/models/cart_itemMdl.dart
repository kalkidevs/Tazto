// lib/models/cart_item.dart

import 'package:tazto/features/customer/models/customer_product_model.dart';

class CartItem {
  final String id;
  final CustomerProduct product;
  int quantity;

  CartItem({required this.id, required this.product, this.quantity = 1});
}

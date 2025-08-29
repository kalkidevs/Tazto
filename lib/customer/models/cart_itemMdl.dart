// lib/models/cart_item.dart
import 'package:tazto/customer/models/productMdl.dart';

class CartItem {
  final String id;
  final Product product;
  int quantity;

  CartItem({required this.id, required this.product, this.quantity = 1});
}

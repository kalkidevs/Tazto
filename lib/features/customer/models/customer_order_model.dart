import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:tazto/features/customer/models/rating.dart';

// Ensure CartItem model is imported correctly
import 'cart_itemMdl.dart';

// Ensure Product model is imported correctly for CartItem's product
import 'customer_product_model.dart';

// Enum for Order Status (align with backend)
enum OrderStatus { pending, confirmed, shipped, delivered, cancelled }

// Helper function to safely convert String to OrderStatus enum
OrderStatus _parseOrderStatus(String? statusString) {
  statusString = statusString
      ?.toLowerCase(); // Make comparison case-insensitive
  switch (statusString) {
    case 'pending':
      return OrderStatus.pending;
    case 'confirmed':
      return OrderStatus.confirmed;
    case 'shipped':
      return OrderStatus.shipped;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.pending; // Default fallback
  }
}

class CustomerOrder {
  final String id; // Use 'id' to match backend response (_id)
  final List<CartItem> items; // Keep using CartItem locally for consistency
  final double totalAmount; // Match backend field name
  final DateTime orderDate; // Match backend field name
  final OrderStatus status;

  // Add address and payment details if needed
  final Map<String, dynamic>? shippingAddress; // Store address map as received
  final String? paymentMethod;

  CustomerOrder({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
    this.shippingAddress,
    this.paymentMethod,
  });

  // Factory constructor to parse JSON from the backend
  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    // Parse items list
    List<CartItem> parsedItems = [];
    if (json['items'] is List) {
      parsedItems = (json['items'] as List)
          .map((itemJson) {
            try {
              if (itemJson is! Map<String, dynamic>) return null;

              CustomerProduct product;

              // --- ROBUST PARSING LOGIC ---
              // Check if productId is a fully populated Map (Backend populate worked)
              if (itemJson['productId'] is Map<String, dynamic>) {
                product = CustomerProduct.fromJson(
                  itemJson['productId'] as Map<String, dynamic>,
                );
              } else {
                // FALLBACK: productId is a String (or null), meaning populate failed
                // or product was deleted. We reconstruct a temporary product object
                // using the snapshot data (title, price) stored in the order item.
                final String pId = itemJson['productId'] is String
                    ? itemJson['productId']
                    : 'unknown_id';

                final String pTitle = itemJson['title'] ?? 'Unknown Product';
                final double pPrice =
                    (itemJson['price'] as num?)?.toDouble() ?? 0.0;

                product = CustomerProduct(
                  id: pId,
                  storeId: '',
                  // Not available in snapshot, leave empty
                  title: pTitle,
                  price: pPrice,
                  description: 'Product details unavailable',
                  category: 'Uncategorized',
                  stock: 0,
                  rating: Rating(rate: 0, count: 0),
                  imageURL: null, // Image likely lost if product deleted
                );
              }

              final quantity = itemJson['quantity'] as int? ?? 1;

              // Create a unique ID for the CartItem (UI key purposes)
              final cartItemId =
                  product.id + DateTime.now().microsecondsSinceEpoch.toString();

              return CartItem(
                id: cartItemId,
                product: product,
                quantity: quantity,
              );
            } catch (e) {
              debugPrint("Error parsing order item: $itemJson - Error: $e");
              return null; // Skip invalid items
            }
          })
          .whereType<CartItem>()
          .toList();
    }

    // Parse date safely
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(
        json['orderDate'] ??
            json['createdAt'] ??
            DateTime.now().toIso8601String(),
      );
    } catch (_) {
      parsedDate = DateTime.now(); // Fallback to current time if parsing fails
    }

    return CustomerOrder(
      id: json['_id'] as String? ?? '',
      items: parsedItems,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      orderDate: parsedDate,
      status: _parseOrderStatus(json['status'] as String?),
      shippingAddress: json['shippingAddress'] as Map<String, dynamic>?,
      paymentMethod: json['paymentMethod'] as String?,
    );
  }

  // Optional: Helper method to format date nicely
  String get formattedOrderDate {
    return '${orderDate.day}/${orderDate.month}/${orderDate.year}';
  }

  // Optional: Helper method to get total items count
  int get totalItemsCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }
}

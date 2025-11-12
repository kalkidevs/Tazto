// Based on the backend Order.js model
class SellerOrder {
  final String id;
  final String userId; // Customer's ID
  final String storeId;
  final List<OrderItem> items;
  final double totalAmount;
  final ShippingAddress shippingAddress;
  final String paymentMethod;
  final String status; // 'Pending', 'Confirmed', 'Shipped', 'Delivered', 'Cancelled'
  final DateTime orderDate;

  // UI-specific additions (not from backend model)
  final String customerName;

  SellerOrder({
    required this.id,
    required this.userId,
    required this.storeId,
    required this.items,
    required this.totalAmount,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.status,
    required this.orderDate,
    this.customerName = 'N/A', // Default value
  });

  factory SellerOrder.fromJson(Map<String, dynamic> json) {
    // Parse customer info (if populated)
    String custName = 'N/A';
    if (json['userId'] is Map<String, dynamic>) {
      custName = (json['userId'] as Map<String, dynamic>)['name'] as String? ?? 'N/A';
    }

    return SellerOrder(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      userId: (json['userId'] is Map)
          ? (json['userId'] as Map<String, dynamic>)['_id'] as String? ?? ''
          : json['userId'] as String? ?? '',
      storeId: json['storeId'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      shippingAddress: ShippingAddress.fromJson(
          json['shippingAddress'] as Map<String, dynamic>? ?? {}),
      paymentMethod: json['paymentMethod'] as String? ?? 'N/A',
      status: json['status'] as String? ?? 'Pending',
      orderDate: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      customerName: custName,
    );
  }
}

class OrderItem {
  final String productId;
  final String title;
  final double price;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String? ?? '',
      title: json['title'] as String? ?? 'Product',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}

class ShippingAddress {
  final String street;
  final String city;
  final String? state;
  final String pincode;
  final String? phone;

  ShippingAddress({
    required this.street,
    required this.city,
    this.state,
    required this.pincode,
    this.phone,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      street: json['street'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String?,
      pincode: json['pincode'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }
}
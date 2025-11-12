/// Model for the seller dashboard analytics data.
class SellerAnalytics {
  final double todayRevenue;
  final double revenueChangePercent;
  final int totalOrders;
  final int newOrders;
  final int activeProducts;
  final int lowStockProducts;
  final double customerRating;
  final double ratingChange;

  SellerAnalytics({
    required this.todayRevenue,
    required this.revenueChangePercent,
    required this.totalOrders,
    required this.newOrders,
    required this.activeProducts,
    required this.lowStockProducts,
    required this.customerRating,
    required this.ratingChange,
  });

  factory SellerAnalytics.fromJson(Map<String, dynamic> json) {
    return SellerAnalytics(
      todayRevenue: (json['todayRevenue'] as num?)?.toDouble() ?? 0.0,
      revenueChangePercent:
      (json['revenueChangePercent'] as num?)?.toDouble() ?? 0.0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      newOrders: (json['newOrders'] as num?)?.toInt() ?? 0,
      activeProducts: (json['activeProducts'] as num?)?.toInt() ?? 0,
      lowStockProducts: (json['lowStockProducts'] as num?)?.toInt() ?? 0,
      customerRating: (json['customerRating'] as num?)?.toDouble() ?? 0.0,
      ratingChange: (json['ratingChange'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/features/seller/models/seller_analytics_model.dart';
import 'package:tazto/features/seller/models/seller_order_model.dart';
import 'package:tazto/features/seller/models/seller_product_model.dart';
import 'package:tazto/providers/seller_provider.dart';

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SellerProvider>();
    final analytics = provider.analytics;
    final orders = provider.orders;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            provider.fetchDashboardAnalytics(),
            provider.fetchOrders(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(provider.store?.storeName),
              const SizedBox(height: 24),
              _buildAnalyticsGrid(provider.isLoadingAnalytics, analytics),
              const SizedBox(height: 24),
              _buildLowStockAlert(analytics?.lowStockProducts ?? 0),
              const SizedBox(height: 24),
              _buildRecentOrders(provider.isLoadingOrders, orders),
              const SizedBox(height: 24),
              _buildLowStockItems(
                provider.isLoadingProducts,
                provider.products,
              ),
              // We will add Quick Actions later
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(String? storeName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, ${storeName ?? 'Partner'}!',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Here's what's happening with your store today.",
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsGrid(bool isLoading, SellerAnalytics? analytics) {
    if (isLoading && analytics == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (analytics == null) {
      return const Center(child: Text('Could not load analytics.'));
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
          title: "Today's Revenue",
          value: '₹${NumberFormat('#,##0').format(analytics.todayRevenue)}',
          change: '+${analytics.revenueChangePercent}%',
          icon: Icons.attach_money,
          color: Colors.green,
        ),
        _StatCard(
          title: 'Total Orders',
          value: analytics.totalOrders.toString(),
          change: '+${analytics.newOrders} new',
          icon: Icons.shopping_cart_outlined,
          color: Colors.blue,
        ),
        _StatCard(
          title: 'Active Products',
          value: analytics.activeProducts.toString(),
          change: '${analytics.lowStockProducts} low stock',
          icon: Icons.inventory_2_outlined,
          color: Colors.purple,
          isChangeBad: true,
        ),
        _StatCard(
          title: 'Customer Rating',
          value: analytics.customerRating.toStringAsFixed(1),
          change:
              '${analytics.ratingChange > 0 ? '+' : ''}${analytics.ratingChange} this week',
          icon: Icons.star_border_outlined,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildLowStockAlert(int lowStockCount) {
    if (lowStockCount == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low Stock Alert',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                Text(
                  'You have $lowStockCount products running low. Consider restocking.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () {
              // TODO: Navigate to Products tab and filter by low stock
            },
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders(bool isLoading, List<SellerOrder> orders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Orders',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (isLoading && orders.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (orders.isEmpty)
          const Center(child: Text('No recent orders found.'))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orders.length > 5 ? 5 : orders.length, // Show max 5
            itemBuilder: (context, index) {
              return _OrderCard(order: orders[index]);
            },
          ),
      ],
    );
  }

  Widget _buildLowStockItems(bool isLoading, List<SellerProduct> products) {
    // This is just a placeholder, we'll build the full product list later
    final lowStockProducts = products
        .where((p) => p.stock < 20)
        .take(3)
        .toList(); // Example logic
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Low Stock Items',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (isLoading && products.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (lowStockProducts.isEmpty)
          const Center(child: Text('All products are well-stocked.'))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lowStockProducts.length,
            itemBuilder: (context, index) {
              final product = lowStockProducts[index];
              return Card(
                elevation: 1,
                shadowColor: Colors.black.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(
                    product.title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(product.category),
                  trailing: Text(
                    '${product.stock} left',
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// --- Reusable Stat Card Widget ---
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color color;
  final bool isChangeBad;

  const _StatCard({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
    this.isChangeBad = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                change,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isChangeBad
                      ? Colors.red.shade400
                      : Colors.green.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Reusable Order Card Widget ---
class _OrderCard extends StatelessWidget {
  final SellerOrder order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ORD-${order.id.substring(order.id.length - 6).toUpperCase()}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '₹${NumberFormat('#,##0.00').format(order.totalAmount)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.customerName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.items.length} ${order.items.length > 1 ? 'items' : 'item'} • ${DateFormat.jm().format(order.orderDate)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to Order Details
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

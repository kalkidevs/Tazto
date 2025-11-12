import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/features/seller/models/seller_order_model.dart';
import 'package:tazto/features/seller/screens/seller_order_details_page.dart';
import 'package:tazto/providers/seller_provider.dart';

/// New Orders Management page based on the UI design (Image 4)
class SellerOrdersPage extends StatefulWidget {
  const SellerOrdersPage({super.key});

  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SellerProvider>();
    final isLoading = provider.isLoadingOrders;
    final orders = provider.orders;

    // Filter orders for tabs
    final pending = orders.where((o) => o.status == 'Pending').toList();
    final preparing = orders.where((o) => o.status == 'Confirmed').toList();
    final ready = orders.where((o) => o.status == 'Shipped').toList();
    final completed = orders.where((o) => o.status == 'Delivered').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildStatCards(
            pending.length,
            preparing.length,
            ready.length,
            completed.length,
          ),
          _buildSearchAndFilter(),
          TabBar(
            controller: _tabController,
            isScrollable: false,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.poppins(),
            tabs: [
              Tab(text: 'Pending (${pending.length})'),
              Tab(text: 'Preparing (${preparing.length})'),
              Tab(text: 'Ready (${ready.length})'),
              Tab(text: 'Completed'),
            ],
          ),
          Expanded(
            child: isLoading && orders.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOrderList(pending, 'No pending orders.'),
                      _buildOrderList(preparing, 'No orders in preparation.'),
                      _buildOrderList(ready, 'No orders ready for pickup.'),
                      _buildOrderList(completed, 'No completed orders.'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(int pending, int preparing, int ready, int completed) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        shrinkWrap: true,
        childAspectRatio: 2.8,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _StatCard(
            title: 'Pending',
            value: pending.toString(),
            icon: Icons.pending_actions_outlined,
            color: Colors.orange,
          ),
          _StatCard(
            title: 'Preparing',
            value: preparing.toString(),
            icon: Icons.kitchen_outlined,
            color: Colors.blue,
          ),
          _StatCard(
            title: 'Ready',
            value: ready.toString(),
            icon: Icons.check_circle_outline,
            color: Colors.purple,
          ),
          _StatCard(
            title: 'Completed Today',
            value: completed.toString(),
            icon: Icons.task_alt_outlined,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Order ID or customer...',
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey.shade300),
              backgroundColor: Colors.white,
            ),
            child: const Icon(Icons.filter_list, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<SellerOrder> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      '₹${order.totalAmount.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  order.customerName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${order.items.length} ${order.items.length > 1 ? 'items' : 'item'} • ${order.paymentMethod}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // --- UPDATED: Navigate to Order Details ---
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SellerOrderDetailsPage(order: order),
                          ),
                        );
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
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Ensure intl is imported
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/features/seller/models/seller_order_model.dart';
import 'package:tazto/features/seller/screens/seller_order_details_page.dart';
import 'package:tazto/providers/seller_provider.dart';

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
    final orders = provider.orders;
    final isLoading = provider.isLoadingOrders;

    // Filter orders
    final pending = orders.where((o) => o.status == 'Pending').toList();
    final preparing = orders.where((o) => o.status == 'Confirmed').toList();
    final ready = orders.where((o) => o.status == 'Shipped').toList();
    final completed = orders.where((o) => o.status == 'Delivered').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: Column(
        children: [
          _buildCustomTabBar(pending.length, preparing.length),
          Expanded(
            child: isLoading && orders.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildOrderList(
                        pending,
                        'No pending orders',
                        Icons.assignment_turned_in_outlined,
                      ),
                      _buildOrderList(
                        preparing,
                        'Kitchen is quiet',
                        Icons.kitchen_outlined,
                      ),
                      _buildOrderList(
                        ready,
                        'No orders ready',
                        Icons.delivery_dining_outlined,
                      ),
                      _buildOrderList(
                        completed,
                        'No history yet',
                        Icons.history_rounded,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar(int pendingCount, int prepCount) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Management',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF4B9FE1)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            splashBorderRadius: BorderRadius.circular(24),
            labelPadding: const EdgeInsets.symmetric(horizontal: 20),
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            tabs: [
              _buildTab('Pending', pendingCount),
              _buildTab('Preparing', prepCount),
              const Tab(text: 'Ready'),
              const Tab(text: 'History'),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Tab _buildTab(String text, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderList(
    List<SellerOrder> orders,
    String emptyMsg,
    IconData emptyIcon,
  ) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Icon(emptyIcon, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMsg,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: orders.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        return _AnimatedOrderCard(order: orders[index]);
      },
    );
  }
}

class _AnimatedOrderCard extends StatelessWidget {
  final SellerOrder order;

  const _AnimatedOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    // Determine status color
    Color statusColor;
    Color statusBg;
    switch (order.status) {
      case 'Pending':
        statusColor = Colors.orange.shade700;
        statusBg = Colors.orange.shade50;
        break;
      case 'Confirmed':
        statusColor = Colors.blue.shade700;
        statusBg = Colors.blue.shade50;
        break;
      case 'Shipped':
        statusColor = Colors.purple.shade700;
        statusBg = Colors.purple.shade50;
        break;
      case 'Delivered':
        statusColor = Colors.green.shade700;
        statusBg = Colors.green.shade50;
        break;
      default:
        statusColor = Colors.grey.shade700;
        statusBg = Colors.grey.shade100;
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SellerOrderDetailsPage(order: order),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order.status.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('h:mm a').format(order.orderDate),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            order.customerName.isNotEmpty
                                ? order.customerName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.customerName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '#${order.id.substring(order.id.length - 6).toUpperCase()}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${order.totalAmount.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${order.items.length} Items',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.payment,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            order.paymentMethod,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'View Details',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

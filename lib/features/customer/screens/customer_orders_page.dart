import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/features/customer/widgets/custom_appbar.dart';
import 'package:tazto/providers/customer_provider.dart';

import '../models/customer_order_model.dart';

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({super.key});

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    // Fetch orders when the page loads if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CustomerProvider>();
      if (provider.orders.isEmpty &&
          !provider.isLoadingOrders &&
          provider.ordersError == null) {
        _fetchOrders();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() {
    // Use context.read() for one-off actions
    return context.read<CustomerProvider>().fetchMyOrders();
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen for changes
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        final orders = provider.orders;
        final isLoading = provider.isLoadingOrders;
        final error = provider.ordersError;

        // Filter orders for tabs
        final pending = orders
            .where((o) => o.status == OrderStatus.pending)
            .toList();
        final confirmed = orders
            .where((o) => o.status == OrderStatus.confirmed)
            .toList();
        final shipped = orders
            .where((o) => o.status == OrderStatus.shipped)
            .toList();
        final delivered = orders
            .where((o) => o.status == OrderStatus.delivered)
            .toList();
        final cancelled = orders
            .where((o) => o.status == OrderStatus.cancelled)
            .toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: ShoppingAppBar(
            title: 'My Orders',
            showBackButton: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: isLoading ? null : _fetchOrders,
                tooltip: 'Refresh Orders',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.poppins(),
              tabs: [
                _buildTab('All', orders.length),
                _buildTab('Pending', pending.length),
                _buildTab('Confirmed', confirmed.length),
                _buildTab('Shipped', shipped.length),
                _buildTab('Delivered', delivered.length),
                _buildTab('Cancelled', cancelled.length),
              ],
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _fetchOrders,
            child: _buildBody(isLoading, error, orders, [
              pending,
              confirmed,
              shipped,
              delivered,
              cancelled,
            ]),
          ),
        );
      },
    );
  }

  Tab _buildTab(String title, int count) {
    return Tab(text: '$title ($count)');
  }

  // Helper method to determine what to display based on provider state
  Widget _buildBody(
    bool isLoading,
    String? error,
    List<CustomerOrder> allOrders,
    List<List<CustomerOrder>> filteredLists,
  ) {
    if (isLoading && allOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && allOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Error fetching orders',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchOrders, // Retry button
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // TabBarView to display filtered lists
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOrderList(allOrders, 'You haven\'t placed any orders yet!'),
        _buildOrderList(filteredLists[0], 'No pending orders.'),
        _buildOrderList(filteredLists[1], 'No confirmed orders.'),
        _buildOrderList(filteredLists[2], 'No shipped orders.'),
        _buildOrderList(filteredLists[3], 'No delivered orders.'),
        _buildOrderList(filteredLists[4], 'No cancelled orders.'),
      ],
    );
  }

  Widget _buildOrderList(List<CustomerOrder> orders, String emptyMessage) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Display the list of orders
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(context, orders[index]);
      },
    );
  }

  // Helper widget to display a single order card
  Widget _buildOrderCard(BuildContext context, CustomerOrder order) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final firstProduct = firstItem?.product;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to Order Details Page
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Order details for #${order.id.substring(order.id.length - 6)} coming soon!',
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${order.id.substring(order.id.length - 6).toUpperCase()}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        // Use intl package for date formatting
                        DateFormat(
                          'dd MMM yyyy',
                        ).format(order.orderDate), // Use formatted date
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // Display first item's image and title as summary
                  if (firstItem != null && firstProduct != null)
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              (firstProduct.imageURL != null &&
                                  firstProduct.imageURL!.isNotEmpty)
                              ? Image.network(
                                  firstProduct.imageURL!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildFallbackImage(),
                                )
                              : _buildFallbackImage(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${firstProduct.title}${order.items.length > 1 ? ' + ${order.items.length - 1} more' : ''}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${order.totalItemsCount} ${order.totalItemsCount > 1 ? 'Items' : 'Item'}',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            // Footer with Status and Total
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(color: Colors.grey[50]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status Chip
                  Chip(
                    label: Text(
                      order.status.name.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(order.status).shade900,
                      ),
                    ),
                    backgroundColor: _getStatusColor(order.status).shade100,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                  ),
                  // Total
                  Text(
                    'Total: ₹${order.totalAmount.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey[200],
      child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
    );
  }

  // Helper function to get color based on order status
  MaterialColor _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}

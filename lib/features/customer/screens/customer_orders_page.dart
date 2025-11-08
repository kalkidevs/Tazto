import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/providers/customer_provider.dart';


import '../models/customer_order_model.dart'; // Import the Order model

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({super.key});

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  @override
  void initState() {
    super.initState();
    // Fetch orders when the page loads if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CustomerProvider>();
      // Fetch only if orders list is empty and not currently loading or in error
      if (provider.orders.isEmpty &&
          !provider.isLoadingOrders &&
          provider.ordersError == null) {
        provider.fetchMyOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen for changes in order list, loading, and error states
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('My Orders'),
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            // Optional: Add a refresh button
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.isLoadingOrders
                    ? null
                    : () => provider.fetchMyOrders(),
                tooltip: 'Refresh Orders',
              ),
            ],
          ),
          body: _buildBody(
            provider,
          ), // Use a helper method to build body based on state
        );
      },
    );
  }

  // Helper method to determine what to display based on provider state
  Widget _buildBody(CustomerProvider provider) {
    if (provider.isLoadingOrders) {
      return const Center(child: CircularProgressIndicator());
    } else if (provider.ordersError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error fetching orders: ${provider.ordersError}'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => provider.fetchMyOrders(), // Retry button
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (provider.orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('You haven\'t placed any orders yet!'),
          ],
        ),
      );
    } else {
      // Display the list of orders
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: provider.orders.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(context, provider.orders[index]);
        },
      );
    }
  }

  // Helper widget to display a single order card
  Widget _buildOrderCard(BuildContext context, CustomerOrder order) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(order.id.length - 6)}',
                  // Show last 6 chars of ID
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                Text(
                  order.formattedOrderDate, // Use formatted date
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            // Display first item's image and title as summary
            if (order.items.isNotEmpty)
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      order.items.first.product.imageURL ?? '',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${order.items.first.product.title}${order.items.length > 1 ? ' + ${order.items.length - 1} more' : ''}',
                      style: GoogleFonts.poppins(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.totalItemsCount} Items',
                  // Use helper for total items
                  style: GoogleFonts.poppins(color: Colors.grey[700]),
                ),
                Text(
                  'Total: ₹${order.totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status Chip
                Chip(
                  label: Text(
                    order.status
                        .toString()
                        .split('.')
                        .last
                        .toUpperCase(), // Display enum name nicely
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(order.status).withOpacity(0.9),
                    ),
                  ),
                  backgroundColor: _getStatusColor(
                    order.status,
                  ).withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide.none,
                ),
                // Details Button
                OutlinedButton(
                  onPressed: () {
                    // TODO: Navigate to Order Details Page (pass order.id)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Order details for ${order.id} coming soon!',
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    'Details',
                    style: TextStyle(color: theme.primaryColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to get color based on order status
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return AppColors.primary;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

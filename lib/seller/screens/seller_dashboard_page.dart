// lib/screens/seller/seller_dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tazto/auth/login_screen.dart';

import '../../providers/sellerPdr.dart';

class SellerDashboardPage extends StatelessWidget {
  const SellerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final sellerProv = context.watch<SellerProvider>();
    final store = sellerProv.stores.first;
    final products = sellerProv.products;
    final orders = sellerProv.orders;

    // calculate revenue on the fly
    final revenue = orders.fold<double>(0, (sum, order) {
      final product = products.firstWhere(
        (p) => p.id == order.productId,
        orElse: () => products.first,
      );
      return sum + (product.price * order.quantity);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${store.name}!'),
        centerTitle: true,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => _confirmLogout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // Stats cards
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _StatCard(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Products',
                  value: products.length.toString(),
                  color: Colors.blue,
                ),
                _StatCard(
                  icon: Icons.receipt_long_outlined,
                  label: 'Orders',
                  value: orders.length.toString(),
                  color: Colors.orange,
                ),
                _StatCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'In Stock',
                  value: products
                      .fold<int>(0, (sum, p) => sum + p.stock)
                      .toString(),
                  color: Colors.green,
                ),
                _StatCard(
                  icon: Icons.attach_money_outlined,
                  label: 'Revenue',
                  value: '\$${revenue.toStringAsFixed(2)}',
                  color: Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 32),

            Text(
              'Recent Orders',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (orders.isEmpty)
              const Center(child: Text('No recent orders'))
            else
              ...orders.take(3).map((o) {
                final prod = products.firstWhere(
                  (p) => p.id == o.productId,
                  orElse: () => products.first,
                );
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: Icon(
                      Icons.shopping_cart,
                      color: Colors.grey.shade700,
                    ),
                    title: Text('${o.quantity} × ${prod.name}'),
                    subtitle: Text(
                      '${o.status.name.toUpperCase()} • ${o.orderDate.toLocal().toShortDateString()}',
                    ),
                    trailing: Text(
                      '\$${(prod.price * o.quantity).toStringAsFixed(2)}',
                    ),
                    onTap: () {
                      // TODO: navigate to SellerOrdersPage with detail view
                    },
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text(
          'Are you sure you want to logout? You will need to login again to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();

              // Pop the dialog
              Navigator.of(context).pop();

              // Navigate to LoginPage and clear back stack
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: Text('Logout', style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
  }
}

/// A small stat card used in the dashboard
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cardWidth = constraints.maxWidth < 600
            ? constraints.maxWidth / 2 - 20
            : 160;

        return SizedBox(
          width: cardWidth.toDouble(),
          height: 100,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(value, style: textTheme.titleLarge),
                        Text(label, style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Extension to format DateTime as short date string
extension DateHelpers on DateTime {
  String toShortDateString() {
    return '${this.day}/${this.month}/${this.year}';
  }
}

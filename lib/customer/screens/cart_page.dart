// lib/screens/customer/cart_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tazto/providers/customer_provider.dart';

// Helper function to get category-based icons
IconData _getCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'mobile':
    case 'phone':
      return Icons.smartphone;
    case 'electronics':
    case 'electronic':
      return Icons.devices;
    case 'clothing':
    case 'clothes':
    case 'fashion':
      return Icons.shopping_bag;
    case 'books':
    case 'book':
      return Icons.menu_book;
    case 'home':
    case 'furniture':
      return Icons.home;
    case 'sports':
    case 'fitness':
      return Icons.fitness_center;
    case 'food':
    case 'grocery':
      return Icons.restaurant;
    case 'beauty':
    case 'cosmetics':
      return Icons.face;
    case 'toys':
    case 'games':
      return Icons.toys;
    case 'automotive':
    case 'car':
      return Icons.directions_car;
    default:
      return Icons.shopping_cart;
  }
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CustomerProvider>();
    final cart = prov.cart;
    final total = cart.fold<double>(
      0,
      (sum, c) => sum + c.quantity * c.product.price,
    );

    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Your Cart',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: cart.length,
              itemBuilder: (_, i) {
                final c = cart[i];
                return ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: c.product.imageURL == null ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: c.product.imageURL != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              'https://backendlinc.up.railway.app/${c.product.imageURL}',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                _getCategoryIcon(c.product.category),
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          )
                        : Icon(
                            _getCategoryIcon(c.product.category),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                  ),
                  title: Text(c.product.title),
                  subtitle: Text('₹${c.product.price.toStringAsFixed(0)} × ${c.quantity}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => prov.removeFromCart(c.id),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₹${total.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 18),
                ),
                ElevatedButton(
                  onPressed: cart.isEmpty ? null : prov.placeOrder,
                  child: const Text('Checkout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

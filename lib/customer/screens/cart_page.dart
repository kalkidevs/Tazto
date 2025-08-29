// lib/screens/customer/cart_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tazto/providers/customerPdr.dart';

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
                  leading: Image.network(
                    c.product.image,
                    width: 50,
                    height: 50,
                  ),
                  title: Text(c.product.title),
                  subtitle: Text('\$${c.product.price} × ${c.quantity}'),
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
                  'Total: \$${total.toStringAsFixed(2)}',
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

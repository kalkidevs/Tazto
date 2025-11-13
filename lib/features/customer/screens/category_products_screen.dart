import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/features/customer/widgets/product_card_widget.dart';
import 'package:tazto/providers/customer_provider.dart';

import '../models/customer_category_model.dart';


class CategoryProductsPage extends StatelessWidget {
  final CustomerCategory category;

  const CategoryProductsPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    // Get the provider
    final customerProvider = context.watch<CustomerProvider>();
    // Filter products based on the passed category name
    final products = customerProvider.getProductsByCategory(category.name);

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        backgroundColor: AppColors.background,
        // Match Figma background
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to Search Page
            },
          ),
        ],
      ),
      body: customerProvider.isLoadingProducts && products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? Center(child: Text('No products found in ${category.name}'))
          : GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          // --- UPDATED: New aspect ratio for the responsive card ---
          childAspectRatio: 0.75,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          // --- UPDATED: Use the single, reusable ProductCard ---
          return ProductCard(
            product: products[index],
            layoutType: ProductCardLayout.grid,
          );
        },
      ),
    );
  }
}

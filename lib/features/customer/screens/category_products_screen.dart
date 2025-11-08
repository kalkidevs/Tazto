import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/features/customer/models/customer_product_model.dart';
import 'package:tazto/providers/customer_provider.dart';

import '../models/customer_category_model.dart';



IconData getCategoryIcon(String category) {
  // Simple mapping, expand as needed
  switch (category.toLowerCase()) {
    case 'vegetables & fruits':
      return Icons.local_florist;
    case 'dairy & breakfast':
      return Icons.breakfast_dining;
    case 'cold drinks & juices':
      return Icons.local_bar;
    case 'instant & frozen food':
      return Icons.ac_unit;
    case 'tea & coffee':
      return Icons.coffee;
    case 'atta, rice & dal':
      return Icons.rice_bowl;
    case 'masala, oil & dry fruits':
      return Icons.set_meal;
    case 'chicken, meat & fish':
      return Icons.kebab_dining;
    default:
      return Icons.category;
  }
}

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
      body: customerProvider.isLoadingProducts
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? Center(child: Text('No products found in ${category.name}'))
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.65, // Adjust ratio to fit content
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                // Use the ProductCard widget for consistency
                return _ProductCard(product: products[index]);
              },
            ),
    );
  }
}

// TEMPORARY: Copied _ProductCard from home_page.dart
// TODO: Refactor this into its own file (e.g., lib/customer/widgets/product_card_widget.dart)
class _ProductCard extends StatelessWidget {
  final CustomerProduct product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final prov = context.read<CustomerProvider>();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    // Determine if there's a discount
    // Assuming a 'discountPrice' or 'originalPrice' field might exist in Product model later
    // For now, let's simulate it if price is lower than an arbitrary value
    final bool hasDiscount = product.price < 12; // Example condition
    final String displayPrice = '₹${product.price.toStringAsFixed(0)}';
    final String? originalPrice = hasDiscount
        ? '₹12'
        : null; // Example original price

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to Product Detail Page
          // Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(productId: product.id)));
          debugPrint("Tapped on ${product.title}");
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              child: Container(
                color: Colors.grey[100], // Placeholder background
                width: double.infinity,
                child:
                    product.imageURL != null &&
                        product.imageURL!.isNotEmpty &&
                        !product.imageURL!.endsWith('undefined')
                    ? Image.network(
                        product.imageURL!, // Use the full URL directly from API
                        fit: BoxFit.contain, // Contain keeps aspect ratio
                        loadingBuilder: (context, child, progress) {
                          return progress == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                );
                        },
                        errorBuilder: (context, error, stackTrace) => Icon(
                          getCategoryIcon(product.category),
                          // Use category icon as fallback
                          size: 40,
                          color: colorScheme.secondary.withOpacity(0.5),
                        ),
                      )
                    : Center(
                        child: Icon(
                          getCategoryIcon(product.category),
                          size: 40,
                          color: colorScheme.secondary.withOpacity(0.5),
                        ),
                      ),
              ),
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Optional: Add weight/volume if available in model
                  Text(
                    '${product.stock} pcs',
                    // Example: Using stock, replace if weight/volume exists
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayPrice,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (originalPrice != null)
                            Text(
                              originalPrice,
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      // Add Button
                      ElevatedButton(
                        onPressed: () {
                          prov.addToCart(product); // Assuming addToCart exists
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.title} added to cart'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          textStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

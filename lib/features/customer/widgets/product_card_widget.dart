import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/providers/customer_provider.dart';

import '../models/customer_product_model.dart';
import '../screens/product_detail_screen.dart';

// Helper function (can be moved to a utils file later)
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
    // Match the category string from your API/Product Model
    case 'electronics':
      return Icons.devices;
    case 'mobile':
      return Icons.smartphone; // Example
    default:
      return Icons.category;
  }
}

class ProductCard extends StatelessWidget {
  final CustomerProduct product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final prov = context.read<CustomerProvider>();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    // Determine if there's a discount (Example logic)
    final bool hasDiscount =
        product.price < 12; // Example condition based on price
    final String displayPrice = '₹${product.price.toStringAsFixed(0)}';
    // You might need an 'originalPrice' field in your Product model
    final String? originalPrice = hasDiscount
        ? '₹${(product.price * 1.2).toStringAsFixed(0)}'
        : null; // Example calculation

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // *** UPDATED: Navigate to Product Detail Page ***
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProductDetailPage(productId: product.id), // Pass the ID
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              child: Container(
                color: Colors.grey[100], // Placeholder background
                width: double.infinity,
                padding: const EdgeInsets.all(8.0), // Padding around the image
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
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint(
                            "Error loading image ${product.imageURL}: $error",
                          );
                          return Icon(
                            getCategoryIcon(product.category),
                            // Use category icon as fallback
                            size: 40,
                            color: colorScheme.secondary.withOpacity(0.5),
                          );
                        },
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
                    // Example using stock, replace if weight/volume exists
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    // Align items to bottom
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
                      SizedBox(
                        height: 36, // Give button fixed height
                        child: ElevatedButton(
                          onPressed: () {
                            prov.addToCart(
                              product,
                            ); // Assuming addToCart exists
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            textStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          child: const Text('Add'),
                        ),
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

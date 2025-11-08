import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/providers/customer_provider.dart';

import '../models/customer_product_model.dart';
import '../widgets/product_card_widget.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  // Use nullable Product type, matching the provider's potential return
  CustomerProduct? _product;
  bool _isLoading = true;
  String? _error;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    // Ensure UI resets correctly on retry or re-entry
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _product = null; // Reset product on fetch start
    });
    try {
      // Fetch details using the provider method
      final fetchedProduct = await context
          .read<CustomerProvider>()
          .getProductDetails(widget.productId);

      if (!mounted) return; // Check mount status AFTER async call
      setState(() {
        _product =
            fetchedProduct; // Assign the potentially null or valid product
        _isLoading = false;
        if (_product == null) {
          _error = 'Product not found.'; // Set error if provider returns null
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst(
          'Exception: ',
          '',
        ); // Clean up error message
        _isLoading = false;
      });
    }
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    // Use read here if only calling methods like addToCart
    final customerProvider = context.read<CustomerProvider>();

    // Get similar products only if _product is not null
    final List<CustomerProduct> similarProducts = _product != null
        ? customerProvider
              .getProductsByCategory(
                _product!.category,
              ) // Use ! because we checked _product != null
              .where((p) => p.id != _product!.id) // Exclude current product
              .take(4)
              .toList()
        : []; // Empty list if _product is null

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_product?.title ?? 'Item Details'),
        // Use null-aware access
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border), // TODO: Add favorite logic
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          // Display error clearly
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Error: $_error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            )
          : _product ==
                null // This case should now be covered by _error state
          ? const Center(child: Text('Product not found.'))
          // Only build the main UI if _product is definitely not null
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Product Image ---
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      // Use null-aware checks for imageURL
                      child:
                          _product!.imageURL != null &&
                              _product!.imageURL!.isNotEmpty &&
                              !_product!.imageURL!.endsWith('undefined')
                          ? Image.network(
                              _product!.imageURL!,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, progress) {
                                return progress == null
                                    ? child
                                    : const Center(
                                        child: CircularProgressIndicator(),
                                      );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.image_not_supported,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                            )
                          : const Icon(
                              Icons.image_not_supported,
                              size: 60,
                              color: Colors.grey,
                            ),
                    ),
                  ),

                  // --- Product Info ---
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Use null assertion ! here because _product is guaranteed non-null
                        Text(
                          _product!.title,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Rating display
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _product!.rating.rate.toStringAsFixed(1),
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${_product!.rating.count} Reviews)',
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹${_product!.price.toStringAsFixed(0)}',
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Add other price/discount elements as needed...
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Description',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _product!.description,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),

                        const SizedBox(height: 24),
                        Text(
                          'Reviews & Ratings',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Placeholder for reviews
                        const ListTile(/* ... Review placeholder ... */),
                        const SizedBox(height: 24),

                        Text(
                          'Similar Products',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Similar Products ---
                  SizedBox(
                    height: 280,
                    child: similarProducts.isEmpty
                        ? const Center(
                            child: Text("No similar products found."),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            itemCount: similarProducts.length,
                            itemBuilder: (context, index) {
                              return SizedBox(
                                width: 170,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  // Ensure ProductCard uses the correct Product type
                                  child: ProductCard(
                                    product: similarProducts[index],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 80), // Space for bottom bar
                ],
              ),
            ),

      // --- Bottom Add to Cart Bar ---
      // Use Visibility to only show if product is loaded
      bottomSheet: Visibility(
        visible: !_isLoading && _product != null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Quantity Selector
              Container(/* ... Quantity Selector ... */),
              const Spacer(),
              // Add to Cart Button
              ElevatedButton(
                onPressed: () {
                  // Add the specific quantity to the cart
                  // Use null assertion ! because visible check ensures _product is not null
                  for (int i = 0; i < _quantity; i++) {
                    customerProvider.addToCart(_product!);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${_product!.title} (x$_quantity) added to cart',
                      ),
                      // Use !
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(/* ... Button Style ... */),
                // Use null assertion ! here as well
                child: Text(
                  'Add to Cart  ₹${(_product!.price * _quantity).toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Ensure the Quantity Selector Container code is present in the final file
// Example Quantity Selector:
// Container(
//   decoration: BoxDecoration(
//     border: Border.all(color: Colors.grey.shade300),
//     borderRadius: BorderRadius.circular(8),
//   ),
//   child: Row(
//     children: [
//       IconButton(
//         icon: const Icon(Icons.remove, size: 20),
//         onPressed: _decrementQuantity,
//         visualDensity: VisualDensity.compact,
//         color: _quantity > 1 ? AppColors.textPrimary : Colors.grey,
//       ),
//       Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 8.0),
//         child: Text(
//           _quantity.toString(),
//           style: textTheme?.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Use null-aware access for textTheme
//         ),
//       ),
//       IconButton(
//         icon: const Icon(Icons.add, size: 20),
//         onPressed: _incrementQuantity,
//         visualDensity: VisualDensity.compact,
//         color: AppColors.textPrimary,
//       ),
//     ],
//   ),
// ),

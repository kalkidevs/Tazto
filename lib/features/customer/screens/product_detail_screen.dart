import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  CustomerProduct? _product;
  bool _isLoading = true;
  String? _error;
  int _quantity = 1;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _product = null;
    });
    try {
      final fetchedProduct = await context
          .read<CustomerProvider>()
          .getProductDetails(widget.productId);

      if (!mounted) return;
      setState(() {
        _product = fetchedProduct;
        _isLoading = false;
        if (_product == null) {
          _error = 'Product not found.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _incrementQuantity() {
    if (_product == null) return;
    if (_quantity < _product!.stock) {
      setState(() {
        _quantity++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stock limit reached (${_product!.stock} available)',
            style: GoogleFonts.poppins(),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  void _addToCart() {
    if (_product == null) return;
    final customerProvider = context.read<CustomerProvider>();
    try {
      customerProvider.addToCart(_product!, quantity: _quantity);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_product!.title} (x$_quantity) added to cart',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll("Exception: ", ""),
            style: GoogleFonts.poppins(),
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final customerProvider = context.watch<CustomerProvider>();

    final List<CustomerProduct> similarProducts = _product != null
        ? customerProvider
              .getProductsByCategory(_product!.category)
              .where((p) => p.id != _product!.id)
              .take(6)
              .toList()
        : [];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Product Details',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // TODO: Add share functionality
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $_error',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: theme.colorScheme.error,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _fetchProductDetails,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _product == null
          ? const Center(child: Text('Product not found.'))
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image Section
                      _buildImageSection(),

                      // Product Info Card
                      _buildProductInfoCard(textTheme),

                      const SizedBox(height: 8),

                      // Product Details Card
                      _buildProductDetailsCard(textTheme),

                      const SizedBox(height: 8),

                      // Key Features Card
                      _buildKeyFeaturesCard(textTheme),

                      const SizedBox(height: 8),

                      // Reviews Section
                      _buildReviewsSection(textTheme),

                      const SizedBox(height: 8),

                      // Similar Products
                      if (similarProducts.isNotEmpty)
                        _buildSimilarProductsSection(
                          textTheme,
                          similarProducts,
                        ),

                      const SizedBox(height: 140), // Space for bottom bar
                    ],
                  ),
                ),

                // Fixed Bottom Bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildBottomBar(),
                ),
              ],
            ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 320,
      width: double.infinity,
      color: Colors.white,
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
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
                            : const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),
          ),
          // Stock Badge
          if (_product!.stock <= 5 && _product!.stock > 0)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Only ${_product!.stock} left!',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 80,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildProductInfoCard(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Title
          Text(
            _product!.title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),

          // Category Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _product!.category.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Rating Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _product!.rating.rate.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.star, color: Colors.white, size: 14),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_product!.rating.count} ratings',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Price Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${_product!.price.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              // Original Price (if on sale - placeholder)
              if (_product!.price < 1000) // Example condition
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '₹${(_product!.price * 1.2).toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey[400],
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
            ],
          ),

          // Stock Status
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                _product!.stock > 0 ? Icons.check_circle : Icons.cancel,
                size: 18,
                color: _product!.stock > 0 ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 6),
              Text(
                _product!.stock > 0
                    ? 'In Stock (${_product!.stock} available)'
                    : 'Out of Stock',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _product!.stock > 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetailsCard(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Description',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _product!.description.isEmpty
                ? 'No description available for this product.'
                : _product!.description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyFeaturesCard(TextTheme textTheme) {
    // Generate sample features based on product data
    final features = [
      {'icon': Icons.verified_outlined, 'text': '100% Authentic Product'},
      {
        'icon': Icons.local_shipping_outlined,
        'text': 'Fast Delivery Available',
      },
      {
        'icon': Icons.assignment_return_outlined,
        'text': '7 Days Return Policy',
      },
      {'icon': Icons.payments_outlined, 'text': 'Secure Payment Options'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Key Features',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature['text'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Customer Reviews',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all reviews
                },
                child: Text(
                  'See All',
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rating Distribution
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _product!.rating.rate.toStringAsFixed(1),
                      style: GoogleFonts.poppins(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < _product!.rating.rate.floor()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_product!.rating.count} ratings',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Column(
                  children: List.generate(5, (index) {
                    final stars = 5 - index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '$stars',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value:
                                  (5 - index) / 5 * _product!.rating.rate / 5,
                              backgroundColor: Colors.grey[200],
                              color: AppColors.primary,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // Placeholder Review
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      color: Colors.grey[400],
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No reviews yet. Be the first to review!',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Add review
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      'Write a Review',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarProductsSection(
    TextTheme textTheme,
    List<CustomerProduct> similarProducts,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Similar Products',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: similarProducts.length,
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 160,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ProductCard(product: similarProducts[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quantity and Price Row
            Row(
              children: [
                // Quantity Selector
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _quantity > 1 ? _decrementQuantity : null,
                        icon: Icon(
                          Icons.remove,
                          size: 20,
                          color: _quantity > 1
                              ? AppColors.textPrimary
                              : Colors.grey[400],
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 36),
                        alignment: Alignment.center,
                        child: Text(
                          _quantity.toString(),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _product!.stock > _quantity
                            ? _incrementQuantity
                            : null,
                        icon: Icon(
                          Icons.add,
                          size: 20,
                          color: _product!.stock > _quantity
                              ? AppColors.primary
                              : Colors.grey[400],
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Add to Cart Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _product!.stock > 0 ? _addToCart : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_cart_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _product!.stock > 0
                              ? 'Add ₹${(_product!.price * _quantity).toStringAsFixed(0)}'
                              : 'Out of Stock',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

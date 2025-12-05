import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/api/api_client.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/providers/customer_provider.dart';

import '../models/customer_product_model.dart';
import '../screens/product_detail_screen.dart';

// Helper function (can be moved to a utils file later)
IconData getCategoryIcon(String? category) {
  if (category == null) return Icons.category;
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
    case 'electronics':
      return Icons.devices;
    case 'fashion':
      return Icons.checkroom;
    case 'groceries':
      return Icons.local_grocery_store;
    case 'home & kitchen':
      return Icons.kitchen;
    case 'toys':
      return Icons.toys;
    case 'mobile':
      return Icons.smartphone;
    default:
      return Icons.category;
  }
}
enum ProductCardLayout { grid, list }
class ProductCard extends StatefulWidget {
  final CustomerProduct product;
  final ProductCardLayout layoutType;

  const ProductCard({
    super.key,
    required this.product,
    this.layoutType = ProductCardLayout.grid,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        _navigateToDetail();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 14),
          ),
          elevation: _isPressed ? 1 : 3,
          shadowColor: Colors.black.withOpacity(0.1),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade50],
              ),
            ),
            child: widget.layoutType == ProductCardLayout.grid
                ? _buildGridLayout(context, isSmallScreen)
                : _buildListLayout(context, isSmallScreen),
          ),
        ),
      ),
    );
  }

  void _navigateToDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(productId: widget.product.id),
      ),
    );
  }

  /// Builds the responsive vertical layout for GridViews.
  Widget _buildGridLayout(BuildContext context, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: _buildProductImage(context, isSmallScreen)),
        Expanded(flex: 5, child: _buildProductDetails(context, isSmallScreen)),
      ],
    );
  }

  /// Builds the responsive horizontal layout for ListViews.
  Widget _buildListLayout(BuildContext context, bool isSmallScreen) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = screenWidth * 0.3;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: imageWidth.clamp(100.0, 140.0),
            child: _buildProductImage(context, isSmallScreen),
          ),
          Expanded(child: _buildProductDetails(context, isSmallScreen)),
        ],
      ),
    );
  }

  /// Enhanced product image with better visual feedback.
  Widget _buildProductImage(BuildContext context, bool isSmallScreen) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasValidImage =
        widget.product.imageURL != null &&
        widget.product.imageURL!.isNotEmpty &&
        !widget.product.imageURL!.endsWith('undefined');

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey.shade100, Colors.grey.shade200],
            ),
          ),
          padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
          child: hasValidImage
              ? Hero(
                  tag: 'product_${widget.product.id}',
                  child: Image.network(
                    widget.product.imageURL!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderIcon(colorScheme, isSmallScreen);
                    },
                  ),
                )
              : _buildPlaceholderIcon(colorScheme, isSmallScreen),
        ),
        // Stock indicator badge
        if (widget.product.stock <= 10)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 6 : 8,
                vertical: isSmallScreen ? 3 : 4,
              ),
              decoration: BoxDecoration(
                color: widget.product.stock == 0
                    ? Colors.red.shade600
                    : Colors.orange.shade600,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.product.stock == 0 ? 'Out' : 'Low',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 9 : 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholderIcon(ColorScheme colorScheme, bool isSmallScreen) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          getCategoryIcon(widget.product.category),
          size: isSmallScreen ? 32 : 40,
          color: colorScheme.primary.withOpacity(0.6),
        ),
      ),
    );
  }

  /// Enhanced product details with responsive typography.
  Widget _buildProductDetails(BuildContext context, bool isSmallScreen) {
    final textTheme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmallScreen = screenWidth < 340;

    final bool hasDiscount = widget.product.price < 12;
    final String displayPrice = '₹${widget.product.price.toStringAsFixed(0)}';
    final String? originalPrice = hasDiscount
        ? '₹${(widget.product.price * 1.2).toStringAsFixed(0)}'
        : null;

    // Responsive padding
    final horizontalPadding = isSmallScreen ? 8.0 : 12.0;
    final verticalPadding = isSmallScreen ? 8.0 : 10.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title Section
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: isVerySmallScreen
                        ? 12
                        : (isSmallScreen ? 13 : 14),
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: Colors.grey.shade800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          // Price and Button Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayPrice,
                      style: GoogleFonts.poppins(
                        fontSize: isVerySmallScreen
                            ? 15
                            : (isSmallScreen ? 16 : 18),
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (originalPrice != null)
                      Text(
                        originalPrice,
                        style: GoogleFonts.poppins(
                          fontSize: isVerySmallScreen ? 10 : 11,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: Colors.grey.shade400,
                          decorationThickness: 1.5,
                        ),
                      ),
                    if (hasDiscount)
                      Text(
                        'Save ${((1 - widget.product.price / (widget.product.price * 1.2)) * 100).toInt()}%',
                        style: GoogleFonts.poppins(
                          fontSize: isVerySmallScreen ? 9 : 10,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              _buildAddButton(context, isSmallScreen),
            ],
          ),
        ],
      ),
    );
  }

  /// Enhanced add button with better visuals and feedback.
  Widget _buildAddButton(BuildContext context, bool isSmallScreen) {
    final prov = context.read<CustomerProvider>();
    final isOutOfStock = widget.product.stock == 0;

    return SizedBox(
      height: isSmallScreen ? 32 : 36,
      child: ElevatedButton(
        onPressed: isOutOfStock
            ? null
            : () {
                try {
                  prov.addToCart(widget.product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${widget.product.title} added to cart',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                } on ApiException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.message,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      duration: const Duration(seconds: 3),
                      backgroundColor: Colors.red.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutOfStock
              ? Colors.grey.shade300
              : AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade500,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
          ),
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
          elevation: isOutOfStock ? 0 : 2,
          shadowColor: AppColors.primary.withOpacity(0.3),
        ),
        child: Text(
          isOutOfStock ? 'Sold' : 'Add',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: isSmallScreen ? 12 : 13,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

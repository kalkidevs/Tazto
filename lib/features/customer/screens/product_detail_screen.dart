import 'dart:ui'; // For blur effect

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/providers/customer_provider.dart';

import '../models/customer_product_model.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  final CustomerProduct? heroProduct; // For immediate hero animation

  const ProductDetailPage({
    super.key,
    required this.productId,
    this.heroProduct,
  });

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
    // Use the passed product immediately if available
    _product = widget.heroProduct;
    if (_product != null) {
      _isLoading = false;
    }
    // Fetch fresh details (reviews, updated price) in background
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    try {
      final fetchedProduct = await context
          .read<CustomerProvider>()
          .getProductDetails(widget.productId, forceRefresh: true);

      if (!mounted) return;
      setState(() {
        _product = fetchedProduct;
        _isLoading = false;
        if (_product == null && widget.heroProduct == null) {
          _error = 'Product not found.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      if (widget.heroProduct == null) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _incrementQuantity() {
    if (_product == null) return;
    if (_quantity < _product!.stock) {
      setState(() => _quantity++);
    } else {
      _showSnack('Stock limit reached', Colors.orange);
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  void _addToCart() {
    if (_product == null) return;
    try {
      context.read<CustomerProvider>().addToCart(
        _product!,
        quantity: _quantity,
      );
      _showSnack('${_product!.title} added to cart', Colors.green);
    } catch (e) {
      _showSnack(e.toString(), Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showRatingDialog() {
    double _rating = 5.0;
    final _commentController = TextEditingController();
    bool _isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Rate Product',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSubmitting)
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () =>
                            setDialogState(() => _rating = index + 1.0),
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts (Optional)',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ],
            ),
            actions: _isSubmitting
                ? []
                : [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (_commentController.text.trim().isEmpty) {
                          // Allow submitting rating without comment, or enforce?
                          // Let's assume comment required for now to prevent spam
                          _showSnack('Please write a comment', Colors.orange);
                          return;
                        }
                        setDialogState(() => _isSubmitting = true);
                        try {
                          await context
                              .read<CustomerProvider>()
                              .addProductReview(
                                widget.productId,
                                _rating,
                                _commentController.text,
                              );
                          if (mounted) {
                            Navigator.pop(context);
                            await _fetchProductDetails(); // Refresh to show new review
                            _showSnack(
                              'Thanks for your feedback!',
                              Colors.green,
                            );
                          }
                        } catch (e) {
                          setDialogState(() => _isSubmitting = false);
                          if (mounted) Navigator.pop(context);
                          _showSnack(
                            e.toString().replaceAll("Exception: ", ""),
                            Colors.red,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Submit'),
                    ),
                  ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _product == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && _product == null) {
      return Scaffold(
        body: Center(child: Text(_error ?? "Error loading product")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. App Bar with Hero Image
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.black,
                      ),
                      onPressed: () =>
                          setState(() => _isFavorite = !_isFavorite),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: const Color(0xFFF8F9FA),
                    padding: const EdgeInsets.all(40),
                    child: Hero(
                      tag: 'product_img_${widget.productId}',
                      child: _product?.imageURL != null
                          ? Image.network(
                              _product!.imageURL!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image,
                                size: 80,
                                color: Colors.grey,
                              ),
                            )
                          : const Icon(
                              Icons.image,
                              size: 100,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                ),
              ),

              // 2. Product Details
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _product!.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _product!.category.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${_product!.price.toStringAsFixed(0)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _product!.rating.rate.toStringAsFixed(1),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Text(
                                      ' (${_product!.rating.count})',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 24),

                      // Description
                      Text(
                        'Description',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _product!.description.isNotEmpty
                            ? _product!.description
                            : 'No description available.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Reviews Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Customer Reviews',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: _showRatingDialog,
                            child: Text(
                              'Write Review',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Review List
                      if (_product!.reviews.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.rate_review_outlined,
                                color: Colors.grey.shade400,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No reviews yet',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Be the first to rate this product!',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _product!.reviews.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final r = _product!.reviews[index];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade100),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppColors.primary
                                            .withOpacity(0.1),
                                        child: Text(
                                          r.userName.isNotEmpty
                                              ? r.userName[0].toUpperCase()
                                              : 'U',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              r.userName,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              DateFormat(
                                                'MMM d, yyyy',
                                              ).format(r.date),
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              r.rating.toStringAsFixed(1),
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.amber[800],
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            Icon(
                                              Icons.star_rounded,
                                              size: 14,
                                              color: Colors.amber[800],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (r.comment.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      r.comment,
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. Floating Bottom Bar (Glassmorphic)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Quantity Controller
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _decrementQuantity,
                              icon: const Icon(
                                Icons.remove,
                                color: Colors.white,
                                size: 18,
                              ),
                              constraints: const BoxConstraints(minWidth: 40),
                            ),
                            Text(
                              '$_quantity',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              onPressed: _incrementQuantity,
                              icon: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 18,
                              ),
                              constraints: const BoxConstraints(minWidth: 40),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Add Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _addToCart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_bag_outlined, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Add to Cart',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

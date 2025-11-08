import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/features/customer/widgets/custom_appbar.dart';
import 'package:tazto/providers/customer_provider.dart';

import '../models/cart_itemMdl.dart';
import 'checkout_screen.dart';

// Helper function
IconData getCategoryIcon(String? category) {
  if (category == null) return Icons.category;
  switch (category.toLowerCase()) {
    case 'vegetables & fruits':
      return Icons.local_florist;
    case 'dairy & breakfast':
      return Icons.breakfast_dining;
    case 'cold drinks & juices':
      return Icons.local_bar;
    case 'electronics':
      return Icons.devices;
    case 'mobile':
      return Icons.smartphone;
    default:
      return Icons.category;
  }
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String? _errorMessage;
  String? _errorProductId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CustomerProvider>();
      if (provider.cart.isEmpty &&
          !provider.isLoadingCart &&
          provider.cartError == null) {
        provider.fetchCart();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message, {bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isWarning ? Icons.warning_amber_rounded : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isWarning ? Colors.orange[700] : Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleQuantityUpdate(
    String productId,
    int newQuantity,
    int currentQuantity,
  ) async {
    final provider = context.read<CustomerProvider>();

    // Clear previous error for this product
    if (_errorProductId == productId) {
      setState(() {
        _errorMessage = null;
        _errorProductId = null;
      });
    }

    // Optimistic update - show the new quantity immediately
    try {
      await provider.updateItemQuantity(productId, newQuantity);
      _animationController.forward(from: 0);
    } catch (e) {
      // Show error for this specific product
      setState(() {
        _errorMessage = e.toString();
        _errorProductId = productId;
      });

      String errorMsg = 'Unable to update quantity';
      if (e.toString().contains('stock')) {
        errorMsg = 'Not enough stock available!';
      }
      _showErrorSnackBar(errorMsg, isWarning: true);

      // Auto-clear error after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _errorProductId == productId) {
          setState(() {
            _errorMessage = null;
            _errorProductId = null;
          });
        }
      });
    }
  }

  Future<void> _handleRemoveItem(String productId, String productName) async {
    final provider = context.read<CustomerProvider>();

    // Show loading indicator briefly
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await provider.removeFromCartByProductId(productId);
      Navigator.pop(context); // Close loading dialog
      _showSuccessSnackBar('$productName removed from cart');
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      _showErrorSnackBar('Failed to remove item');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        final cartItems = provider.cart;
        final cartTotal = provider.cartTotal;
        final cartItemCount = provider.cartItemCount;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: ShoppingAppBar(
            title: 'My Cart',
            subtitle: cartItemCount > 0
                ? '$cartItemCount ${cartItemCount == 1 ? "Item" : "Items"}'
                : 'Your cart is empty',
            showBackButton: false,
            actions: [
              if (cartItems.isNotEmpty)
                IconButton(
                  icon: const Icon(
                    Icons.delete_sweep_outlined,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Clear Cart',
                  onPressed: () => _confirmClearCart(context),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await provider.fetchCart();
            },
            color: AppColors.primary,
            child: provider.isLoadingCart
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading your cart...'),
                      ],
                    ),
                  )
                : provider.cartError != null
                ? _buildErrorState(provider)
                : cartItems.isEmpty
                ? _buildEmptyCartState()
                : _buildCartList(cartItems),
          ),
          bottomNavigationBar: cartItems.isEmpty
              ? null
              : _buildCheckoutBar(cartTotal, cartItemCount),
        );
      },
    );
  }

  Widget _buildErrorState(CustomerProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.cartError ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.fetchCart(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCartState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty!',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to get started',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to shop or home
              DefaultTabController.of(context).animateTo(0);
            },
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('Start Shopping'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(List<CartItem> cartItems) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: cartItems.length,
      itemBuilder: (context, index) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCartItemCard(context, cartItems[index]),
        );
      },
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItem item) {
    final hasError = _errorProductId == item.product.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasError
            ? BorderSide(color: Colors.blue[300]!, width: 2)
            : BorderSide.none,
      ),
      elevation: hasError ? 4 : 1,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Image with Hero animation
                Hero(
                  tag: 'cart_${item.product.id}',
                  child: Container(
                    width: 70,
                    height: 70,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        item.product.imageURL != null &&
                            item.product.imageURL!.isNotEmpty &&
                            !item.product.imageURL!.endsWith('undefined')
                        ? Image.network(
                            item.product.imageURL!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              getCategoryIcon(item.product.category),
                              color: Colors.grey[400],
                            ),
                            loadingBuilder: (context, child, progress) =>
                                progress == null
                                ? child
                                : Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary.withOpacity(0.5),
                                    ),
                                  ),
                          )
                        : Icon(
                            getCategoryIcon(item.product.category),
                            color: Colors.grey[400],
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '₹${item.product.price.toStringAsFixed(0)}',
                            style: GoogleFonts.poppins(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '× ${item.quantity}',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Subtotal: ₹${(item.product.price * item.quantity).toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Quantity Control
                _buildQuantityControl(context, item),
              ],
            ),
          ),
          // Error message banner
          if (hasError && _errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stock limit reached',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
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

  Widget _buildQuantityControl(BuildContext context, CartItem item) {
    final hasError = _errorProductId == item.product.id;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError ? Colors.blue[300]! : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: item.quantity > 1
                      ? () => _handleQuantityUpdate(
                          item.product.id,
                          item.quantity - 1,
                          item.quantity,
                        )
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.remove,
                      size: 18,
                      color: item.quantity > 1
                          ? AppColors.textPrimary
                          : Colors.grey[400],
                    ),
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 32),
                alignment: Alignment.center,
                child: Text(
                  item.quantity.toString(),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _handleQuantityUpdate(
                    item.product.id,
                    item.quantity + 1,
                    item.quantity,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.add,
                      size: 18,
                      color: hasError ? Colors.orange[700] : AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Delete Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _handleRemoveItem(item.product.id, item.product.title),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.delete_outline,
                color: Colors.red.shade400,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutBar(double cartTotal, int itemCount) {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total ($itemCount ${itemCount == 1 ? 'item' : 'items'})',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${cartTotal.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CheckoutPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Checkout',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearCart(BuildContext context) {
    final provider = context.read<CustomerProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            const SizedBox(width: 12),
            const Text('Clear Cart?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to remove all items from your cart?',
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Clear All'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await provider.clearCart();
                _showSuccessSnackBar('Cart cleared successfully');
              } catch (e) {
                _showErrorSnackBar('Failed to clear cart');
              }
            },
          ),
        ],
      ),
    );
  }
}

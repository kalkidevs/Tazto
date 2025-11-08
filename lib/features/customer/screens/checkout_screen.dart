import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
// Import your custom appbar
import 'package:tazto/features/customer/widgets/custom_appbar.dart';
import 'package:tazto/providers/customer_provider.dart';
import 'package:tazto/widgets/error_dialog.dart';

import '../models/cart_itemMdl.dart';
import '../models/customer_address_model.dart'; // Import Address model

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // --- ADDED: State variables to hold selections ---
  CustomerAddress? _selectedAddress;
  String _selectedPaymentMethod = 'card'; // Default to 'card'

  @override
  void initState() {
    super.initState();
    // --- ADDED: Initialize the selected address ---
    // Set the initial selected address to the first one in the user's list
    final provider = context.read<CustomerProvider>();
    if (provider.user?.addresses.isNotEmpty ?? false) {
      _selectedAddress = provider.user!.addresses.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to react to changes and read for actions
    final provider = context.watch<CustomerProvider>();
    final cartItems = provider.cart;
    final cartTotal = provider.cartTotal;
    // Example fees - replace with actual calculation logic if needed
    const double deliveryFee = 0.0;
    const double discount = 2.0;
    final double grandTotal = cartTotal - discount + deliveryFee;

    // --- UPDATED: Use the state variable ---
    // Safely get the selected address from our state
    final CustomerAddress? shippingAddress = _selectedAddress;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ShoppingAppBar(
        title: 'Checkout',
        subtitle:
            '${cartItems.length} ${cartItems.length == 1 ? "Item" : "Items"}',
        showBackButton: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              // Show checkout help/instructions
              _showCheckoutHelp(context);
            },
            tooltip: 'Checkout Help',
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
            // Extra bottom padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Order Summary ---
                _buildSectionHeader('Order Summary'),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) =>
                      _buildCartItemTile(cartItems[index]),
                  separatorBuilder: (context, index) =>
                      const Divider(height: 16),
                ),
                const SizedBox(height: 24),

                // --- Coupon ---
                _buildSectionHeader('Coupon Code'),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.local_offer_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('APPLY COUPON'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showApplyCouponDialog(context);
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // --- Price Details ---
                _buildSectionHeader('Price Details'),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildPriceRow('Item Total', cartTotal),
                        _buildPriceRow('Discount', -discount, isDiscount: true),
                        // Show discount as negative
                        _buildPriceRow(
                          'Delivery Fee',
                          deliveryFee,
                          isFree: deliveryFee == 0,
                        ),
                        const Divider(height: 20, thickness: 1),
                        _buildPriceRow(
                          'Grand Total',
                          grandTotal,
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // --- Delivery Address ---
                _buildSectionHeader('Delivery Address'),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  // --- UPDATED: Build address card based on state variable ---
                  child: shippingAddress == null
                      ? const ListTile(
                          title: Text('No address found'),
                          subtitle: Text(
                            'Please add an address in your profile.',
                          ),
                          leading: Icon(
                            Icons.location_off_outlined,
                            color: Colors.red,
                          ),
                        )
                      : ListTile(
                          leading: const Icon(
                            Icons.home_outlined,
                            color: AppColors.primary,
                          ),
                          title: Text(shippingAddress.label), // e.g., 'Home'
                          // Safely display address components
                          subtitle: Text(
                            '${shippingAddress.street}, ${shippingAddress.city}${shippingAddress.state != null ? ', ${shippingAddress.state}' : ''} - ${shippingAddress.pincode}',
                          ),
                          trailing: TextButton(
                            child: const Text(
                              'Change',
                              style: TextStyle(color: AppColors.primary),
                            ),
                            onPressed: () {
                              _showAddressSelectionDialog(context);
                            },
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // --- Payment Method ---
                _buildSectionHeader('Payment Method'),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  // --- UPDATED: Show selected payment method ---
                  child: ListTile(
                    leading: Icon(
                      _getPaymentIcon(_selectedPaymentMethod),
                      color: AppColors.primary,
                    ),
                    title: Text(_getPaymentMethodName(_selectedPaymentMethod)),
                    subtitle: _selectedPaymentMethod == 'card'
                        ? const Text('**** **** **** 6589')
                        : null,
                    trailing: TextButton(
                      child: const Text(
                        'Change',
                        style: TextStyle(color: AppColors.primary),
                      ),
                      onPressed: () {
                        _showPaymentMethodSelectionDialog(context);
                      },
                    ),
                    onTap: () {
                      _showPaymentMethodSelectionDialog(context);
                    },
                  ),
                ),
                const SizedBox(height: 40), // Additional space
              ],
            ),
          ),

          // --- Bottom Place Order Button ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
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
              child: ElevatedButton(
                // Disable button if placing order, no items, or no address
                onPressed:
                    provider.isPlacingOrder ||
                        cartItems.isEmpty ||
                        shippingAddress == null
                    ? null
                    : () async {
                        bool success = await context
                            .read<CustomerProvider>()
                            .placeOrder(
                              // --- ADDED: Pass selected address to provider ---
                              selectedAddress: _selectedAddress!,
                            );
                        if (success && context.mounted) {
                          // Show success dialog
                          showSuccessDialog(
                            context,
                            'Order Placed!',
                            'Your order has been placed successfully. You can track it in the Orders section.',
                            () {
                              // onOk pressed
                              Navigator.of(context).popUntil(
                                (route) => route.isFirst,
                              ); // Go back to home screen
                            },
                          );
                        } else if (!success && context.mounted) {
                          // Show error dialog using the provider's error message
                          showErrorDialog(
                            context,
                            'Order Failed',
                            context.read<CustomerProvider>().placeOrderError ??
                                'An unknown error occurred.',
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  // Full width
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                // Show loading indicator or text
                child: provider.isPlacingOrder
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Place Order  ₹${grandTotal.toStringAsFixed(0)}'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for section headers
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  // Helper widget for cart item tile in summary
  Widget _buildCartItemTile(CartItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  item.product.imageURL != null &&
                      item.product.imageURL!.isNotEmpty
                  ? Image.network(
                      item.product.imageURL!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                      ),
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : Center(
                              child: CircularProgressIndicator(strokeWidth: 1),
                            ),
                    )
                  : Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[400],
                      size: 30,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${item.product.price.toStringAsFixed(0)} each',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '₹${(item.product.price * item.quantity).toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for price rows
  Widget _buildPriceRow(
    String label,
    double value, {
    bool isTotal = false,
    bool isDiscount = false,
    bool isFree = false,
  }) {
    final style = GoogleFonts.poppins(
      fontSize: isTotal ? 16 : 14,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
      color: isDiscount
          ? AppColors.primary
          : (isTotal ? AppColors.textPrimary : Colors.grey[700]),
    );
    final valueText = isFree
        ? 'Free'
        : (isDiscount
              ? '- ₹${value.abs().toStringAsFixed(0)}'
              : '₹${value.toStringAsFixed(0)}');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: style.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.textPrimary : Colors.grey[700],
            ),
          ),
          Text(valueText, style: style),
        ],
      ),
    );
  }

  // Helper method to show checkout help
  void _showCheckoutHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Checkout Help',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Before placing your order, please ensure:',
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 8),
              _buildHelpItem('Your delivery address is correct'),
              _buildHelpItem('Payment method is selected'),
              _buildHelpItem('All items are as expected'),
              const SizedBox(height: 16),
              Text(
                'Need assistance?',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper widget for help items
  Widget _buildHelpItem(String text) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: AppColors.primary, size: 16),
        const SizedBox(width: 8),
        Flexible(child: Text(text, style: GoogleFonts.poppins(fontSize: 12))),
      ],
    );
  }

  // Helper method to show apply coupon dialog
  void _showApplyCouponDialog(BuildContext context) {
    TextEditingController couponController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Apply Coupon',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: TextField(
            controller: couponController,
            decoration: InputDecoration(
              hintText: 'Enter coupon code',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Apply coupon logic here
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Coupon "${couponController.text}" applied!'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text('Apply', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }

  // --- UPDATED: Address selection dialog is now stateful ---
  void _showAddressSelectionDialog(BuildContext context) {
    final provider = context.read<CustomerProvider>();
    final addresses = provider.user!.addresses;
    // Temporary variable to hold selection within the dialog
    String? tempSelectedAddressId = _selectedAddress?.id;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Use StatefulBuilder to manage the dialog's internal state
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Text(
                'Select Address',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              content: addresses.isEmpty
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No addresses found',
                          style: GoogleFonts.poppins(),
                        ),
                        Text(
                          'Add an address in your profile',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    )
                  : Container(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: addresses.length,
                        itemBuilder: (context, index) {
                          final address = addresses[index];
                          return RadioListTile<String>(
                            title: Text(address.label),
                            subtitle: Text(
                              '${address.street}, ${address.city}${address.state != null ? ', ${address.state}' : ''} - ${address.pincode}',
                            ),
                            value: address.id,
                            // Use the dialog's state variable
                            groupValue: tempSelectedAddressId,
                            onChanged: (value) {
                              // Update the dialog's state
                              dialogSetState(() {
                                tempSelectedAddressId = value;
                              });
                            },
                          );
                        },
                      ),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
                // --- ADDED: Select Button ---
                ElevatedButton(
                  onPressed: () {
                    if (tempSelectedAddressId != null) {
                      // Find the full address object
                      final newSelectedAddress = addresses.firstWhere(
                        (addr) => addr.id == tempSelectedAddressId,
                      );
                      // Update the main page's state
                      setState(() {
                        _selectedAddress = newSelectedAddress;
                      });
                    }
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Select', style: GoogleFonts.poppins()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- UPDATED: Payment method selection dialog is now stateful ---
  void _showPaymentMethodSelectionDialog(BuildContext context) {
    // Temporary variable to hold selection within the dialog
    String? tempSelectedPayment = _selectedPaymentMethod;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Use StatefulBuilder to manage the dialog's internal state
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Text(
                'Select Payment Method',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text('Credit/Debit Card'),
                    subtitle: const Text('**** **** **** 6589'),
                    value: 'card',
                    groupValue: tempSelectedPayment,
                    onChanged: (value) {
                      dialogSetState(() {
                        tempSelectedPayment = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Cash on Delivery'),
                    value: 'cod',
                    groupValue: tempSelectedPayment,
                    onChanged: (value) {
                      dialogSetState(() {
                        tempSelectedPayment = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Digital Wallet'),
                    value: 'wallet',
                    groupValue: tempSelectedPayment,
                    onChanged: (value) {
                      dialogSetState(() {
                        tempSelectedPayment = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update the main page's state
                    if (tempSelectedPayment != null) {
                      setState(() {
                        _selectedPaymentMethod = tempSelectedPayment!;
                      });
                    }
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Save', style: GoogleFonts.poppins()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- ADDED: Helper functions for payment method ---
  String _getPaymentMethodName(String methodKey) {
    switch (methodKey) {
      case 'cod':
        return 'Cash on Delivery';
      case 'wallet':
        return 'Digital Wallet';
      case 'card':
      default:
        return 'Credit/Debit Card';
    }
  }

  IconData _getPaymentIcon(String methodKey) {
    switch (methodKey) {
      case 'cod':
        return Icons.money;
      case 'wallet':
        return Icons.wallet;
      case 'card':
      default:
        return Icons.credit_card;
    }
  }
}

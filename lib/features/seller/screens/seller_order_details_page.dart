import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/features/seller/models/seller_order_model.dart';
import 'package:tazto/providers/seller_provider.dart';
import 'package:tazto/widgets/error_dialog.dart';

class SellerOrderDetailsPage extends StatefulWidget {
  final SellerOrder order;

  const SellerOrderDetailsPage({super.key, required this.order});

  @override
  State<SellerOrderDetailsPage> createState() => _SellerOrderDetailsPageState();
}

class _SellerOrderDetailsPageState extends State<SellerOrderDetailsPage> {
  late String _currentStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order.status;
  }

  String get _orderIdShort {
    return 'ORD-${widget.order.id.substring(widget.order.id.length - 6).toUpperCase()}';
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    final provider = context.read<SellerProvider>();

    final success = await provider.updateOrderStatus(
      orderId: widget.order.id,
      status: newStatus,
    );

    if (mounted) {
      if (success) {
        setState(() {
          _currentStatus = newStatus;
        });
        showSuccessDialog(context, 'Status Updated',
            'Order has been moved to "$newStatus"', () {
              Navigator.of(context).pop(); // pop dialog
            });
      } else {
        showErrorDialog(context, 'Update Failed',
            provider.ordersError ?? 'An unknown error occurred.');
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _orderIdShort,
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Customer & Address',
              icon: Icons.person_outline,
              child: _buildCustomerDetails(),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Order Summary',
              icon: Icons.list_alt_outlined,
              child: _buildOrderSummary(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STATUS',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                _currentStatus,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'ORDER PLACED',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                DateFormat('dd MMM yyyy, h:mm a').format(widget.order.orderDate),
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      {required String title,
        required IconData icon,
        required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildCustomerDetails() {
    final address = widget.order.shippingAddress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.order.customerName,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        if (address.phone != null)
          Text(
            address.phone!,
            style: GoogleFonts.poppins(
                fontSize: 13, color: AppColors.textSecondary),
          ),
        const SizedBox(height: 8),
        Text(
          '${address.street}, ${address.city}, ${address.state ?? ''} - ${address.pincode}',
          style:
          GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.order.items.length,
          itemBuilder: (context, index) {
            final item = widget.order.items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text(
                    '${item.quantity} x',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item.title, style: GoogleFonts.poppins())),
                  const SizedBox(width: 8),
                  Text(
                    '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          },
        ),
        const Divider(height: 24),
        _buildPriceRow('Item Total', widget.order.totalAmount),
        _buildPriceRow('Delivery Fee', 0.0), // Assuming free delivery
        const Divider(height: 16),
        _buildPriceRow('Grand Total', widget.order.totalAmount, isTotal: true),
      ],
    );
  }

  Widget _buildPriceRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    Widget primaryButton;
    Widget? secondaryButton;

    switch (_currentStatus) {
      case 'Pending':
        primaryButton = _buildButton(
          'Accept Order',
          AppColors.primary,
              () => _updateStatus('Confirmed'), // 'Confirmed' is 'Preparing' in UI
        );
        secondaryButton = _buildButton(
          'Cancel Order',
          Colors.red,
              () => _updateStatus('Cancelled'),
          isOutlined: true,
        );
        break;
      case 'Confirmed': // This is 'Preparing'
        primaryButton = _buildButton(
          'Mark as Ready',
          AppColors.primary,
              () => _updateStatus('Shipped'), // 'Shipped' is 'Ready' in UI
        );
        break;
      case 'Shipped': // This is 'Ready'
        primaryButton = _buildButton(
          'Mark as Completed', // Assuming a driver app isn't built yet
          Colors.green,
              () => _updateStatus('Delivered'),
        );
        break;
      default:
        return const SizedBox.shrink(); // No actions for Completed/Cancelled
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          if (secondaryButton != null) Expanded(child: secondaryButton),
          if (secondaryButton != null) const SizedBox(width: 16),
          Expanded(child: primaryButton),
        ],
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed,
      {bool isOutlined = false}) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          minimumSize: const Size(double.infinity, 50),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(text, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
    );
  }
}
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
        showSuccessDialog(
          context,
          'Status Updated',
          'Order has been moved to "$newStatus"',
          () {
            Navigator.of(context).pop(); // pop dialog
          },
        );
      } else {
        showErrorDialog(
          context,
          'Update Failed',
          provider.ordersError ?? 'An unknown error occurred.',
        );
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
    Color statusColor;
    Color statusBg;

    // Status color logic same as dashboard for consistency
    switch (_currentStatus) {
      case 'Pending':
        statusColor = Colors.orange.shade700;
        statusBg = Colors.orange.shade50;
        break;
      case 'Confirmed':
        statusColor = Colors.blue.shade700;
        statusBg = Colors.blue.shade50;
        break;
      case 'Shipped':
        statusColor = Colors.purple.shade700;
        statusBg = Colors.purple.shade50;
        break;
      case 'Delivered':
        statusColor = Colors.green.shade700;
        statusBg = Colors.green.shade50;
        break;
      case 'Cancelled':
        statusColor = Colors.red.shade700;
        statusBg = Colors.red.shade50;
        break;
      default:
        statusColor = Colors.grey.shade700;
        statusBg = Colors.grey.shade100;
    }

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
                'CURRENT STATUS',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _currentStatus.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
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
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                DateFormat('dd MMM, h:mm a').format(widget.order.orderDate),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
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
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
        Row(
          children: [
            const Icon(Icons.person, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              widget.order.customerName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (address.phone != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  address.phone!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${address.street}, ${address.city}, ${address.state ?? ''} - ${address.pincode}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ),
          ],
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
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.quantity}x',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Item Price: ₹${item.price.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
              color: isTotal ? AppColors.textPrimary : Colors.grey[600],
            ),
          ),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? AppColors.primary : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    // If order is completed or cancelled, don't show action buttons
    if (_currentStatus == 'Delivered' || _currentStatus == 'Cancelled') {
      return const SizedBox.shrink();
    }

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
          () => _updateStatus('Confirmed'), // Confirmed = Preparing
        );
        secondaryButton = _buildButton(
          'Reject Order',
          Colors.red,
          () => _updateStatus('Cancelled'),
          isOutlined: true,
        );
        break;
      case 'Confirmed': // Preparing
        primaryButton = _buildButton(
          'Mark Ready to Ship',
          AppColors.primary,
          () => _updateStatus('Shipped'), // Shipped = Ready
        );
        break;
      case 'Shipped': // Ready
        primaryButton = _buildButton(
          'Complete Delivery',
          Colors.green,
          () => _updateStatus('Delivered'),
        );
        break;
      default:
        return const SizedBox.shrink();
    }

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
      child: Row(
        children: [
          if (secondaryButton != null) Expanded(child: secondaryButton),
          if (secondaryButton != null) const SizedBox(width: 16),
          Expanded(child: primaryButton),
        ],
      ),
    );
  }

  Widget _buildButton(
    String text,
    Color color,
    VoidCallback onPressed, {
    bool isOutlined = false,
  }) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    );
  }
}

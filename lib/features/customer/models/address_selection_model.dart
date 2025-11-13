import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/features/customer/features/01_address/screens/add_new_address.dart';
import 'package:tazto/features/customer/models/customer_address_model.dart';
import 'package:tazto/providers/customer_provider.dart';

class AddressSelectionModal extends StatefulWidget {
  const AddressSelectionModal({super.key});

  @override
  State<AddressSelectionModal> createState() => _AddressSelectionModalState();
}

class _AddressSelectionModalState extends State<AddressSelectionModal>
    with SingleTickerProviderStateMixin {
  String? _selectedAddressId;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Set initial selected address from provider
    final provider = context.read<CustomerProvider>();
    final defaultAddress = provider.user?.addresses.firstWhere(
          (addr) => addr.isDefault, // Find the default address
      orElse: () => provider.user!.addresses
          .first, // Or fallback to the first address
    );
    _selectedAddressId = defaultAddress?.id;

    // Blinking animation for the confirm button
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.05).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeInOut,
        ));
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (_selectedAddressId == null) return;
    final provider = context.read<CustomerProvider>();

    // Set the new default address
    provider.setDefaultAddress(_selectedAddressId!);

    // Close the bottom sheet
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final addresses = provider.user?.addresses ?? [];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select Delivery Address',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(height: 1),
            if (addresses.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'No addresses found. Please add a new address.',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    return _buildAddressTile(address);
                  },
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    icon:
                    const Icon(Icons.add_location_alt_outlined, size: 20),
                    label: const Text('Add a new address'),
                    onPressed: () {
                      Navigator.pop(context); // Close modal first
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddAddressPage()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: ElevatedButton(
                      onPressed: _onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Confirm Location',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressTile(CustomerAddress address) {
    final bool isSelected = _selectedAddressId == address.id;
    return RadioListTile<String>(
      value: address.id,
      groupValue: _selectedAddressId,
      onChanged: (value) {
        setState(() {
          _selectedAddressId = value;
        });
      },
      activeColor: AppColors.primary,
      title: Text(
        address.label,
        style: GoogleFonts.poppins(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '${address.street}, ${address.city} - ${address.pincode}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(fontSize: 13),
      ),
      secondary: Icon(
        address.label.toLowerCase() == 'home'
            ? Icons.home_outlined
            : address.label.toLowerCase() == 'work'
            ? Icons.work_outline
            : Icons.location_on_outlined,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }
}
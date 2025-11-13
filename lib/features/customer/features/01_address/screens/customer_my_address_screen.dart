import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/features/customer/features/01_address/screens/add_new_address.dart';
import 'package:tazto/features/customer/models/customer_address_model.dart';
import 'package:tazto/features/customer/widgets/custom_appbar.dart';
import 'package:tazto/providers/customer_provider.dart';

/// New page to display and manage all of the user's saved addresses.
class MyAddressesPage extends StatefulWidget {
  const MyAddressesPage({super.key});

  @override
  State<MyAddressesPage> createState() => _MyAddressesPageState();
}

class _MyAddressesPageState extends State<MyAddressesPage> {
  /// Shows a confirmation dialog before deleting an address
  void _confirmDeleteAddress(
      BuildContext context,
      CustomerProvider provider,
      String addressId,
      ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_outlined, color: Colors.orange[700]),
            const SizedBox(width: 12),
            const Text('Delete Address?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this address? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await provider.deleteAddress(addressId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Address deleted successfully'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  /// Calls the provider to set the default address
  Future<void> _onSetDefault(CustomerProvider provider, String addressId) async {
    try {
      await provider.setDefaultAddress(addressId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Default address updated!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set default: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider for updates
    final provider = context.watch<CustomerProvider>();
    final addresses = provider.user?.addresses ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const ShoppingAppBar(
        title: 'My Addresses',
        showBackButton: true,
      ),
      body: addresses.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined,
                size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No addresses saved yet',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add Your First Address'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddAddressPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            )
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: addresses.length,
        itemBuilder: (context, index) {
          final address = addresses[index];
          return AddressCard(
            address: address,
            onEdit: () {
              // TODO: Implement Edit Address Page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Edit address ${address.id} coming soon!',
                  ),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            onDelete: () {
              _confirmDeleteAddress(context, provider, address.id);
            },
            onSetDefault: () {
              _onSetDefault(provider, address.id);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddAddressPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

/// ============== ADDRESS CARD (Moved here) ==============
class AddressCard extends StatelessWidget {
  final CustomerAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const AddressCard({
    super.key,
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
          address.isDefault ? AppColors.primary : Colors.grey.shade200,
          width: address.isDefault ? 1.5 : 1.0,
        ),
        boxShadow: address.isDefault
            ? [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          )
        ]
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_getAddressIcon(),
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${address.street}, ${address.city} - ${address.pincode}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                    if (address.phone != null && address.phone!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Phone: ${address.phone}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon:
                Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!address.isDefault) ...[
            const Divider(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onSetDefault,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: const Text(
                  'Set as Default',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Default Address',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getAddressIcon() {
    final label = address.label.toLowerCase();
    if (label == 'home') return Icons.home_outlined;
    if (label == 'work') return Icons.work_outline;
    return Icons.location_on_outlined;
  }
}
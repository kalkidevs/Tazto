import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/features/customer/features/01_address/screens/add_new_address.dart';
import 'package:tazto/features/customer/models/customer_address_model.dart';
import 'package:tazto/features/customer/models/customer_user_model.dart';
import 'package:tazto/providers/customer_provider.dart';

import '../widgets/customer_profile_widgets.dart';

/// ============== QUICK STATS SECTION ==============
class ProfileQuickStats extends StatelessWidget {
  final CustomerProvider provider;
  final CustomerUser user;

  const ProfileQuickStats({
    super.key,
    required this.provider,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              icon: Icons.shopping_bag_outlined,
              label: 'Orders',
              value: '${provider.orders.length}',
              color: Colors.blue,
              onTap: () => debugPrint('Navigate to orders'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              icon: Icons.favorite_outline,
              label: 'Wishlist',
              value: '8',
              color: Colors.red,
              onTap: () => debugPrint('Navigate to wishlist'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
              icon: Icons.location_on_outlined,
              label: 'Addresses',
              value: '${user.addresses.length}',
              color: Colors.green,
              onTap: () => debugPrint('Navigate to addresses'),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============== ACCOUNT SECTION ==============
class ProfileAccountSection extends StatelessWidget {
  final CustomerUser user;

  const ProfileAccountSection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: 'Account Information',
      icon: Icons.person_outline,
      child: Column(
        children: [
          InfoTile(
            icon: Icons.person_outline,
            label: 'Full Name',
            value: user.name,
          ),
          InfoTile(
            icon: Icons.email_outlined,
            label: 'Email Address',
            value: user.email,
          ),
          if (user.phone != null && user.phone!.isNotEmpty)
            InfoTile(
              icon: Icons.phone_outlined,
              label: 'Phone Number',
              value: user.phone!,
            ),
          InfoTile(
            icon: Icons.calendar_today_outlined,
            label: 'Member Since',
            value: user.memberSince, // Using the new helper from user_model
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: OutlinedButton.icon(
              onPressed: () {
                showEditProfileDialog(
                  context,
                  context.read<CustomerProvider>(),
                );
                debugPrint('Edit profile');
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============== ADDRESSES SECTION ==============
class ProfileAddressesSection extends StatelessWidget {
  final CustomerProvider provider;
  final List<CustomerAddress> addresses;

  const ProfileAddressesSection({
    super.key,
    required this.provider,
    required this.addresses,
  });

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: 'Saved Addresses',
      icon: Icons.location_on_outlined,
      trailing: TextButton.icon(
        icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
        label: const Text(
          'Add New',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddAddressPage()),
          );
        },
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
      ),
      child: addresses.isEmpty
          ? EmptyState(
              icon: Icons.location_off_outlined,
              message: 'No addresses saved yet',
              description: 'Add delivery addresses for faster checkout',
              actionLabel: 'Add Address',
              onAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddAddressPage()),
                );
              },
            )
          : Column(
              children: addresses
                  .map(
                    (address) => AddressCard(
                      address: address,
                      onEdit: () {
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Set as default address'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
    );
  }

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
}

/// ============== ADDRESS CARD ==============
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
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_getAddressIcon(), color: AppColors.primary, size: 20),
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
                    fontSize: 14,
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
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              } else if (value == 'default') {
                onSetDefault();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'default',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 18),
                    SizedBox(width: 12),
                    Text('Set as Default'),
                  ],
                ),
              ),
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
                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
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

/// ============== ORDERS SECTION ==============
class ProfileOrdersSection extends StatelessWidget {
  const ProfileOrdersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: 'My Orders',
      icon: Icons.shopping_cart_outlined,
      trailing: TextButton(
        onPressed: () => debugPrint('Navigate to all orders'),
        child: const Text(
          'View All',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Column(
        children: [
          MenuTile(
            icon: Icons.pending_actions_outlined,
            iconColor: Colors.orange,
            title: 'Pending Orders',
            subtitle: '2 orders awaiting confirmation',
            trailing: const ProfileBadge(text: '2', color: Colors.orange),
            onTap: () => debugPrint('Navigate to pending orders'),
          ),
          MenuTile(
            icon: Icons.local_shipping_outlined,
            iconColor: Colors.blue,
            title: 'In Transit',
            subtitle: '1 order on the way',
            trailing: const ProfileBadge(text: '1', color: Colors.blue),
            onTap: () => debugPrint('Navigate to in transit orders'),
          ),
          MenuTile(
            icon: Icons.check_circle_outline,
            iconColor: Colors.green,
            title: 'Completed',
            subtitle: 'View order history',
            onTap: () => debugPrint('Navigate to completed orders'),
          ),
          MenuTile(
            icon: Icons.replay_outlined,
            iconColor: Colors.purple,
            title: 'Returns & Refunds',
            subtitle: 'Manage returns',
            onTap: () => debugPrint('Navigate to returns'),
          ),
        ],
      ),
    );
  }
}

/// ============== WALLET SECTION ==============
class ProfileWalletSection extends StatelessWidget {
  const ProfileWalletSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: 'Wallet & Payments',
      icon: Icons.account_balance_wallet_outlined,
      child: Column(
        children: [
          _buildWalletBalance(),
          MenuTile(
            icon: Icons.receipt_long_outlined,
            iconColor: Colors.blue,
            title: 'Transaction History',
            subtitle: 'View all transactions',
            onTap: () => debugPrint('Navigate to transaction history'),
          ),
          MenuTile(
            icon: Icons.credit_card_outlined,
            iconColor: Colors.purple,
            title: 'Saved Cards',
            subtitle: 'Manage payment methods',
            onTap: () => debugPrint('Navigate to saved cards'),
          ),
          MenuTile(
            icon: Icons.loyalty_outlined,
            iconColor: Colors.amber,
            title: 'Coupons & Offers',
            subtitle: 'View available offers',
            trailing: const ProfileBadge(text: '5', color: Colors.amber),
            onTap: () => debugPrint('Navigate to coupons'),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletBalance() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wallet Balance',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '₹1,250.00',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => debugPrint('Add money to wallet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Add Money',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============== SETTINGS SECTION ==============
class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: 'Settings & Preferences',
      icon: Icons.settings_outlined,
      child: Column(
        children: [
          MenuTile(
            icon: Icons.notifications_outlined,
            iconColor: Colors.orange,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () => debugPrint('Navigate to notifications settings'),
          ),
          MenuTile(
            icon: Icons.language_outlined,
            iconColor: Colors.blue,
            title: 'Language',
            subtitle: 'English',
            onTap: () => debugPrint('Navigate to language settings'),
          ),
          MenuTile(
            icon: Icons.lock_outline,
            iconColor: Colors.red,
            title: 'Privacy & Security',
            subtitle: 'Change password, privacy settings',
            onTap: () => debugPrint('Navigate to privacy settings'),
          ),
          MenuTile(
            icon: Icons.help_outline,
            iconColor: Colors.green,
            title: 'Help & Support',
            subtitle: 'FAQs, contact support',
            onTap: () => debugPrint('Navigate to help & support'),
          ),
          MenuTile(
            icon: Icons.star_outline,
            iconColor: Colors.amber,
            title: 'Rate Us',
            subtitle: 'Share your feedback',
            onTap: () => debugPrint('Open rating dialog'),
          ),
          MenuTile(
            icon: Icons.share_outlined,
            iconColor: Colors.purple,
            title: 'Refer & Earn',
            subtitle: 'Invite friends and get rewards',
            onTap: () => debugPrint('Navigate to referral program'),
          ),
          MenuTile(
            icon: Icons.info_outline,
            iconColor: Colors.grey,
            title: 'About',
            subtitle: 'Terms, privacy & app info',
            onTap: () => debugPrint('Navigate to about page'),
          ),
        ],
      ),
    );
  }
}

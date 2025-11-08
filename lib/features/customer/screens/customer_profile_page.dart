import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/features/customer/features/01_address/screens/add_new_address.dart';
import 'package:tazto/providers/customer_provider.dart';
import 'package:tazto/widgets/logout_button.dart';

import '../widgets/custom_appbar.dart';
import '../widgets/customer_profile_sections.dart';
import '../widgets/customer_profile_widgets.dart';

/// Customer Profile Page - Main Screen
class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => CustomerProfilePageState();
}

class CustomerProfilePageState extends State<CustomerProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserProfile();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  void _loadUserProfile() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CustomerProvider>();
      if (provider.user == null && !provider.isLoadingUser) {
        provider.fetchUserProfile();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Public method to check and show address form if needed
  void checkAndShowAddressForm() {
    if (!mounted) return;
    final provider = context.read<CustomerProvider>();
    final user = provider.user;
    if (user != null && user.addresses.isEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddAddressPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        final user = provider.user;

        // Loading State
        if (provider.isLoadingUser && user == null) {
          return const CustomerProfileLoadingState();
        }

        // Error State
        if (provider.userError != null) {
          return CustomerProfileErrorState(
            error: provider.userError!,
            onRetry: provider.fetchUserProfile,
          );
        }

        // Not Logged In State
        if (user == null) {
          return const CustomerProfileNotLoggedInState();
        }

        // Main Profile Content
        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            onRefresh: () async {
              await provider.fetchUserProfile();
              _animationController.forward(from: 0);
            },
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                ShoppingAppBar(
                  title: 'My Profile',
                  // subtitle: user.name ?? 'Customer',
                  showBackButton: false,
                  useSliverAppBar: true,
                  backgroundColor: AppColors.background,
                  foregroundColor: AppColors.textPrimary,
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        // Navigate to notifications
                      },
                      tooltip: 'Notifications',
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (String value) {
                        switch (value) {
                          case 'edit':
                            // Navigate to edit profile
                            break;
                          case 'settings':
                            // Navigate to settings
                            break;
                          case 'help':
                            // Navigate to help
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Edit Profile'),
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'settings',
                              child: ListTile(
                                leading: Icon(Icons.settings_outlined),
                                title: Text('Settings'),
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem<String>(
                              value: 'help',
                              child: ListTile(
                                leading: Icon(Icons.help_outline),
                                title: Text('Help & Support'),
                              ),
                            ),
                          ],
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        CustomerProfileHeader(user: user),
                        const SizedBox(height: 24),
                        ProfileQuickStats(provider: provider, user: user),
                        const SizedBox(height: 24),
                        ProfileAccountSection(user: user),
                        const SizedBox(height: 16),
                        ProfileAddressesSection(
                          provider: provider,
                          addresses: user.addresses,
                        ),
                        const SizedBox(height: 16),
                        const ProfileOrdersSection(),
                        const SizedBox(height: 16),
                        const ProfileWalletSection(),
                        const SizedBox(height: 16),
                        const ProfileSettingsSection(),
                        const SizedBox(height: 24),
                         Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: ReusableLogoutButton(),
                        ),
                        const SizedBox(height: 32),
                        const CustomerProfileAppVersion(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

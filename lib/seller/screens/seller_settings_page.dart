// lib/screens/seller/seller_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tazto/auth/login_screen.dart';
import 'package:tazto/providers/loginPdr.dart';

class SellerSettingsPage extends StatelessWidget {
  const SellerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Account Info
          _buildSectionHeader(context, 'Account'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            subtitle: const Text('Edit your personal info'),
            onTap: () {
              // TODO: navigate to Profile/Edit page
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            subtitle: const Text('Update your password'),
            onTap: () {
              // TODO: navigate to Change Password page
            },
          ),
          const SizedBox(height: 24),

          // Store Settings
          _buildSectionHeader(context, 'Store'),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Store Information'),
            subtitle: const Text('Manage store details'),
            onTap: () {
              // TODO: navigate to Store Info page
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_outlined),
            title: const Text('Manage Products'),
            subtitle: const Text('Add, edit or remove products'),
            onTap: () {
              // TODO: navigate to SellerProductsPage
            },
          ),
          const SizedBox(height: 24),

          // App Preferences
          _buildSectionHeader(context, 'Preferences'),
          Consumer<LoginProvider>(
            builder: (_, loginProv, __) {
              return SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark Mode'),
                value: Theme.of(context).brightness == Brightness.dark,
                onChanged: (on) {
                  // TODO: wire up real theme change with provider
                },
              );
            },
          ),
          const ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('Notifications'),
            subtitle: Text('Manage notification settings'),
          ),
          const SizedBox(height: 24),

          // Support
          _buildSectionHeader(context, 'Support'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & FAQs'),
            onTap: () {
              // TODO: navigate to Help/FAQ page
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('Send Feedback'),
            onTap: () {
              // TODO: open feedback form or email
            },
          ),
          const SizedBox(height: 32),

          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout_outlined, color: Colors.white),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => _confirmLogout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.black54,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text(
          'Are you sure you want to logout? You will need to login again to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();

              // Pop the dialog
              Navigator.of(context).pop();

              // Navigate to LoginPage and clear back stack
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: Text('Logout', style: TextStyle(color: Colors.red.shade600)),
          ),
        ],
      ),
    );
  }
}

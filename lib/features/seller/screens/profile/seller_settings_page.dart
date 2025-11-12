import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/features/seller/models/seller_store_model.dart';
import 'package:tazto/helper/dialog_helper.dart';
import 'package:tazto/providers/seller_provider.dart';


/// New Settings page based on the UI design (Image 9, 10, 11, 12)
class SellerSettingsPage extends StatefulWidget {
  const SellerSettingsPage({super.key});

  @override
  State<SellerSettingsPage> createState() => _SellerSettingsPageState();
}

class _SellerSettingsPageState extends State<SellerSettingsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SellerProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: provider.isLoadingStore && provider.store == null
          ? const Center(child: CircularProgressIndicator())
          : provider.store == null
          ? const Center(child: Text('Could not load store profile.'))
          : Column(
              children: [
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: GoogleFonts.poppins(),
                  tabs: const [
                    Tab(text: 'Store Details'),
                    Tab(text: 'Operating Hours'),
                    Tab(text: 'Notifications'),
                    Tab(text: 'Security'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      StoreDetailsTab(store: provider.store!),
                      OperatingHoursTab(store: provider.store!),
                      const NotificationsTab(),
                      const SecurityTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// --- Store Details Tab (Image 9) ---
class StoreDetailsTab extends StatefulWidget {
  final Store store;

  const StoreDetailsTab({super.key, required this.store});

  @override
  State<StoreDetailsTab> createState() => _StoreDetailsTabState();
}

class _StoreDetailsTabState extends State<StoreDetailsTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _storeNameC,
      _ownerNameC,
      _descriptionC,
      _phoneC,
      _emailC,
      _addressC,
      _gstC;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _storeNameC = TextEditingController(text: widget.store.storeName);
    _ownerNameC = TextEditingController(
      text: widget.store.ownerName,
    ); // <-- FIXED: Use widget.store.ownerName
    _descriptionC = TextEditingController(text: widget.store.storeDescription);
    _phoneC = TextEditingController(text: widget.store.phone);
    _emailC = TextEditingController(text: widget.store.email);
    _addressC = TextEditingController(text: widget.store.address);
    _gstC = TextEditingController(text: widget.store.gstNumber);
  }

  @override
  void dispose() {
    _storeNameC.dispose();
    _ownerNameC.dispose();
    _descriptionC.dispose();
    _phoneC.dispose();
    _emailC.dispose();
    _addressC.dispose();
    _gstC.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final provider = context.read<SellerProvider>();
    // Create a map of updates
    final updates = {
      'storeName': _storeNameC.text,
      'storeDescription': _descriptionC.text,
      'phone': _phoneC.text,
      'email': _emailC.text,
      'address': _addressC.text,
      'gstNumber': _gstC.text,
      // 'ownerName': _ownerNameC.text, // Cannot update owner name this way
    };

    final success = await provider.updateStoreProfile(updates);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Success'),
            content: const Text('Store details updated successfully!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showErrorDialog(
          context,
          'Update Failed',
          provider.storeError ?? 'An unknown error occurred.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildSection(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(
                      Icons.storefront,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {}, // TODO: Implement image picker
                    icon: const Icon(Icons.camera_alt_outlined, size: 16),
                    label: const Text('Change Logo'),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _storeNameC,
                    'Store Name',
                    Icons.storefront_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _ownerNameC,
                    'Owner Name',
                    Icons.person_outline,
                    readOnly: true,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _descriptionC,
                    'Store Description',
                    Icons.description_outlined,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              child: Column(
                children: [
                  _buildTextField(
                    _phoneC,
                    'Phone Number',
                    Icons.phone_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _emailC,
                    'Email Address',
                    Icons.email_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _addressC,
                    'Store Address',
                    Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _gstC,
                    'GST Number (Optional)',
                    Icons.receipt_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  TextFormField _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool readOnly = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      validator: (value) {
        if (!readOnly && (value == null || value.isEmpty)) {
          return '$label is required';
        }
        return null;
      },
    );
  }
}

// --- Operating Hours Tab (Image 10, 11) ---
class OperatingHoursTab extends StatefulWidget {
  final Store store;

  const OperatingHoursTab({super.key, required this.store});

  @override
  State<OperatingHoursTab> createState() => _OperatingHoursTabState();
}

class _OperatingHoursTabState extends State<OperatingHoursTab> {
  // TODO: Initialize state from widget.store.schedule
  bool _isOpen = true;
  bool _autoAccept = false;

  @override
  void initState() {
    super.initState();
    _isOpen = widget.store.isOpen;
    _autoAccept = widget.store.autoAcceptOrders;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Store Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: SwitchListTile(
              title: Text(
                'Store is currently Open',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Accepting new orders',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              value: _isOpen,
              onChanged: (val) => setState(() => _isOpen = val),
              secondary: Icon(
                Icons.storefront,
                color: _isOpen ? Colors.green : Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Weekly Schedule (Placeholder)
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Schedule',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Schedule editor coming soon...',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary),
                ),
                // TODO: Build the full schedule editor
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Order Settings
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SwitchListTile(
                  title: Text(
                    'Auto-accept Orders',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Automatically accept all incoming orders',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  value: _autoAccept,
                  onChanged: (val) => setState(() => _autoAccept = val),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                Text(
                  'Average Preparation Time (minutes)',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  initialValue: widget.store.avgPreparationTime.toString(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Text(
                  'Minimum Order Value (₹)',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  initialValue: widget.store.minOrderValue.toStringAsFixed(0),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement save logic for this tab
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}

// --- Notifications Tab (Image 12) ---
class NotificationsTab extends StatelessWidget {
  const NotificationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Preferences',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _NotifySwitch(
              title: 'Email Notifications',
              subtitle: 'Receive order updates via email',
              value: true,
            ),
            _NotifySwitch(
              title: 'SMS Notifications',
              subtitle: 'Receive order updates via SMS',
              value: false,
            ),
            _NotifySwitch(
              title: 'New Order Alerts',
              subtitle: 'Get notified when new orders arrive',
              value: true,
            ),
            _NotifySwitch(
              title: 'Low Stock Alerts',
              subtitle: 'Alert when products are running low',
              value: true,
            ),
            _NotifySwitch(
              title: 'Payment Updates',
              subtitle: 'Notifications for settlements and payouts',
              value: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifySwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;

  const _NotifySwitch({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12)),
      value: value,
      onChanged: (val) {},
      // TODO: Implement state change
      contentPadding: EdgeInsets.zero,
    );
  }
}

// --- Security Tab (Placeholder) ---
class SecurityTab extends StatelessWidget {
  const SecurityTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Password',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/features/seller/models/seller_store_model.dart';
import 'package:tazto/providers/login_provider.dart';
import 'package:tazto/providers/seller_provider.dart';
import 'package:tazto/widgets/error_dialog.dart';

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
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    labelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(),
                    tabs: const [
                      Tab(text: 'Store Details'),
                      Tab(text: 'Operating Hours'),
                      Tab(text: 'Notifications'),
                      Tab(text: 'Security'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      StoreDetailsTab(store: provider.store!),
                      OperatingHoursTab(store: provider.store!),
                      NotificationsTab(store: provider.store!),
                      const SecurityTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// --- Store Details Tab ---
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
    _ownerNameC = TextEditingController(text: widget.store.ownerName);
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
    final updates = {
      'storeName': _storeNameC.text,
      'storeDescription': _descriptionC.text,
      'phone': _phoneC.text,
      'email': _emailC.text,
      'address': _addressC.text,
      'gstNumber': _gstC.text,
    };

    final success = await provider.updateStoreProfile(updates);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        showSuccessDialog(
          context,
          'Success',
          'Store details updated successfully!',
          () {
            if (mounted) Navigator.of(context).pop();
          },
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Image upload coming soon!"),
                        ),
                      );
                    },
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
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
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
          if (label.contains("GST")) return null;
          return '$label is required';
        }
        return null;
      },
    );
  }
}

// --- Operating Hours Tab ---
class OperatingHoursTab extends StatefulWidget {
  final Store store;

  const OperatingHoursTab({super.key, required this.store});

  @override
  State<OperatingHoursTab> createState() => _OperatingHoursTabState();
}

class _OperatingHoursTabState extends State<OperatingHoursTab> {
  // Use late to initialize, but don't duplicate state if not needed
  late TextEditingController _prepTimeC;
  late TextEditingController _minOrderC;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _prepTimeC = TextEditingController(
      text: widget.store.avgPreparationTime.toString(),
    );
    _minOrderC = TextEditingController(
      text: widget.store.minOrderValue.toStringAsFixed(0),
    );
  }

  @override
  void didUpdateWidget(covariant OperatingHoursTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If external data changed (e.g. pulled from backend), sync local controllers if not editing
    if (oldWidget.store.avgPreparationTime != widget.store.avgPreparationTime) {
      _prepTimeC.text = widget.store.avgPreparationTime.toString();
    }
    if (oldWidget.store.minOrderValue != widget.store.minOrderValue) {
      _minOrderC.text = widget.store.minOrderValue.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _prepTimeC.dispose();
    _minOrderC.dispose();
    super.dispose();
  }

  Future<void> _saveSettings({bool? isOpen, bool? autoAccept}) async {
    setState(() => _isLoading = true);

    // If specific toggles passed, use them, otherwise use current widget state
    // Note: We use widget.store.isOpen directly if not passed to ensure we rely on single source of truth when toggling
    final newIsOpen = isOpen ?? widget.store.isOpen;
    final newAutoAccept = autoAccept ?? widget.store.autoAcceptOrders;

    final updates = {
      'isOpen': newIsOpen,
      'autoAcceptOrders': newAutoAccept,
      'avgPreparationTime': int.tryParse(_prepTimeC.text) ?? 15,
      'minOrderValue': double.tryParse(_minOrderC.text) ?? 0.0,
    };

    final provider = context.read<SellerProvider>();
    final success = await provider.updateStoreProfile(updates);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.storeError ?? 'Failed to update'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // We read directly from widget.store for the switches to ensure
    // the UI always reflects the Provider's state (Single Source of Truth).
    final isOpen = widget.store.isOpen;
    final autoAccept = widget.store.autoAcceptOrders;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: SwitchListTile(
              title: Text(
                'Store is currently ${isOpen ? "Open" : "Closed"}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                isOpen ? 'Accepting new orders' : 'Not accepting orders',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              value: isOpen,
              // When toggled, we immediately call save with the new value
              onChanged: (val) => _saveSettings(isOpen: val),
              secondary: Icon(
                Icons.storefront,
                color: isOpen ? Colors.green : Colors.grey,
              ),
              activeColor: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
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
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(
                    'Auto-accept Orders',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Automatically confirm all incoming orders',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  value: autoAccept,
                  onChanged: (val) => _saveSettings(autoAccept: val),
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.primary,
                ),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Average Preparation Time (minutes)',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _prepTimeC,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    hintText: "e.g. 15",
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Text(
                  'Minimum Order Value (₹)',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _minOrderC,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    hintText: "e.g. 100",
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _saveSettings(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}

// --- Notifications Tab ---
class NotificationsTab extends StatefulWidget {
  final Store store;

  const NotificationsTab({super.key, required this.store});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  bool _emailNotify = true;
  bool _smsNotify = false;
  bool _newOrders = true;
  bool _lowStock = true;
  bool _payments = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final prefs = widget.store.notificationPreferences;
    _emailNotify = prefs.email;
    _smsNotify = prefs.sms;
    _newOrders = prefs.newOrders;
    _lowStock = prefs.lowStock;
    _payments = prefs.payments;
  }

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);

    final provider = context.read<SellerProvider>();
    final updates = {
      'notificationPreferences': {
        'email': _emailNotify,
        'sms': _smsNotify,
        'newOrders': _newOrders,
        'lowStock': _lowStock,
        'payments': _payments,
      },
    };

    final success = await provider.updateStoreProfile(updates);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        showErrorDialog(
          context,
          'Save Failed',
          provider.storeError ?? 'Unknown error occurred',
        );
      }
    }
  }

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
              value: _emailNotify,
              onChanged: (val) => setState(() => _emailNotify = val),
            ),
            _NotifySwitch(
              title: 'SMS Notifications',
              subtitle: 'Receive order updates via SMS',
              value: _smsNotify,
              onChanged: (val) => setState(() => _smsNotify = val),
            ),
            const Divider(),
            _NotifySwitch(
              title: 'New Order Alerts',
              subtitle: 'Get notified when new orders arrive',
              value: _newOrders,
              onChanged: (val) => setState(() => _newOrders = val),
            ),
            _NotifySwitch(
              title: 'Low Stock Alerts',
              subtitle: 'Alert when products are running low',
              value: _lowStock,
              onChanged: (val) => setState(() => _lowStock = val),
            ),
            _NotifySwitch(
              title: 'Payment Updates',
              subtitle: 'Notifications for settlements and payouts',
              value: _payments,
              onChanged: (val) => setState(() => _payments = val),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Save Preferences"),
              ),
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
  final ValueChanged<bool> onChanged;

  const _NotifySwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
      ),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      activeColor: AppColors.primary,
    );
  }
}

// --- Security Tab ---
class SecurityTab extends StatefulWidget {
  const SecurityTab({super.key});

  @override
  State<SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends State<SecurityTab> {
  final _passKey = GlobalKey<FormState>();
  final _oldPassC = TextEditingController();
  final _newPassC = TextEditingController();
  final _confirmPassC = TextEditingController();
  bool _isUpdating = false;

  Future<void> _updatePassword() async {
    if (!_passKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    final loginProvider = context.read<LoginProvider>();
    final success = await loginProvider.changePassword(
      _oldPassC.text.trim(),
      _newPassC.text.trim(),
    );

    if (mounted) {
      setState(() => _isUpdating = false);
      if (success) {
        _oldPassC.clear();
        _newPassC.clear();
        _confirmPassC.clear();

        showSuccessDialog(
          context,
          "Password Updated",
          "Your password has been changed successfully.",
          () {
            if (mounted) Navigator.of(context).pop();
          },
        );
      } else {
        showErrorDialog(
          context,
          "Update Failed",
          loginProvider.errorMessage ?? "Could not update password",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _passKey,
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _oldPassC,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (val) => val != null && val.length < 6
                    ? "Enter valid current password"
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPassC,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_reset),
                ),
                obscureText: true,
                validator: (val) => val != null && val.length < 6
                    ? "Password must be at least 6 chars"
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPassC,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.check_circle_outline),
                ),
                obscureText: true,
                validator: (val) =>
                    val != _newPassC.text ? "Passwords do not match" : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isUpdating ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUpdating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Update Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

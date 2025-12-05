import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tazto/app/config/app_theme.dart';

/// A reusable wrapper that automatically checks for required permissions
/// when the app starts or resumes from the background.
class PermissionGuard extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PermissionGuard({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<PermissionGuard> createState() => _PermissionGuardState();
}

class _PermissionGuardState extends State<PermissionGuard>
    with WidgetsBindingObserver {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.enabled) {
      // Check immediately on load
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkPermissions());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.enabled) {
      _checkPermissions();
    }
  }

  /// The list of essential permissions for the app
  Future<Map<Permission, PermissionStatus>> _getPermissionStatuses() async {
    final permissions = <Permission>[
      Permission.locationWhenInUse,
      Permission.camera,
      Permission.notification,
      // Storage logic based on platform/version
      if (Platform.isAndroid)
      // Android 13+ uses photos/videos/audio, older uses storage
      // We'll request photos as a proxy for media access
        Permission.photos
      else
        Permission.storage,
    ];

    Map<Permission, PermissionStatus> statuses = {};
    for (var perm in permissions) {
      statuses[perm] = await perm.status;
    }
    return statuses;
  }

  Future<void> _checkPermissions() async {
    if (_isChecking) return;
    _isChecking = true;

    final statuses = await _getPermissionStatuses();

    // Filter for denied or permanently denied permissions
    final missingPermissions = statuses.entries
        .where((e) => !e.value.isGranted)
        .map((e) => e.key)
        .toList();

    if (missingPermissions.isNotEmpty && mounted) {
      // If we have missing permissions, show the sheet
      // We check if a sheet is already open to avoid stacking
      final bool isSheetOpen = ModalRoute.of(context)?.isCurrent != true;
      if (!isSheetOpen) {
        await _showPermissionSheet(missingPermissions);
      }
    }

    _isChecking = false;
  }

  Future<void> _showPermissionSheet(List<Permission> missingPermissions) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PermissionRequestSheet(
        missingPermissions: missingPermissions,
        onPermissionsGranted: () {
          Navigator.pop(context);
          _checkPermissions(); // Double check
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _PermissionRequestSheet extends StatefulWidget {
  final List<Permission> missingPermissions;
  final VoidCallback onPermissionsGranted;

  const _PermissionRequestSheet({
    required this.missingPermissions,
    required this.onPermissionsGranted,
  });

  @override
  State<_PermissionRequestSheet> createState() =>
      _PermissionRequestSheetState();
}

class _PermissionRequestSheetState extends State<_PermissionRequestSheet> {
  bool _isRequesting = false;

  Future<void> _requestPermissions() async {
    setState(() => _isRequesting = true);

    // Request all missing permissions at once
    Map<Permission, PermissionStatus> statuses =
    await widget.missingPermissions.request();

    // Check if any are permanently denied (requires opening settings)
    bool anyPermanentlyDenied =
    statuses.values.any((s) => s.isPermanentlyDenied);

    if (anyPermanentlyDenied) {
      if (mounted) {
        // Show a dialog guiding to settings
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text(
              'Some permissions are permanently denied. Please enable them in system settings to use the app.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    } else {
      // Re-evaluate if everything is granted
      bool allGranted = statuses.values.every((s) => s.isGranted);
      if (allGranted) {
        widget.onPermissionsGranted();
      }
    }

    if (mounted) setState(() => _isRequesting = false);
  }

  @override
  Widget build(BuildContext context) {
    // Prevent back button closing
    return PopScope(
      canPop: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.security_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Permissions Required',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'To provide the best experience like Blinkit, LINC needs access to the following:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Permission List
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: widget.missingPermissions.map((perm) {
                    return _PermissionTile(permission: perm);
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isRequesting ? null : _requestPermissions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isRequesting
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  'Allow Access',
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
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final Permission permission;

  const _PermissionTile({required this.permission});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String title;
    String subtitle;

    if (permission == Permission.locationWhenInUse ||
        permission == Permission.location) {
      icon = Icons.location_on_outlined;
      title = 'Location';
      subtitle = 'To find nearby stores and deliver orders.';
    } else if (permission == Permission.camera) {
      icon = Icons.camera_alt_outlined;
      title = 'Camera';
      subtitle = 'To upload product images and profile photos.';
    } else if (permission == Permission.notification) {
      icon = Icons.notifications_none_rounded;
      title = 'Notifications';
      subtitle = 'To update you on order status and offers.';
    } else if (permission == Permission.storage ||
        permission == Permission.photos) {
      icon = Icons.folder_open_rounded;
      title = 'Storage/Photos';
      subtitle = 'To access device gallery for uploads.';
    } else {
      icon = Icons.settings;
      title = 'System';
      subtitle = 'Required for app functionality.';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey.shade800, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
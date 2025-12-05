import 'dart:ui'; // For BackdropFilter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/features/seller/screens/dashboard/seller_orders_page.dart';
import 'package:tazto/features/seller/screens/dashboard/seller_products_page.dart';
import 'package:tazto/features/seller/screens/dashboard/seller_store_onboarding_screen.dart';
import 'package:tazto/features/seller/screens/profile/seller_settings_page.dart';
import 'package:tazto/providers/seller_provider.dart';
import 'package:tazto/widgets/loading_overlay.dart';
import 'package:tazto/widgets/logout_button.dart'; // IMPORTED
import 'package:tazto/widgets/permission_guard.dart';

import '../../../widgets/circular_icon_button.dart';
import 'dashboard/seller_dashboard_page.dart';

class SellerLayout extends StatefulWidget {
  const SellerLayout({super.key});

  @override
  State<SellerLayout> createState() => _SellerLayoutState();
}

class _SellerLayoutState extends State<SellerLayout> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<String> _titles = [
    'Dashboard',
    'My Products',
    'Orders',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final isStoreLoading = context.select<SellerProvider, bool>(
      (p) => p.isLoadingStore,
    );
    final storeExists = context.select<SellerProvider, bool>(
      (p) => p.store != null,
    );

    if (isStoreLoading) {
      return const Scaffold(
        body: LoadingOverlay(
          isLoading: true,
          message: "Loading your store...",
          child: SizedBox.expand(),
        ),
      );
    }

    if (!storeExists) {
      return const CreateStorePage();
    }

    return PermissionGuard(
      child: LoadingOverlay(
        isLoading: false,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FC),
          extendBody: true,
          appBar: _buildAnimatedAppBar(context),
          drawer: const _EnhancedSellerDrawer(),
          body: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              SellerDashboardPage(),
              SellerProductsPage(),
              SellerOrdersPage(),
              SellerSettingsPage(),
            ],
          ),
          bottomNavigationBar: _ModernFloatingBottomBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAnimatedAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 10),
      child: Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0.0),
            ],
          ),
        ),
        child: AppBar(
          primary: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: Builder(
            builder: (context) => CircularIconButton(
              icon: Icons.menu_rounded,
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0.0, 0.5),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutBack,
                        ),
                      ),
                  child: child,
                ),
              );
            },
            child: Text(
              _titles[_currentIndex],
              key: ValueKey<String>(_titles[_currentIndex]),
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
          ),
          actions: [
            CircularIconButton(
              icon: Icons.notifications_none_rounded,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernFloatingBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ModernFloatingBottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavBarItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Home',
                  index: 0,
                  currentIndex: currentIndex,
                  onTap: onTap,
                ),
                _NavBarItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Products',
                  index: 1,
                  currentIndex: currentIndex,
                  onTap: onTap,
                ),
                _NavBarItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Orders',
                  index: 2,
                  currentIndex: currentIndex,
                  onTap: onTap,
                ),
                _NavBarItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  index: 3,
                  currentIndex: currentIndex,
                  onTap: onTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.primary : Colors.grey.shade400;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              tween: Tween(begin: 1.0, end: isSelected ? 1.2 : 1.0),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Icon(icon, color: color, size: 24),
                );
              },
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.0,
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EnhancedSellerDrawer extends StatelessWidget {
  const _EnhancedSellerDrawer();

  @override
  Widget build(BuildContext context) {
    final sellerProvider = context.watch<SellerProvider>();
    final store = sellerProvider.store;

    final storeName = store?.storeName ?? 'My Store';
    final ownerName = store?.ownerName ?? 'Partner';
    final storeImage = store?.storeLogoUrl;
    final isOpen = store?.isOpen ?? false;

    return Drawer(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          color: Colors.white,
                        ),
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: Colors.white,
                          backgroundImage: storeImage != null
                              ? NetworkImage(storeImage)
                              : null,
                          child: storeImage == null
                              ? Text(
                                  storeName.isNotEmpty
                                      ? storeName[0].toUpperCase()
                                      : 'S',
                                  style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isOpen ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (isOpen ? Colors.green : Colors.red)
                                .withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOpen
                                ? Icons.check_circle
                                : Icons.power_settings_new,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOpen ? 'OPEN' : 'CLOSED',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  storeName,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  ownerName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildDrawerTile(
                  context,
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  color: Colors.blue,
                  onTap: () => _navigate(context, 0),
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.inventory_2_rounded,
                  title: 'Products',
                  color: Colors.purple,
                  onTap: () => _navigate(context, 1),
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.receipt_long_rounded,
                  title: 'Orders',
                  color: Colors.orange,
                  onTap: () => _navigate(context, 2),
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  color: Colors.teal,
                  onTap: () => _navigate(context, 3),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8),
                  child: Divider(height: 1),
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  color: Colors.indigo,
                  onTap: () {},
                ),
                _buildDrawerTile(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: 'About LINC',
                  color: Colors.grey,
                  onTap: () {},
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Reused Logout Tile
                const LogoutListTile(),
                const SizedBox(height: 16),
                Text(
                  'LINC Seller v1.0.0',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    Navigator.pop(context);
    final state = context.findAncestorStateOfType<_SellerLayoutState>();
    state?._onTabTapped(index);
  }

  Widget _buildDrawerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade300,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

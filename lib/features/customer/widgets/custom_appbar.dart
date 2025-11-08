import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tazto/app/config/app_theme.dart';

/// A reusable, customized AppBar for the customer-facing app.
///
/// It implements [PreferredSizeWidget] so it can be used directly in
/// the [Scaffold.appBar] property.
class ShoppingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackButtonPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? leadingIconColor;
  final Color? titleColor;
  final Color? subtitleColor;
  final double? elevation;
  final bool centerTitle;
  final Widget? leading;
  final Widget? titleWidget;
  final PreferredSizeWidget? bottom;
  final bool showShadow;
  final double? toolbarHeight;
  final EdgeInsets? titlePadding;
  final bool? hasSubtitle;
  final TextStyle? titleTextStyle;
  final TextStyle? subtitleTextStyle;
  final bool useSliverAppBar;
  final double expandedHeight;
  final Widget? flexibleSpace;
  final bool forceElevated;
  final bool includeSafeArea;

  const ShoppingAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = true,
    this.onBackButtonPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.leadingIconColor,
    this.titleColor,
    this.subtitleColor,
    this.elevation,
    this.centerTitle = false,
    this.leading,
    this.titleWidget,
    this.bottom,
    this.showShadow = true,
    this.toolbarHeight,
    this.titlePadding,
    this.hasSubtitle,
    this.titleTextStyle,
    this.subtitleTextStyle,
    this.useSliverAppBar = false,
    this.expandedHeight = 0,
    this.flexibleSpace,
    this.forceElevated = false,
    this.includeSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSubtitleText =
        (hasSubtitle ?? subtitle != null && subtitle!.isNotEmpty);
    final double effectiveToolbarHeight =
        toolbarHeight ?? kToolbarHeight + (hasSubtitleText ? 8.0 : 0);

    Widget titleContent =
        titleWidget ??
        Column(
          crossAxisAlignment: centerTitle
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style:
                  titleTextStyle ??
                  GoogleFonts.poppins(
                    color: titleColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
            ),
            if (hasSubtitleText)
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  subtitle!,
                  style:
                      subtitleTextStyle ??
                      GoogleFonts.poppins(
                        color: subtitleColor ?? AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                      ),
                ),
              ),
          ],
        );

    if (useSliverAppBar) {
      // --- SLIVER APP BAR ---
      // SliverAppBar automatically handles status bar padding (SafeArea)
      // when it's the primary app bar.
      return SliverAppBar(
        pinned: true,
        floating: false,
        snap: false,
        expandedHeight: expandedHeight > 0 ? expandedHeight : null,
        flexibleSpace: expandedHeight > 0 ? flexibleSpace : null,
        automaticallyImplyLeading: false,
        backgroundColor: backgroundColor ?? AppColors.background,
        foregroundColor: foregroundColor,
        elevation: showShadow ? (elevation ?? 0) : 0,
        centerTitle: centerTitle,
        // **FIX**: Removed 'forceMaterialTransparency: true'
        // This line was causing the SliverAppBar to not account for
        // the status bar height in its layout.
        titleSpacing: showBackButton ? 0 : 16,
        toolbarHeight: effectiveToolbarHeight,
        // **FIX**: Removed internal SafeArea wrapper.
        // SliverAppBar handles its own safe area padding.
        // Wrapping the title again can cause double padding.
        title: Padding(
          padding: titlePadding ?? const EdgeInsets.all(0),
          child: titleContent,
        ),
        // **FIX**: Removed internal SafeArea wrapper from leading/actions
        leading: _buildLeading(context, applySafeArea: false),
        actions: _buildActions(applySafeArea: false),
        bottom: bottom,
      );
    } else {
      // --- REGULAR APP BAR ---
      // Regular AppBar does NOT handle status bar padding,
      // so we use 'includeSafeArea' to add it manually.
      return AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: backgroundColor ?? AppColors.background,
        foregroundColor: foregroundColor,
        elevation: showShadow ? (elevation ?? 0) : 0,
        centerTitle: centerTitle,
        titleSpacing: showBackButton ? 0 : 16,
        toolbarHeight: effectiveToolbarHeight,
        // Apply SafeArea wrapper if 'includeSafeArea' is true
        title: includeSafeArea
            ? SafeArea(
                top: true,
                bottom: false,
                child: Padding(
                  padding:
                      titlePadding ??
                      const EdgeInsets.symmetric(horizontal: 8.0),
                  child: titleContent,
                ),
              )
            : Padding(
                padding:
                    titlePadding ?? const EdgeInsets.symmetric(horizontal: 8.0),
                child: titleContent,
              ),
        leading: _buildLeading(context, applySafeArea: includeSafeArea),
        actions: _buildActions(applySafeArea: includeSafeArea),
        bottom: bottom,
      );
    }
  }

  // Modified helper to conditionally apply SafeArea
  Widget? _buildLeading(BuildContext context, {required bool applySafeArea}) {
    Widget? defaultLeading = showBackButton
        ? IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: leadingIconColor ?? AppColors.textPrimary,
              size: 20,
            ),
            onPressed: onBackButtonPressed ?? () => Navigator.of(context).pop(),
            tooltip: 'Back',
          )
        : null;

    Widget? finalLeading = leading ?? defaultLeading;

    if (!applySafeArea || finalLeading == null) {
      return finalLeading;
    }

    return SafeArea(top: true, bottom: false, child: finalLeading);
  }

  // Modified helper to conditionally apply SafeArea
  List<Widget>? _buildActions({required bool applySafeArea}) {
    if (actions == null) {
      return null;
    }

    if (!applySafeArea) {
      return actions;
    }

    return [
      SafeArea(
        top: true,
        bottom: false,
        child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
      ),
    ];
  }

  @override
  Size get preferredSize => Size.fromHeight(
    (toolbarHeight ?? kToolbarHeight) +
        ((hasSubtitle ?? (subtitle != null && subtitle!.isNotEmpty)) ? 8.0 : 0),
  );
}

/// Alternative constructor for common use cases
extension ShoppingAppBarExtensions on ShoppingAppBar {
  /// AppBar with search functionality
  static ShoppingAppBar withSearch({
    required String title,
    String? subtitle,
    List<Widget>? actions,
    bool showBackButton = true,
    VoidCallback? onBackButtonPressed,
    Widget? searchField,
    Color? backgroundColor,
    Color? foregroundColor,
    bool includeSafeArea = true,
  }) {
    return ShoppingAppBar(
      title: title,
      subtitle: subtitle,
      showBackButton: showBackButton,
      onBackButtonPressed: onBackButtonPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      includeSafeArea: includeSafeArea,
      actions: [
        if (searchField != null) searchField,
        if (actions != null) ...actions,
      ],
    );
  }

  /// AppBar with cart and notification icons
  static ShoppingAppBar withCart({
    required String title,
    String? subtitle,
    bool showBackButton = true,
    VoidCallback? onBackButtonPressed,
    VoidCallback? onCartPressed,
    VoidCallback? onNotificationPressed,
    int cartItemCount = 0,
    int notificationCount = 0,
    Color? backgroundColor,
    Color? foregroundColor,
    bool includeSafeArea = true,
  }) {
    return ShoppingAppBar(
      title: title,
      subtitle: subtitle,
      showBackButton: showBackButton,
      onBackButtonPressed: onBackButtonPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      includeSafeArea: includeSafeArea,
      actions: [
        if (onNotificationPressed != null)
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: onNotificationPressed,
              ),
              if (notificationCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '$notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        if (onCartPressed != null)
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: onCartPressed,
              ),
              if (cartItemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '$cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  /// AppBar with profile and settings
  static ShoppingAppBar withProfile({
    required String title,
    String? subtitle,
    bool showBackButton = true,
    VoidCallback? onBackButtonPressed,
    VoidCallback? onProfilePressed,
    VoidCallback? onSettingsPressed,
    String? profileImageUrl,
    Color? backgroundColor,
    Color? foregroundColor,
    bool includeSafeArea = true,
  }) {
    return ShoppingAppBar(
      title: title,
      subtitle: subtitle,
      showBackButton: showBackButton,
      onBackButtonPressed: onBackButtonPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      includeSafeArea: includeSafeArea,
      actions: [
        if (onSettingsPressed != null)
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: onSettingsPressed,
          ),
        if (onProfilePressed != null)
          GestureDetector(
            onTap: onProfilePressed,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: Icon(Icons.person, size: 18, color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}

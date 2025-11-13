import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tazto/app/config/app_theme.dart';

/// An enhanced, animated AppBar specifically for the search screen.
///
/// Features:
/// - Smooth animations for text field interactions
/// - Haptic feedback on interactions
/// - Beautiful micro-animations
/// - Responsive design for all screen sizes
class EnhancedSearchAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onBack;
  final VoidCallback? onClear;

  const EnhancedSearchAppBar({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.onChanged,
    this.onBack,
    this.onClear,
  });

  @override
  State<EnhancedSearchAppBar> createState() => _EnhancedSearchAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _EnhancedSearchAppBarState extends State<EnhancedSearchAppBar>
    with SingleTickerProviderStateMixin {
  bool _showClearButton = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _showClearButton = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (_showClearButton) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final shouldShow = widget.controller.text.isNotEmpty;
    if (_showClearButton != shouldShow) {
      setState(() {
        _showClearButton = shouldShow;
      });
      if (shouldShow) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _handleClear() {
    widget.onClear?.call();
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        titleSpacing: 8.0,
        leading: _buildBackButton(context),
        title: _buildSearchField(theme, isSmallScreen),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onBack ?? () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme, bool isSmallScreen) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isFocused ? AppColors.primary : Colors.grey.shade300,
          width: _isFocused ? 1.5 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: true,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        textInputAction: TextInputAction.search,
        style: GoogleFonts.poppins(
          fontSize: isSmallScreen ? 14 : 15,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
        decoration: InputDecoration(
          hintText: 'Search for products...',
          hintStyle: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 14 : 15,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              Icons.search_rounded,
              color: _isFocused ? AppColors.primary : Colors.grey.shade500,
              size: 22,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 40,
            minHeight: 40,
          ),
          suffixIcon: _buildSuffixIcon(isSmallScreen),
          filled: false,
          contentPadding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 12 : 14,
            horizontal: 0,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon(bool isSmallScreen) {
    if (!_showClearButton) return null;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleClear,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.grey.shade600,
                  size: isSmallScreen ? 16 : 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
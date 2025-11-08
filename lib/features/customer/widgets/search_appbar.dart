import 'package:flutter/material.dart';
import 'package:tazto/app/config/app_theme.dart';

/// A reusable AppBar specifically for the search screen.
///
/// It implements [PreferredSizeWidget] to be used in [Scaffold.appBar].
class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String>?
  onChanged; // <-- ADDED: Callback for real-time text changes
  final VoidCallback? onBack;
  final VoidCallback? onClear;

  const SearchAppBar({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.onChanged, // <-- ADDED
    this.onBack,
    this.onClear,
  });

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SearchAppBarState extends State<SearchAppBar> {
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    // Set initial state
    _showClearButton = widget.controller.text.isNotEmpty;
    // Listen for changes to show/hide the clear button
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {
        _showClearButton = widget.controller.text.isNotEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      foregroundColor: AppColors.textPrimary,
      titleSpacing: 16.0,
      // Use a custom back button to ensure consistent styling
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
        ),
        onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        tooltip: 'Back',
      ),
      // The search text field as the title
      title: TextField(
        controller: widget.controller,
        autofocus: true,
        // Automatically focus when page opens
        onChanged: widget.onChanged,
        // <-- ADDED: Pass through the onChanged
        onSubmitted: widget.onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search for products...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _showClearButton
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: widget.onClear,
                  tooltip: 'Clear search',
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

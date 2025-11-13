import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tazto/app/config/app_theme.dart';
import 'package:tazto/features/customer/models/customer_product_model.dart';
import 'package:tazto/features/customer/widgets/search_appbar.dart';
import 'package:tazto/providers/customer_provider.dart';
import '../widgets/product_card_widget.dart';
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _recentSearches = [
    "Good Knight",
    "Tata Salt",
    "Sunflower Oil",
    "Dettol Liquid",
    "Madhur Sugar",
    "Amul Ghee",
  ];

  bool _isSearching = false;
  bool _hasSearchQuery = false;
  List<CustomerProduct> _searchResults = [];
  Timer? _debounce;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Fade animation for transitions
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Slide animation for content
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Start initial animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    if (mounted) {
      setState(() {
        _hasSearchQuery = query.isNotEmpty;
      });
    }

    // Animate transitions
    if (query.isNotEmpty) {
      _fadeController.forward();
      _slideController.forward(from: 0);
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        if (mounted) {
          setState(() {
            _isSearching = false;
            _searchResults = [];
          });
          _slideController.forward(from: 0);
        }
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    if (mounted) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearchQuery = false; // <-- This will toggle back to suggestions
      });
      _slideController.forward(from: 0);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    if (mounted) {
      setState(() {
        _isSearching = true;
        if (!(_debounce?.isActive ?? false)) {
          _recentSearches.remove(query);
          _recentSearches.insert(0, query);
          if (_recentSearches.length > 6) _recentSearches.removeLast();
        }
      });
    }

    await Future.delayed(const Duration(milliseconds: 600));
    final prov = context.read<CustomerProvider>();
    final results = prov.products
        .where((p) => p.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
      _slideController.forward(from: 0);
    }
  }

  void _onSearchChipTap(String term) {
    _searchController.text = term;
    _performSearch(term);
    _fadeController.forward(from: 0);
    _slideController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: EnhancedSearchAppBar(
        controller: _searchController,
        onSubmitted: (query) {
          _debounce?.cancel();
          _performSearch(query);
        },
        onClear: _clearSearch,
        onChanged: _onQueryChanged,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: CustomScrollView(
          key: ValueKey(_hasSearchQuery),
          physics: const BouncingScrollPhysics(),
          slivers: _hasSearchQuery
              ? _buildResultsSlivers()
              : _buildSuggestionsSlivers(),
        ),
      ),
    );
  }

  List<Widget> _buildResultsSlivers() {

    if (_isSearching) {
      return [
        SliverFillRemaining(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Searching...',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return [
        SliverFillRemaining(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_off_rounded,
                          color: Colors.grey.shade400,
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "No results found",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Try searching with different keywords",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '"${_searchController.text}"',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ];
    }

    return [
      // FIX 1: Replaced SliverOpacity with SliverFadeTransition
      SliverFadeTransition(
        opacity: _fadeAnimation,
        sliver: SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Text(
                  '${_searchResults.length} ',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'results found',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // FIX 2: Replaced SliverOpacity with SliverFadeTransition
      SliverFadeTransition(
        opacity: _fadeAnimation,
        sliver: SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          // FIX 3: Removed the invalid SlideTransition wrapper
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 0.65,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              // The animation builder here is correct and animates each item
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 300 + (index * 50)),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: ProductCard(product: _searchResults[index]),
              );
            }, childCount: _searchResults.length),
          ),
        ),
      ),
      const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
    ];
  }

  List<Widget> _buildSuggestionsSlivers() {
    final prov = context.watch<CustomerProvider>();
    final trendingProducts = prov.products.take(6).toList();

    return [
      // Recent Search Section with Animation
      SliverToBoxAdapter(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 22,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Searches',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                if (_recentSearches.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _recentSearches.clear();
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Clear All',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      if (_recentSearches.isEmpty)
        // FIX 4: Replaced SliverOpacity with SliverFadeTransition
        SliverFadeTransition(
          opacity: _fadeAnimation,
          sliver: SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No recent searches',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your search history will appear here',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _recentSearches.asMap().entries.map((entry) {
                  final index = entry.key;
                  final term = entry.value;
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 200 + (index * 50)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _onSearchChipTap(term),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                term,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

      // Trending Now Section
      SliverToBoxAdapter(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 28.0, 16.0, 12.0),
            child: Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 22,
                  color: Colors.orange.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Trending Now',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 310,
          child: prov.isLoadingProducts
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                )
              : trendingProducts.isEmpty
              ? Center(
                  child: Text(
                    "No trending products found.",
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: trendingProducts.length,
                    itemBuilder: (context, index) {
                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 300 + (index * 80)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(30 * (1 - value), 0),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: SizedBox(
                          width: 180,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: ProductCard(
                              product: trendingProducts[index],
                              layoutType: ProductCardLayout.grid,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
      const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
    ];
  }
}

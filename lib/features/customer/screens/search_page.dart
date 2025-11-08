import 'dart:async'; // Import for Timer

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

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _recentSearches = [
    "Good Knight",
    "Tata Salt",
    "Sunflower Oil",
    "Dettol Liquid",
    "Madhur Sugar",
    "Amul Ghee",
  ]; // Dummy data

  // --- NEW STATE VARIABLES ---
  bool _isSearching = false;
  bool _hasSearchQuery = false;
  List<CustomerProduct> _searchResults = [];
  Timer? _debounce; // <-- ADDED: For debouncing

  // --- REMOVED: Listener from initState ---

  @override
  void dispose() {
    _debounce?.cancel(); // <-- ADDED: Cancel timer on dispose
    _searchController.dispose();
    super.dispose();
  }

  // --- NEW: Handles real-time query changes with debouncing ---
  void _onQueryChanged(String query) {
    // Update the view toggle immediately
    if (mounted) {
      setState(() {
        _hasSearchQuery = query.isNotEmpty;
      });
    }

    // Cancel any old timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Start a new timer
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.isNotEmpty) {
        _performSearch(query); // Perform search after 300ms
      } else {
        // If query is empty, clear results but stay on results view
        if (mounted) {
          setState(() {
            _isSearching = false;
            _searchResults = [];
          });
        }
      }
    });
  }

  // --- UPDATED: Clears the search field and results ---
  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    if (mounted) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearchQuery = false; // <-- This will toggle back to suggestions
      });
    }
  }

  // --- UPDATED: Performs a mock search ---
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    // Don't unfocus keyboard, user might still be typing
    // FocusScope.of(context).unfocus();

    if (mounted) {
      setState(() {
        _isSearching = true;
        // Add to recent searches (only on submit, let's move this)
        if (!(_debounce?.isActive ?? false)) {
          _recentSearches.remove(query);
          _recentSearches.insert(0, query);
          if (_recentSearches.length > 6) _recentSearches.removeLast();
        }
      });
    }

    // --- Mock API Call ---
    await Future.delayed(const Duration(milliseconds: 600)); // Simulate delay
    final prov = context.read<CustomerProvider>();
    final results = prov.products
        .where((p) => p.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
    // ---------------------

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // --- UPDATED: Use the new SearchAppBar ---
      appBar: SearchAppBar(
        controller: _searchController,
        onSubmitted: (query) {
          _debounce?.cancel(); // Cancel any pending debounce
          _performSearch(query); // Submit immediately
        },
        onClear: _clearSearch,
        onChanged: _onQueryChanged, // <-- ADDED: Listen to changes
      ),
      // --- UPDATED: Conditionally show results or suggestions ---
      body: CustomScrollView(
        slivers: _hasSearchQuery
            ? _buildResultsSlivers()
            : _buildSuggestionsSlivers(),
      ),
    );
  }

  // --- NEW: Builds the search results view ---
  List<Widget> _buildResultsSlivers() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    if (_isSearching) {
      return [
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, color: Colors.grey, size: 64),
                const SizedBox(height: 16),
                Text(
                  "No results found",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "No products found for '${_searchController.text}'",
                  style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    // If we have results, show them in a grid
    return [
      SliverPadding(
        padding: const EdgeInsets.all(16.0),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: 0.65, // Adjust this ratio to fit your ProductCard
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            return ProductCard(product: _searchResults[index]);
          }, childCount: _searchResults.length),
        ),
      ),
    ];
  }

  // --- NEW: Builds the suggestions view (Recent/Trending) ---
  List<Widget> _buildSuggestionsSlivers() {
    final prov = context.watch<CustomerProvider>();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final trendingProducts = prov.products.take(4).toList();

    return [
      // --- Recent Search Section ---
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Search',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              // --- ADDED: Clear All Button ---
              if (_recentSearches.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _recentSearches.clear();
                    });
                  },
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      // Show empty message if no recent searches
      if (_recentSearches.isEmpty)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Your recent searches will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverToBoxAdapter(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _recentSearches
                  .map(
                    (term) => ActionChip(
                      label: Text(term),
                      labelStyle: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      onPressed: () {
                        _searchController.text = term; // Put term in search bar
                        _performSearch(term); // Execute search
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ),

      // --- Trending Now Section ---
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
          child: Text(
            'Trending Now',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 280, // Adjust height based on Product Card size
          child: prov.isLoadingProducts
              ? const Center(child: CircularProgressIndicator())
              : trendingProducts.isEmpty
              ? const Center(child: Text("No trending products found."))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: trendingProducts.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 170, // Fixed width for horizontal cards
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: ProductCard(product: trendingProducts[index]),
                      ),
                    );
                  },
                ),
        ),
      ),
      const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
    ];
  }
}

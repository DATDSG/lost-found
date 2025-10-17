import 'package:flutter/material.dart';
import '../models/search_models.dart';
import '../models/report.dart';
import '../models/media.dart';
import '../services/api_service.dart';
import '../core/error/error_handler.dart';

/// Search Provider - Manages search and filter functionality
class SearchProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Search state
  List<Report> _searchResults = [];
  List<SearchSuggestion> _searchSuggestions = [];
  SearchFilters _currentFilters = SearchFilters();
  SearchState _searchState = SearchState.idle;
  String? _error;
  String _lastQuery = '';
  bool _hasMoreResults = false;
  int _currentPage = 1;
  static const int _pageSize = 20;

  // Analytics and trends
  SearchAnalytics? _analytics;
  Map<String, dynamic>? _trends;
  Map<String, List<FilterOption>> _filterOptions = {};

  // Getters
  List<Report> get searchResults => _searchResults;
  List<SearchSuggestion> get searchSuggestions => _searchSuggestions;
  SearchFilters get currentFilters => _currentFilters;
  SearchState get searchState => _searchState;
  String? get error => _error;
  String get lastQuery => _lastQuery;
  bool get hasMoreResults => _hasMoreResults;
  SearchAnalytics? get analytics => _analytics;
  Map<String, dynamic>? get trends => _trends;
  Map<String, List<FilterOption>> get filterOptions => _filterOptions;

  bool get isLoading =>
      _searchState == SearchState.searching ||
      _searchState == SearchState.loadingMore;
  bool get hasError => _searchState == SearchState.error;
  bool get isEmpty => _searchState == SearchState.empty;
  bool get hasResults => _searchResults.isNotEmpty;

  /// Perform universal search with current filters
  Future<void> search({bool loadMore = false}) async {
    if (loadMore) {
      _searchState = SearchState.loadingMore;
      _currentPage++;
    } else {
      _searchState = SearchState.searching;
      _currentPage = 1;
      _searchResults.clear();
    }

    _error = null;
    notifyListeners();

    try {
      List<Report> results;

      // If there's a search query, use semantic search for better results
      if (_currentFilters.search != null &&
          _currentFilters.search!.trim().isNotEmpty) {
        // Try semantic search first for better relevance
        try {
          final semanticResults = await _apiService.semanticSearch(
            _currentFilters.search!,
          );
          // Convert SearchResult to Report for compatibility
          results = semanticResults
              .map(
                (result) => Report(
                  id: result.id,
                  title: result.title,
                  description: result.description,
                  type: result.type,
                  status: 'approved', // Default status for search results
                  category: result.category,
                  city: result.city,
                  occurredAt: result.occurredAt,
                  createdAt: result.createdAt,
                  media:
                      result.media
                          ?.map(
                            (url) => Media(
                              id: url,
                              url: url,
                              type: MediaType.image,
                              filename: url.split('/').last,
                              mimeType: 'image/jpeg',
                            ),
                          )
                          .toList() ??
                      [],
                  colors: result.colors,
                  rewardOffered: result.rewardOffered,
                  latitude: result.latitude,
                  longitude: result.longitude,
                ),
              )
              .toList();
          // Apply additional filters to semantic results
          results = _applyFiltersToResults(results);
        } catch (e) {
          // Fallback to regular search if semantic search fails
          results = await _apiService.searchReports(
            filters: _currentFilters.copyWith(
              page: _currentPage,
              pageSize: _pageSize,
            ),
            page: _currentPage,
            pageSize: _pageSize,
          );
        }
      } else {
        // Regular filtered search when no search query
        results = await _apiService.searchReports(
          filters: _currentFilters.copyWith(
            page: _currentPage,
            pageSize: _pageSize,
          ),
          page: _currentPage,
          pageSize: _pageSize,
        );
      }

      if (loadMore) {
        _searchResults.addAll(results);
      } else {
        _searchResults = results;
      }

      _hasMoreResults = results.length == _pageSize;
      _searchState = _searchResults.isEmpty
          ? SearchState.empty
          : SearchState.success;
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Search');
      _searchState = SearchState.error;
      if (loadMore) {
        _currentPage--; // Revert page increment on error
      }
      notifyListeners();
    }
  }

  /// Apply additional filters to search results
  List<Report> _applyFiltersToResults(List<Report> results) {
    return results.where((result) {
      // Type filter
      if (_currentFilters.type != null && result.type != _currentFilters.type) {
        return false;
      }

      // Category filter
      if (_currentFilters.category != null &&
          result.category != _currentFilters.category) {
        return false;
      }

      // City filter
      if (_currentFilters.city != null &&
          result.city.toLowerCase() != _currentFilters.city!.toLowerCase()) {
        return false;
      }

      // Colors filter
      if (_currentFilters.colors != null &&
          _currentFilters.colors!.isNotEmpty) {
        if (result.colors == null || result.colors!.isEmpty) {
          return false;
        }
        bool hasMatchingColor = _currentFilters.colors!.any(
          (color) => result.colors!.any(
            (resultColor) =>
                resultColor.toLowerCase().contains(color.toLowerCase()),
          ),
        );
        if (!hasMatchingColor) {
          return false;
        }
      }

      // Reward filter
      if (_currentFilters.rewardOffered != null &&
          result.rewardOffered != _currentFilters.rewardOffered) {
        return false;
      }

      // Date range filter
      if (_currentFilters.startDate != null &&
          result.createdAt.isBefore(_currentFilters.startDate!)) {
        return false;
      }
      if (_currentFilters.endDate != null &&
          result.createdAt.isAfter(_currentFilters.endDate!)) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Perform quick search (for suggestions)
  Future<void> quickSearch(String query) async {
    if (query.trim().isEmpty) {
      _searchSuggestions.clear();
      notifyListeners();
      return;
    }

    try {
      // Get suggestions from API
      final apiSuggestions = await _apiService.getSearchSuggestions(query);

      // Add recent searches that match the query
      final recentSuggestions = await _getRecentSuggestions(query);

      // Combine and deduplicate suggestions
      final allSuggestions = <SearchSuggestion>[];
      final seenTexts = <String>{};

      // Add API suggestions first (higher priority)
      for (final suggestion in apiSuggestions) {
        if (!seenTexts.contains(suggestion.text)) {
          allSuggestions.add(suggestion);
          seenTexts.add(suggestion.text);
        }
      }

      // Add recent suggestions
      for (final suggestion in recentSuggestions) {
        if (!seenTexts.contains(suggestion.text)) {
          allSuggestions.add(suggestion);
          seenTexts.add(suggestion.text);
        }
      }

      _searchSuggestions = allSuggestions.take(10).toList();
      notifyListeners();
    } catch (e) {
      // Don't show error for suggestions, just clear them
      _searchSuggestions.clear();
      notifyListeners();
    }
  }

  /// Get recent search suggestions that match the query
  Future<List<SearchSuggestion>> _getRecentSuggestions(String query) async {
    try {
      final recentSearches = await _apiService.getRecentSearches();
      return recentSearches
          .where(
            (search) => search.text.toLowerCase().contains(query.toLowerCase()),
          )
          .take(5)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save search query for future suggestions
  Future<void> saveSearchQuery(String query) async {
    if (query.trim().isEmpty) return;

    try {
      await _apiService.saveSearchQuery(query);
    } catch (e) {
      // Silently fail - not critical for user experience
    }
  }

  /// Load search analytics
  Future<void> loadAnalytics() async {
    try {
      _analytics = await _apiService.getSearchAnalytics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading search analytics: $e');
    }
  }

  /// Load search trends
  Future<void> loadTrends({DateTime? startDate, DateTime? endDate}) async {
    try {
      _trends = await _apiService.getSearchTrends(
        startDate: startDate,
        endDate: endDate,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading search trends: $e');
    }
  }

  /// Load filter options
  Future<void> loadFilterOptions() async {
    try {
      _filterOptions = await _apiService.getFilterOptions();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading filter options: $e');
    }
  }

  /// Advanced search with complex filters
  Future<void> advancedSearch({bool loadMore = false}) async {
    if (loadMore) {
      _searchState = SearchState.loadingMore;
      _currentPage++;
    } else {
      _searchState = SearchState.searching;
      _currentPage = 1;
      _searchResults.clear();
    }

    _error = null;
    notifyListeners();

    try {
      final results = await _apiService.advancedSearch(
        filters: _currentFilters.copyWith(
          page: _currentPage,
          pageSize: _pageSize,
        ),
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (loadMore) {
        _searchResults.addAll(results);
      } else {
        _searchResults = results;
      }

      _hasMoreResults = results.length == _pageSize;
      _searchState = _searchResults.isEmpty
          ? SearchState.empty
          : SearchState.success;
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Advanced search');
      _searchState = SearchState.error;
      if (loadMore) {
        _currentPage--; // Revert page increment on error
      }
      notifyListeners();
    }
  }

  /// Search by location
  Future<void> searchByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    bool loadMore = false,
  }) async {
    if (loadMore) {
      _searchState = SearchState.loadingMore;
      _currentPage++;
    } else {
      _searchState = SearchState.searching;
      _currentPage = 1;
      _searchResults.clear();
    }

    _error = null;
    notifyListeners();

    try {
      final results = await _apiService.searchByLocation(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        additionalFilters: _currentFilters,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (loadMore) {
        _searchResults.addAll(results);
      } else {
        _searchResults = results;
      }

      _hasMoreResults = results.length == _pageSize;
      _searchState = _searchResults.isEmpty
          ? SearchState.empty
          : SearchState.success;
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Location search');
      _searchState = SearchState.error;
      if (loadMore) {
        _currentPage--; // Revert page increment on error
      }
      notifyListeners();
    }
  }

  /// Search by image similarity
  Future<void> searchByImage({
    required String imageUrl,
    double threshold = 0.7,
    bool loadMore = false,
  }) async {
    if (loadMore) {
      _searchState = SearchState.loadingMore;
      _currentPage++;
    } else {
      _searchState = SearchState.searching;
      _currentPage = 1;
      _searchResults.clear();
    }

    _error = null;
    notifyListeners();

    try {
      final results = await _apiService.searchByImage(
        imageUrl: imageUrl,
        threshold: threshold,
        additionalFilters: _currentFilters,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (loadMore) {
        _searchResults.addAll(results);
      } else {
        _searchResults = results;
      }

      _hasMoreResults = results.length == _pageSize;
      _searchState = _searchResults.isEmpty
          ? SearchState.empty
          : SearchState.success;
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.handleError(e, context: 'Image search');
      _searchState = SearchState.error;
      if (loadMore) {
        _currentPage--; // Revert page increment on error
      }
      notifyListeners();
    }
  }

  /// Update search filters
  void updateFilters(SearchFilters filters) {
    _currentFilters = filters;
    notifyListeners();
  }

  /// Update search query
  void updateSearchQuery(String query) {
    _currentFilters = _currentFilters.copyWith(search: query);
    _lastQuery = query;
    notifyListeners();
  }

  /// Add or remove a filter
  void toggleFilter(String key, dynamic value) {
    SearchFilters newFilters;

    switch (key) {
      case 'type':
        newFilters = _currentFilters.copyWith(type: value);
        break;
      case 'category':
        newFilters = _currentFilters.copyWith(category: value);
        break;
      case 'status':
        newFilters = _currentFilters.copyWith(status: value);
        break;
      case 'city':
        newFilters = _currentFilters.copyWith(city: value);
        break;
      case 'rewardOffered':
        newFilters = _currentFilters.copyWith(rewardOffered: value);
        break;
      case 'sortBy':
        newFilters = _currentFilters.copyWith(sortBy: value);
        break;
      case 'maxDistance':
        newFilters = _currentFilters.copyWith(maxDistance: value);
        break;
      default:
        return;
    }

    updateFilters(newFilters);
  }

  /// Toggle color filter
  void toggleColorFilter(String color) {
    final currentColors = List<String>.from(_currentFilters.colors ?? []);

    if (currentColors.contains(color)) {
      currentColors.remove(color);
    } else {
      currentColors.add(color);
    }

    updateFilters(
      _currentFilters.copyWith(
        colors: currentColors.isEmpty ? null : currentColors,
      ),
    );
  }

  /// Set date range filter
  void setDateRange(DateTime? startDate, DateTime? endDate) {
    updateFilters(
      _currentFilters.copyWith(startDate: startDate, endDate: endDate),
    );
  }

  /// Set location filter
  void setLocationFilter({
    String? city,
    double? latitude,
    double? longitude,
    double? maxDistance,
  }) {
    updateFilters(
      _currentFilters.copyWith(
        city: city,
        minLatitude: latitude != null ? latitude - 0.01 : null,
        maxLatitude: latitude != null ? latitude + 0.01 : null,
        minLongitude: longitude != null ? longitude - 0.01 : null,
        maxLongitude: longitude != null ? longitude + 0.01 : null,
        maxDistance: maxDistance,
      ),
    );
  }

  /// Clear all filters
  void clearAllFilters() {
    _currentFilters = SearchFilters();
    notifyListeners();
  }

  /// Clear specific filter
  void clearFilter(String key) {
    SearchFilters newFilters;

    switch (key) {
      case 'search':
        newFilters = _currentFilters.copyWith(search: null);
        break;
      case 'type':
        newFilters = _currentFilters.copyWith(type: null);
        break;
      case 'category':
        newFilters = _currentFilters.copyWith(category: null);
        break;
      case 'status':
        newFilters = _currentFilters.copyWith(status: null);
        break;
      case 'city':
        newFilters = _currentFilters.copyWith(city: null);
        break;
      case 'colors':
        newFilters = _currentFilters.copyWith(colors: null);
        break;
      case 'rewardOffered':
        newFilters = _currentFilters.copyWith(rewardOffered: null);
        break;
      case 'sortBy':
        newFilters = _currentFilters.copyWith(sortBy: null);
        break;
      case 'maxDistance':
        newFilters = _currentFilters.copyWith(maxDistance: null);
        break;
      case 'dateRange':
        newFilters = _currentFilters.copyWith(startDate: null, endDate: null);
        break;
      default:
        return;
    }

    updateFilters(newFilters);
  }

  /// Load more results (pagination)
  Future<void> loadMoreResults() async {
    if (!_hasMoreResults || isLoading) return;
    await search(loadMore: true);
  }

  /// Refresh search results
  Future<void> refresh() async {
    await search();
  }

  /// Clear search results
  void clearResults() {
    _searchResults.clear();
    _searchSuggestions.clear();
    _searchState = SearchState.idle;
    _error = null;
    _hasMoreResults = false;
    _currentPage = 1;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    if (_searchState == SearchState.error) {
      _searchState = SearchState.idle;
    }
    notifyListeners();
  }

  /// Reset all search state
  void reset() {
    _searchResults.clear();
    _searchSuggestions.clear();
    _currentFilters = SearchFilters();
    _searchState = SearchState.idle;
    _error = null;
    _lastQuery = '';
    _hasMoreResults = false;
    _currentPage = 1;
    notifyListeners();
  }

  /// Get filter options for UI
  List<FilterOption> getTypeOptions() {
    return [
      FilterOption(
        value: 'lost',
        label: 'Lost Items',
        icon: Icons.search_off_rounded,
        color: const Color(0xFFEF4444),
      ),
      FilterOption(
        value: 'found',
        label: 'Found Items',
        icon: Icons.search_rounded,
        color: const Color(0xFF10B981),
      ),
    ];
  }

  List<FilterOption> getCategoryOptions() {
    return [
      FilterOption(
        value: 'electronics',
        label: 'Electronics',
        icon: Icons.devices_rounded,
      ),
      FilterOption(
        value: 'personal_items',
        label: 'Personal Items',
        icon: Icons.person_rounded,
      ),
      FilterOption(
        value: 'clothing',
        label: 'Clothing',
        icon: Icons.checkroom_rounded,
      ),
      FilterOption(
        value: 'documents',
        label: 'Documents',
        icon: Icons.description_rounded,
      ),
      FilterOption(
        value: 'jewelry',
        label: 'Jewelry',
        icon: Icons.diamond_rounded,
      ),
      FilterOption(
        value: 'bags',
        label: 'Bags & Accessories',
        icon: Icons.shopping_bag_rounded,
      ),
      FilterOption(value: 'keys', label: 'Keys', icon: Icons.vpn_key_rounded),
      FilterOption(
        value: 'other',
        label: 'Other',
        icon: Icons.category_rounded,
      ),
    ];
  }

  List<FilterOption> getColorOptions() {
    return [
      FilterOption(value: 'red', label: 'Red', color: Colors.red),
      FilterOption(value: 'blue', label: 'Blue', color: Colors.blue),
      FilterOption(value: 'green', label: 'Green', color: Colors.green),
      FilterOption(value: 'yellow', label: 'Yellow', color: Colors.yellow),
      FilterOption(value: 'black', label: 'Black', color: Colors.black),
      FilterOption(value: 'white', label: 'White', color: Colors.white),
      FilterOption(value: 'gray', label: 'Gray', color: Colors.grey),
      FilterOption(value: 'brown', label: 'Brown', color: Colors.brown),
      FilterOption(value: 'purple', label: 'Purple', color: Colors.purple),
      FilterOption(value: 'orange', label: 'Orange', color: Colors.orange),
    ];
  }

  List<FilterOption> getSortOptions() {
    return SearchSortOption.values
        .map(
          (option) => FilterOption(
            value: option.value,
            label: option.label,
            icon: _getSortIcon(option),
          ),
        )
        .toList();
  }

  IconData _getSortIcon(SearchSortOption option) {
    switch (option) {
      case SearchSortOption.relevance:
        return Icons.star_rounded;
      case SearchSortOption.dateNewest:
        return Icons.schedule_rounded;
      case SearchSortOption.dateOldest:
        return Icons.history_rounded;
      case SearchSortOption.distance:
        return Icons.location_on_rounded;
      case SearchSortOption.title:
        return Icons.sort_by_alpha_rounded;
    }
  }

  /// Get search statistics
  Map<String, dynamic> getSearchStats() {
    return {
      'total_results': _searchResults.length,
      'active_filters': _currentFilters.activeFilterCount,
      'has_query':
          _currentFilters.search != null && _currentFilters.search!.isNotEmpty,
      'search_state': _searchState.name,
    };
  }

  /// Get popular searches
  Future<List<SearchSuggestion>> getPopularSearches() async {
    try {
      return await _apiService.getPopularSearches();
    } catch (e) {
      debugPrint('Error getting popular searches: $e');
      return [];
    }
  }

  /// Get recent searches
  Future<List<SearchSuggestion>> getRecentSearches() async {
    try {
      return await _apiService.getRecentSearches();
    } catch (e) {
      debugPrint('Error getting recent searches: $e');
      return [];
    }
  }
}

import 'package:flutter/material.dart';
import '../models/search_models.dart';
import '../models/report.dart';
import '../services/api_service.dart';
import 'base_provider.dart';

/// Search Provider - Manages search and filter functionality
class SearchProvider extends BaseProvider {
  final ApiService _apiService = ApiService();

  // Search state
  List<Report> _searchResults = [];
  List<SearchSuggestion> _searchSuggestions = [];
  SearchFilters _currentFilters = SearchFilters();
  SearchState _searchState = SearchState.idle;
  String _lastQuery = '';
  bool _hasMoreResults = false;
  int _currentPage = 1;
  static const int _pageSize = 20;

  // Analytics and trends
  SearchAnalytics? _analytics;
  Map<String, dynamic>? _trends;
  Map<String, List<FilterOption>> _filterOptions = {};

  // Search history
  List<String> _searchHistory = [];
  List<String> _recentSearches = [];

  // Getters
  List<Report> get searchResults => _searchResults;
  List<SearchSuggestion> get searchSuggestions => _searchSuggestions;
  SearchFilters get currentFilters => _currentFilters;
  SearchState get searchState => _searchState;
  String get lastQuery => _lastQuery;
  bool get hasMoreResults => _hasMoreResults;
  SearchAnalytics? get analytics => _analytics;
  Map<String, dynamic>? get trends => _trends;
  Map<String, List<FilterOption>> get filterOptions => _filterOptions;
  List<String> get searchHistory => _searchHistory;
  List<String> get recentSearches => _recentSearches;

  bool get isSearching =>
      _searchState == SearchState.searching ||
      _searchState == SearchState.loadingMore;
  bool get isEmpty => _searchState == SearchState.empty;
  bool get hasResults => _searchResults.isNotEmpty;
  @override
  bool get hasError => _searchState == SearchState.error;

  /// Update search query
  void updateSearchQuery(String query) {
    _lastQuery = query;
    notifyListeners();
  }

  /// Quick search for suggestions
  Future<void> quickSearch(String query) async {
    if (query.isEmpty) {
      _searchSuggestions = [];
      notifyListeners();
      return;
    }

    try {
      setLoading();
      final suggestions = await _apiService.getSearchSuggestions(query);
      _searchSuggestions = suggestions
          .map((text) => SearchSuggestion(
                text: text,
                type: 'suggestion',
              ))
          .toList();
      setLoaded();
      notifyListeners();
    } catch (e) {
      setError('Failed to get search suggestions: $e');
    }
  }

  /// Clear search results
  void clearResults() {
    _searchResults = [];
    _searchState = SearchState.idle;
    _currentPage = 1;
    _hasMoreResults = false;
    notifyListeners();
  }

  /// Update filters
  void updateFilters(SearchFilters filters) {
    _currentFilters = filters;
    notifyListeners();
  }

  /// Toggle a specific filter
  void toggleFilter(String filterType, String value) {
    switch (filterType) {
      case 'sortBy':
        _currentFilters = _currentFilters.copyWith(sortBy: value);
        break;
      case 'type':
        _currentFilters = _currentFilters.copyWith(type: value);
        break;
      case 'category':
        _currentFilters = _currentFilters.copyWith(category: value);
        break;
      case 'status':
        _currentFilters = _currentFilters.copyWith(status: value);
        break;
      case 'city':
        _currentFilters = _currentFilters.copyWith(city: value);
        break;
    }
    notifyListeners();
  }

  /// Save search query to history
  void saveSearchQuery(String query) {
    if (query.isNotEmpty && !_searchHistory.contains(query)) {
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 50) {
        _searchHistory = _searchHistory.take(50).toList();
      }
      notifyListeners();
    }
  }

  /// Get type options for filters
  List<FilterOption> getTypeOptions() {
    return [
      FilterOption(value: 'lost', label: 'Lost Items', icon: Icons.search_off),
      FilterOption(value: 'found', label: 'Found Items', icon: Icons.search),
    ];
  }

  /// Get category options for filters
  List<FilterOption> getCategoryOptions() {
    return [
      FilterOption(
          value: 'electronics', label: 'Electronics', icon: Icons.devices),
      FilterOption(value: 'clothing', label: 'Clothing', icon: Icons.checkroom),
      FilterOption(
          value: 'accessories', label: 'Accessories', icon: Icons.watch),
      FilterOption(
          value: 'documents', label: 'Documents', icon: Icons.description),
      FilterOption(value: 'keys', label: 'Keys', icon: Icons.vpn_key),
      FilterOption(value: 'bags', label: 'Bags', icon: Icons.shopping_bag),
      FilterOption(value: 'jewelry', label: 'Jewelry', icon: Icons.diamond),
      FilterOption(value: 'books', label: 'Books', icon: Icons.book),
      FilterOption(value: 'sports', label: 'Sports', icon: Icons.sports),
      FilterOption(value: 'other', label: 'Other', icon: Icons.category),
    ];
  }

  /// Get color options for filters
  List<FilterOption> getColorOptions() {
    return [
      FilterOption(value: 'black', label: 'Black', color: Colors.black),
      FilterOption(value: 'white', label: 'White', color: Colors.white),
      FilterOption(value: 'red', label: 'Red', color: Colors.red),
      FilterOption(value: 'blue', label: 'Blue', color: Colors.blue),
      FilterOption(value: 'green', label: 'Green', color: Colors.green),
      FilterOption(value: 'yellow', label: 'Yellow', color: Colors.yellow),
      FilterOption(value: 'orange', label: 'Orange', color: Colors.orange),
      FilterOption(value: 'purple', label: 'Purple', color: Colors.purple),
      FilterOption(value: 'pink', label: 'Pink', color: Colors.pink),
      FilterOption(value: 'brown', label: 'Brown', color: Colors.brown),
      FilterOption(value: 'gray', label: 'Gray', color: Colors.grey),
      FilterOption(
          value: 'silver', label: 'Silver', color: Colors.grey.shade400),
      FilterOption(value: 'gold', label: 'Gold', color: Colors.amber),
    ];
  }

  /// Get sort options for filters
  List<FilterOption> getSortOptions() {
    return [
      FilterOption(
          value: 'date_newest',
          label: 'Newest First',
          icon: Icons.arrow_downward),
      FilterOption(
          value: 'date_oldest',
          label: 'Oldest First',
          icon: Icons.arrow_upward),
      FilterOption(
          value: 'relevance', label: 'Most Relevant', icon: Icons.star),
      FilterOption(
          value: 'distance', label: 'Nearest First', icon: Icons.location_on),
      FilterOption(
          value: 'title', label: 'Alphabetical', icon: Icons.sort_by_alpha),
    ];
  }

  /// Perform universal search with current filters
  Future<void> search({bool loadMore = false}) async {
    try {
      setLoading();

      if (loadMore) {
        _searchState = SearchState.loadingMore;
        _currentPage++;
      } else {
        _searchState = SearchState.searching;
        _currentPage = 1;
        _searchResults.clear();
      }
      notifyListeners();

      final Map<String, dynamic> filters = _currentFilters.toQueryParams();
      filters['page'] = _currentPage;
      filters['page_size'] = _pageSize;

      final List<Map<String, dynamic>> rawResults =
          await _apiService.searchReports(
        query: _lastQuery.isNotEmpty ? _lastQuery : 'all',
        additionalFilters: filters,
      );

      final List<Report> newResults =
          rawResults.map((json) => Report.fromJson(json)).toList();

      if (loadMore) {
        _searchResults.addAll(newResults);
      } else {
        _searchResults = newResults;
      }

      _hasMoreResults = newResults.length == _pageSize;
      _searchState =
          _searchResults.isEmpty ? SearchState.empty : SearchState.success;
      setLoaded();
      notifyListeners();
    } catch (e) {
      setError('Search failed: $e');
      _searchState = SearchState.error;
    }
  }

  /// Apply filters to search
  void applyFilters(SearchFilters filters) {
    _currentFilters = filters;
    search();
  }

  /// Reset filters
  void resetFilters() {
    _currentFilters = SearchFilters();
    search();
  }

  /// Fetch search suggestions based on query
  Future<void> fetchSearchSuggestions(String query) async {
    if (query.isEmpty) {
      _searchSuggestions = [];
      notifyListeners();
      return;
    }

    try {
      setLoading();
      final List<String> rawSuggestions =
          await _apiService.getSearchSuggestions(query);
      _searchSuggestions = rawSuggestions
          .map((text) => SearchSuggestion(
                text: text,
                type: 'suggestion',
              ))
          .toList();
      setLoaded();
      notifyListeners();
    } catch (e) {
      setError('Failed to fetch search suggestions: $e');
    }
  }

  /// Fetch search analytics
  Future<void> fetchSearchAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      setLoading();
      final Map<String, dynamic>? rawAnalytics =
          await _apiService.getSearchAnalytics();
      _analytics =
          rawAnalytics != null ? SearchAnalytics.fromJson(rawAnalytics) : null;
      setLoaded();
      notifyListeners();
    } catch (e) {
      setError('Failed to fetch search analytics: $e');
    }
  }

  /// Fetch search trends
  Future<void> fetchSearchTrends() async {
    try {
      setLoading();
      final List<Map<String, dynamic>> trendsList =
          await _apiService.getSearchTrends();
      _trends = {'trends': trendsList};
      setLoaded();
      notifyListeners();
    } catch (e) {
      setError('Failed to fetch search trends: $e');
    }
  }

  /// Fetch filter options
  Future<void> fetchFilterOptions() async {
    try {
      setLoading();
      final Map<String, dynamic>? rawOptions =
          await _apiService.getFilterOptions();
      if (rawOptions != null) {
        _filterOptions = rawOptions.map((key, value) => MapEntry(
            key,
            (value as List)
                .map((e) => FilterOption(
                      value: e['value'] ?? '',
                      label: e['label'] ?? '',
                      count: e['count'],
                    ))
                .toList()));
      }
      setLoaded();
      notifyListeners();
    } catch (e) {
      setError('Failed to fetch filter options: $e');
    }
  }

  /// Advanced search with specific filters
  Future<void> advancedSearch({
    String? query,
    String? type,
    String? category,
    String? status,
    String? city,
    DateTime? startDate,
    DateTime? endDate,
    double? minReward,
    double? maxReward,
    bool loadMore = false,
  }) async {
    try {
      setLoading();

      if (loadMore) {
        _searchState = SearchState.loadingMore;
        _currentPage++;
      } else {
        _searchState = SearchState.searching;
        _currentPage = 1;
        _searchResults.clear();
      }
      notifyListeners();

      final Map<String, dynamic> filters = {
        if (query != null) 'query': query,
        if (type != null) 'type': type,
        if (category != null) 'category': category,
        if (status != null) 'status': status,
        if (city != null) 'city': city,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (minReward != null) 'min_reward': minReward,
        if (maxReward != null) 'max_reward': maxReward,
        'page': _currentPage,
        'page_size': _pageSize,
      };

      final List<Map<String, dynamic>> rawResults =
          await _apiService.searchReports(
        query: _lastQuery.isNotEmpty ? _lastQuery : 'all',
        additionalFilters: filters,
      );

      final List<Report> newResults =
          rawResults.map((json) => Report.fromJson(json)).toList();

      if (loadMore) {
        _searchResults.addAll(newResults);
      } else {
        _searchResults = newResults;
      }

      _hasMoreResults = newResults.length == _pageSize;
      _searchState =
          _searchResults.isEmpty ? SearchState.empty : SearchState.success;
      setLoaded();
      notifyListeners();
    } catch (e) {
      setError('Advanced search failed: $e');
      _searchState = SearchState.error;
    }
  }

  /// Perform image search
  Future<void> imageSearch(String imageUrl) async {
    try {
      setLoading();
      _searchState = SearchState.searching;
      _searchResults.clear();
      notifyListeners();

      final List<Map<String, dynamic>> rawResults =
          await _apiService.searchReports(
        query: 'image_search',
        additionalFilters: {'image_url': imageUrl},
      );

      _searchResults = rawResults.map((json) => Report.fromJson(json)).toList();
      _searchState =
          _searchResults.isEmpty ? SearchState.empty : SearchState.success;
      setLoaded();
      notifyListeners();
    } catch (e) {
      setError('Image search failed: $e');
      _searchState = SearchState.error;
    }
  }

  /// Perform semantic search
  Future<void> semanticSearch(String query) async {
    try {
      setLoading();
      _searchState = SearchState.searching;
      _searchResults.clear();
      notifyListeners();

      final List<Map<String, dynamic>> rawResults =
          await _apiService.searchReports(
        query: query,
        additionalFilters: {'semantic_search': true},
      );

      _searchResults = rawResults.map((json) => Report.fromJson(json)).toList();
      _searchState =
          _searchResults.isEmpty ? SearchState.empty : SearchState.success;
      setLoaded();
      notifyListeners();
    } catch (e) {
      setError('Semantic search failed: $e');
      _searchState = SearchState.error;
    }
  }

  /// Perform location search
  Future<void> locationSearch({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    bool loadMore = false,
  }) async {
    try {
      setLoading();

      if (loadMore) {
        _searchState = SearchState.loadingMore;
        _currentPage++;
      } else {
        _searchState = SearchState.searching;
        _currentPage = 1;
        _searchResults.clear();
      }
      notifyListeners();

      final List<Map<String, dynamic>> rawResults =
          await _apiService.searchReports(
        query: 'location_search',
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        additionalFilters: {
          'page': _currentPage,
          'page_size': _pageSize,
        },
      );

      final List<Report> newResults =
          rawResults.map((json) => Report.fromJson(json)).toList();

      if (loadMore) {
        _searchResults.addAll(newResults);
      } else {
        _searchResults = newResults;
      }

      _hasMoreResults = newResults.length == _pageSize;
      _searchState =
          _searchResults.isEmpty ? SearchState.empty : SearchState.success;
      setLoaded();
      notifyListeners();
    } catch (e) {
      setError('Location search failed: $e');
      _searchState = SearchState.error;
    }
  }

  /// Get recent search suggestions
  Future<List<SearchSuggestion>> getRecentSuggestions() async {
    try {
      final List<String> recent = await _apiService.getRecentSearches();
      return recent
          .map((text) => SearchSuggestion(
                text: text,
                type: 'recent',
              ))
          .toList();
    } catch (e) {
      setError('Failed to get recent suggestions: $e');
      return [];
    }
  }

  /// Get popular search suggestions
  Future<List<SearchSuggestion>> getPopularSearches() async {
    try {
      final List<String> popular = await _apiService.getPopularSearches();
      return popular
          .map((text) => SearchSuggestion(
                text: text,
                type: 'popular',
              ))
          .toList();
    } catch (e) {
      setError('Failed to get popular searches: $e');
      return [];
    }
  }

  /// Get recent searches
  Future<List<SearchSuggestion>> getRecentSearches() async {
    try {
      final List<String> recent = await _apiService.getRecentSearches();
      return recent
          .map((text) => SearchSuggestion(
                text: text,
                type: 'recent',
              ))
          .toList();
    } catch (e) {
      setError('Failed to get recent searches: $e');
      return [];
    }
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    try {
      setLoading();
      // Note: API method not implemented yet
      _searchHistory.clear();
      setLoaded();
      notifyListeners();
    } catch (e) {
      setError('Failed to clear search history: $e');
    }
  }

  /// Export search results
  Future<void> exportSearchResults() async {
    try {
      setLoading();
      // Note: API method not implemented yet
      setLoaded();
      notifyListeners();
    } catch (e) {
      setError('Failed to export search results: $e');
    }
  }

  /// Get search statistics
  Future<Map<String, dynamic>?> getSearchStats() async {
    try {
      // Note: API method not implemented yet
      return null;
    } catch (e) {
      setError('Failed to get search stats: $e');
      return null;
    }
  }
}

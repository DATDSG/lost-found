import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../models/item.dart';
import '../services/api_service.dart';
import '../services/preferences_service.dart';
import '../services/location_service.dart';
import 'locale_provider.dart'; // For preferencesServiceProvider

/// Items state
class ItemsState {
  final List<Item> items;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final Map<String, String?> filters;
  final double? userLatitude;
  final double? userLongitude;

  ItemsState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.filters = const {},
    this.userLatitude,
    this.userLongitude,
  });

  List<Item> get lostItems => items.where((item) => item.isLost).toList();
  List<Item> get foundItems => items.where((item) => item.isFound).toList();

  ItemsState copyWith({
    List<Item>? items,
    bool? isLoading,
    String? error,
    String? searchQuery,
    Map<String, String?>? filters,
    double? userLatitude,
    double? userLongitude,
  }) {
    return ItemsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
    );
  }
}

/// Items notifier
class ItemsNotifier extends StateNotifier<ItemsState> {
  final ApiService _apiService;
  final PreferencesService _preferencesService;
  final LocationService _locationService;

  ItemsNotifier(
    this._apiService,
    this._preferencesService,
    this._locationService,
  ) : super(ItemsState()) {
    _initializeFilters();
    _initializeLocation();
  }

  /// Initialize filters from preferences
  void _initializeFilters() {
    final savedFilters = _preferencesService.getAllFilters();
    state = state.copyWith(filters: savedFilters);
  }

  /// Initialize user location
  Future<void> _initializeLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        state = state.copyWith(
          userLatitude: position.latitude,
          userLongitude: position.longitude,
        );
        // Save location to preferences
        await _preferencesService.setLastLocation(
          position.latitude,
          position.longitude,
        );
      }
    } catch (e) {
      // Try to load last known location
      final lastLocation = _preferencesService.getLastLocation();
      if (lastLocation != null) {
        state = state.copyWith(
          userLatitude: lastLocation['latitude'],
          userLongitude: lastLocation['longitude'],
        );
      }
    }
  }

  /// Search items with current query and filters
  Future<void> searchItems() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final items = await _apiService.searchItems(
        query: state.searchQuery,
        type: state.filters['type'],
        time: state.filters['time'],
        distance: state.filters['distance'],
        category: state.filters['category'],
        location: state.filters['location'],
        latitude: state.userLatitude,
        longitude: state.userLongitude,
      );

      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load items (alias for searchItems for backward compatibility)
  Future<void> loadItems({String? type}) async {
    if (type != null) {
      await applyFilters({'type': type});
    } else {
      await searchItems();
    }
  }

  /// Update search query
  Future<void> updateSearchQuery(String? query) async {
    state = state.copyWith(searchQuery: query);
    await searchItems();
  }

  /// Apply filters
  Future<void> applyFilters(Map<String, String?> filters) async {
    // Save filters to preferences
    await _preferencesService.saveAllFilters(filters);

    // Update state and search
    state = state.copyWith(filters: filters);
    await searchItems();
  }

  /// Clear filters
  Future<void> clearFilters() async {
    await _preferencesService.clearAllFilters();
    state = state.copyWith(filters: {});
    await searchItems();
  }

  /// Refresh location and search
  Future<void> refreshLocation() async {
    await _initializeLocation();
    await searchItems();
  }

  /// Get single item
  Future<Item?> getItem(String id) async {
    try {
      return await _apiService.getItemDetails(id);
    } catch (e) {
      return null;
    }
  }

  /// Create new item
  Future<bool> createItem(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(ApiConfig.items, data: data);
      final newItem = Item.fromJson(response.data);

      // Add to local state
      state = state.copyWith(
        items: [...state.items, newItem],
      );

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update item
  Future<bool> updateItem(String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _apiService.put('${ApiConfig.items}/$id', data: data);
      final updatedItem = Item.fromJson(response.data);

      // Update in local state
      final updatedItems = state.items.map((item) {
        return item.id == id ? updatedItem : item;
      }).toList();

      state = state.copyWith(items: updatedItems);

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Delete item
  Future<bool> deleteItem(String id) async {
    try {
      await _apiService.delete('${ApiConfig.items}/$id');

      // Remove from local state
      final updatedItems = state.items.where((item) => item.id != id).toList();
      state = state.copyWith(items: updatedItems);

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

/// Items provider
final itemsProvider = StateNotifierProvider<ItemsNotifier, ItemsState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final prefsService = ref.read(preferencesServiceProvider);
  final locationService = LocationService();

  return ItemsNotifier(apiService, prefsService, locationService);
});

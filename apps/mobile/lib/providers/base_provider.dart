import 'package:flutter/foundation.dart';

/// Base state enum for providers
enum BaseState {
  initial,
  loading,
  loaded,
  error,
  updating,
  deleting,
  creating,
}

/// Base provider with common state management patterns
abstract class BaseProvider with ChangeNotifier {
  BaseState _state = BaseState.initial;
  String? _error;
  bool _isLoading = false;

  // Getters
  BaseState get state => _state;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isLoaded => _state == BaseState.loaded;
  bool get hasError => _state == BaseState.error;
  bool get isUpdating => _state == BaseState.updating;
  bool get isDeleting => _state == BaseState.deleting;
  bool get isCreating => _state == BaseState.creating;

  /// Set loading state
  void setLoading() {
    _state = BaseState.loading;
    _isLoading = true;
    _error = null;
    notifyListeners();
  }

  /// Set loaded state
  void setLoaded() {
    _state = BaseState.loaded;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Set error state
  void setError(String error) {
    _state = BaseState.error;
    _isLoading = false;
    _error = error;
    notifyListeners();
  }

  /// Set updating state
  void setUpdating() {
    _state = BaseState.updating;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Set deleting state
  void setDeleting() {
    _state = BaseState.deleting;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Set creating state
  void setCreating() {
    _state = BaseState.creating;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Execute operation with state management
  Future<T?> executeOperation<T>(
    Future<T> Function() operation, {
    BaseState? loadingState,
    String? operationName,
  }) async {
    try {
      if (loadingState != null) {
        _state = loadingState;
        _isLoading = true;
        _error = null;
        notifyListeners();
      }

      final result = await operation();
      setLoaded();
      return result;
    } catch (e) {
      final errorMessage =
          operationName != null ? 'Error $operationName: $e' : 'Error: $e';
      setError(errorMessage);
      return null;
    }
  }

  /// Execute operation that returns a list
  Future<List<T>> executeListOperation<T>(
    Future<List<T>> Function() operation, {
    BaseState? loadingState,
    String? operationName,
  }) async {
    try {
      if (loadingState != null) {
        _state = loadingState;
        _isLoading = true;
        _error = null;
        notifyListeners();
      }

      final result = await operation();
      setLoaded();
      return result;
    } catch (e) {
      final errorMessage =
          operationName != null ? 'Error $operationName: $e' : 'Error: $e';
      setError(errorMessage);
      return [];
    }
  }

  /// Execute operation with no return value
  Future<bool> executeVoidOperation(
    Future<void> Function() operation, {
    BaseState? loadingState,
    String? operationName,
  }) async {
    try {
      if (loadingState != null) {
        _state = loadingState;
        _isLoading = true;
        _error = null;
        notifyListeners();
      }

      await operation();
      setLoaded();
      return true;
    } catch (e) {
      final errorMessage =
          operationName != null ? 'Error $operationName: $e' : 'Error: $e';
      setError(errorMessage);
      return false;
    }
  }
}

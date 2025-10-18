/// Loading state utilities used by multiple providers.
///
/// A lightweight mixin that helps track loading/error states across different
/// operations without forcing a specific state-management solution.
mixin LoadingStateMixin {
  final Map<String, bool> _loadingStates = {};
  final Map<String, String?> _errorStates = {};

  /// Returns a read-only view of loading flags.
  Map<String, bool> get loadingStates => Map.unmodifiable(_loadingStates);

  /// Returns a read-only view of tracked errors.
  Map<String, String?> get errorStates => Map.unmodifiable(_errorStates);

  /// Whether any tracked operation is currently loading.
  bool get isAnyLoading => _loadingStates.values.any((isLoading) => isLoading);
  bool get hasErrors => _errorStates.isNotEmpty;

  /// Convenience getter for a specific loading flag.
  bool isLoading(String key) => _loadingStates[key] ?? false;

  /// Convenience getter for a specific error message.
  String? errorFor(String key) => _errorStates[key];

  /// Update loading state for a named operation.
  void setLoading(String key, bool value) {
    if (value) {
      _loadingStates[key] = true;
    } else {
      _loadingStates.remove(key);
    }
  }

  /// Capture or clear an error for a named operation.
  void setError(String key, String? message) {
    if (message == null || message.isEmpty) {
      _errorStates.remove(key);
    } else {
      _errorStates[key] = message;
    }
  }

  /// Remove all tracked loading flags.
  void clearAllLoading() => _loadingStates.clear();

  /// Remove all tracked errors.
  void clearAllErrors() => _errorStates.clear();
}

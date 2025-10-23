import 'package:get_it/get_it.dart';

/// Dependency injection setup for the app
final GetIt getIt = GetIt.instance;

/// Initialize dependency injection
Future<void> initDependencyInjection() async {
  // Register services here
  // Example:
  // getIt.registerLazySingleton<ApiService>(() => ApiService());
}

/// Get a service instance from dependency injection
T getService<T extends Object>() => getIt.get<T>();

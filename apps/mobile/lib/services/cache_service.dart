import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

/// Cache entry model
class CacheEntry {
  final String key;
  final String data;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? tag;
  final Map<String, dynamic>? metadata;

  CacheEntry({
    required this.key,
    required this.data,
    required this.createdAt,
    required this.expiresAt,
    this.tag,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'tag': tag,
      'metadata': metadata != null ? jsonEncode(metadata) : null,
    };
  }

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      key: json['key'],
      data: json['data'],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      tag: json['tag'],
      metadata: json['metadata'] != null ? jsonDecode(json['metadata']) : null,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Comprehensive caching service using SQLite
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  Database? _database;
  static const String _tableName = 'cache_entries';
  static const int _databaseVersion = 1;

  // Cache configuration
  static const Duration _defaultExpiry = Duration(hours: 24);
  static const int _maxCacheSize = 1000; // Maximum number of entries
  static const int _maxCacheSizeMB = 100; // Maximum cache size in MB

  // Getters
  bool get isInitialized => _database != null;
  Database? get database => _database;

  /// Initialize the cache database
  Future<void> initialize() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'app_cache.db');

      _database = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
      );

      // Clean up expired entries on startup
      await _cleanupExpiredEntries();

      debugPrint('✅ CacheService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize CacheService: $e');
    }
  }

  /// Create database tables
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        key TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        tag TEXT,
        metadata TEXT
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_expires_at ON $_tableName(expires_at)');
    await db.execute('CREATE INDEX idx_tag ON $_tableName(tag)');
    await db.execute('CREATE INDEX idx_created_at ON $_tableName(created_at)');
  }

  /// Upgrade database schema
  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Handle database upgrades here
    debugPrint('Upgrading database from $oldVersion to $newVersion');
  }

  /// Store data in cache
  Future<void> store(
    String key,
    dynamic data, {
    Duration? expiry,
    String? tag,
    Map<String, dynamic>? metadata,
  }) async {
    if (_database == null) {
      debugPrint('CacheService not initialized');
      return;
    }

    try {
      final expiryDuration = expiry ?? _defaultExpiry;
      final expiresAt = DateTime.now().add(expiryDuration);
      final dataString = data is String ? data : jsonEncode(data);

      final entry = CacheEntry(
        key: key,
        data: dataString,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
        tag: tag,
        metadata: metadata,
      );

      await _database!.insert(
        _tableName,
        entry.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Check cache size and cleanup if necessary
      await _enforceCacheLimits();

      debugPrint(
        '📦 Cached data for key: $key (expires: ${expiryDuration.inHours}h)',
      );
    } catch (e) {
      debugPrint('❌ Failed to store cache entry: $e');
    }
  }

  /// Retrieve data from cache
  Future<T?> retrieve<T>(String key) async {
    if (_database == null) {
      debugPrint('CacheService not initialized');
      return null;
    }

    try {
      final results = await _database!.query(
        _tableName,
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (results.isEmpty) {
        return null;
      }

      final entry = CacheEntry.fromJson(results.first);

      // Check if entry is expired
      if (entry.isExpired) {
        await _remove(key);
        return null;
      }

      // Parse data based on expected type
      if (T == String) {
        return entry.data as T;
      } else {
        return jsonDecode(entry.data) as T;
      }
    } catch (e) {
      debugPrint('❌ Failed to retrieve cache entry: $e');
      return null;
    }
  }

  /// Check if key exists in cache and is not expired
  Future<bool> exists(String key) async {
    if (_database == null) return false;

    try {
      final results = await _database!.query(
        _tableName,
        columns: ['expires_at'],
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );

      if (results.isEmpty) return false;

      final expiresAt = DateTime.parse(results.first['expires_at'] as String);
      if (DateTime.now().isAfter(expiresAt)) {
        await _remove(key);
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Failed to check cache existence: $e');
      return false;
    }
  }

  /// Remove specific cache entry
  Future<void> remove(String key) async {
    await _remove(key);
  }

  Future<void> _remove(String key) async {
    if (_database == null) return;

    try {
      await _database!.delete(_tableName, where: 'key = ?', whereArgs: [key]);
    } catch (e) {
      debugPrint('❌ Failed to remove cache entry: $e');
    }
  }

  /// Remove all entries with a specific tag
  Future<void> removeByTag(String tag) async {
    if (_database == null) return;

    try {
      await _database!.delete(_tableName, where: 'tag = ?', whereArgs: [tag]);
      debugPrint('🗑️ Removed all cache entries with tag: $tag');
    } catch (e) {
      debugPrint('❌ Failed to remove cache entries by tag: $e');
    }
  }

  /// Clear all cache entries
  Future<void> clear() async {
    if (_database == null) return;

    try {
      await _database!.delete(_tableName);
      debugPrint('🗑️ Cleared all cache entries');
    } catch (e) {
      debugPrint('❌ Failed to clear cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    if (_database == null) {
      return {
        'total_entries': 0,
        'expired_entries': 0,
        'cache_size_mb': 0.0,
        'oldest_entry': null,
        'newest_entry': null,
      };
    }

    try {
      // Get total entries
      final totalResult = await _database!.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      final totalEntries = totalResult.first['count'] as int;

      // Get expired entries
      final expiredResult = await _database!.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE expires_at < ?',
        [DateTime.now().toIso8601String()],
      );
      final expiredEntries = expiredResult.first['count'] as int;

      // Get oldest and newest entries
      final oldestResult = await _database!.rawQuery(
        'SELECT created_at FROM $_tableName ORDER BY created_at ASC LIMIT 1',
      );
      final newestResult = await _database!.rawQuery(
        'SELECT created_at FROM $_tableName ORDER BY created_at DESC LIMIT 1',
      );

      // Calculate cache size (approximate)
      final sizeResult = await _database!.rawQuery(
        'SELECT SUM(LENGTH(data)) as size FROM $_tableName',
      );
      final sizeBytes = sizeResult.first['size'] as int? ?? 0;
      final cacheSizeMB = sizeBytes / (1024 * 1024);

      return {
        'total_entries': totalEntries,
        'expired_entries': expiredEntries,
        'cache_size_mb': cacheSizeMB,
        'oldest_entry': oldestResult.isNotEmpty
            ? oldestResult.first['created_at']
            : null,
        'newest_entry': newestResult.isNotEmpty
            ? newestResult.first['created_at']
            : null,
      };
    } catch (e) {
      debugPrint('❌ Failed to get cache stats: $e');
      return {
        'total_entries': 0,
        'expired_entries': 0,
        'cache_size_mb': 0.0,
        'oldest_entry': null,
        'newest_entry': null,
      };
    }
  }

  /// Clean up expired entries
  Future<void> _cleanupExpiredEntries() async {
    if (_database == null) return;

    try {
      final deletedCount = await _database!.delete(
        _tableName,
        where: 'expires_at < ?',
        whereArgs: [DateTime.now().toIso8601String()],
      );

      if (deletedCount > 0) {
        debugPrint('🧹 Cleaned up $deletedCount expired cache entries');
      }
    } catch (e) {
      debugPrint('❌ Failed to cleanup expired entries: $e');
    }
  }

  /// Enforce cache size limits
  Future<void> _enforceCacheLimits() async {
    if (_database == null) return;

    try {
      // Check entry count limit
      final countResult = await _database!.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      final entryCount = countResult.first['count'] as int;

      if (entryCount > _maxCacheSize) {
        // Remove oldest entries
        final excessCount = entryCount - _maxCacheSize;
        await _database!.rawDelete(
          'DELETE FROM $_tableName WHERE key IN (SELECT key FROM $_tableName ORDER BY created_at ASC LIMIT ?)',
          [excessCount],
        );
        debugPrint('🧹 Removed $excessCount oldest cache entries');
      }

      // Check cache size limit
      final sizeResult = await _database!.rawQuery(
        'SELECT SUM(LENGTH(data)) as size FROM $_tableName',
      );
      final sizeBytes = sizeResult.first['size'] as int? ?? 0;
      final sizeMB = sizeBytes / (1024 * 1024);

      if (sizeMB > _maxCacheSizeMB) {
        // Remove oldest entries until under limit
        await _database!.rawDelete(
          'DELETE FROM $_tableName WHERE key IN (SELECT key FROM $_tableName ORDER BY created_at ASC LIMIT ?)',
          [entryCount ~/ 4], // Remove 25% of entries
        );
        debugPrint(
          '🧹 Removed entries to stay under ${_maxCacheSizeMB}MB limit',
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to enforce cache limits: $e');
    }
  }

  /// Get all cache entries (for debugging)
  Future<List<CacheEntry>> getAllEntries() async {
    if (_database == null) return [];

    try {
      final results = await _database!.query(
        _tableName,
        orderBy: 'created_at DESC',
      );

      return results.map((json) => CacheEntry.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Failed to get all cache entries: $e');
      return [];
    }
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      debugPrint('🔒 CacheService closed');
    }
  }
}




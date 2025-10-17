import 'dart:async';
import 'package:flutter/material.dart';
import '../services/offline_manager.dart';
import '../services/offline_queue_service.dart';

/// Offline status indicator widget
class OfflineStatusWidget extends StatefulWidget {
  final Widget child;
  final bool showStatusBar;
  final bool showQueueCount;

  const OfflineStatusWidget({
    super.key,
    required this.child,
    this.showStatusBar = true,
    this.showQueueCount = true,
  });

  @override
  State<OfflineStatusWidget> createState() => _OfflineStatusWidgetState();
}

class _OfflineStatusWidgetState extends State<OfflineStatusWidget> {
  final OfflineManager _offlineManager = OfflineManager();
  StreamSubscription<bool>? _connectivitySubscription;
  StreamSubscription<List<OfflineOperation>>? _queueSubscription;

  int _queueCount = 0;
  bool _showOfflineBanner = false;

  @override
  void initState() {
    super.initState();
    _initializeOfflineStatus();
  }

  void _initializeOfflineStatus() {
    _queueCount = _offlineManager.offlineQueueService.operationCount;

    // Listen to connectivity changes
    _connectivitySubscription = _offlineManager
        .connectivityService
        .connectivityStream
        .listen((isOnline) {
          setState(() {
            _showOfflineBanner = !isOnline;
          });
        });

    // Listen to queue changes
    _queueSubscription = _offlineManager.offlineQueueService.queueStream.listen(
      (operations) {
        setState(() {
          _queueCount = operations.length;
        });
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _queueSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showStatusBar) _buildOfflineBanner(),
        if (widget.showQueueCount && _queueCount > 0) _buildQueueIndicator(),
      ],
    );
  }

  Widget _buildOfflineBanner() {
    if (!_showOfflineBanner) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade600,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You\'re offline. Changes will sync when you\'re back online.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_queueCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_queueCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueueIndicator() {
    return Positioned(
      top: _showOfflineBanner ? 60 : 0,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade600,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sync, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              '$_queueCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Offline status banner (simpler version)
class OfflineBanner extends StatelessWidget {
  final bool isOnline;
  final int queueCount;
  final VoidCallback? onTap;

  const OfflineBanner({
    super.key,
    required this.isOnline,
    this.queueCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline && queueCount == 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isOnline ? Colors.blue.shade600 : Colors.orange.shade600,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(
              isOnline ? Icons.sync : Icons.wifi_off,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isOnline
                    ? 'Syncing $queueCount pending changes...'
                    : 'You\'re offline. Changes will sync when you\'re back online.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (queueCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$queueCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Offline status dialog
class OfflineStatusDialog extends StatelessWidget {
  const OfflineStatusDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final offlineManager = OfflineManager();

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            offlineManager.isOnline ? Icons.wifi : Icons.wifi_off,
            color: offlineManager.isOnline ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Text(offlineManager.isOnline ? 'Online' : 'Offline'),
        ],
      ),
      content: FutureBuilder<Map<String, dynamic>>(
        future: offlineManager.getOfflineStatus(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }

          final status = snapshot.data!;
          final cacheStats = status['cache_stats'] as Map<String, dynamic>?;
          final queueStats = status['queue_stats'] as Map<String, dynamic>?;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connection Status: ${status['is_online'] ? 'Online' : 'Offline'}',
              ),
              const SizedBox(height: 16),

              if (cacheStats != null) ...[
                Text(
                  'Cache Statistics:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text('• Total entries: ${cacheStats['total_entries']}'),
                Text(
                  '• Cache size: ${cacheStats['cache_size_mb']?.toStringAsFixed(2)} MB',
                ),
                Text('• Expired entries: ${cacheStats['expired_entries']}'),
                const SizedBox(height: 16),
              ],

              if (queueStats != null) ...[
                Text(
                  'Offline Queue:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text('• Total operations: ${queueStats['total_operations']}'),
                Text('• Failed operations: ${queueStats['failed_operations']}'),
                const SizedBox(height: 16),
              ],
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (!offlineManager.isOnline)
          TextButton(
            onPressed: () async {
              await offlineManager.processOfflineQueue();
              Navigator.of(context).pop();
            },
            child: const Text('Retry Sync'),
          ),
      ],
    );
  }
}

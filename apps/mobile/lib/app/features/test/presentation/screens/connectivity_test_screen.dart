import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/connectivity_test_service.dart';
import '../../../../core/services/debug_service.dart';
import '../../../../core/services/network_connectivity_service.dart';

/// Test screen to verify all our improvements
class ConnectivityTestScreen extends ConsumerStatefulWidget {
  /// Creates a new connectivity test screen
  const ConnectivityTestScreen({super.key});

  @override
  ConsumerState<ConnectivityTestScreen> createState() =>
      _ConnectivityTestScreenState();
}

class _ConnectivityTestScreenState
    extends ConsumerState<ConnectivityTestScreen> {
  final ConnectivityTestService _connectivityTest = ConnectivityTestService();
  final DebugService _debugService = DebugService();
  final NetworkConnectivityService _networkService =
      NetworkConnectivityService();

  Map<String, dynamic>? _testResults;
  bool _isLoading = false;
  String _status = 'Ready to test';

  @override
  void initState() {
    super.initState();
    _debugService.info(
      'Connectivity test screen initialized',
      category: 'test',
    );
  }

  Future<void> _runBasicTest() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing basic connectivity...';
    });

    try {
      _debugService.info('Starting basic connectivity test', category: 'test');
      final result = await _connectivityTest.testBasicConnectivity();

      setState(() {
        _testResults = {'basic': result};
        _status = 'Basic test completed';
        _isLoading = false;
      });

      _debugService.info(
        'Basic connectivity test completed',
        category: 'test',
        data: result,
      );
    } on Exception catch (e) {
      setState(() {
        _status = 'Basic test failed: $e';
        _isLoading = false;
      });

      _debugService.error(
        'Basic connectivity test failed',
        category: 'test',
        data: {'error': e.toString()},
      );
    }
  }

  Future<void> _runApiTest() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing API connectivity...';
    });

    try {
      _debugService.info('Starting API connectivity test', category: 'test');
      final result = await _connectivityTest.testApiConnectivity();

      setState(() {
        _testResults = {...?_testResults, 'api': result};
        _status = 'API test completed';
        _isLoading = false;
      });

      _debugService.info(
        'API connectivity test completed',
        category: 'test',
        data: result,
      );
    } on Exception catch (e) {
      setState(() {
        _status = 'API test failed: $e';
        _isLoading = false;
      });

      _debugService.error(
        'API connectivity test failed',
        category: 'test',
        data: {'error': e.toString()},
      );
    }
  }

  Future<void> _runComprehensiveTest() async {
    setState(() {
      _isLoading = true;
      _status = 'Running comprehensive tests...';
    });

    try {
      _debugService.info(
        'Starting comprehensive connectivity tests',
        category: 'test',
      );
      final result = await _connectivityTest.runComprehensiveTests();

      setState(() {
        _testResults = result;
        _status = 'Comprehensive tests completed';
        _isLoading = false;
      });

      _debugService.info(
        'Comprehensive connectivity tests completed',
        category: 'test',
        data: result,
      );
    } on Exception catch (e) {
      setState(() {
        _status = 'Comprehensive tests failed: $e';
        _isLoading = false;
      });

      _debugService.error(
        'Comprehensive connectivity tests failed',
        category: 'test',
        data: {'error': e.toString()},
      );
    }
  }

  Future<void> _getSystemDiagnostics() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting system diagnostics...';
    });

    try {
      _debugService.info('Getting system diagnostics', category: 'test');
      final diagnostics = await _debugService.getSystemDiagnostics();

      setState(() {
        _testResults = {'diagnostics': diagnostics};
        _status = 'System diagnostics completed';
        _isLoading = false;
      });

      _debugService.info(
        'System diagnostics completed',
        category: 'test',
        data: diagnostics,
      );
    } on Exception catch (e) {
      setState(() {
        _status = 'System diagnostics failed: $e';
        _isLoading = false;
      });

      _debugService.error(
        'System diagnostics failed',
        category: 'test',
        data: {'error': e.toString()},
      );
    }
  }

  void _clearLogs() {
    _debugService
      ..clearLogs()
      ..info('Logs cleared', category: 'test');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Debug logs cleared')));
  }

  void _exportLogs() {
    final logsJson = _debugService.exportLogs();
    _debugService.info(
      'Logs exported',
      category: 'test',
      data: {'logCount': logsJson.length},
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported ${logsJson.length} characters of logs')),
    );
  }

  @override
  // ignore: prefer_expression_function_bodies
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connectivity Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $_status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Network Status: ${_networkService.isConnected ? 'Online' : 'Offline'}',
                      style: TextStyle(
                        color: _networkService.isConnected
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _runBasicTest,
                  child: const Text('Basic Test'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _runApiTest,
                  child: const Text('API Test'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _runComprehensiveTest,
                  child: const Text('Comprehensive Test'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _getSystemDiagnostics,
                  child: const Text('System Diagnostics'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Debug Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Actions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _clearLogs,
                          child: const Text('Clear Logs'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _exportLogs,
                          child: const Text('Export Logs'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Results
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Results',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _testResults != null
                            ? SingleChildScrollView(
                                child: Text(
                                  _formatResults(_testResults!),
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              )
                            : const Text('No test results yet'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatResults(Map<String, dynamic> results) {
    final buffer = StringBuffer();

    void formatMap(Map<String, dynamic> map, int indent) {
      final indentStr = '  ' * indent;
      for (final entry in map.entries) {
        if (entry.value is Map<String, dynamic>) {
          buffer.writeln('$indentStr${entry.key}:');
          formatMap(entry.value as Map<String, dynamic>, indent + 1);
        } else {
          buffer.writeln('$indentStr${entry.key}: ${entry.value}');
        }
      }
    }

    formatMap(results, 0);
    return buffer.toString();
  }
}

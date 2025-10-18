import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/items_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/item_card.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../auth/login_screen.dart';
import '../report/report_screen.dart';
import '../profile/profile_screen.dart';
import '../matches/matches_screen.dart';
import '../chat/chat_page.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  String? _filter; // null = all, 'lost', or 'found'
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _appliedFilters;

  @override
  void initState() {
    super.initState();
    // Load items when screen loads
    Future.microtask(() {
      ref.read(itemsProvider.notifier).loadItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
      // Reset filter when changing tabs
      _filter = null;
    });

    // Load items when switching to home tab
    if (index == 0) {
      ref.read(itemsProvider.notifier).searchItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Check if user is logged in
    if (!authState.isLoggedIn) {
      return const LoginScreen();
    }

    final List<Widget> pages = [
      _buildHomeTab(),
      const MatchesScreen(),
      const ReportScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: const CustomAppBar(),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onTabChanged,
      ),
    );
  }

  Widget _buildHomeTab() {
    final itemsState = ref.watch(itemsProvider);

    return Column(
      children: [
        // Search Bar and Filter
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Row(
            children: [
              // Search Bar
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Enter item name, category, Locat...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.blue[400],
                        size: 24,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (value) {
                      // Debounce search to avoid too many API calls
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (_searchController.text == value) {
                          ref
                              .read(itemsProvider.notifier)
                              .updateSearchQuery(value.isEmpty ? null : value);
                        }
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Filter Button
              GestureDetector(
                onTap: _showFilterSheet,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      const Icon(
                        Icons.tune,
                        color: Colors.white,
                        size: 24,
                      ),
                      if (_appliedFilters != null)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Items List
        Expanded(
          child: _buildItemsList(itemsState),
        ),
      ],
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: FilterBottomSheet(
            initialType: _filter,
            onApply: (filters) {
              setState(() {
                _appliedFilters = filters;
                _filter = filters['type'];
              });
              // Apply filters through the provider
              // Cast to Map<String, String?>
              final stringFilters = Map<String, String?>.from(
                filters.map((key, value) => MapEntry(key, value?.toString())),
              );
              ref.read(itemsProvider.notifier).applyFilters(stringFilters);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildItemsList(ItemsState itemsState) {
    if (itemsState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (itemsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${itemsState.error}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ref.read(itemsProvider.notifier).loadItems(type: _filter);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final items = _filter == 'lost'
        ? itemsState.lostItems
        : _filter == 'found'
            ? itemsState.foundItems
            : itemsState.items;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No items found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _filter == null
                  ? 'Be the first to report an item!'
                  : 'No $_filter items yet',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(itemsProvider.notifier).loadItems(type: _filter);
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ItemCard(
            item: items[index],
            onContactTap: () {
              _navigateToChat(items[index]);
            },
          );
        },
      ),
    );
  }

  Future<void> _navigateToChat(dynamic item) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final apiService = ApiService();
      final chatProvider = ref.read(chatProviderProvider.notifier);

      // Create or get existing conversation
      final conversation = await chatProvider.createConversation(
        item.id,
        item.userId,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (conversation != null) {
          // Navigate to chat screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatPage(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start conversation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to contact owner: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

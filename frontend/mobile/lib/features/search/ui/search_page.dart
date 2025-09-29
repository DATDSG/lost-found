import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/models/item.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../item_details/ui/item_details_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _mapController = MapController();
  late TabController _tabController;

  bool _isMapView = false;
  bool _isLoading = false;
  LatLng _currentLocation = const LatLng(6.9271, 79.8612); // Colombo default
  List<Item> _searchResults = [];

  // Filter states
  String _selectedCategory = '';
  String _selectedType = 'all'; // 'all', 'lost', 'found'
  double _radiusKm = 5.0;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _showFilters = false;

  final List<String> _categories = [
    'All Categories',
    'Electronics',
    'Personal Items',
    'Documents',
    'Clothing',
    'Jewelry',
    'Sports Equipment',
    'Bags & Luggage',
    'Keys',
    'Pets',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getCurrentLocation();
    _performSearch(); // Load initial results
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DT.c.surface,
      appBar: AppBar(
        title: Text('Search Items', style: DT.t.h2),
        backgroundColor: DT.c.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'List'),
            Tab(icon: Icon(Icons.map), text: 'Map'),
          ],
          onTap: (index) {
            setState(() {
              _isMapView = index == 1;
            });
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
              color: _showFilters ? DT.c.brand : null,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_showFilters) _buildFilters(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildListView(), _buildMapView()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(DT.s.lg),
      child: Row(
        children: [
          Expanded(
            child: CustomTextField(
              controller: _searchController,
              label: 'Search items',
              hint: 'Enter keywords, brand, color...',
              prefixIcon: Icons.search,
              onChanged: (value) {
                // Debounce search
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _performSearch();
                  }
                });
              },
            ),
          ),
          SizedBox(width: DT.s.md),
          CustomButton(
            text: 'Search',
            onPressed: _performSearch,
            isLoading: _isLoading,
            width: 100,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(DT.s.lg),
      decoration: BoxDecoration(
        color: DT.c.blueTint.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: DT.c.blueTint.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters', style: DT.t.h3),
          SizedBox(height: DT.s.md),

          // Type filter
          Row(
            children: [
              Text(
                'Type: ',
                style: DT.t.body.copyWith(fontWeight: FontWeight.w600),
              ),
              _buildTypeChip('All', 'all'),
              SizedBox(width: DT.s.sm),
              _buildTypeChip('Lost', 'lost'),
              SizedBox(width: DT.s.sm),
              _buildTypeChip('Found', 'found'),
            ],
          ),
          SizedBox(height: DT.s.md),

          // Category filter (only show in list view for better UX)
          if (!_isMapView)
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory.isEmpty
                  ? 'All Categories'
                  : _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: DT.s.md,
                  vertical: DT.s.sm,
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value == 'All Categories'
                      ? ''
                      : value ?? '';
                });
                _performSearch();
              },
            ),
          if (!_isMapView) SizedBox(height: DT.s.md),

          // Radius filter
          Row(
            children: [
              Text(
                'Radius: ',
                style: DT.t.body.copyWith(fontWeight: FontWeight.w600),
              ),
              Expanded(
                child: Slider(
                  value: _radiusKm,
                  min: 1.0,
                  max: 50.0,
                  divisions: 49,
                  label: '${_radiusKm.round()} km',
                  onChanged: (value) {
                    setState(() {
                      _radiusKm = value;
                    });
                  },
                  onChangeEnd: (value) {
                    _performSearch();
                  },
                ),
              ),
              Text('${_radiusKm.round()} km', style: DT.t.caption),
            ],
          ),

          // Date range
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    _dateFrom != null && _dateTo != null
                        ? '${_dateFrom!.day}/${_dateFrom!.month} - ${_dateTo!.day}/${_dateTo!.month}'
                        : 'Date Range',
                  ),
                ),
              ),
              if (_dateFrom != null) ...[
                SizedBox(width: DT.s.sm),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _dateFrom = null;
                      _dateTo = null;
                    });
                    _performSearch();
                  },
                  icon: const Icon(Icons.clear),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, String value) {
    final isSelected = _selectedType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = value;
        });
        _performSearch();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: DT.s.md, vertical: DT.s.sm),
        decoration: BoxDecoration(
          color: isSelected ? DT.c.brand : Colors.transparent,
          border: Border.all(color: DT.c.brand),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: DT.t.caption.copyWith(
            color: isSelected ? Colors.white : DT.c.brand,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: DT.c.textMuted),
            SizedBox(height: DT.s.lg),
            Text(
              'No items found',
              style: DT.t.h3.copyWith(color: DT.c.textMuted),
            ),
            SizedBox(height: DT.s.md),
            Text(
              'Try adjusting your search filters',
              style: DT.t.body.copyWith(color: DT.c.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(DT.s.lg),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildItemCard(Item item) {
    return Card(
      margin: EdgeInsets.only(bottom: DT.s.lg),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailsPage(item: item),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(DT.s.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: DT.c.blueTint.withValues(alpha: 0.3),
                  child: item.images.isNotEmpty
                      ? Image.network(
                          item.images.first.url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.image, color: DT.c.textMuted);
                          },
                        )
                      : Icon(Icons.image, color: DT.c.textMuted),
                ),
              ),
              SizedBox(width: DT.s.lg),

              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: DT.s.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: item.type == ItemType.lost
                                ? DT.c.danger.withValues(alpha: 0.1)
                                : DT.c.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.type == ItemType.lost ? 'LOST' : 'FOUND',
                            style: DT.t.caption.copyWith(
                              color: item.type == ItemType.lost
                                  ? DT.c.danger
                                  : DT.c.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(item.dateLostFound),
                          style: DT.t.caption.copyWith(color: DT.c.textMuted),
                        ),
                      ],
                    ),
                    SizedBox(height: DT.s.sm),
                    Text(
                      item.title,
                      style: DT.t.title.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: DT.s.sm),
                    Text(
                      item.description,
                      style: DT.t.body.copyWith(color: DT.c.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: DT.s.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: DT.c.textMuted,
                        ),
                        SizedBox(width: DT.s.xs),
                        Expanded(
                          child: Text(
                            item.location.address ?? 'Location not specified',
                            style: DT.t.caption.copyWith(color: DT.c.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.rewardOffered != null &&
                            item.rewardOffered! > 0) ...[
                          SizedBox(width: DT.s.sm),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: DT.s.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DT.c.brand.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'LKR ${item.rewardOffered!.toStringAsFixed(0)}',
                              style: DT.t.caption.copyWith(
                                color: DT.c.brand,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLocation,
        initialZoom: 13.0,
        onTap: (tapPosition, point) {
          // Handle map tap if needed
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.lostfound',
        ),
        MarkerLayer(
          markers: [
            // Current location marker
            Marker(
              point: _currentLocation,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: DT.c.brand,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            // Item markers
            ..._searchResults.map((item) {
              return Marker(
                point: LatLng(item.location.latitude, item.location.longitude),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    _showItemBottomSheet(item);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: item.type == ItemType.lost
                          ? DT.c.danger
                          : DT.c.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      item.type == ItemType.lost
                          ? Icons.search
                          : Icons.location_on,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  void _showItemBottomSheet(Item item) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(DT.s.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DT.s.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: item.type == ItemType.lost
                          ? DT.c.danger.withValues(alpha: 0.1)
                          : DT.c.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.type == ItemType.lost ? 'LOST' : 'FOUND',
                      style: DT.t.caption.copyWith(
                        color: item.type == ItemType.lost
                            ? DT.c.danger
                            : DT.c.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(item.dateLostFound),
                    style: DT.t.caption.copyWith(color: DT.c.textMuted),
                  ),
                ],
              ),
              SizedBox(height: DT.s.md),
              Text(
                item.title,
                style: DT.t.title.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: DT.s.sm),
              Text(
                item.description,
                style: DT.t.body.copyWith(color: DT.c.textMuted),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: DT.s.lg),
              CustomButton(
                text: 'View Details',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailsPage(item: item),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Use default location (Colombo) if location access fails
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _dateFrom = picked.start;
        _dateTo = picked.end;
      });
      _performSearch();
    }
  }

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 800));

      // Generate mock search results
      final mockResults = _generateMockResults();

      setState(() {
        _searchResults = mockResults;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error searching items: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Item> _generateMockResults() {
    // Generate mock items for demonstration
    return [
      Item(
        id: '1',
        type: ItemType.lost,
        status: ItemStatus.active,
        title: 'iPhone 13 Pro',
        description:
            'Lost my black iPhone 13 Pro near the university. Has a blue case.',
        category: 'Electronics',
        subcategory: 'Phone',
        brand: 'Apple',
        color: 'Black',
        model: 'iPhone 13 Pro',
        location: Location(
          latitude: _currentLocation.latitude + 0.01,
          longitude: _currentLocation.longitude + 0.01,
          address: 'University of Colombo, Colombo 03',
        ),
        dateLostFound: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        userId: 'user1',
        userName: 'John Doe',
        images: [
          ItemImage(
            id: '1',
            url: 'https://via.placeholder.com/300x300?text=iPhone',
            isPrimary: true,
          ),
        ],
        rewardOffered: 5000,
      ),
      Item(
        id: '2',
        type: ItemType.found,
        status: ItemStatus.active,
        title: 'Blue Wallet',
        description: 'Found a blue leather wallet with some cards inside.',
        category: 'Personal Items',
        subcategory: 'Wallet',
        color: 'Blue',
        location: Location(
          latitude: _currentLocation.latitude - 0.005,
          longitude: _currentLocation.longitude + 0.008,
          address: 'Galle Face Green, Colombo 03',
        ),
        dateLostFound: DateTime.now().subtract(const Duration(hours: 6)),
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
        userId: 'user2',
        userName: 'Jane Smith',
        images: [
          ItemImage(
            id: '2',
            url: 'https://via.placeholder.com/300x300?text=Wallet',
            isPrimary: true,
          ),
        ],
      ),
    ];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}

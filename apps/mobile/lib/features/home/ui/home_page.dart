import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/routing/app_routes.dart';
import '../../../providers/reports_provider.dart';
import '../../../providers/search_provider.dart';
import '../../../models/report.dart';
import '../../../models/search_models.dart';
import '../../../widgets/modern_filter_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  String _currentSortBy = 'date_newest'; // Default sort
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    final reportsProvider = Provider.of<ReportsProvider>(
      context,
      listen: false,
    );
    await reportsProvider.loadReports();
  }

  void _onSearchChanged(String value) {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);

    // Update search query in provider
    searchProvider.updateSearchQuery(value);

    // Toggle search mode based on whether there's a search query
    setState(() {
      _isSearchMode = value.trim().isNotEmpty;
    });

    // Get suggestions for quick search
    searchProvider.quickSearch(value);

    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == value) {
        if (value.trim().isNotEmpty) {
          searchProvider.search();
          // Save search query for future suggestions
          searchProvider.saveSearchQuery(value);
        } else {
          searchProvider.clearResults();
        }
      }
    });
  }

  void _onFiltersChanged(SearchFilters filters) {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    searchProvider.updateFilters(filters);
    searchProvider.search();
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      _currentSortBy = sortBy;
    });

    if (_isSearchMode) {
      final searchProvider = Provider.of<SearchProvider>(
        context,
        listen: false,
      );
      // Update the sort filter but don't trigger a new search
      // The sorting will be handled by _getSortedReports
      searchProvider.toggleFilter('sortBy', sortBy);
    }
  }

  List<Report> _getSortedReports(List<Report> reports) {
    switch (_currentSortBy) {
      case 'date_newest':
        return reports..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case 'date_oldest':
        return reports..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case 'title':
        return reports..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case 'type':
        return reports..sort(
          (a, b) => a.type.toLowerCase().compareTo(b.type.toLowerCase()),
        );
      case 'category':
        return reports..sort(
          (a, b) =>
              a.category.toLowerCase().compareTo(b.category.toLowerCase()),
        );
      case 'city':
        return reports..sort(
          (a, b) => a.city.toLowerCase().compareTo(b.city.toLowerCase()),
        );
      default:
        return reports;
    }
  }

  void _showFilterSheet() {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModernFilterSheet(
        currentFilters: searchProvider.currentFilters,
        onFiltersChanged: _onFiltersChanged,
        typeOptions: searchProvider.getTypeOptions(),
        categoryOptions: searchProvider.getCategoryOptions(),
        colorOptions: searchProvider.getColorOptions(),
        sortOptions: searchProvider.getSortOptions(),
      ),
    );
  }

  Widget _buildHomeSearchBar(SearchProvider searchProvider) {
    return Container(
      height: 52, // Increased height for better visibility
      decoration: BoxDecoration(
        color: DT.c.card, // Use card color for better contrast
        borderRadius: BorderRadius.circular(DT.r.md), // Increased radius
        border: Border.all(
          color: DT.c.border.withValues(alpha: 0.8),
          width: 1.5, // Slightly thicker border
        ),
        boxShadow: [
          // Enhanced shadow for better visibility
          BoxShadow(
            color: DT.c.shadow.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: DT.c.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Search icon
          Padding(
            padding: EdgeInsets.only(left: DT.s.lg), // Increased padding
            child: Icon(
              Icons.search_rounded,
              size: 22, // Increased icon size
              color: DT.c.textSecondary.withValues(
                alpha: 0.8,
              ), // Better contrast
            ),
          ),
          SizedBox(width: DT.s.md), // Increased spacing
          // Search input
          Expanded(
            child: TextField(
              controller: _searchController,
              style: DT.t.body.copyWith(
                color: DT.c.textPrimary,
                fontWeight: FontWeight.w600, // Increased font weight
                fontSize: 15, // Slightly larger font
              ),
              cursorColor: DT.c.brand,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Enter item name, category, Location...',
                hintStyle: DT.t.bodyMuted.copyWith(
                  fontSize: 15, // Match input font size
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Filter button
          _buildFilterButton(),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    final hasActiveFilters = _hasActiveFilters();

    return Padding(
      padding: EdgeInsets.only(right: DT.s.md), // Increased padding
      child: GestureDetector(
        onTap: _showFilterSheet,
        child: Container(
          height: 36, // Increased height
          width: 36, // Increased width
          decoration: BoxDecoration(
            color: hasActiveFilters
                ? DT.c.brand.withValues(alpha: 0.1)
                : DT.c.card,
            borderRadius: BorderRadius.circular(DT.r.sm), // Increased radius
            border: Border.all(
              color: hasActiveFilters ? DT.c.brand : DT.c.border,
              width: hasActiveFilters ? 2 : 1.5, // Thicker border when active
            ),
            boxShadow: [
              // Enhanced shadow for better visibility
              BoxShadow(
                color: DT.c.shadow.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 3),
                spreadRadius: 0,
              ),
              if (hasActiveFilters)
                BoxShadow(
                  color: DT.c.brand.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 14, // Increased width
                      height: 2.5, // Increased height
                      decoration: BoxDecoration(
                        color: hasActiveFilters
                            ? DT.c.brand
                            : DT.c.textSecondary,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                    const SizedBox(height: 2.5), // Increased spacing
                    Container(
                      width: 14, // Increased width
                      height: 2.5, // Increased height
                      decoration: BoxDecoration(
                        color: hasActiveFilters
                            ? DT.c.brand
                            : DT.c.textSecondary,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                    const SizedBox(height: 2.5), // Increased spacing
                    Container(
                      width: 14, // Increased width
                      height: 2.5, // Increased height
                      decoration: BoxDecoration(
                        color: hasActiveFilters
                            ? DT.c.brand
                            : DT.c.textSecondary,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasActiveFilters)
                Positioned(
                  top: 6, // Adjusted position
                  right: 6, // Adjusted position
                  child: Container(
                    height: 8, // Increased size
                    width: 8, // Increased size
                    decoration: BoxDecoration(
                      color: DT.c.brand,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: DT.c.brand.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return GestureDetector(
      onTap: _showSortOptions,
      child: Container(
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: DT.s.md),
        decoration: BoxDecoration(
          color: DT.c.surface,
          borderRadius: BorderRadius.circular(DT.r.sm),
          border: Border.all(color: DT.c.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_rounded, size: 16, color: DT.c.textSecondary),
            SizedBox(width: DT.s.xs),
            Text(
              _getSortLabel(_currentSortBy),
              style: DT.t.label.copyWith(
                color: DT.c.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'date_newest':
        return 'Newest';
      case 'date_oldest':
        return 'Oldest';
      case 'title':
        return 'Title';
      case 'type':
        return 'Type';
      case 'category':
        return 'Category';
      case 'city':
        return 'City';
      default:
        return 'Sort';
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: DT.c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(DT.s.lg),
              child: Text('Sort By', style: DT.t.title.copyWith(fontSize: 18)),
            ),
            ..._getSortOptions().map((option) {
              return ListTile(
                title: Text(option['label']),
                leading: Icon(option['icon']),
                trailing: _currentSortBy == option['value']
                    ? Icon(Icons.check, color: DT.c.brand)
                    : null,
                onTap: () {
                  _onSortChanged(option['value']);
                  Navigator.pop(context);
                },
              );
            }),
            SizedBox(height: DT.s.lg),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getSortOptions() {
    return [
      {
        'value': 'date_newest',
        'label': 'Newest First',
        'icon': Icons.schedule_rounded,
      },
      {
        'value': 'date_oldest',
        'label': 'Oldest First',
        'icon': Icons.history_rounded,
      },
      {
        'value': 'title',
        'label': 'Title A-Z',
        'icon': Icons.sort_by_alpha_rounded,
      },
      {'value': 'type', 'label': 'Type', 'icon': Icons.category_rounded},
      {'value': 'category', 'label': 'Category', 'icon': Icons.label_rounded},
      {'value': 'city', 'label': 'City', 'icon': Icons.location_on_rounded},
    ];
  }

  bool _hasActiveFilters() {
    final searchProvider = Provider.of<SearchProvider>(context, listen: false);
    return searchProvider.currentFilters.hasActiveFilters;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer2<ReportsProvider, SearchProvider>(
        builder: (context, reportsProvider, searchProvider, _) {
          return Column(
            children: [
              // Always visible search bar
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: DT.s.lg,
                  vertical: DT.s.lg, // Increased vertical padding
                ),
                child: _buildHomeSearchBar(searchProvider),
              ),

              // Sort controls
              Padding(
                padding: EdgeInsets.symmetric(horizontal: DT.s.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isSearchMode
                            ? 'Search Results (${searchProvider.searchResults.length})'
                            : 'All Reports (${reportsProvider.reports.length})',
                        style: DT.t.title.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: DT.c.textPrimary,
                        ),
                      ),
                    ),
                    _buildSortButton(),
                  ],
                ),
              ),
              SizedBox(height: DT.s.md),

              // Content
              Expanded(
                child: _isSearchMode
                    ? _buildSearchContent(searchProvider)
                    : _buildReportsContent(reportsProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchContent(SearchProvider searchProvider) {
    if (searchProvider.isLoading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(DT.s.xxl),
          child: CircularProgressIndicator(color: DT.c.brand),
        ),
      );
    }

    if (searchProvider.hasError) {
      return Container(
        margin: EdgeInsets.all(DT.s.lg),
        padding: EdgeInsets.all(DT.s.lg),
        decoration: BoxDecoration(
          color: DT.c.dangerBg,
          borderRadius: BorderRadius.circular(DT.r.md),
          border: Border.all(color: DT.c.dangerFg.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: DT.c.dangerFg),
            SizedBox(height: DT.s.sm),
            Text(
              searchProvider.error!,
              style: DT.t.body.copyWith(color: DT.c.dangerFg),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DT.s.md),
            ElevatedButton(
              onPressed: () => searchProvider.search(),
              style: ElevatedButton.styleFrom(
                backgroundColor: DT.c.brand,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (searchProvider.isEmpty) {
      return Container(
        margin: EdgeInsets.all(DT.s.lg),
        padding: EdgeInsets.all(DT.s.xl),
        decoration: BoxDecoration(
          color: DT.c.surface,
          borderRadius: BorderRadius.circular(DT.r.lg),
          boxShadow: DT.e.card,
        ),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 64, color: DT.c.textTertiary),
            SizedBox(height: DT.s.md),
            Text(
              'No results found',
              style: DT.t.title.copyWith(color: DT.c.textSecondary),
            ),
            SizedBox(height: DT.s.sm),
            Text(
              'Try adjusting your search terms or filters',
              style: DT.t.body.copyWith(color: DT.c.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Convert search results to reports and sort them
    final reports = _getSortedReports(searchProvider.searchResults);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(DT.s.lg, 0, DT.s.lg, DT.s.xxl + 80),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];
        return Column(
          children: [
            _ItemCard(
              report: report,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.viewDetails,
                arguments: {
                  'reportId': report.id,
                  'reportType': report.isLost ? 'lost' : 'found',
                  'reportData': {
                    'title': report.title,
                    'description': report.description,
                    'category': report.category,
                    'brand': 'Unknown',
                    'color': report.colors?.isNotEmpty == true
                        ? report.colors!.first
                        : 'Unknown',
                    'condition': 'Unknown',
                    'value': 'Unknown',
                    'reporterName': 'Anonymous',
                    'phone': 'Not provided',
                    'email': 'Not provided',
                    'preferredContact': 'Any',
                    'address': report.locationAddress ?? 'Not specified',
                    'city': report.city,
                    'state': 'Unknown',
                    'landmark': 'None',
                    'status': 'Active',
                    'lastUpdated': DateFormat(
                      'MMM d, yyyy',
                    ).format(report.createdAt),
                    'views': 0,
                    'date': DateFormat('MMM d, yyyy').format(report.createdAt),
                    'images': report.media.map((m) => m.url).toList(),
                  },
                },
              ),
            ),
            if (index < reports.length - 1) SizedBox(height: DT.s.xl),
          ],
        );
      },
    );
  }

  Widget _buildReportsContent(ReportsProvider reportsProvider) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        DT.s.lg,
        0,
        DT.s.lg,
        DT.s.xxl + 80,
      ), // Use system spacing
      children: [
        // Loading state
        if (reportsProvider.isLoading)
          Center(
            child: Padding(
              padding: EdgeInsets.all(DT.s.xxl), // Use system spacing
              child: CircularProgressIndicator(
                color: DT.c.brand, // Use system brand color
              ),
            ),
          ),

        // Error state
        if (reportsProvider.error != null)
          Container(
            margin: EdgeInsets.all(DT.s.lg), // Use system spacing
            padding: EdgeInsets.all(DT.s.lg), // Use system spacing
            decoration: BoxDecoration(
              color: DT.c.dangerBg, // Use system danger background
              borderRadius: BorderRadius.circular(DT.r.md), // Use system radius
              border: Border.all(
                color: DT.c.dangerFg.withValues(alpha: 0.3),
              ), // Use system danger color
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: DT.c.dangerFg,
                ), // Use system danger color
                SizedBox(height: DT.s.sm), // Use system spacing
                Text(
                  reportsProvider.error!,
                  style: DT.t.body.copyWith(
                    color: DT.c.dangerFg,
                  ), // Use system text style and color
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: DT.s.md), // Use system spacing
                ElevatedButton(
                  onPressed: _loadReports,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DT.c.brand, // Use system brand color
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),

        // Empty state
        if (!reportsProvider.isLoading &&
            reportsProvider.error == null &&
            reportsProvider.reports.isEmpty)
          Container(
            margin: EdgeInsets.all(DT.s.lg), // Use system spacing
            padding: EdgeInsets.all(DT.s.xl), // Use system spacing
            decoration: BoxDecoration(
              color: DT.c.surface, // Use system surface color
              borderRadius: BorderRadius.circular(DT.r.lg), // Use system radius
              boxShadow: DT.e.card, // Use system elevation
            ),
            child: Column(
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: DT.c.textTertiary,
                ), // Use system text color
                SizedBox(height: DT.s.md), // Use system spacing
                Text(
                  'No reports found',
                  style: DT.t.title.copyWith(
                    color: DT.c.textSecondary,
                  ), // Use system text style and color
                ),
                SizedBox(height: DT.s.sm), // Use system spacing
                Text(
                  'Be the first to report a lost or found item!',
                  style: DT.t.body.copyWith(
                    color: DT.c.textSecondary,
                  ), // Use system text style and color
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: DT.s.lg), // Use system spacing
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.reportLost),
                  icon: const Icon(Icons.add),
                  label: const Text('Report Lost Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DT.c.brand, // Use system brand color
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

        // Reports list (sorted)
        ..._getSortedReports(reportsProvider.reports).asMap().entries.map((
          entry,
        ) {
          final index = entry.key;
          final report = entry.value;
          return Column(
            children: [
              _ItemCard(
                report: report,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.viewDetails,
                  arguments: {
                    'reportId': report.id,
                    'reportType': report.isLost ? 'lost' : 'found',
                    'reportData': {
                      'title': report.title,
                      'description': report.description,
                      'category': report.category,
                      'brand': 'Unknown',
                      'color': report.colors?.isNotEmpty == true
                          ? report.colors!.first
                          : 'Unknown',
                      'condition': 'Unknown',
                      'value': 'Unknown',
                      'reporterName': 'Anonymous',
                      'phone': 'Not provided',
                      'email': 'Not provided',
                      'preferredContact': 'Any',
                      'address': report.locationAddress ?? 'Not specified',
                      'city': report.city,
                      'state': 'Unknown',
                      'landmark': 'None',
                      'status': 'Active',
                      'lastUpdated': DateFormat(
                        'MMM d, yyyy',
                      ).format(report.createdAt),
                      'views': 0,
                      'date': DateFormat(
                        'MMM d, yyyy',
                      ).format(report.createdAt),
                      'images': report.media.map((m) => m.url).toList(),
                    },
                  },
                ),
              ),
              if (index < reportsProvider.reports.length - 1)
                SizedBox(height: DT.s.xl), // Increased spacing between cards
            ],
          );
        }),
      ],
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const _ItemCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = report.isLost
        ? DT.c.accentRed
        : DT.c.accentGreen; // Use system accent colors
    final statusBg = report.isLost
        ? DT.c.dangerBg
        : DT.c.successBg; // Use system state colors
    final statusText = report.isLost ? 'Lost' : 'Found';

    return Container(
      decoration: BoxDecoration(
        color: DT.c.card, // Use system card color
        borderRadius: BorderRadius.circular(
          DT.r.lg,
        ), // Increased radius for better visibility
        boxShadow: [
          // Enhanced shadow for better card visibility
          BoxShadow(
            color: DT.c.shadow.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: DT.c.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: DT.c.border.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      padding: EdgeInsets.all(DT.s.lg), // Increased padding for better spacing
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Square image
          ClipRRect(
            borderRadius: BorderRadius.circular(DT.r.sm), // Increased radius
            child: Container(
              height: 88, // Increased height
              width: 88, // Increased width
              decoration: BoxDecoration(
                color: DT.c.surface,
                border: Border.all(
                  color: DT.c.border.withValues(alpha: 0.4),
                  width: 0.5,
                ),
              ),
              child: report.media.isNotEmpty
                  ? Image.network(
                      report.media.first.url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: DT.c.surface,
                          child: Icon(
                            report.isLost ? Icons.search_off : Icons.search,
                            size: 36, // Increased icon size
                            color: DT.c.textTertiary,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: DT.c.surface,
                      child: Icon(
                        report.isLost ? Icons.search_off : Icons.search,
                        size: 36, // Increased icon size
                        color: DT.c.textTertiary,
                      ),
                    ),
            ),
          ),
          SizedBox(width: DT.s.lg), // Increased spacing
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and status tag
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        report.title,
                        style: DT.t.title.copyWith(
                          fontSize: 17, // Increased font size
                          fontWeight: FontWeight.w700, // Increased font weight
                          color: DT.c.textPrimary,
                          height: 1.2, // Better line height
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: DT.s.md), // Increased spacing
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DT.s.md, // Increased padding
                        vertical: DT.s.sm, // Increased padding
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(
                          DT.r.sm,
                        ), // Increased radius
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        statusText,
                        style: DT.t.label.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700, // Increased font weight
                          fontSize: 13, // Increased font size
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DT.s.md), // Increased spacing
                // Location, distance, and time
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16, // Increased icon size
                      color: DT.c.textSecondary,
                    ),
                    SizedBox(width: DT.s.sm), // Increased spacing
                    Text(
                      report.city,
                      style: DT.t.bodySmall.copyWith(
                        color: DT.c.textSecondary,
                        fontWeight: FontWeight.w600, // Increased font weight
                        fontSize: 13, // Increased font size
                      ),
                    ),
                    Text(
                      ' | 0.5 mi | ',
                      style: DT.t.bodySmall.copyWith(
                        color: DT.c.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13, // Increased font size
                      ),
                    ),
                    Text(
                      _formatTimeAgo(report.createdAt),
                      style: DT.t.bodySmall.copyWith(
                        color: DT.c.textSecondary,
                        fontWeight: FontWeight.w600, // Increased font weight
                        fontSize: 13, // Increased font size
                      ),
                    ),
                  ],
                ),
                SizedBox(height: DT.s.lg), // Increased spacing
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton('Contact', () {
                      _showContactDetails(context, report);
                    }, isPrimary: false),
                    SizedBox(width: DT.s.md), // Increased spacing
                    _buildActionButton('View Details', onTap, isPrimary: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    VoidCallback onPressed, {
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: DT.s.lg, // Increased padding
          vertical: DT.s.md, // Increased padding
        ),
        decoration: BoxDecoration(
          color: isPrimary ? DT.c.brand : DT.c.card,
          borderRadius: BorderRadius.circular(DT.r.sm), // Increased radius
          border: Border.all(
            color: isPrimary ? DT.c.brand : DT.c.border,
            width: isPrimary ? 0 : 1.5, // Thicker border for secondary
          ),
          boxShadow: [
            // Enhanced shadow for better visibility
            BoxShadow(
              color: DT.c.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
            if (isPrimary)
              BoxShadow(
                color: DT.c.brand.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
          ],
        ),
        child: Text(
          text,
          style: DT.t.label.copyWith(
            color: isPrimary ? Colors.white : DT.c.textSecondary,
            fontWeight: FontWeight.w700, // Increased font weight
            fontSize: 13, // Increased font size
          ),
        ),
      ),
    );
  }

  void _showContactDetails(BuildContext context, Report report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(DT.r.lg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(DT.s.lg),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: DT.c.border.withValues(alpha: 0.3)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.contact_phone_rounded,
                    color: DT.c.brand,
                    size: 24,
                  ),
                  SizedBox(width: DT.s.sm),
                  Text(
                    'Contact Information',
                    style: DT.t.title.copyWith(fontSize: 18),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: DT.c.textMuted),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(DT.s.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contact Details
                    _buildContactItem(
                      'Name',
                      'Anonymous', // Since Report model doesn't have user info
                      Icons.person_rounded,
                    ),
                    _buildContactItem(
                      'Phone',
                      'Not provided',
                      Icons.phone_rounded,
                      isActionable: false,
                    ),
                    _buildContactItem(
                      'Email',
                      'Not provided',
                      Icons.email_rounded,
                      isActionable: false,
                    ),
                    _buildContactItem(
                      'Preferred Contact',
                      'Any',
                      Icons.favorite_rounded,
                    ),
                  ],
                ),
              ),
            ),

            // Fixed Action Buttons
            Container(
              padding: EdgeInsets.all(DT.s.lg),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: DT.c.border.withValues(alpha: 0.3)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showContactMessage(context),
                      icon: const Icon(Icons.message_rounded),
                      label: const Text('Send Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DT.c.brand,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: DT.s.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DT.r.lg),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: DT.s.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showContactMessage(context),
                      icon: const Icon(Icons.chat_rounded),
                      label: const Text('Chat'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DT.c.brand,
                        side: BorderSide(color: DT.c.brand),
                        padding: EdgeInsets.symmetric(vertical: DT.s.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DT.r.lg),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(
    String label,
    String value,
    IconData icon, {
    bool isActionable = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: DT.s.md),
      padding: EdgeInsets.all(DT.s.md),
      decoration: BoxDecoration(
        color: DT.c.background,
        borderRadius: BorderRadius.circular(DT.r.md),
        border: Border.all(color: DT.c.border.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(DT.s.sm),
            decoration: BoxDecoration(
              color: DT.c.brand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DT.r.sm),
            ),
            child: Icon(icon, color: DT.c.brand, size: 20),
          ),
          SizedBox(width: DT.s.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: DT.t.caption.copyWith(
                    color: DT.c.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: DT.s.xs),
                Text(
                  value,
                  style: DT.t.body.copyWith(
                    fontWeight: isActionable
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: isActionable ? DT.c.brand : DT.c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (isActionable)
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: DT.c.textMuted,
              size: 16,
            ),
        ],
      ),
    );
  }

  void _showContactMessage(BuildContext context) {
    Navigator.pop(context); // Close the contact details sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Contact feature coming soon!'),
        backgroundColor: DT.c.brand,
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

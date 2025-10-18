import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/item.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';

final itemDetailsProvider =
    FutureProvider.family<Item?, String>((ref, itemId) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getItemDetails(itemId);
});

class ItemDetailsScreen extends ConsumerWidget {
  final String itemId;

  const ItemDetailsScreen({
    super.key,
    required this.itemId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemDetailsProvider(itemId));

    return Scaffold(
      body: itemAsync.when(
        data: (item) {
          if (item == null) {
            return const _ErrorView(
              error: 'Item not found',
              onRetry: null,
            );
          }
          return _ItemDetailsContent(item: item);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorView(
          error: error.toString(),
          onRetry: () {
            ref.invalidate(itemDetailsProvider(itemId));
          },
        ),
      ),
    );
  }
}

class _ItemDetailsContent extends ConsumerStatefulWidget {
  final Item item;

  const _ItemDetailsContent({required this.item});

  @override
  ConsumerState<_ItemDetailsContent> createState() =>
      _ItemDetailsContentState();
}

class _ItemDetailsContentState extends ConsumerState<_ItemDetailsContent> {
  int _currentImageIndex = 0;
  bool _isContactingUser = false;
  String _distance = 'Calculating...';
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(context),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageGallery(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildInfoSection(),
                    const SizedBox(height: 24),
                    _buildDescriptionSection(),
                    const SizedBox(height: 24),
                    _buildLocationSection(),
                    const SizedBox(height: 24),
                    _buildContactButton(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.share, color: Colors.black),
          ),
          onPressed: () {
            _shareItem();
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildImageGallery() {
    final images = widget.item.imageUrls.isEmpty
        ? ['https://via.placeholder.com/400']
        : widget.item.imageUrls;

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                images[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child:
                        const Icon(Icons.image, size: 80, color: Colors.grey),
                  );
                },
              );
            },
          ),
          if (images.length > 1)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentImageIndex + 1}/${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.category,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                widget.item.type == 'lost' ? Colors.red[50] : Colors.green[50],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.item.type == 'lost' ? 'LOST' : 'FOUND',
            style: TextStyle(
              color: widget.item.type == 'lost' ? Colors.red : Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    final displayDate = widget.item.dateLost ?? widget.item.dateReported;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.calendar_today,
            'Date',
            _formatDate(displayDate),
          ),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.access_time,
            'Time',
            _formatTime(displayDate),
          ),
          if (widget.item.location != null) ...[
            const Divider(height: 24),
            _buildInfoRow(
              Icons.location_on,
              'Distance',
              _distance,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.item.description.isEmpty
              ? 'No description provided'
              : widget.item.description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    if (widget.item.location == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      widget.item.location!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    if (_currentPosition != null &&
                        widget.item.latitude != null &&
                        widget.item.longitude != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Distance: $_distance',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: _openInMaps,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.navigation, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _isContactingUser ? null : _handleContact,
        icon: _isContactingUser
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.chat_bubble),
        label: Text(
          _isContactingUser ? 'Starting conversation...' : 'Contact Owner',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _getDistance() {
    if (widget.item.location == null) return 'N/A';

    // TODO: Get current location and calculate actual distance
    // For now, return placeholder
    return 'Calculating...';
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _distance = 'Location disabled';
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _distance = 'Permission denied';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _distance = 'Permission denied forever';
        });
        return;
      }

      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Calculate distance if we have item coordinates
      if (widget.item.latitude != null && widget.item.longitude != null) {
        final distanceInMeters = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          widget.item.latitude!,
          widget.item.longitude!,
        );

        setState(() {
          if (distanceInMeters < 1000) {
            _distance = '${distanceInMeters.round()}m';
          } else {
            _distance = '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
          }
        });
      } else {
        setState(() {
          _distance = 'Location unavailable';
        });
      }
    } catch (e) {
      setState(() {
        _distance = 'Error calculating';
      });
    }
  }

  Future<void> _shareItem() async {
    try {
      final shareText = '''
${widget.item.title}
${widget.item.type.toUpperCase()} Item

Category: ${widget.item.category}
Date: ${_formatDate(widget.item.dateLost ?? widget.item.dateReported)}
${widget.item.location != null ? 'Location: ${widget.item.location}' : ''}

${widget.item.description.isNotEmpty ? widget.item.description : 'No description provided'}

Found this item? Contact the owner through Lost & Found app!
''';

      await Clipboard.setData(ClipboardData(text: shareText));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item details copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openInMaps() async {
    if (widget.item.latitude == null || widget.item.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location coordinates not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Open in Google Maps
      final url =
          'https://www.google.com/maps/search/?api=1&query=${widget.item.latitude},${widget.item.longitude}';

      // In a real app, you would use url_launcher package
      await Clipboard.setData(ClipboardData(text: url));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Map URL copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleContact() async {
    setState(() {
      _isContactingUser = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      // TODO: Get recipient ID from item owner
      final recipientId = widget.item.userId;
      final conversation = await apiService.createConversation(
        widget.item.id,
        recipientId,
      );

      if (!mounted) return;

      // Navigate to chat screen
      Navigator.pushNamed(
        context,
        '/chat/detail',
        arguments: conversation,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start conversation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isContactingUser = false;
        });
      }
    }
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Failed to load item details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

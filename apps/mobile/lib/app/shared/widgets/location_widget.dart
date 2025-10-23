import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/design_tokens.dart';
import '../providers/api_providers.dart';

/// Widget for getting and displaying current location
class LocationWidget extends ConsumerStatefulWidget {
  /// Creates a new location widget
  const LocationWidget({
    super.key,
    this.onLocationChanged,
    this.showAddress = true,
    this.showCoordinates = true,
  });

  /// Callback when location changes
  final void Function(double latitude, double longitude, String? address)?
  onLocationChanged;

  /// Whether to show the address
  final bool showAddress;

  /// Whether to show coordinates
  final bool showCoordinates;

  @override
  ConsumerState<LocationWidget> createState() => _LocationWidgetState();
}

class _LocationWidgetState extends ConsumerState<LocationWidget> {
  bool _isLoading = false;
  String? _currentAddress;
  double? _currentLatitude;
  double? _currentLongitude;
  double? _currentAccuracy;
  String? _accuracyStatus;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locationService = ref.read(locationServiceProvider);

      // Try to get the most accurate position possible
      final position = await locationService.getMostAccuratePosition();

      if (position != null) {
        if (mounted) {
          setState(() {
            _currentLatitude = position.latitude;
            _currentLongitude = position.longitude;
            _currentAccuracy = position.accuracy;
            _accuracyStatus = locationService.getAccuracyStatusMessage(
              position,
            );
          });
        }

        // Get address if requested
        if (widget.showAddress) {
          final address = await locationService.getAddressFromCoordinates(
            latitude: position.latitude,
            longitude: position.longitude,
          );
          if (mounted) {
            setState(() {
              _currentAddress = address;
            });
          }
        }

        // Notify parent widget
        widget.onLocationChanged?.call(
          position.latitude,
          position.longitude,
          _currentAddress,
        );
      } else {
        // Fallback to regular location if high accuracy fails
        final coordinates = await locationService.getCoordinates();
        if (coordinates.latitude != null && coordinates.longitude != null) {
          if (mounted) {
            setState(() {
              _currentLatitude = coordinates.latitude;
              _currentLongitude = coordinates.longitude;
            });
          }

          // Get address if requested
          if (widget.showAddress) {
            final address = await locationService.getAddressFromCoordinates(
              latitude: coordinates.latitude!,
              longitude: coordinates.longitude!,
            );
            if (mounted) {
              setState(() {
                _currentAddress = address;
              });
            }
          }

          // Notify parent widget
          widget.onLocationChanged?.call(
            coordinates.latitude!,
            coordinates.longitude!,
            _currentAddress,
          );
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: ${e.toString()}'),
            backgroundColor: DT.c.accentRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: DT.c.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DT.r.md),
      side: BorderSide(color: DT.c.border),
    ),
    child: Padding(
      padding: EdgeInsets.all(DT.s.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: DT.c.brand, size: 20),
              SizedBox(width: DT.s.sm),
              Text(
                'Current Location',
                style: DT.t.titleMedium.copyWith(
                  color: DT.c.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(DT.c.brand),
                  ),
                )
              else
                IconButton(
                  onPressed: _getCurrentLocation,
                  icon: Icon(Icons.refresh, color: DT.c.brand, size: 20),
                  tooltip: 'Refresh location',
                ),
            ],
          ),
          SizedBox(height: DT.s.sm),
          if (_currentAddress != null && widget.showAddress) ...[
            Text(
              _currentAddress!,
              style: DT.t.bodyMedium.copyWith(color: DT.c.textSecondary),
            ),
            SizedBox(height: DT.s.xs),
          ],
          if (_currentLatitude != null &&
              _currentLongitude != null &&
              widget.showCoordinates) ...[
            Text(
              'Lat: ${_currentLatitude!.toStringAsFixed(6)}, '
              'Lng: ${_currentLongitude!.toStringAsFixed(6)}',
              style: DT.t.bodySmall.copyWith(
                color: DT.c.textMuted,
                fontFamily: 'monospace',
              ),
            ),
            if (_accuracyStatus != null) ...[
              SizedBox(height: DT.s.xs),
              Row(
                children: [
                  Icon(
                    _currentAccuracy != null && _currentAccuracy! <= 30
                        ? Icons.check_circle
                        : _currentAccuracy != null && _currentAccuracy! <= 100
                        ? Icons.warning
                        : Icons.error,
                    color: _currentAccuracy != null && _currentAccuracy! <= 30
                        ? DT.c.accentGreen
                        : _currentAccuracy != null && _currentAccuracy! <= 100
                        ? DT.c.accentOrange
                        : DT.c.accentRed,
                    size: 16,
                  ),
                  SizedBox(width: DT.s.xs),
                  Expanded(
                    child: Text(
                      _accuracyStatus!,
                      style: DT.t.bodySmall.copyWith(
                        color:
                            _currentAccuracy != null && _currentAccuracy! <= 30
                            ? DT.c.accentGreen
                            : _currentAccuracy != null &&
                                  _currentAccuracy! <= 100
                            ? DT.c.accentOrange
                            : DT.c.accentRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
          if (_currentLatitude == null && !_isLoading)
            Text(
              'Location not available',
              style: DT.t.bodyMedium.copyWith(color: DT.c.textMuted),
            ),
        ],
      ),
    ),
  );
}

/// Simple location button widget
class LocationButton extends ConsumerWidget {
  /// Creates a new location button
  const LocationButton({
    super.key,
    this.onLocationObtained,
    this.icon = Icons.my_location,
    this.label = 'Get Current Location',
  });

  /// Callback when location is obtained
  final void Function(double latitude, double longitude)? onLocationObtained;

  /// Icon to display
  final IconData icon;

  /// Label for the button
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) => OutlinedButton.icon(
    onPressed: () => _getLocation(context, ref),
    icon: Icon(icon, size: 18),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: DT.c.brand,
      side: BorderSide(color: DT.c.brand),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DT.r.md),
      ),
      padding: EdgeInsets.symmetric(horizontal: DT.s.md, vertical: DT.s.sm),
    ),
  );

  Future<void> _getLocation(BuildContext context, WidgetRef ref) async {
    try {
      final locationService = ref.read(locationServiceProvider);

      // Try to get the most accurate position possible
      final position = await locationService.getMostAccuratePosition(
        maxAttempts: 2,
      );

      if (position != null) {
        onLocationObtained?.call(position.latitude, position.longitude);

        if (context.mounted) {
          final accuracyMessage = locationService.getAccuracyStatusMessage(
            position,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location obtained: $accuracyMessage'),
              backgroundColor: position.accuracy <= 30
                  ? DT.c.accentGreen
                  : position.accuracy <= 100
                  ? DT.c.accentOrange
                  : DT.c.accentRed,
            ),
          );
        }
      } else {
        // Fallback to regular location
        final coordinates = await locationService.getCoordinates();
        if (coordinates.latitude != null && coordinates.longitude != null) {
          onLocationObtained?.call(
            coordinates.latitude!,
            coordinates.longitude!,
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Location obtained (basic accuracy)'),
                backgroundColor: DT.c.accentOrange,
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to get location'),
                backgroundColor: DT.c.accentRed,
              ),
            );
          }
        }
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: DT.c.accentRed,
          ),
        );
      }
    }
  }
}

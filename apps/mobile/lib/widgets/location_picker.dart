import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../core/theme/design_tokens.dart';
import 'google_maps_location_picker.dart';

class LocationPicker extends StatefulWidget {
  final Function(String address, double latitude, double longitude)
  onLocationSelected;

  const LocationPicker({super.key, required this.onLocationSelected});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  bool _isLoading = false;
  String? _currentAddress;
  double? _currentLatitude;
  double? _currentLongitude;

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorDialog(
          'Location services are disabled. Please enable them in settings.',
        );
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorDialog('Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorDialog('Location permissions are permanently denied.');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      String address = await _getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentAddress = address;
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
      });

      widget.onLocationSelected(address, position.latitude, position.longitude);
    } catch (e) {
      _showErrorDialog('Failed to get location: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        List<String> addressParts = [];

        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        return addressParts.join(', ');
      }
    } catch (e) {
      debugPrint('Error getting address: $e');
    }

    return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showManualLocationDialog() {
    final TextEditingController addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Location'),
        content: TextField(
          controller: addressController,
          decoration: const InputDecoration(
            hintText: 'Enter address or location',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (addressController.text.trim().isNotEmpty) {
                setState(() {
                  _currentAddress = addressController.text.trim();
                  _currentLatitude = null; // Manual entry, no coordinates
                  _currentLongitude = null;
                });
                widget.onLocationSelected(
                  addressController.text.trim(),
                  0.0, // Placeholder coordinates
                  0.0,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _openGoogleMapsPicker() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GoogleMapsLocationPicker(
          onLocationSelected: (address, lat, lng) {
            setState(() {
              _currentAddress = address;
              _currentLatitude = lat;
              _currentLongitude = lng;
            });
            widget.onLocationSelected(address, lat, lng);
          },
          initialLatitude: _currentLatitude,
          initialLongitude: _currentLongitude,
          initialAddress: _currentAddress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location', style: DT.t.title),
        SizedBox(height: DT.s.md),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _getCurrentLocation,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.my_location),
                label: Text(_isLoading ? 'Getting...' : 'Use Current Location'),
              ),
            ),
            SizedBox(width: DT.s.md),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openGoogleMapsPicker,
                icon: const Icon(Icons.map),
                label: const Text('Pick on Map'),
              ),
            ),
          ],
        ),

        SizedBox(height: DT.s.md),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showManualLocationDialog,
                icon: const Icon(Icons.edit_location),
                label: const Text('Enter Manually'),
              ),
            ),
          ],
        ),

        if (_currentAddress != null) ...[
          SizedBox(height: DT.s.md),
          Container(
            padding: EdgeInsets.all(DT.s.md),
            decoration: BoxDecoration(
              color: DT.c.successBg,
              borderRadius: BorderRadius.circular(DT.r.md),
              border: Border.all(color: DT.c.successFg.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: DT.c.successFg),
                SizedBox(width: DT.s.sm),
                Expanded(
                  child: Text(
                    _currentAddress!,
                    style: DT.t.body.copyWith(color: DT.c.successFg),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _currentAddress = null;
                      _currentLatitude = null;
                      _currentLongitude = null;
                    });
                  },
                  icon: Icon(Icons.close, color: DT.c.successFg),
                ),
              ],
            ),
          ),
        ],

        SizedBox(height: DT.s.md),
        Text(
          'Location helps others find your item more easily',
          style: DT.t.caption.copyWith(color: DT.c.textMuted),
        ),
      ],
    );
  }
}

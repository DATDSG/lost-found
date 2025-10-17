/// Location models for the Lost & Found mobile app

/// Location data model
class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? placeId;
  final Map<String, dynamic>? metadata;
  final DateTime? timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.placeId,
    this.metadata,
    this.timestamp,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postal_code'],
      placeId: json['place_id'],
      metadata: json['metadata'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (postalCode != null) 'postal_code': postalCode,
      if (placeId != null) 'place_id': placeId,
      if (metadata != null) 'metadata': metadata,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
    };
  }

  LocationData copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? placeId,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      placeId: placeId ?? this.placeId,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Get formatted address string
  String get formattedAddress {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }

  /// Get short address (city, state)
  String get shortAddress {
    final parts = <String>[];
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    return parts.join(', ');
  }

  /// Check if location is valid
  bool get isValid {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }
}

/// Location search result model
class LocationSearchResult {
  final String id;
  final String name;
  final String? description;
  final LocationData location;
  final String? type;
  final double? rating;
  final Map<String, dynamic>? metadata;

  LocationSearchResult({
    required this.id,
    required this.name,
    this.description,
    required this.location,
    this.type,
    this.rating,
    this.metadata,
  });

  factory LocationSearchResult.fromJson(Map<String, dynamic> json) {
    return LocationSearchResult(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      location: LocationData.fromJson(json['location'] ?? {}),
      type: json['type'],
      rating: json['rating']?.toDouble(),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'location': location.toJson(),
      if (type != null) 'type': type,
      if (rating != null) 'rating': rating,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// Location autocomplete suggestion model
class LocationSuggestion {
  final String id;
  final String text;
  final String? description;
  final LocationData? location;
  final String? type;
  final Map<String, dynamic>? metadata;

  LocationSuggestion({
    required this.id,
    required this.text,
    this.description,
    this.location,
    this.type,
    this.metadata,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      description: json['description'],
      location: json['location'] != null
          ? LocationData.fromJson(json['location'])
          : null,
      type: json['type'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      if (description != null) 'description': description,
      if (location != null) 'location': location!.toJson(),
      if (type != null) 'type': type,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// Distance calculation result model
class DistanceResult {
  final double distance;
  final String unit;
  final Duration? duration;
  final String? routeType;

  DistanceResult({
    required this.distance,
    required this.unit,
    this.duration,
    this.routeType,
  });

  factory DistanceResult.fromJson(Map<String, dynamic> json) {
    return DistanceResult(
      distance: json['distance']?.toDouble() ?? 0.0,
      unit: json['unit'] ?? 'km',
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'])
          : null,
      routeType: json['route_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'unit': unit,
      if (duration != null) 'duration': duration!.inSeconds,
      if (routeType != null) 'route_type': routeType,
    };
  }

  /// Get formatted distance string
  String get formattedDistance {
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    } else {
      return '${distance.toStringAsFixed(1)} $unit';
    }
  }
}

/// Location bounds model
class LocationBounds {
  final double northEastLatitude;
  final double northEastLongitude;
  final double southWestLatitude;
  final double southWestLongitude;

  LocationBounds({
    required this.northEastLatitude,
    required this.northEastLongitude,
    required this.southWestLatitude,
    required this.southWestLongitude,
  });

  factory LocationBounds.fromJson(Map<String, dynamic> json) {
    return LocationBounds(
      northEastLatitude: json['northeast']['lat']?.toDouble() ?? 0.0,
      northEastLongitude: json['northeast']['lng']?.toDouble() ?? 0.0,
      southWestLatitude: json['southwest']['lat']?.toDouble() ?? 0.0,
      southWestLongitude: json['southwest']['lng']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'northeast': {'lat': northEastLatitude, 'lng': northEastLongitude},
      'southwest': {'lat': southWestLatitude, 'lng': southWestLongitude},
    };
  }

  /// Get center point of bounds
  LocationData get center {
    return LocationData(
      latitude: (northEastLatitude + southWestLatitude) / 2,
      longitude: (northEastLongitude + southWestLongitude) / 2,
    );
  }

  /// Check if location is within bounds
  bool contains(LocationData location) {
    return location.latitude >= southWestLatitude &&
        location.latitude <= northEastLatitude &&
        location.longitude >= southWestLongitude &&
        location.longitude <= northEastLongitude;
  }
}

/// Location history entry model
class LocationHistoryEntry {
  final String id;
  final LocationData location;
  final DateTime timestamp;
  final String? activity;
  final Map<String, dynamic>? metadata;

  LocationHistoryEntry({
    required this.id,
    required this.location,
    required this.timestamp,
    this.activity,
    this.metadata,
  });

  factory LocationHistoryEntry.fromJson(Map<String, dynamic> json) {
    return LocationHistoryEntry(
      id: json['id'] ?? '',
      location: LocationData.fromJson(json['location'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
      activity: json['activity'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location.toJson(),
      'timestamp': timestamp.toIso8601String(),
      if (activity != null) 'activity': activity,
      if (metadata != null) 'metadata': metadata,
    };
  }
}

/// Location statistics model
class LocationStats {
  final int totalLocations;
  final int uniqueCities;
  final int uniqueCountries;
  final DateTime? firstLocationDate;
  final DateTime? lastLocationDate;
  final Map<String, int> cityCounts;
  final Map<String, int> countryCounts;

  LocationStats({
    required this.totalLocations,
    required this.uniqueCities,
    required this.uniqueCountries,
    this.firstLocationDate,
    this.lastLocationDate,
    required this.cityCounts,
    required this.countryCounts,
  });

  factory LocationStats.fromJson(Map<String, dynamic> json) {
    return LocationStats(
      totalLocations: json['total_locations'] ?? 0,
      uniqueCities: json['unique_cities'] ?? 0,
      uniqueCountries: json['unique_countries'] ?? 0,
      firstLocationDate: json['first_location_date'] != null
          ? DateTime.parse(json['first_location_date'])
          : null,
      lastLocationDate: json['last_location_date'] != null
          ? DateTime.parse(json['last_location_date'])
          : null,
      cityCounts: Map<String, int>.from(json['city_counts'] ?? {}),
      countryCounts: Map<String, int>.from(json['country_counts'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_locations': totalLocations,
      'unique_cities': uniqueCities,
      'unique_countries': uniqueCountries,
      if (firstLocationDate != null)
        'first_location_date': firstLocationDate!.toIso8601String(),
      if (lastLocationDate != null)
        'last_location_date': lastLocationDate!.toIso8601String(),
      'city_counts': cityCounts,
      'country_counts': countryCounts,
    };
  }
}

/// Location permission status enum
enum LocationPermissionStatus {
  denied,
  deniedForever,
  whileInUse,
  always,
  unknown,
}

/// Location accuracy enum
enum LocationAccuracy { lowest, low, medium, high, highest }

/// Location service status enum
enum LocationServiceStatus { disabled, enabled, unknown }


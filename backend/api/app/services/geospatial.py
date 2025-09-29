"""
Geospatial utilities for the Lost & Found system.

Handles geohash generation, neighbor calculation, and distance calculations.
"""

import geohash2
import math
from typing import List, Tuple, Optional
from geopy.distance import geodesic


def encode_geohash(lat: float, lng: float, precision: int = 6) -> str:
    """
    Encode latitude/longitude to geohash.
    
    Args:
        lat: Latitude
        lng: Longitude  
        precision: Geohash precision (default 6 for ~1.2km)
        
    Returns:
        Geohash string
    """
    return geohash2.encode(lat, lng, precision)


def decode_geohash(geohash: str) -> Tuple[float, float]:
    """
    Decode geohash to latitude/longitude.
    
    Args:
        geohash: Geohash string
        
    Returns:
        Tuple of (latitude, longitude)
    """
    return geohash2.decode(geohash)


def get_geohash_neighbors(geohash: str) -> List[str]:
    """
    Get all neighboring geohash cells.
    
    Args:
        geohash: Center geohash
        
    Returns:
        List of neighboring geohash strings
    """
    neighbors = []
    
    # Get direct neighbors (8 surrounding cells)
    for direction in ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw']:
        neighbor = geohash2.neighbors(geohash, direction)
        if neighbor:
            neighbors.append(neighbor)
    
    return neighbors


def calculate_distance_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """
    Calculate geodesic distance between two points in kilometers.
    
    Args:
        lat1, lng1: First point coordinates
        lat2, lng2: Second point coordinates
        
    Returns:
        Distance in kilometers
    """
    return geodesic((lat1, lng1), (lat2, lng2)).kilometers


def calculate_haversine_distance(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """
    Calculate haversine distance between two points in kilometers.
    Faster than geodesic but less accurate for long distances.
    
    Args:
        lat1, lng1: First point coordinates
        lat2, lng2: Second point coordinates
        
    Returns:
        Distance in kilometers
    """
    # Convert latitude and longitude from degrees to radians
    lat1, lng1, lat2, lng2 = map(math.radians, [lat1, lng1, lat2, lng2])
    
    # Haversine formula
    dlat = lat2 - lat1
    dlng = lng2 - lng1
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlng/2)**2
    c = 2 * math.asin(math.sqrt(a))
    
    # Radius of earth in kilometers
    r = 6371
    
    return c * r


def fuzz_coordinates(lat: float, lng: float, fuzz_meters: int = 100) -> Tuple[float, float]:
    """
    Add random noise to coordinates for privacy protection.
    
    Args:
        lat, lng: Original coordinates
        fuzz_meters: Maximum fuzzing distance in meters
        
    Returns:
        Tuple of (fuzzed_lat, fuzzed_lng)
    """
    import random
    
    # Convert meters to degrees (approximate)
    # 1 degree latitude ≈ 111,000 meters
    # 1 degree longitude ≈ 111,000 * cos(latitude) meters
    lat_offset = (random.uniform(-fuzz_meters, fuzz_meters) / 111000)
    lng_offset = (random.uniform(-fuzz_meters, fuzz_meters) / (111000 * math.cos(math.radians(lat))))
    
    return lat + lat_offset, lng + lng_offset


def is_within_radius(
    center_lat: float, 
    center_lng: float, 
    point_lat: float, 
    point_lng: float, 
    radius_km: float
) -> bool:
    """
    Check if a point is within a given radius of a center point.
    
    Args:
        center_lat, center_lng: Center point coordinates
        point_lat, point_lng: Point to check
        radius_km: Radius in kilometers
        
    Returns:
        True if point is within radius
    """
    distance = calculate_distance_km(center_lat, center_lng, point_lat, point_lng)
    return distance <= radius_km


def get_bounding_box(lat: float, lng: float, radius_km: float) -> Tuple[float, float, float, float]:
    """
    Get bounding box coordinates for a circle.
    
    Args:
        lat, lng: Center coordinates
        radius_km: Radius in kilometers
        
    Returns:
        Tuple of (min_lat, min_lng, max_lat, max_lng)
    """
    # Approximate conversion: 1 degree ≈ 111 km
    lat_offset = radius_km / 111.0
    lng_offset = radius_km / (111.0 * math.cos(math.radians(lat)))
    
    return (
        lat - lat_offset,  # min_lat
        lng - lng_offset,  # min_lng
        lat + lat_offset,  # max_lat
        lng + lng_offset   # max_lng
    )


def validate_coordinates(lat: float, lng: float) -> bool:
    """
    Validate latitude and longitude values.
    
    Args:
        lat: Latitude
        lng: Longitude
        
    Returns:
        True if coordinates are valid
    """
    return -90 <= lat <= 90 and -180 <= lng <= 180


class GeospatialUtils:
    """Utility class for geospatial operations."""
    
    @staticmethod
    def create_point_wkt(lat: float, lng: float) -> str:
        """Create WKT POINT string for PostGIS."""
        return f"POINT({lng} {lat})"
    
    @staticmethod
    def parse_point_wkt(wkt: str) -> Optional[Tuple[float, float]]:
        """Parse WKT POINT string to lat/lng."""
        try:
            # Extract coordinates from "POINT(lng lat)"
            coords = wkt.replace("POINT(", "").replace(")", "").split()
            lng, lat = float(coords[0]), float(coords[1])
            return lat, lng
        except (ValueError, IndexError):
            return None
    
    @staticmethod
    def get_geohash_precision_info() -> dict:
        """Get information about geohash precision levels."""
        return {
            1: {"error": "±2500 km", "description": "continent"},
            2: {"error": "±630 km", "description": "large country"},
            3: {"error": "±78 km", "description": "country/state"},
            4: {"error": "±20 km", "description": "city"},
            5: {"error": "±2.4 km", "description": "neighborhood"},
            6: {"error": "±610 m", "description": "street block"},
            7: {"error": "±76 m", "description": "building"},
            8: {"error": "±19 m", "description": "house"},
        }

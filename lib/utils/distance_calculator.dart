import 'dart:math';
import 'package:geolocator/geolocator.dart';

class DistanceCalculator {
  static const double _earthRadius = 6371; // Earth's radius in kilometers

  // Calculate distance between two points using Haversine formula
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Convert degrees to radians
    double lat1Rad = _degreesToRadians(lat1);
    double lon1Rad = _degreesToRadians(lon1);
    double lat2Rad = _degreesToRadians(lat2);
    double lon2Rad = _degreesToRadians(lon2);

    // Differences in coordinates
    double deltaLat = lat2Rad - lat1Rad;
    double deltaLon = lon2Rad - lon1Rad;

    // Haversine formula
    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = _earthRadius * c;

    return distance;
  }

  // Calculate distance using Geolocator (more accurate)
  static Future<double> calculateDistanceAccurate(double lat1, double lon1, double lat2, double lon2) async {
    try {
      return await Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
    } catch (e) {
      // Fallback to Haversine formula
      return calculateDistance(lat1, lon1, lat2, lon2);
    }
  }

  // Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  // Convert radians to degrees
  static double _radiansToDegrees(double radians) {
    return radians * (180 / pi);
  }

  // Convert kilometers to miles
  static double kilometersToMiles(double kilometers) {
    return kilometers * 0.621371;
  }

  // Convert miles to kilometers
  static double milesToKilometers(double miles) {
    return miles * 1.60934;
  }

  // Format distance for display
  static String formatDistance(double distanceInKm, {bool useMiles = true}) {
    if (useMiles) {
      double miles = kilometersToMiles(distanceInKm);
      if (miles < 1) {
        return '${(miles * 5280).round()} ft'; // Convert to feet
      } else if (miles < 10) {
        return '${miles.toStringAsFixed(1)} mi';
      } else {
        return '${miles.round()} mi';
      }
    } else {
      if (distanceInKm < 1) {
        return '${(distanceInKm * 1000).round()} m';
      } else if (distanceInKm < 10) {
        return '${distanceInKm.toStringAsFixed(1)} km';
      } else {
        return '${distanceInKm.round()} km';
      }
    }
  }

  // Estimate travel time (rough calculation)
  static int estimateTravelTime(double distanceInKm, {String mode = 'driving'}) {
    double averageSpeed; // km/h
    
    switch (mode.toLowerCase()) {
      case 'walking':
        averageSpeed = 5.0; // 5 km/h walking speed
        break;
      case 'cycling':
        averageSpeed = 15.0; // 15 km/h cycling speed
        break;
      case 'transit':
        averageSpeed = 25.0; // 25 km/h public transit
        break;
      case 'driving':
      default:
        averageSpeed = 40.0; // 40 km/h average driving speed in city
        break;
    }
    
    return (distanceInKm / averageSpeed * 60).round(); // Convert to minutes
  }

  // Format travel time
  static String formatTravelTime(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      int hours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours hr';
      } else {
        return '$hours hr $remainingMinutes min';
      }
    }
  }

  // Check if location is within radius
  static bool isWithinRadius(
    double centerLat,
    double centerLon,
    double targetLat,
    double targetLon,
    double radiusInKm,
  ) {
    double distance = calculateDistance(centerLat, centerLon, targetLat, targetLon);
    return distance <= radiusInKm;
  }

  // Calculate bearing between two points
  static double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    double lat1Rad = _degreesToRadians(lat1);
    double lat2Rad = _degreesToRadians(lat2);
    double deltaLon = _degreesToRadians(lon2 - lon1);

    double y = sin(deltaLon) * cos(lat2Rad);
    double x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(deltaLon);
    
    double bearing = atan2(y, x);
    return _radiansToDegrees(bearing);
  }

  // Calculate destination point given start point, bearing, and distance
  static Map<String, double> calculateDestination(
    double startLat,
    double startLon,
    double bearing,
    double distanceInKm,
  ) {
    double angularDistance = distanceInKm / _earthRadius;
    double bearingRad = _degreesToRadians(bearing);
    double lat1Rad = _degreesToRadians(startLat);
    double lon1Rad = _degreesToRadians(startLon);

    double lat2Rad = asin(
      sin(lat1Rad) * cos(angularDistance) +
      cos(lat1Rad) * sin(angularDistance) * cos(bearingRad)
    );

    double lon2Rad = lon1Rad + atan2(
      sin(bearingRad) * sin(angularDistance) * cos(lat1Rad),
      cos(angularDistance) - sin(lat1Rad) * sin(lat2Rad)
    );

    return {
      'latitude': _radiansToDegrees(lat2Rad),
      'longitude': _radiansToDegrees(lon2Rad),
    };
  }

  // Calculate area of a circle with given radius
  static double calculateCircleArea(double radiusInKm) {
    return pi * radiusInKm * radiusInKm;
  }

  // Calculate bounding box for a given center point and radius
  static Map<String, double> calculateBoundingBox(
    double centerLat,
    double centerLon,
    double radiusInKm,
  ) {
    // Convert radius from km to degrees (approximate)
    double latDelta = radiusInKm / 111.0; // 1 degree ≈ 111 km
    double lonDelta = radiusInKm / (111.0 * cos(_degreesToRadians(centerLat)));

    return {
      'minLat': centerLat - latDelta,
      'maxLat': centerLat + latDelta,
      'minLon': centerLon - lonDelta,
      'maxLon': centerLon + lonDelta,
    };
  }

  // Validate coordinates
  static bool isValidLatitude(double lat) {
    return lat >= -90 && lat <= 90;
  }

  static bool isValidLongitude(double lon) {
    return lon >= -180 && lon <= 180;
  }

  static bool isValidCoordinates(double lat, double lon) {
    return isValidLatitude(lat) && isValidLongitude(lon);
  }

  // Calculate distance between multiple points (route distance)
  static double calculateRouteDistance(List<Map<String, double>> points) {
    if (points.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      double lat1 = points[i]['latitude']!;
      double lon1 = points[i]['longitude']!;
      double lat2 = points[i + 1]['latitude']!;
      double lon2 = points[i + 1]['longitude']!;
      
      totalDistance += calculateDistance(lat1, lon1, lat2, lon2);
    }
    
    return totalDistance;
  }

  // Get distance category for display
  static String getDistanceCategory(double distanceInKm) {
    if (distanceInKm < 1) return 'Very Close';
    if (distanceInKm < 5) return 'Close';
    if (distanceInKm < 10) return 'Nearby';
    if (distanceInKm < 25) return 'Moderate';
    return 'Far';
  }

  // Get distance category color
  static int getDistanceCategoryColor(double distanceInKm) {
    if (distanceInKm < 1) return 0xFF4CAF50; // Green
    if (distanceInKm < 5) return 0xFF8BC34A; // Light Green
    if (distanceInKm < 10) return 0xFFFFC107; // Amber
    if (distanceInKm < 25) return 0xFFFF9800; // Orange
    return 0xFFF44336; // Red
  }
} 
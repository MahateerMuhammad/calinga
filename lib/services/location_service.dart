import 'dart:math';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static const double _earthRadius = 6371; // Earth's radius in kilometers

  // Get current user location
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Calculate distance between two points using Haversine formula
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

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
    double distance = earthRadius * c;

    return distance;
  }

  // Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
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
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()} m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.round()} km';
    }
  }

  // Generate mock locations for testing
  static List<Map<String, dynamic>> generateMockCaregiverLocations({
    required double centerLat,
    required double centerLon,
    required double radiusInKm,
    int count = 10,
  }) {
    List<Map<String, dynamic>> locations = [];
    final random = Random();

    for (int i = 0; i < count; i++) {
      // Generate random distance within radius
      double distance = random.nextDouble() * radiusInKm;
      
      // Generate random bearing (direction)
      double bearing = random.nextDouble() * 2 * pi;

      // Calculate new coordinates
      double lat1 = _degreesToRadians(centerLat);
      double lon1 = _degreesToRadians(centerLon);
      
      double angularDistance = distance / _earthRadius;
      
      double lat2 = asin(
        sin(lat1) * cos(angularDistance) +
        cos(lat1) * sin(angularDistance) * cos(bearing)
      );
      
      double lon2 = lon1 + atan2(
        sin(bearing) * sin(angularDistance) * cos(lat1),
        cos(angularDistance) - sin(lat1) * sin(lat2)
      );

      // Convert back to degrees
      double newLat = _radiansToDegrees(lat2);
      double newLon = _radiansToDegrees(lon2);

      locations.add({
        'latitude': newLat,
        'longitude': newLon,
        'distance': distance,
        'formattedDistance': formatDistance(distance),
      });
    }

    return locations;
  }

  // Convert radians to degrees
  static double _radiansToDegrees(double radians) {
    return radians * (180 / pi);
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

  // Get mock address from coordinates (for testing)
  static String getMockAddress(double lat, double lon) {
    // Simple mock address generation based on coordinates
    final random = Random((lat * 1000 + lon * 1000).round());
    
    List<String> streetNames = [
      'Main Street', 'Oak Avenue', 'Pine Road', 'Elm Street',
      'Maple Drive', 'Cedar Lane', 'Birch Boulevard', 'Willow Way'
    ];
    
    List<String> cities = [
      'Los Angeles', 'San Francisco', 'San Diego', 'Sacramento',
      'Fresno', 'Long Beach', 'Oakland', 'Bakersfield'
    ];
    
    String streetName = streetNames[random.nextInt(streetNames.length)];
    String city = cities[random.nextInt(cities.length)];
    int streetNumber = random.nextInt(9999) + 1;
    int zipCode = random.nextInt(90000) + 10000;
    
    return '$streetNumber $streetName, $city, CA $zipCode';
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
} 
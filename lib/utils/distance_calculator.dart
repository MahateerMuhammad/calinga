import 'dart:math';

class DistanceCalculator {
  static const double _earthRadius = 6371; // Earth's radius in kilometers

  /// Calculate distance between two points using Haversine formula
  /// Returns distance in kilometers
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

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Convert radians to degrees
  static double _radiansToDegrees(double radians) {
    return radians * (180 / pi);
  }

  /// Convert kilometers to miles
  static double kilometersToMiles(double kilometers) {
    return kilometers * 0.621371;
  }

  /// Convert miles to kilometers
  static double milesToKilometers(double miles) {
    return miles * 1.60934;
  }

  /// Format distance for display
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()} m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.round()} km';
    }
  }

  /// Format distance in miles for display
  static String formatDistanceMiles(double distanceInMiles) {
    if (distanceInMiles < 1) {
      return '${(distanceInMiles * 5280).round()} ft';
    } else if (distanceInMiles < 10) {
      return '${distanceInMiles.toStringAsFixed(1)} mi';
    } else {
      return '${distanceInMiles.round()} mi';
    }
  }

  /// Check if a location is within a specified radius
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

  /// Calculate bounding box for a given center point and radius
  /// Returns [minLat, maxLat, minLon, maxLon]
  static List<double> calculateBoundingBox(
    double centerLat,
    double centerLon,
    double radiusInKm,
  ) {
    double latDelta = radiusInKm / _earthRadius * (180 / pi);
    double lonDelta = radiusInKm / _earthRadius * (180 / pi) / cos(_degreesToRadians(centerLat));

    return [
      centerLat - latDelta, // minLat
      centerLat + latDelta, // maxLat
      centerLon - lonDelta, // minLon
      centerLon + lonDelta, // maxLon
    ];
  }

  /// Calculate estimated travel time based on distance
  /// Returns time in minutes
  static int calculateTravelTime(double distanceInKm, {double speedKmh = 30}) {
    return (distanceInKm / speedKmh * 60).round();
  }

  /// Format travel time for display
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

  /// Calculate bearing between two points
  /// Returns bearing in degrees (0-360)
  static double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    double lat1Rad = _degreesToRadians(lat1);
    double lat2Rad = _degreesToRadians(lat2);
    double deltaLon = _degreesToRadians(lon2 - lon1);

    double y = sin(deltaLon) * cos(lat2Rad);
    double x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(deltaLon);
    double bearing = atan2(y, x);

    return (_radiansToDegrees(bearing) + 360) % 360;
  }

  /// Calculate midpoint between two points
  /// Returns [midLat, midLon]
  static List<double> calculateMidpoint(double lat1, double lon1, double lat2, double lon2) {
    double lat1Rad = _degreesToRadians(lat1);
    double lon1Rad = _degreesToRadians(lon1);
    double lat2Rad = _degreesToRadians(lat2);
    double lon2Rad = _degreesToRadians(lon2);

    double Bx = cos(lat2Rad) * cos(lon2Rad - lon1Rad);
    double By = cos(lat2Rad) * sin(lon2Rad - lon1Rad);

    double midLat = atan2(
      sin(lat1Rad) + sin(lat2Rad),
      sqrt((cos(lat1Rad) + Bx) * (cos(lat1Rad) + Bx) + By * By),
    );
    double midLon = lon1Rad + atan2(By, cos(lat1Rad) + Bx);

    return [_radiansToDegrees(midLat), _radiansToDegrees(midLon)];
  }

  /// Validate coordinates
  static bool isValidLatitude(double lat) {
    return lat >= -90 && lat <= 90;
  }

  static bool isValidLongitude(double lon) {
    return lon >= -180 && lon <= 180;
  }

  static bool isValidCoordinates(double lat, double lon) {
    return isValidLatitude(lat) && isValidLongitude(lon);
  }

  /// Calculate area of a polygon defined by coordinates
  /// Uses shoelace formula
  static double calculatePolygonArea(List<List<double>> coordinates) {
    if (coordinates.length < 3) return 0;

    double area = 0;
    int j = coordinates.length - 1;

    for (int i = 0; i < coordinates.length; i++) {
      area += (coordinates[j][0] + coordinates[i][0]) * (coordinates[j][1] - coordinates[i][1]);
      j = i;
    }

    return (area / 2).abs();
  }

  /// Calculate centroid of a polygon
  /// Returns [centroidLat, centroidLon]
  static List<double> calculatePolygonCentroid(List<List<double>> coordinates) {
    if (coordinates.isEmpty) return [0, 0];

    double centroidLat = 0;
    double centroidLon = 0;

    for (List<double> coord in coordinates) {
      centroidLat += coord[0];
      centroidLon += coord[1];
    }

    return [centroidLat / coordinates.length, centroidLon / coordinates.length];
  }
} 
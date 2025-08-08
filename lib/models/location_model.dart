import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final double latitude;
  final double longitude;
  final String? address;
  final String? placeId;
  final String? geohash;
  final double? accuracy;
  final DateTime? timestamp;

  LocationModel({
    required this.latitude,
    required this.longitude,
    this.address,
    this.placeId,
    this.geohash,
    this.accuracy,
    this.timestamp,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      address: json['address'],
      placeId: json['placeId'],
      geohash: json['geohash'],
      accuracy: json['accuracy']?.toDouble(),
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'placeId': placeId,
      'geohash': geohash,
      'accuracy': accuracy,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
    };
  }

  // Create from GeoPoint (Firestore)
  factory LocationModel.fromGeoPoint(GeoPoint geoPoint, {String? address}) {
    return LocationModel(
      latitude: geoPoint.latitude,
      longitude: geoPoint.longitude,
      address: address,
    );
  }

  // Convert to GeoPoint for Firestore
  GeoPoint toGeoPoint() {
    return GeoPoint(latitude, longitude);
  }

  // Generate geohash for this location (simplified implementation)
  String generateGeohash() {
    // Simple geohash implementation for now
    // In production, you would use a proper geohash library
    return '${latitude.toStringAsFixed(6)}_${longitude.toStringAsFixed(6)}';
  }

  // Calculate distance to another location
  double distanceTo(LocationModel other) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double lat1 = _degreesToRadians(latitude);
    double lon1 = _degreesToRadians(longitude);
    double lat2 = _degreesToRadians(other.latitude);
    double lon2 = _degreesToRadians(other.longitude);

    double deltaLat = lat2 - lat1;
    double deltaLon = lon2 - lon1;

    double a =
        _haversin(deltaLat) + cos(lat1) * cos(lat2) * _haversin(deltaLon);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  double _haversin(double theta) {
    double s = sin(theta / 2);
    return s * s;
  }

  // Check if location is valid
  bool get isValid {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  // Copy with new values
  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? placeId,
    String? geohash,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      placeId: placeId ?? this.placeId,
      geohash: geohash ?? this.geohash,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'LocationModel(lat: $latitude, lng: $longitude, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode {
    return latitude.hashCode ^ longitude.hashCode;
  }
}

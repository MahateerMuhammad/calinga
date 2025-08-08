import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location_model.dart';
import '../models/user_model.dart';

class GoogleMapsService {
  static const String _apiKey = 'AIzaSyB5XvbHXJ3XOd-VCiicLABANs9mzxrHsH0';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user location
  Future<LocationModel?> getCurrentLocation() async {
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
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      String? address;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          address =
              '${place.street}, ${place.locality}, ${place.administrativeArea}';
        }
      } catch (e) {
        debugPrint('Error getting address: $e');
      }

      return LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  // Get address from coordinates
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
      return null;
    } catch (e) {
      debugPrint('Error getting address: $e');
      return null;
    }
  }

  // Get coordinates from address
  Future<LocationModel?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        Location location = locations[0];
        return LocationModel(
          latitude: location.latitude,
          longitude: location.longitude,
          address: address,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting coordinates: $e');
      return null;
    }
  }

  // Get nearby caregivers
  Future<List<Map<String, dynamic>>> getNearbyCaregivers({
    required double centerLat,
    required double centerLon,
    required double radiusInKm,
    String? role,
    double? minRate,
    double? maxRate,
    bool? isAvailable,
  }) async {
    try {
      // Query caregivers within radius
      Query query = _firestore.collection('caregivers');

      // Filter by availability if specified
      if (isAvailable != null) {
        query = query.where('isAvailable', isEqualTo: isAvailable);
      }

      // Filter by role if specified
      if (role != null && role != 'All') {
        query = query.where('role', isEqualTo: role);
      }

      // Filter by hourly rate if specified
      if (minRate != null) {
        query = query.where('hourlyRate', isGreaterThanOrEqualTo: minRate);
      }
      if (maxRate != null) {
        query = query.where('hourlyRate', isLessThanOrEqualTo: maxRate);
      }

      QuerySnapshot snapshot = await query.get();
      List<Map<String, dynamic>> caregivers = [];

      for (DocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Check if caregiver has location data
        if (data['location'] != null) {
          GeoPoint geoPoint = data['location'];
          double distance = _calculateDistance(
            centerLat,
            centerLon,
            geoPoint.latitude,
            geoPoint.longitude,
          );

          // Only include caregivers within radius
          if (distance <= radiusInKm) {
            caregivers.add({
              'id': doc.id,
              'name': data['name'] ?? 'Unknown',
              'role': data['role'] ?? 'Caregiver',
              'rating': data['rating']?.toDouble() ?? 0.0,
              'hourlyRate': data['hourlyRate']?.toDouble() ?? 0.0,
              'isAvailable': data['isAvailable'] ?? false,
              'latitude': geoPoint.latitude,
              'longitude': geoPoint.longitude,
              'distance': distance,
              'formattedDistance': _formatDistance(distance),
              'address': data['address'],
              'profileImage': data['profileImage'],
              'specializations': data['specializations'] ?? [],
              'experience': data['experience'] ?? 'Unknown',
              'certifications': data['certifications'] ?? [],
            });
          }
        }
      }

      // Sort by distance
      caregivers.sort(
        (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
      );

      return caregivers;
    } catch (e) {
      debugPrint('Error getting nearby caregivers: $e');
      return [];
    }
  }

  // Update caregiver location
  Future<void> updateCaregiverLocation(
    String caregiverId,
    LocationModel location,
  ) async {
    try {
      await _firestore.collection('caregivers').doc(caregiverId).update({
        'location': location.toGeoPoint(),
        'address': location.address,
        'geohash': location.generateGeohash(),
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating caregiver location: $e');
      rethrow;
    }
  }

  // Migrate caregiver documents to use Firebase Auth UID as document ID
  Future<void> migrateCaregiverIds() async {
    try {
      print('DEBUG: Starting caregiver ID migration...');
      final caregivers = await _firestore.collection('caregivers').get();

      for (final doc in caregivers.docs) {
        final data = doc.data();
        final userUid = data['uid'] ?? data['userId']; // Look for UID field

        print('DEBUG: Caregiver ${doc.id} - UserUID: $userUid');

        if (userUid != null && userUid != doc.id) {
          // Create new document with correct ID (Firebase Auth UID)
          await _firestore.collection('caregivers').doc(userUid).set(data);
          // Delete old document
          await doc.reference.delete();
          print('DEBUG: Migrated caregiver from ${doc.id} to $userUid');
        }
      }

      print('DEBUG: Caregiver migration completed');
    } catch (e) {
      print('DEBUG: Caregiver migration failed: $e');
      throw Exception('Failed to migrate caregiver IDs: $e');
    }
  }

  // Ensure current caregiver document uses Firebase Auth UID
  Future<void> ensureCaregiverDocumentId(String firebaseAuthUid) async {
    try {
      // Check if document already exists with correct ID
      final correctDoc = await _firestore
          .collection('caregivers')
          .doc(firebaseAuthUid)
          .get();

      if (!correctDoc.exists) {
        // Look for caregiver document with this UID in the data
        final querySnapshot = await _firestore
            .collection('caregivers')
            .where('uid', isEqualTo: firebaseAuthUid)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final oldDoc = querySnapshot.docs.first;
          final data = oldDoc.data();

          // Create new document with Firebase Auth UID as document ID
          await _firestore
              .collection('caregivers')
              .doc(firebaseAuthUid)
              .set(data);
          // Delete old document
          await oldDoc.reference.delete();

          print(
            'DEBUG: Moved caregiver document to correct ID: $firebaseAuthUid',
          );
        } else {
          print('DEBUG: No caregiver document found for UID: $firebaseAuthUid');
        }
      } else {
        print(
          'DEBUG: Caregiver document already has correct ID: $firebaseAuthUid',
        );
      }
    } catch (e) {
      print('DEBUG: Error ensuring caregiver document ID: $e');
    }
  }

  // Stream caregiver location updates
  Stream<LocationModel?> streamCaregiverLocation(String caregiverId) {
    return _firestore.collection('caregivers').doc(caregiverId).snapshots().map(
      (doc) {
        if (doc.exists && doc.data()?['location'] != null) {
          GeoPoint geoPoint = doc.data()!['location'];
          return LocationModel.fromGeoPoint(
            geoPoint,
            address: doc.data()!['address'],
          );
        }
        return null;
      },
    );
  }

  // Calculate distance between two points
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) /
        1000; // Convert to km
  }

  // Format distance for display
  String _formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()} m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.round()} km';
    }
  }

  // Create custom marker icon
  Future<BitmapDescriptor> createCustomMarkerIcon({
    required String role,
    required bool isAvailable,
  }) async {
    // Default marker colors based on role and availability
    Color markerColor;
    switch (role.toLowerCase()) {
      case 'rn':
      case 'registered nurse':
        markerColor = isAvailable ? Colors.green : Colors.grey;
        break;
      case 'lvn':
      case 'licensed vocational nurse':
        markerColor = isAvailable ? Colors.blue : Colors.grey;
        break;
      case 'cna':
      case 'certified nursing assistant':
        markerColor = isAvailable ? Colors.orange : Colors.grey;
        break;
      case 'pt':
      case 'physical therapist':
        markerColor = isAvailable ? Colors.purple : Colors.grey;
        break;
      default:
        markerColor = isAvailable ? Colors.red : Colors.grey;
    }

    return BitmapDescriptor.defaultMarkerWithHue(_colorToHue(markerColor));
  }

  // Convert color to hue for marker
  double _colorToHue(Color color) {
    if (color == Colors.green) return BitmapDescriptor.hueGreen;
    if (color == Colors.blue) return BitmapDescriptor.hueBlue;
    if (color == Colors.orange) return BitmapDescriptor.hueOrange;
    if (color == Colors.purple) return BitmapDescriptor.hueViolet;
    if (color == Colors.red) return BitmapDescriptor.hueRed;
    return BitmapDescriptor.hueAzure; // Default
  }

  // Get map widget with markers
  Widget getMapWidget({
    required double centerLat,
    required double centerLon,
    required double zoom,
    required List<Map<String, dynamic>> markers,
    Function(Map<String, dynamic>)? onMarkerTap,
    Function(LatLng)? onMapTap,
    Function(CameraPosition)? onCameraMove,
  }) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(centerLat, centerLon),
        zoom: zoom,
      ),
      markers: _createMarkers(markers, onMarkerTap),
      onTap: onMapTap,
      onCameraMove: onCameraMove,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      trafficEnabled: false,
      indoorViewEnabled: false,
    );
  }

  // Create markers from caregiver data
  Set<Marker> _createMarkers(
    List<Map<String, dynamic>> caregivers,
    Function(Map<String, dynamic>)? onMarkerTap,
  ) {
    return caregivers.map((caregiver) {
      return Marker(
        markerId: MarkerId(caregiver['id']),
        position: LatLng(caregiver['latitude'], caregiver['longitude']),
        infoWindow: InfoWindow(
          title: caregiver['name'],
          snippet: '${caregiver['role']} • ${caregiver['formattedDistance']}',
        ),
        onTap: () => onMarkerTap?.call(caregiver),
      );
    }).toSet();
  }

  // Calculate route between two points
  Future<Map<String, dynamic>> calculateRoute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) async {
    try {
      double distance = _calculateDistance(startLat, startLon, endLat, endLon);
      int estimatedTimeMinutes = (distance * 2.5).round(); // Rough estimate

      return {
        'distance': distance,
        'formattedDistance': _formatDistance(distance),
        'estimatedTimeMinutes': estimatedTimeMinutes,
        'estimatedTimeFormatted': _formatDuration(estimatedTimeMinutes),
      };
    } catch (e) {
      debugPrint('Error calculating route: $e');
      return {
        'distance': 0.0,
        'formattedDistance': '0 m',
        'estimatedTimeMinutes': 0,
        'estimatedTimeFormatted': '0 min',
      };
    }
  }

  // Format duration
  String _formatDuration(int minutes) {
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
}

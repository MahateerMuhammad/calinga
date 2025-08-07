import 'dart:math';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'location_service.dart';

// Mock position class for when geolocator is not available
class MockPosition {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final double heading;
  final DateTime timestamp;

  MockPosition({
    required this.latitude,
    required this.longitude,
    this.accuracy = 10.0,
    this.altitude = 0.0,
    this.speed = 0.0,
    this.heading = 0.0,
    required this.timestamp,
  });
}

class MapService {
  static const String _googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY'; // TODO: Replace with actual API key
  static bool _useMockData = true; // Toggle for testing without API key

  // Check if Google Maps API key is available
  static bool get hasValidApiKey => _googleMapsApiKey != 'YOUR_GOOGLE_MAPS_API_KEY';

  // Toggle between mock and real data
  static void setMockMode(bool useMock) {
    _useMockData = useMock;
  }

  static bool get useMockData => _useMockData;

  // Get current location (with fallback to mock)
  static Future<MockPosition?> getCurrentLocation() async {
    if (_useMockData || !hasValidApiKey) {
      // Return mock location (Los Angeles area)
      return MockPosition(
        latitude: 34.0522,
        longitude: -118.2437,
        timestamp: DateTime.now(),
      );
    }

    try {
      // TODO: Implement real geolocation when geolocator is available
      // final position = await Geolocator.getCurrentPosition();
      // return MockPosition(
      //   latitude: position.latitude,
      //   longitude: position.longitude,
      //   accuracy: position.accuracy,
      //   altitude: position.altitude,
      //   speed: position.speed,
      //   heading: position.heading,
      //   timestamp: position.timestamp,
      // );
      return null;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Generate mock caregiver data with locations
  static List<Map<String, dynamic>> getMockCaregivers({
    required double centerLat,
    required double centerLon,
    required double radiusInKm,
  }) {
    final random = Random();
    final locations = LocationService.generateMockCaregiverLocations(
      centerLat: centerLat,
      centerLon: centerLon,
      radiusInKm: radiusInKm,
      count: 15,
    );

    List<String> names = [
      'Sarah Johnson', 'Michael Chen', 'Emily Rodriguez', 'David Kim',
      'Lisa Patel', 'James Wilson', 'Maria Garcia', 'Robert Taylor',
      'Jennifer Brown', 'Christopher Davis', 'Amanda Miller', 'Daniel Anderson',
      'Jessica Thomas', 'Matthew Jackson', 'Ashley White'
    ];

    List<String> roles = ['CNA', 'LVN', 'RN', 'NP', 'PT', 'HHA', 'Private Caregiver'];

    return locations.asMap().entries.map((entry) {
      int index = entry.key;
      Map<String, dynamic> location = entry.value;
      
      return {
        'id': 'caregiver_${index + 1}',
        'name': names[index % names.length],
        'role': roles[random.nextInt(roles.length)],
        'rating': 4.0 + random.nextDouble() * 1.0, // 4.0 to 5.0
        'hourlyRate': 20.0 + random.nextDouble() * 30.0, // $20 to $50
        'isAvailable': random.nextBool(),
        'latitude': location['latitude'],
        'longitude': location['longitude'],
        'distance': location['distance'],
        'formattedDistance': location['formattedDistance'],
        'address': LocationService.getMockAddress(location['latitude'], location['longitude']),
        'profileImage': null, // TODO: Add mock profile images
        'specializations': _getRandomSpecializations(),
        'experience': '${random.nextInt(10) + 1} years',
        'certifications': _getRandomCertifications(),
      };
    }).toList();
  }

  // Get random specializations for caregivers
  static List<String> _getRandomSpecializations() {
    final random = Random();
    List<String> allSpecializations = [
      'Elderly Care', 'Post-Surgery Care', 'Dementia Care', 'Palliative Care',
      'Physical Therapy', 'Occupational Therapy', 'Wound Care', 'Medication Management',
      'Mobility Assistance', 'Personal Hygiene', 'Meal Preparation', 'Transportation'
    ];

    int count = random.nextInt(4) + 2; // 2-5 specializations
    allSpecializations.shuffle(random);
    return allSpecializations.take(count).toList();
  }

  // Get random certifications for caregivers
  static List<String> _getRandomCertifications() {
    final random = Random();
    List<String> allCertifications = [
      'CPR Certified', 'First Aid Certified', 'California CNA License',
      'California LVN License', 'California RN License', 'Physical Therapy License',
      'Home Health Aide Certification', 'Dementia Care Specialist'
    ];

    int count = random.nextInt(3) + 1; // 1-3 certifications
    allCertifications.shuffle(random);
    return allCertifications.take(count).toList();
  }

  // Filter caregivers by criteria
  static List<Map<String, dynamic>> filterCaregivers({
    required List<Map<String, dynamic>> caregivers,
    String? role,
    double? maxDistance,
    double? minRate,
    double? maxRate,
    bool? isAvailable,
    String? searchQuery,
  }) {
    return caregivers.where((caregiver) {
      // Filter by role
      if (role != null && role != 'All' && caregiver['role'] != role) {
        return false;
      }

      // Filter by distance
      if (maxDistance != null && caregiver['distance'] > maxDistance) {
        return false;
      }

      // Filter by hourly rate
      if (minRate != null && caregiver['hourlyRate'] < minRate) {
        return false;
      }
      if (maxRate != null && caregiver['hourlyRate'] > maxRate) {
        return false;
      }

      // Filter by availability
      if (isAvailable != null && caregiver['isAvailable'] != isAvailable) {
        return false;
      }

      // Filter by search query
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final name = caregiver['name'].toString().toLowerCase();
        final roleStr = caregiver['role'].toString().toLowerCase();
        final specializations = caregiver['specializations']
            .map((s) => s.toString().toLowerCase())
            .join(' ');

        if (!name.contains(query) && 
            !roleStr.contains(query) && 
            !specializations.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Sort caregivers by criteria
  static List<Map<String, dynamic>> sortCaregivers({
    required List<Map<String, dynamic>> caregivers,
    String sortBy = 'distance',
  }) {
    switch (sortBy) {
      case 'distance':
        caregivers.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
        break;
      case 'rating':
        caregivers.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
        break;
      case 'price_low':
        caregivers.sort((a, b) => (a['hourlyRate'] as double).compareTo(b['hourlyRate'] as double));
        break;
      case 'price_high':
        caregivers.sort((a, b) => (b['hourlyRate'] as double).compareTo(a['hourlyRate'] as double));
        break;
      case 'name':
        caregivers.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
        break;
    }
    return caregivers;
  }

  // Calculate route distance and time (mock implementation)
  static Map<String, dynamic> calculateRoute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
  }) {
    final distance = LocationService.calculateDistance(startLat, startLon, endLat, endLon);
    final estimatedTimeMinutes = (distance * 2.5).round(); // Rough estimate: 2.5 min per km

    return {
      'distance': distance,
      'formattedDistance': LocationService.formatDistance(distance),
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'estimatedTimeFormatted': _formatDuration(estimatedTimeMinutes),
    };
  }

  // Format duration in minutes to readable string
  static String _formatDuration(int minutes) {
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

  // Get map widget (placeholder for Google Maps integration)
  static Widget getMapWidget({
    required double centerLat,
    required double centerLon,
    required double zoom,
    required List<Map<String, dynamic>> markers,
    Function(Map<String, dynamic>)? onMarkerTap,
  }) {
    if (_useMockData || !hasValidApiKey) {
      // Return mock map widget
      return _MockMapWidget(
        centerLat: centerLat,
        centerLon: centerLon,
        zoom: zoom,
        markers: markers,
        onMarkerTap: onMarkerTap,
      );
    }

    // TODO: Implement real Google Maps widget
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Text('Google Maps Integration\n(TODO: Add API key)'),
      ),
    );
  }
}

// Mock map widget for testing
class _MockMapWidget extends StatelessWidget {
  final double centerLat;
  final double centerLon;
  final double zoom;
  final List<Map<String, dynamic>> markers;
  final Function(Map<String, dynamic>)? onMarkerTap;

  const _MockMapWidget({
    required this.centerLat,
    required this.centerLon,
    required this.zoom,
    required this.markers,
    this.onMarkerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Mock map background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomPaint(
              painter: _MockMapPainter(
                centerLat: centerLat,
                centerLon: centerLon,
                zoom: zoom,
                markers: markers,
              ),
            ),
          ),
          // Mock markers
          ...markers.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> marker = entry.value;
            
            return Positioned(
              left: 50 + (index * 30) % 200,
              top: 50 + (index * 40) % 300,
              child: GestureDetector(
                onTap: () => onMarkerTap?.call(marker),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            );
          }).toList(),
          // Mock map controls
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.remove, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for mock map
class _MockMapPainter extends CustomPainter {
  final double centerLat;
  final double centerLon;
  final double zoom;
  final List<Map<String, dynamic>> markers;

  _MockMapPainter({
    required this.centerLat,
    required this.centerLon,
    required this.zoom,
    required this.markers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw mock grid lines
    for (int i = 0; i < size.width; i += 30) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }
    for (int i = 0; i < size.height; i += 30) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 
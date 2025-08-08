import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_model.dart';

class CustomMapMarkers {
  // Create custom marker for caregiver
  static Future<BitmapDescriptor> createCaregiverMarker({
    required String role,
    required bool isAvailable,
    double? rating,
  }) async {
    // Default marker colors based on role and availability
    Color markerColor;
    IconData iconData;
    
    switch (role.toLowerCase()) {
      case 'rn':
      case 'registered nurse':
        markerColor = isAvailable ? Colors.green : Colors.grey;
        iconData = Icons.medical_services;
        break;
      case 'lvn':
      case 'licensed vocational nurse':
        markerColor = isAvailable ? Colors.blue : Colors.grey;
        iconData = Icons.medical_services;
        break;
      case 'cna':
      case 'certified nursing assistant':
        markerColor = isAvailable ? Colors.orange : Colors.grey;
        iconData = Icons.health_and_safety;
        break;
      case 'pt':
      case 'physical therapist':
        markerColor = isAvailable ? Colors.purple : Colors.grey;
        iconData = Icons.accessibility;
        break;
      case 'hha':
      case 'home health aide':
        markerColor = isAvailable ? Colors.teal : Colors.grey;
        iconData = Icons.home;
        break;
      case 'np':
      case 'nurse practitioner':
        markerColor = isAvailable ? Colors.indigo : Colors.grey;
        iconData = Icons.medical_services;
        break;
      default:
        markerColor = isAvailable ? Colors.red : Colors.grey;
        iconData = Icons.person;
    }

    return BitmapDescriptor.defaultMarkerWithHue(
      _colorToHue(markerColor),
    );
  }

  // Convert color to hue for marker
  static double _colorToHue(Color color) {
    if (color == Colors.green) return BitmapDescriptor.hueGreen;
    if (color == Colors.blue) return BitmapDescriptor.hueBlue;
    if (color == Colors.orange) return BitmapDescriptor.hueOrange;
    if (color == Colors.purple) return BitmapDescriptor.hueViolet;
    if (color == Colors.teal) return BitmapDescriptor.hueCyan;
    if (color == Colors.indigo) return BitmapDescriptor.hueAzure;
    if (color == Colors.red) return BitmapDescriptor.hueRed;
    return BitmapDescriptor.hueAzure; // Default
  }

  // Create marker with custom info window
  static Marker createCaregiverMarkerWithInfo({
    required String id,
    required double latitude,
    required double longitude,
    required String name,
    required String role,
    required bool isAvailable,
    String? distance,
    double? hourlyRate,
    double? rating,
    List<String>? specializations,
    Function()? onTap,
  }) {
    return Marker(
      markerId: MarkerId(id),
      position: LatLng(latitude, longitude),
      infoWindow: InfoWindow(
        title: name,
        snippet: _buildMarkerSnippet(role, distance, hourlyRate, rating),
        onTap: onTap,
      ),
      onTap: onTap,
    );
  }

  // Build marker snippet text
  static String _buildMarkerSnippet(
    String role,
    String? distance,
    double? hourlyRate,
    double? rating,
  ) {
    List<String> info = [];
    
    info.add(role);
    
    if (distance != null) {
      info.add(distance);
    }
    
    if (hourlyRate != null) {
      info.add('\$${hourlyRate.toStringAsFixed(0)}/hr');
    }

    return info.join(' • ');
  }

  // Create availability status indicator
  static Widget createAvailabilityIndicator(bool isAvailable) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  // Create rating indicator
  static Widget createRatingIndicator(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.white, size: 12),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Create price indicator
  static Widget createPriceIndicator(double hourlyRate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        '\$${hourlyRate.toStringAsFixed(0)}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Create distance indicator
  static Widget createDistanceIndicator(String distance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, color: Colors.white, size: 12),
          const SizedBox(width: 2),
          Text(
            distance,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Create role badge
  static Widget createRoleBadge(String role) {
    Color badgeColor;
    switch (role.toLowerCase()) {
      case 'rn':
      case 'registered nurse':
        badgeColor = Colors.green;
        break;
      case 'lvn':
      case 'licensed vocational nurse':
        badgeColor = Colors.blue;
        break;
      case 'cna':
      case 'certified nursing assistant':
        badgeColor = Colors.orange;
        break;
      case 'pt':
      case 'physical therapist':
        badgeColor = Colors.purple;
        break;
      case 'hha':
      case 'home health aide':
        badgeColor = Colors.teal;
        break;
      case 'np':
      case 'nurse practitioner':
        badgeColor = Colors.indigo;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        role.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Create marker cluster
  static Widget createMarkerCluster(int count, {double? radius}) {
    return Container(
      width: radius ?? 40,
      height: radius ?? 40,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Create custom marker widget
  static Widget createCustomMarkerWidget({
    required String name,
    required String role,
    required bool isAvailable,
    String? distance,
    double? hourlyRate,
    double? rating,
    List<String>? specializations,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Availability indicator
            createAvailabilityIndicator(isAvailable),
            const SizedBox(height: 4),
            
            // Name
            Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Role badge
            const SizedBox(height: 4),
            createRoleBadge(role),
            
            // Additional info
            if (distance != null || hourlyRate != null || rating != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (rating != null) createRatingIndicator(rating),
                  if (rating != null && distance != null) const SizedBox(width: 4),
                  if (distance != null) createDistanceIndicator(distance),
                  if (distance != null && hourlyRate != null) const SizedBox(width: 4),
                  if (hourlyRate != null) createPriceIndicator(hourlyRate),
                ],
              ),
            ],
            
            // Specializations (if any)
            if (specializations != null && specializations.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 2,
                runSpacing: 2,
                children: specializations
                    .take(2)
                    .map((spec) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            spec,
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 
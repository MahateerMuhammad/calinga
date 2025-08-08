import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissions {
  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check current permission status
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  // Check if we have location permission
  static Future<bool> hasPermission() async {
    LocationPermission permission = await checkPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  // Get permission status description
  static String getPermissionStatusDescription(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return 'Location permission is denied';
      case LocationPermission.deniedForever:
        return 'Location permission is permanently denied';
      case LocationPermission.whileInUse:
        return 'Location permission granted while app is in use';
      case LocationPermission.always:
        return 'Location permission granted always';
      case LocationPermission.unableToDetermine:
        return 'Unable to determine location permission status';
    }
  }

  // Show permission request dialog
  static Future<bool> showPermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'CALiNGA needs location access to find caregivers near you and provide accurate distance calculations. '
            'Your location will only be used to show nearby caregivers and will not be shared with others.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Grant Permission'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Show location services disabled dialog
  static Future<bool> showLocationServicesDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'Location services are disabled on your device. '
            'Please enable location services in your device settings to use this feature.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                Geolocator.openLocationSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Show permission permanently denied dialog
  static Future<bool> showPermanentlyDeniedDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Location permission has been permanently denied. '
            'Please enable location permission in your device settings to use this feature.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  // Request permission with user-friendly flow
  static Future<bool> requestPermissionWithDialog(BuildContext context) async {
    // Check if location services are enabled
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      bool shouldOpenSettings = await showLocationServicesDialog(context);
      if (shouldOpenSettings) {
        return false; // User will handle it in settings
      }
      return false;
    }

    // Check current permission
    LocationPermission permission = await checkPermission();
    
    if (permission == LocationPermission.denied) {
      // Show permission request dialog
      bool shouldRequest = await showPermissionDialog(context);
      if (shouldRequest) {
        permission = await requestPermission();
      } else {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Show permanently denied dialog
      bool shouldOpenSettings = await showPermanentlyDeniedDialog(context);
      if (shouldOpenSettings) {
        return false; // User will handle it in settings
      }
      return false;
    }

    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  // Show location accuracy improvement dialog
  static Future<void> showAccuracyDialog(BuildContext context, double currentAccuracy) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Improve Location Accuracy'),
          content: Text(
            'Your current location accuracy is ${currentAccuracy.toStringAsFixed(1)} meters. '
            'For better results, try:\n\n'
            '• Moving to an open area\n'
            '• Waiting a few seconds for GPS to stabilize\n'
            '• Checking if GPS is enabled in your device settings',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Get location accuracy level
  static String getAccuracyLevel(double accuracy) {
    if (accuracy <= 5) return 'High';
    if (accuracy <= 20) return 'Medium';
    return 'Low';
  }

  // Get accuracy color
  static Color getAccuracyColor(double accuracy) {
    if (accuracy <= 5) return Colors.green;
    if (accuracy <= 20) return Colors.orange;
    return Colors.red;
  }

  // Show location status snackbar
  static void showLocationStatusSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.location_on,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
} 
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';
import '../services/google_maps_service.dart';

class LocationProvider with ChangeNotifier {
  final GoogleMapsService _mapsService = GoogleMapsService();
  
  LocationModel? _currentLocation;
  bool _isLoading = false;
  String? _error;
  bool _hasLocationPermission = false;
  bool _isLocationServiceEnabled = false;

  // Getters
  LocationModel? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLocationPermission => _hasLocationPermission;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;
  bool get hasValidLocation => _currentLocation != null && _currentLocation!.isValid;

  // Initialize location services
  Future<void> initializeLocation() async {
    _setLoading(true);
    _clearError();

    try {
      // Check if location services are enabled
      _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      
      if (!_isLocationServiceEnabled) {
        _setError('Location services are disabled. Please enable location services in your device settings.');
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      _hasLocationPermission = permission == LocationPermission.whileInUse || 
                               permission == LocationPermission.always;

      if (!_hasLocationPermission) {
        // Request permission
        permission = await Geolocator.requestPermission();
        _hasLocationPermission = permission == LocationPermission.whileInUse || 
                                 permission == LocationPermission.always;

        if (!_hasLocationPermission) {
          _setError('Location permission is required to use this feature.');
          return;
        }
      }

      // Get current location
      await getCurrentLocation();
    } catch (e) {
      _setError('Failed to initialize location: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get current location
  Future<void> getCurrentLocation() async {
    if (!_hasLocationPermission || !_isLocationServiceEnabled) {
      await initializeLocation();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      _currentLocation = await _mapsService.getCurrentLocation();
      
      if (_currentLocation == null) {
        _setError('Unable to get current location. Please check your GPS settings.');
      }
    } catch (e) {
      _setError('Failed to get current location: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update current location
  Future<void> updateCurrentLocation() async {
    await getCurrentLocation();
  }

  // Set location manually (for testing or user input)
  void setLocation(LocationModel location) {
    _currentLocation = location;
    _clearError();
    notifyListeners();
  }

  // Get address from coordinates
  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      return await _mapsService.getAddressFromCoordinates(lat, lng);
    } catch (e) {
      debugPrint('Error getting address: $e');
      return null;
    }
  }

  // Get coordinates from address
  Future<LocationModel?> getCoordinatesFromAddress(String address) async {
    try {
      return await _mapsService.getCoordinatesFromAddress(address);
    } catch (e) {
      debugPrint('Error getting coordinates: $e');
      return null;
    }
  }

  // Check if location is within radius
  bool isWithinRadius(LocationModel targetLocation, double radiusInKm) {
    if (_currentLocation == null) return false;
    return _currentLocation!.distanceTo(targetLocation) <= radiusInKm;
  }

  // Calculate distance to a location
  double? distanceTo(LocationModel targetLocation) {
    if (_currentLocation == null) return null;
    return _currentLocation!.distanceTo(targetLocation);
  }

  // Format distance for display
  String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()} m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.round()} km';
    }
  }

  // Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      _hasLocationPermission = permission == LocationPermission.whileInUse || 
                               permission == LocationPermission.always;
      
      if (_hasLocationPermission) {
        await getCurrentLocation();
      }
      
      notifyListeners();
      return _hasLocationPermission;
    } catch (e) {
      _setError('Failed to request location permission: $e');
      return false;
    }
  }

  // Check location service status
  Future<void> checkLocationServiceStatus() async {
    try {
      _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      
      LocationPermission permission = await Geolocator.checkPermission();
      _hasLocationPermission = permission == LocationPermission.whileInUse || 
                               permission == LocationPermission.always;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking location service status: $e');
    }
  }

  // Get location accuracy level
  String getLocationAccuracyLevel() {
    if (_currentLocation?.accuracy == null) return 'Unknown';
    
    double accuracy = _currentLocation!.accuracy!;
    if (accuracy <= 5) return 'High';
    if (accuracy <= 20) return 'Medium';
    return 'Low';
  }

  // Get location status summary
  Map<String, dynamic> getLocationStatus() {
    return {
      'hasLocation': hasValidLocation,
      'hasPermission': _hasLocationPermission,
      'serviceEnabled': _isLocationServiceEnabled,
      'accuracy': getLocationAccuracyLevel(),
      'lastUpdate': _currentLocation?.timestamp,
      'coordinates': _currentLocation != null 
          ? '${_currentLocation!.latitude.toStringAsFixed(6)}, ${_currentLocation!.longitude.toStringAsFixed(6)}'
          : 'Not available',
    };
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Dispose method
  @override
  void dispose() {
    super.dispose();
  }
} 
// ignore_for_file: unnecessary_overrides

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/availability_model.dart';
import '../models/location_model.dart';
import '../services/google_maps_service.dart';

class AvailabilityProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleMapsService _mapsService = GoogleMapsService();

  AvailabilityModel? _availability;
  bool _isLoading = false;
  String? _error;

  // Getters
  AvailabilityModel? get availability => _availability;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAvailable => _availability?.isAvailable ?? false;
  String get statusDisplayText => _availability?.statusDisplayText ?? 'Unknown';

  // Initialize availability for current user
  Future<void> initializeAvailability() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _setLoading(true);
    _clearError();

    try {
      // Check if availability document exists
      final doc = await _firestore
          .collection('caregivers')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        _availability = AvailabilityModel.fromJson(doc.data()!);
      } else {
        // Create default availability
        _availability = AvailabilityModel(
          userId: user.uid,
          isAvailable: false,
          lastAvailabilityUpdate: DateTime.now(),
          availabilityStatus: 'offline',
        );
        
        // Save to Firestore
        await _firestore
            .collection('caregivers')
            .doc(user.uid)
            .set(_availability!.toJson());
      }
    } catch (e) {
      _setError('Failed to initialize availability: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Toggle availability status
  Future<void> toggleAvailability() async {
    if (_availability == null) return;

    _setLoading(true);
    _clearError();

    try {
      final newStatus = _availability!.isAvailable ? 'offline' : 'online';
      final newAvailability = _availability!.copyWith(
        isAvailable: !_availability!.isAvailable,
        availabilityStatus: newStatus,
        lastAvailabilityUpdate: DateTime.now(),
      );

      // Update local state
      _availability = newAvailability;

      // Update Firestore with availability and location
      Map<String, dynamic> updateData = newAvailability.toJson();
      
      // Add location data if available
      try {
        LocationModel? currentLocation = await _mapsService.getCurrentLocation();
        if (currentLocation != null) {
          updateData['location'] = currentLocation.toGeoPoint();
          updateData['address'] = currentLocation.address;
          updateData['geohash'] = currentLocation.generateGeohash();
          updateData['lastLocationUpdate'] = FieldValue.serverTimestamp();
        }
      } catch (e) {
        debugPrint('Error updating location: $e');
      }

      await _firestore
          .collection('caregivers')
          .doc(_auth.currentUser!.uid)
          .update(updateData);

      notifyListeners();
    } catch (e) {
      _setError('Failed to update availability: $e');
      // Revert local state on error
      _availability = _availability!.copyWith(
        isAvailable: !_availability!.isAvailable,
        availabilityStatus: _availability!.isAvailable ? 'online' : 'offline',
      );
    } finally {
      _setLoading(false);
    }
  }

  // Set specific availability status
  Future<void> setAvailabilityStatus(String status) async {
    if (_availability == null) return;

    _setLoading(true);
    _clearError();

    try {
      final isAvailable = status == 'online';
      final newAvailability = _availability!.copyWith(
        isAvailable: isAvailable,
        availabilityStatus: status,
        lastAvailabilityUpdate: DateTime.now(),
      );

      // Update local state
      _availability = newAvailability;

      // Update Firestore
      await _firestore
          .collection('caregivers')
          .doc(_auth.currentUser!.uid)
          .update(newAvailability.toJson());

      notifyListeners();
    } catch (e) {
      _setError('Failed to set availability status: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Set busy status (for when caregiver is on a call/booking)
  Future<void> setBusyStatus() async {
    await setAvailabilityStatus('busy');
  }

  // Set online status
  Future<void> setOnlineStatus() async {
    await setAvailabilityStatus('online');
  }

  // Set offline status
  Future<void> setOfflineStatus() async {
    await setAvailabilityStatus('offline');
  }

  // Stream availability changes
  Stream<AvailabilityModel?> streamAvailability() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('caregivers')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return AvailabilityModel.fromJson(doc.data()!);
      }
      return null;
    });
  }

  // Refresh availability from Firestore
  Future<void> refreshAvailability() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _setLoading(true);
    _clearError();

    try {
      final doc = await _firestore
          .collection('caregivers')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        _availability = AvailabilityModel.fromJson(doc.data()!);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to refresh availability: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update availability schedule (future enhancement)
  Future<void> updateSchedule(Map<String, dynamic> schedule) async {
    if (_availability == null) return;

    _setLoading(true);
    _clearError();

    try {
      final newAvailability = _availability!.copyWith(
        schedule: schedule,
        lastAvailabilityUpdate: DateTime.now(),
      );

      // Update local state
      _availability = newAvailability;

      // Update Firestore
      await _firestore
          .collection('caregivers')
          .doc(_auth.currentUser!.uid)
          .update(newAvailability.toJson());

      notifyListeners();
    } catch (e) {
      _setError('Failed to update schedule: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get availability statistics
  Future<Map<String, dynamic>> getAvailabilityStats() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    try {
      final doc = await _firestore
          .collection('caregivers')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final lastUpdate = (data['lastAvailabilityUpdate'] as Timestamp).toDate();
        final now = DateTime.now();
        final timeSinceUpdate = now.difference(lastUpdate);

        return {
          'lastUpdate': lastUpdate,
          'timeSinceUpdate': timeSinceUpdate,
          'formattedTimeSinceUpdate': _formatDuration(timeSinceUpdate),
          'totalOnlineTime': data['totalOnlineTime'] ?? 0,
          'totalBookings': data['totalBookings'] ?? 0,
        };
      }
      return {};
    } catch (e) {
      _setError('Failed to get availability stats: $e');
      return {};
    }
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

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Dispose method
  @override
  void dispose() {
    super.dispose();
  }
} 
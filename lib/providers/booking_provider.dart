// ignore_for_file: avoid_print

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import '../services/google_maps_service.dart';

class BookingProvider with ChangeNotifier {
  final BookingService _bookingService = BookingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<BookingModel> _bookings = [];
  List<BookingModel> _upcomingBookings = [];
  List<BookingModel> _completedBookings = [];
  BookingModel? _selectedBooking;
  bool _isLoading = false;
  String? _error;
  String? _userRole;

  // Getters
  List<BookingModel> get bookings => _bookings;
  List<BookingModel> get upcomingBookings => _upcomingBookings;
  List<BookingModel> get completedBookings => _completedBookings;
  BookingModel? get selectedBooking => _selectedBooking;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userRole => _userRole;

  // Set user role manually

  // Initialize booking provider
  Future<void> initialize() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _setLoading(true);
    _clearError();

    try {
      // First, try to fix any existing bookings with empty IDs
      try {
        await _bookingService.fixExistingBookings();
        await _bookingService.testCaregiverIds(); // Test caregiver document IDs
      } catch (e) {
        print('Warning: Could not run booking migration: $e');
      }

      // Get user role from auth service
      if (_userRole == null) {
        // Try to determine role from user data
        try {
          final authService = AuthService();
          final userData = await authService.getCurrentUserData();
          _userRole = userData?.role ?? 'CareSeeker'; // Default for careseeker
        } catch (e) {
          _userRole = 'CareSeeker'; // Fallback
        }
      }

      // If user is a caregiver, ensure their document uses Firebase Auth UID
      if (_userRole == 'CALiNGApro') {
        try {
          final GoogleMapsService mapsService = GoogleMapsService();
          await mapsService.ensureCaregiverDocumentId(user.uid);
        } catch (e) {
          print('Warning: Could not fix caregiver document ID: $e');
        }
      }

      // Load all bookings
      await loadBookings();

      // Load upcoming and completed bookings
      await loadUpcomingBookings();
      await loadCompletedBookings();
    } catch (e) {
      _setError('Failed to initialize bookings: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load all bookings for current user
  Future<void> loadBookings() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('DEBUG: No current user, cannot load bookings');
      return;
    }

    print(
      'DEBUG: Loading bookings for user: ${user.uid} with role: $_userRole',
    );
    _setLoading(true);
    _clearError();

    try {
      _bookings = await _bookingService.getUserBookings(
        user.uid,
        role: _userRole,
      );
      print('DEBUG: Loaded ${_bookings.length} bookings');
      _categorizeBookings(); // Categorize bookings after loading
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error loading bookings: $e');
      _setError('Failed to load bookings: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Categorize bookings into upcoming and completed
  void _categorizeBookings() {
    _upcomingBookings = _bookings
        .where(
          (booking) =>
              booking.status == 'pending' || booking.status == 'confirmed',
        )
        .toList();

    _completedBookings = _bookings
        .where((booking) => booking.status == 'completed')
        .toList();

    // Sort upcoming by date (earliest first)
    _upcomingBookings.sort(
      (a, b) => _parseScheduleDate(
        a.schedule['date'],
      ).compareTo(_parseScheduleDate(b.schedule['date'])),
    );

    // Sort completed by date (most recent first)
    _completedBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // Helper method to safely parse schedule date
  DateTime _parseScheduleDate(dynamic value) {
    if (value == null) {
      return DateTime.now();
    } else if (value is Timestamp) {
      return value.toDate();
    } else if (value is DateTime) {
      return value;
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else {
      return DateTime.now();
    }
  }

  // Load upcoming bookings
  Future<void> loadUpcomingBookings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Use categorization from existing bookings since we already have all data
      _categorizeBookings();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load upcoming bookings: $e');
    }
  }

  // Load completed bookings
  Future<void> loadCompletedBookings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Use categorization from existing bookings since we already have all data
      _categorizeBookings();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load completed bookings: $e');
    }
  }

  // Create new booking
  Future<bool> createBooking(BookingModel booking) async {
    _setLoading(true);
    _clearError();

    try {
      final bookingId = await _bookingService.createBooking(booking);

      // Add to local list
      final newBooking = booking.copyWith(bookingId: bookingId);
      _bookings.insert(0, newBooking);

      // Update upcoming bookings if applicable
      if (newBooking.isPending || newBooking.isConfirmed) {
        _upcomingBookings.add(newBooking);
        _upcomingBookings.sort(
          (a, b) => a.schedule['date'].compareTo(b.schedule['date']),
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to create booking: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update booking status
  Future<bool> updateBookingStatus(String bookingId, String newStatus) async {
    _setLoading(true);
    _clearError();

    try {
      await _bookingService.updateBookingStatus(bookingId, newStatus);

      // Update local booking
      final index = _bookings.indexWhere((b) => b.bookingId == bookingId);
      if (index != -1) {
        _bookings[index] = _bookings[index].copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
      }

      // Update upcoming bookings
      final upcomingIndex = _upcomingBookings.indexWhere(
        (b) => b.bookingId == bookingId,
      );
      if (upcomingIndex != -1) {
        if (newStatus == 'completed' || newStatus == 'cancelled') {
          _upcomingBookings.removeAt(upcomingIndex);
        } else {
          _upcomingBookings[upcomingIndex] = _upcomingBookings[upcomingIndex]
              .copyWith(status: newStatus, updatedAt: DateTime.now());
        }
      }

      // Update completed bookings if status is completed
      if (newStatus == 'completed') {
        final completedBooking = _bookings.firstWhere(
          (b) => b.bookingId == bookingId,
        );
        _completedBookings.add(completedBooking);
        _completedBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update booking status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add rating and review
  Future<bool> addRatingAndReview(
    String bookingId,
    double rating,
    String review,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      await _bookingService.addRatingAndReview(bookingId, rating, review);

      // Update local booking
      final index = _bookings.indexWhere((b) => b.bookingId == bookingId);
      if (index != -1) {
        _bookings[index] = _bookings[index].copyWith(
          rating: rating,
          review: review,
          updatedAt: DateTime.now(),
        );
      }

      // Update completed bookings
      final completedIndex = _completedBookings.indexWhere(
        (b) => b.bookingId == bookingId,
      );
      if (completedIndex != -1) {
        _completedBookings[completedIndex] = _completedBookings[completedIndex]
            .copyWith(
              rating: rating,
              review: review,
              updatedAt: DateTime.now(),
            );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add rating and review: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Cancel booking
  Future<bool> cancelBooking(String bookingId, String reason) async {
    return await updateBookingStatus(bookingId, 'cancelled');
  }

  // Get booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      return await _bookingService.getBookingById(bookingId);
    } catch (e) {
      _setError('Failed to get booking: $e');
      return null;
    }
  }

  // Select booking for detailed view
  void selectBooking(BookingModel booking) {
    _selectedBooking = booking;
    notifyListeners();
  }

  // Clear selected booking
  void clearSelectedBooking() {
    _selectedBooking = null;
    notifyListeners();
  }

  // Get bookings by status
  List<BookingModel> getBookingsByStatus(String status) {
    return _bookings.where((booking) => booking.status == status).toList();
  }

  // Get today's bookings for caregiver dashboard
  List<BookingModel> getTodaysBookings() {
    final today = DateTime.now();
    return _bookings.where((booking) {
      final bookingDate = _parseScheduleDate(booking.schedule['date']);

      return bookingDate.year == today.year &&
          bookingDate.month == today.month &&
          bookingDate.day == today.day &&
          (booking.status == 'pending' ||
              booking.status == 'confirmed' ||
              booking.status == 'in-progress');
    }).toList();
  }

  // Get booking statistics
  Map<String, dynamic> getBookingStats() {
    final totalBookings = _bookings.length;
    final pendingBookings = _bookings.where((b) => b.isPending).length;
    final confirmedBookings = _bookings.where((b) => b.isConfirmed).length;
    final completedBookings = _bookings.where((b) => b.isCompleted).length;
    final cancelledBookings = _bookings.where((b) => b.isCancelled).length;
    final todaysBookings = getTodaysBookings().length;

    double totalEarnings = 0;
    if (_userRole == 'CALiNGApro') {
      totalEarnings = _bookings
          .where((b) => b.isCompleted)
          .fold(
            0,
            (sum, booking) => sum + (booking.serviceDetails['totalCost'] ?? 0),
          );
    }

    return {
      'totalBookings': totalBookings,
      'pendingBookings': pendingBookings,
      'confirmedBookings': confirmedBookings,
      'completedBookings': completedBookings,
      'cancelledBookings': cancelledBookings,
      'todaysBookings': todaysBookings,
      'totalEarnings': totalEarnings,
    };
  }

  // Refresh all booking data
  Future<void> refresh() async {
    await loadBookings();
    await loadUpcomingBookings();
    await loadCompletedBookings();
  }

  // Stream bookings for real-time updates
  void startBookingStream() {
    final user = _auth.currentUser;
    if (user == null) return;

    _bookingService
        .streamUserBookings(user.uid, role: _userRole)
        .listen(
          (bookings) {
            _bookings = bookings;
            _upcomingBookings = bookings
                .where((b) => b.isPending || b.isConfirmed)
                .toList();
            _completedBookings = bookings.where((b) => b.isCompleted).toList();
            notifyListeners();
          },
          onError: (error) {
            _setError('Booking stream error: $error');
          },
        );
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

  // Set user role
  void setUserRole(String role) {
    _userRole = role;
    notifyListeners();
  }

  // Accept a booking (change status to confirmed)
  Future<bool> acceptBooking(String bookingId) async {
    try {
      await _bookingService.updateBookingStatus(bookingId, 'confirmed');
      await refresh(); // Refresh the bookings list
      return true;
    } catch (e) {
      _setError('Failed to accept booking: $e');
      return false;
    }
  }

  // Decline a booking (change status to cancelled)
  Future<bool> declineBooking(String bookingId) async {
    try {
      await _bookingService.updateBookingStatus(bookingId, 'cancelled');
      await refresh(); // Refresh the bookings list
      return true;
    } catch (e) {
      _setError('Failed to decline booking: $e');
      return false;
    }
  }

  // Dispose method
  @override
  void dispose() {
    super.dispose();
  }
}

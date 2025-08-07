import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

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

  // Initialize booking provider
  Future<void> initialize() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _setLoading(true);
    _clearError();

    try {
      // Get user role from auth service
      // TODO: Implement role detection or pass from auth service
      _userRole = 'CareSeeker'; // Default for now

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
    if (user == null) return;

    _setLoading(true);
    _clearError();

    try {
      _bookings = await _bookingService.getUserBookings(user.uid, role: _userRole);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load bookings: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load upcoming bookings
  Future<void> loadUpcomingBookings() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _upcomingBookings = await _bookingService.getUpcomingBookings(user.uid, role: _userRole);
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
      _completedBookings = await _bookingService.getCompletedBookings(user.uid, role: _userRole);
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
        _upcomingBookings.sort((a, b) => a.schedule['date'].compareTo(b.schedule['date']));
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
      final upcomingIndex = _upcomingBookings.indexWhere((b) => b.bookingId == bookingId);
      if (upcomingIndex != -1) {
        if (newStatus == 'completed' || newStatus == 'cancelled') {
          _upcomingBookings.removeAt(upcomingIndex);
        } else {
          _upcomingBookings[upcomingIndex] = _upcomingBookings[upcomingIndex].copyWith(
            status: newStatus,
            updatedAt: DateTime.now(),
          );
        }
      }

      // Update completed bookings if status is completed
      if (newStatus == 'completed') {
        final completedBooking = _bookings.firstWhere((b) => b.bookingId == bookingId);
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
  Future<bool> addRatingAndReview(String bookingId, double rating, String review) async {
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
      final completedIndex = _completedBookings.indexWhere((b) => b.bookingId == bookingId);
      if (completedIndex != -1) {
        _completedBookings[completedIndex] = _completedBookings[completedIndex].copyWith(
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

  // Get booking statistics
  Map<String, dynamic> getBookingStats() {
    final totalBookings = _bookings.length;
    final pendingBookings = _bookings.where((b) => b.isPending).length;
    final confirmedBookings = _bookings.where((b) => b.isConfirmed).length;
    final completedBookings = _bookings.where((b) => b.isCompleted).length;
    final cancelledBookings = _bookings.where((b) => b.isCancelled).length;

    double totalEarnings = 0;
    if (_userRole == 'CALiNGApro') {
      totalEarnings = _bookings
          .where((b) => b.isCompleted)
          .fold(0, (sum, booking) => sum + (booking.serviceDetails['totalCost'] ?? 0));
    }

    return {
      'totalBookings': totalBookings,
      'pendingBookings': pendingBookings,
      'confirmedBookings': confirmedBookings,
      'completedBookings': completedBookings,
      'cancelledBookings': cancelledBookings,
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

    _bookingService.streamUserBookings(user.uid, role: _userRole).listen(
      (bookings) {
        _bookings = bookings;
        _upcomingBookings = bookings.where((b) => b.isPending || b.isConfirmed).toList();
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

  // Dispose method
  @override
  void dispose() {
    super.dispose();
  }
} 
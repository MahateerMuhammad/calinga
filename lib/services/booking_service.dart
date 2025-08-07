import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new booking
  Future<String> createBooking(BookingModel booking) async {
    try {
      final docRef = await _firestore.collection('bookings').add(booking.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  // Get bookings for a specific user (caregiver or care seeker)
  Future<List<BookingModel>> getUserBookings(String userId, {String? role}) async {
    try {
      Query query = _firestore.collection('bookings');
      
      if (role == 'CALiNGApro') {
        query = query.where('caregiver.id', isEqualTo: userId);
      } else {
        query = query.where('careSeekerId', isEqualTo: userId);
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => BookingModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch bookings: $e');
    }
  }

  // Get bookings by status
  Future<List<BookingModel>> getBookingsByStatus(String userId, String status, {String? role}) async {
    try {
      Query query = _firestore.collection('bookings');
      
      if (role == 'CALiNGApro') {
        query = query.where('caregiver.id', isEqualTo: userId);
      } else {
        query = query.where('careSeekerId', isEqualTo: userId);
      }
      
      query = query.where('status', isEqualTo: status);
      query = query.orderBy('createdAt', descending: true);
      
      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => BookingModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch bookings by status: $e');
    }
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Add rating and review to booking
  Future<void> addRatingAndReview(String bookingId, double rating, String review) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'rating': rating,
        'review': review,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add rating and review: $e');
    }
  }

  // Get booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      if (doc.exists) {
        return BookingModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch booking: $e');
    }
  }

  // Cancel booking
  Future<void> cancelBooking(String bookingId, String reason) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  // Get upcoming bookings
  Future<List<BookingModel>> getUpcomingBookings(String userId, {String? role}) async {
    try {
      final now = DateTime.now();
      Query query = _firestore.collection('bookings');
      
      if (role == 'CALiNGApro') {
        query = query.where('caregiver.id', isEqualTo: userId);
      } else {
        query = query.where('careSeekerId', isEqualTo: userId);
      }
      
      query = query.where('status', whereIn: ['pending', 'confirmed']);
      query = query.where('schedule.date', isGreaterThan: Timestamp.fromDate(now));
      query = query.orderBy('schedule.date');
      
      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => BookingModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch upcoming bookings: $e');
    }
  }

  // Get completed bookings
  Future<List<BookingModel>> getCompletedBookings(String userId, {String? role}) async {
    try {
      Query query = _firestore.collection('bookings');
      
      if (role == 'CALiNGApro') {
        query = query.where('caregiver.id', isEqualTo: userId);
      } else {
        query = query.where('careSeekerId', isEqualTo: userId);
      }
      
      query = query.where('status', isEqualTo: 'completed');
      query = query.orderBy('createdAt', descending: true);
      
      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => BookingModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch completed bookings: $e');
    }
  }

  // Stream for real-time booking updates
  Stream<List<BookingModel>> streamUserBookings(String userId, {String? role}) {
    Query query = _firestore.collection('bookings');
    
    if (role == 'CALiNGApro') {
      query = query.where('caregiver.id', isEqualTo: userId);
    } else {
      query = query.where('careSeekerId', isEqualTo: userId);
    }
    
    query = query.orderBy('createdAt', descending: true);
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BookingModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Get booking statistics
  Future<Map<String, dynamic>> getBookingStats(String userId, {String? role}) async {
    try {
      final allBookings = await getUserBookings(userId, role: role);
      
      final totalBookings = allBookings.length;
      final pendingBookings = allBookings.where((b) => b.isPending).length;
      final confirmedBookings = allBookings.where((b) => b.isConfirmed).length;
      final completedBookings = allBookings.where((b) => b.isCompleted).length;
      final cancelledBookings = allBookings.where((b) => b.isCancelled).length;
      
      double totalEarnings = 0;
      if (role == 'CALiNGApro') {
        totalEarnings = allBookings
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
    } catch (e) {
      throw Exception('Failed to fetch booking statistics: $e');
    }
  }
} 
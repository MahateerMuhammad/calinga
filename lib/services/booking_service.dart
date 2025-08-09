import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new booking
  Future<String> createBooking(BookingModel booking) async {
    try {
      // Create booking with proper ID structure
      final bookingData = booking.toJson();
      final docRef = await _firestore.collection('bookings').add(bookingData);

      // Update the document to include its own ID as bookingId
      await docRef.update({'bookingId': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  // Get bookings for a specific user (caregiver or care seeker)
  Future<List<BookingModel>> getUserBookings(
    String userId, {
    String? role,
  }) async {
    try {
      print('DEBUG: Getting bookings for user $userId with role: $role');

      // First, let's see ALL bookings to understand the data structure
      final allBookingsQuery = await _firestore
          .collection('bookings')
          .limit(5)
          .get();
      print('DEBUG: Sample of ALL bookings in database:');
      for (final doc in allBookingsQuery.docs) {
        final data = doc.data();
        final caregiverData = data['caregiver'];
        final careSeekerId = data['careSeekerId'];
        print(
          'DEBUG: Sample Booking ${doc.id} - careSeekerId: $careSeekerId, caregiver: $caregiverData',
        );
      }

      Query query = _firestore.collection('bookings');

      if (role == 'CALiNGApro') {
        print('DEBUG: Searching for caregiver.id == $userId');
        query = query.where('caregiver.id', isEqualTo: userId);
      } else {
        print('DEBUG: Searching for careSeekerId == $userId');
        query = query.where('careSeekerId', isEqualTo: userId);
      }

      query = query.orderBy('createdAt', descending: true);

      final querySnapshot = await query.get();
      final bookings = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Always use document ID as bookingId to ensure consistency
        data['bookingId'] = doc.id;

        // Debug: Check if booking actually belongs to the user
        if (role == 'CALiNGApro') {
          final caregiverData = data['caregiver'] as Map<String, dynamic>?;
          final caregiverId = caregiverData?['id'];
          print(
            'DEBUG: Booking ${doc.id} - Expected CaregiverId: $userId, Actual: $caregiverId, Match: ${caregiverId == userId}',
          );
        } else {
          final careSeekerId = data['careSeekerId'];
          print(
            'DEBUG: Booking ${doc.id} - Expected CareSeekerID: $userId, Actual: $careSeekerId, Match: ${careSeekerId == userId}',
          );
        }

        return BookingModel.fromJson(data);
      }).toList();

      print(
        'DEBUG: Found ${bookings.length} bookings for user $userId with role $role',
      );
      return bookings;
    } catch (e) {
      throw Exception('Failed to fetch bookings: $e');
    }
  }

  // Get bookings by status
  Future<List<BookingModel>> getBookingsByStatus(
    String userId,
    String status, {
    String? role,
  }) async {
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
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Always use document ID as bookingId to ensure consistency
        data['bookingId'] = doc.id;
        return BookingModel.fromJson(data);
      }).toList();
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
  Future<void> addRatingAndReview(
    String bookingId,
    double rating,
    String review,
  ) async {
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
        final data = doc.data() as Map<String, dynamic>;
        // Always use document ID as bookingId to ensure consistency
        data['bookingId'] = doc.id;
        return BookingModel.fromJson(data);
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
  Future<List<BookingModel>> getUpcomingBookings(
    String userId, {
    String? role,
  }) async {
    try {
      final now = DateTime.now();
      Query query = _firestore.collection('bookings');

      if (role == 'CALiNGApro') {
        query = query.where('caregiver.id', isEqualTo: userId);
      } else {
        query = query.where('careSeekerId', isEqualTo: userId);
      }

      query = query.where('status', whereIn: ['pending', 'confirmed']);
      query = query.where(
        'schedule.date',
        isGreaterThan: Timestamp.fromDate(now),
      );
      query = query.orderBy('schedule.date');

      final querySnapshot = await query.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Always use document ID as bookingId to ensure consistency
        data['bookingId'] = doc.id;
        return BookingModel.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch upcoming bookings: $e');
    }
  }

  // Get completed bookings
  Future<List<BookingModel>> getCompletedBookings(
    String userId, {
    String? role,
  }) async {
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
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Always use document ID as bookingId to ensure consistency
        data['bookingId'] = doc.id;
        return BookingModel.fromJson(data);
      }).toList();
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
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['bookingId'] = doc.id; // Ensure document ID is included
        return BookingModel.fromJson(data);
      }).toList();
    });
  }

  // Get booking statistics
  Future<Map<String, dynamic>> getBookingStats(
    String userId, {
    String? role,
  }) async {
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
            .fold(
              0,
              (sum, booking) =>
                  sum + (booking.serviceDetails['totalCost'] ?? 0),
            );
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

  // Migration method to fix existing bookings with empty bookingId
  Future<void> fixExistingBookings() async {
    try {
      print('Starting booking ID migration...');

      // Get all booking documents
      final querySnapshot = await _firestore.collection('bookings').get();

      int fixedCount = 0;
      for (final doc in querySnapshot.docs) {
        final data = doc.data();

        // Log the booking structure for debugging
        final caregiverData = data['caregiver'] as Map<String, dynamic>?;
        final caregiverId = caregiverData?['id'];
        final careSeekerId = data['careSeekerId'];

        print(
          'DEBUG: Booking ${doc.id} - CareSeekerID: $careSeekerId, CaregiverID: $caregiverId, Status: ${data['status']}',
        );

        // If bookingId is null or empty, update it with document ID
        if (data['bookingId'] == null || data['bookingId'].toString().isEmpty) {
          await doc.reference.update({'bookingId': doc.id});
          fixedCount++;
          print('Fixed booking: ${doc.id}');
        }
      }

      print('Migration completed. Fixed $fixedCount bookings.');
    } catch (e) {
      print('Migration failed: $e');
      throw Exception('Failed to fix existing bookings: $e');
    }
  }

  // Quick test method to verify caregiver document IDs
  Future<void> testCaregiverIds() async {
    try {
      print('DEBUG: Testing caregiver document IDs...');
      final caregivers = await _firestore
          .collection('caregivers')
          .limit(3)
          .get();

      for (final doc in caregivers.docs) {
        final data = doc.data();
        final userUid = data['uid'] ?? data['userId'] ?? 'NO_UID_FIELD';
        print(
          'DEBUG: Caregiver Doc ID: ${doc.id}, UID Field: $userUid, Match: ${doc.id == userUid}',
        );
      }
    } catch (e) {
      print('DEBUG: Error testing caregiver IDs: $e');
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/booking_card.dart';

class AllBookingsScreen extends StatefulWidget {
  const AllBookingsScreen({super.key});

  @override
  State<AllBookingsScreen> createState() => _AllBookingsScreenState();
}

class _AllBookingsScreenState extends State<AllBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM d, yyyy').format(date);
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

  // Helper method to safely extract substring
  String _getSafeSubstring(String? text, int maxLength) {
    if (text == null || text.isEmpty) {
      return 'N/A';
    }
    return text.length > maxLength ? text.substring(0, maxLength) : text;
  }

  // Accept a booking
  Future<void> _acceptBooking(BuildContext context, String? bookingId) async {
    if (bookingId == null || bookingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid booking ID - cannot accept booking'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );
    final success = await bookingProvider.acceptBooking(bookingId);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Booking accepted successfully!'
              : 'Failed to accept booking',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  // Decline a booking
  Future<void> _declineBooking(BuildContext context, String? bookingId) async {
    if (bookingId == null || bookingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid booking ID - cannot decline booking'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final shouldDecline = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Decline Booking'),
          content: const Text('Are you sure you want to decline this booking?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Decline'),
            ),
          ],
        );
      },
    );

    if (shouldDecline != true) return;

    final bookingProvider = Provider.of<BookingProvider>(
      context,
      listen: false,
    );
    final success = await bookingProvider.declineBooking(bookingId);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Booking declined successfully!'
              : 'Failed to decline booking',
        ),
        backgroundColor: success ? Colors.orange : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, _) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text(
              'All Bookings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.orange,
              labelColor: Colors.orange,
              unselectedLabelColor: Colors.grey[600],
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Completed'),
                Tab(text: 'All'),
              ],
            ),
          ),
          body: bookingProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Upcoming Bookings Tab
                    _buildBookingsList(
                      bookingProvider.upcomingBookings,
                      'upcoming',
                    ),

                    // Completed Bookings Tab
                    _buildBookingsList(
                      bookingProvider.completedBookings,
                      'completed',
                    ),

                    // All Bookings Tab
                    _buildBookingsList(bookingProvider.bookings, 'all'),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildBookingsList(List bookings, String type) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                color: Colors.grey[400],
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              type == 'upcoming'
                  ? 'No upcoming bookings'
                  : type == 'completed'
                  ? 'No completed bookings'
                  : 'No bookings yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'upcoming'
                  ? 'New bookings will appear here'
                  : type == 'completed'
                  ? 'Completed bookings will appear here'
                  : 'Start accepting bookings to see them here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async =>
          Provider.of<BookingProvider>(context, listen: false).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking.toJson(), type == 'upcoming');
        },
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, bool isUpcoming) {
    final Color statusColor =
        booking['status'] == 'confirmed' || booking['status'] == 'completed'
        ? Colors.green
        : booking['status'] == 'pending'
        ? Colors.orange
        : booking['status'] == 'in-progress'
        ? Colors.blue
        : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with booking ID and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Booking',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking['status'].toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Care seeker info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.person, size: 20, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Care Seeker',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        booking['serviceDetails']?['type'] ?? 'Care Service',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\$${booking['serviceDetails']?['totalCost']?.toStringAsFixed(0) ?? '0'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Date and time
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  _formatDate(_parseScheduleDate(booking['schedule']?['date'])),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${booking['schedule']?['startTime'] ?? ''} - ${booking['schedule']?['endTime'] ?? ''}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Location
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    booking['location']?['address'] ?? 'Location not specified',
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isUpcoming && booking['status'] == 'pending')
                  OutlinedButton(
                    onPressed: () =>
                        _acceptBooking(context, booking['bookingId']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                    ),
                    child: const Text('Accept'),
                  ),
                if (isUpcoming && booking['status'] == 'pending')
                  const SizedBox(width: 8),
                if (isUpcoming && booking['status'] != 'cancelled')
                  OutlinedButton(
                    onPressed: () =>
                        _declineBooking(context, booking['bookingId']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: Text(
                      booking['status'] == 'pending' ? 'Decline' : 'Cancel',
                    ),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // View details logic
                  },
                  child: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

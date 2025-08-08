import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utils/constants.dart';
import '../../providers/booking_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(
      () => Provider.of<BookingProvider>(context, listen: false).initialize(),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('EEE, MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Bookings'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
              ],
            ),
          ),
          body: bookingProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Upcoming Bookings Tab
                    bookingProvider.upcomingBookings.isEmpty
                        ? const Center(child: Text('No upcoming bookings'))
                        : RefreshIndicator(
                            onRefresh: () async => bookingProvider.refresh(),
                            child: ListView.builder(
                              itemCount:
                                  bookingProvider.upcomingBookings.length,
                              itemBuilder: (context, index) {
                                final booking =
                                    bookingProvider.upcomingBookings[index];
                                return _buildBookingCard(
                                  booking.toJson(),
                                  isUpcoming: true,
                                );
                              },
                            ),
                          ),

                    // Past Bookings Tab
                    bookingProvider.completedBookings.isEmpty
                        ? const Center(child: Text('No past bookings'))
                        : RefreshIndicator(
                            onRefresh: () async => bookingProvider.refresh(),
                            child: ListView.builder(
                              itemCount:
                                  bookingProvider.completedBookings.length,
                              itemBuilder: (context, index) {
                                final booking =
                                    bookingProvider.completedBookings[index];
                                return _buildBookingCard(
                                  booking.toJson(),
                                  isUpcoming: false,
                                );
                              },
                            ),
                          ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildBookingCard(
    Map<String, dynamic> booking, {
    required bool isUpcoming,
  }) {
    final Color statusColor =
        booking['status'] == 'confirmed' || booking['status'] == 'completed'
        ? Colors.green
        : booking['status'] == 'pending'
        ? Colors.orange
        : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking #${booking['bookingId'] ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    booking['status'],
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),

            // Caregiver Info
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey.shade200,
                  child: const Icon(Icons.person, size: 25, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['caregiver']?['name'] ?? 'Caregiver',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      booking['caregiver']?['role'] ?? 'Role',
                      style: TextStyle(color: AppConstants.primaryColor),
                    ),
                    if (!isUpcoming &&
                        booking['status'] == 'completed' &&
                        booking['rating'] != null)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text('${booking['rating']}'),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date and Time
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  _formatDate(
                    (booking['schedule']?['date'] as Timestamp).toDate(),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${booking['schedule']?['startTime']} - ${booking['schedule']?['endTime']}',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Address
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(booking['location']?['address'] ?? '')),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isUpcoming && booking['status'] != 'cancelled')
                  OutlinedButton(
                    onPressed: () {
                      // Cancel booking
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Cancel'),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // View details
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

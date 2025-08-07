import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Dummy data for bookings
  final List<Map<String, dynamic>> _upcomingBookings = [
    {
      'id': '1001',
      'caregiverName': 'Sarah Johnson',
      'role': 'CNA',
      'date': DateTime.now().add(const Duration(days: 2)),
      'startTime': '09:00 AM',
      'endTime': '11:00 AM',
      'address': '123 Main St, Anytown, CA 12345',
      'status': 'Confirmed',
    },
    {
      'id': '1002',
      'caregiverName': 'Michael Chen',
      'role': 'RN',
      'date': DateTime.now().add(const Duration(days: 5)),
      'startTime': '02:00 PM',
      'endTime': '04:00 PM',
      'address': '123 Main St, Anytown, CA 12345',
      'status': 'Pending',
    },
  ];

  final List<Map<String, dynamic>> _pastBookings = [
    {
      'id': '1003',
      'caregiverName': 'Emily Rodriguez',
      'role': 'HHA',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'startTime': '10:00 AM',
      'endTime': '12:00 PM',
      'address': '123 Main St, Anytown, CA 12345',
      'status': 'Completed',
      'rating': 4.5,
    },
    {
      'id': '1004',
      'caregiverName': 'David Kim',
      'role': 'PT',
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'startTime': '03:00 PM',
      'endTime': '04:00 PM',
      'address': '123 Main St, Anytown, CA 12345',
      'status': 'Completed',
      'rating': 5.0,
    },
    {
      'id': '1005',
      'caregiverName': 'Lisa Patel',
      'role': 'LVN',
      'date': DateTime.now().subtract(const Duration(days: 14)),
      'startTime': '11:00 AM',
      'endTime': '01:00 PM',
      'address': '123 Main St, Anytown, CA 12345',
      'status': 'Cancelled',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      body: TabBarView(
        controller: _tabController,
        children: [
          // Upcoming Bookings Tab
          _upcomingBookings.isEmpty
              ? const Center(child: Text('No upcoming bookings'))
              : ListView.builder(
                  itemCount: _upcomingBookings.length,
                  itemBuilder: (context, index) {
                    final booking = _upcomingBookings[index];
                    return _buildBookingCard(booking, isUpcoming: true);
                  },
                ),

          // Past Bookings Tab
          _pastBookings.isEmpty
              ? const Center(child: Text('No past bookings'))
              : ListView.builder(
                  itemCount: _pastBookings.length,
                  itemBuilder: (context, index) {
                    final booking = _pastBookings[index];
                    return _buildBookingCard(booking, isUpcoming: false);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(
    Map<String, dynamic> booking, {
    required bool isUpcoming,
  }) {
    final Color statusColor =
        booking['status'] == 'Confirmed' || booking['status'] == 'Completed'
        ? Colors.green
        : booking['status'] == 'Pending'
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
                  'Booking #${booking['id']}',
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
                      booking['caregiverName'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      booking['role'],
                      style: TextStyle(color: AppConstants.primaryColor),
                    ),
                    if (!isUpcoming && booking['status'] == 'Completed')
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
                Text(_formatDate(booking['date'])),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text('${booking['startTime']} - ${booking['endTime']}'),
              ],
            ),
            const SizedBox(height: 8),

            // Address
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(booking['address'])),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isUpcoming && booking['status'] != 'Cancelled')
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

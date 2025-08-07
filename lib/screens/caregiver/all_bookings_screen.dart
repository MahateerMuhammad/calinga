import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';

class AllBookingsScreen extends StatefulWidget {
  const AllBookingsScreen({super.key});

  @override
  State<AllBookingsScreen> createState() => _AllBookingsScreenState();
}

class _AllBookingsScreenState extends State<AllBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  // Dummy data for bookings
  final List<Map<String, dynamic>> _upcomingBookings = [
    {
      'id': '1001',
      'clientName': 'John Doe',
      'date': DateTime.now().add(const Duration(days: 2)),
      'startTime': '09:00 AM',
      'endTime': '11:00 AM',
      'address': '123 Main St, Anytown, CA 12345',
      'status': 'Confirmed',
      'notes': 'Client needs assistance with mobility exercises.',
    },
    {
      'id': '1002',
      'clientName': 'Jane Smith',
      'date': DateTime.now().add(const Duration(days: 5)),
      'startTime': '02:00 PM',
      'endTime': '04:00 PM',
      'address': '456 Oak St, Anytown, CA 12345',
      'status': 'Pending',
      'notes': 'First-time client. Needs help with medication management.',
    },
  ];

  final List<Map<String, dynamic>> _pastBookings = [
    {
      'id': '1003',
      'clientName': 'Robert Johnson',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'startTime': '10:00 AM',
      'endTime': '12:00 PM',
      'address': '789 Pine St, Anytown, CA 12345',
      'status': 'Completed',
      'notes': 'Client was satisfied with the service.',
      'earnings': 50.0,
    },
    {
      'id': '1004',
      'clientName': 'Mary Williams',
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'startTime': '03:00 PM',
      'endTime': '04:00 PM',
      'address': '101 Elm St, Anytown, CA 12345',
      'status': 'Completed',
      'notes': 'Client requested same caregiver for next appointment.',
      'earnings': 25.0,
    },
    {
      'id': '1005',
      'clientName': 'David Brown',
      'date': DateTime.now().subtract(const Duration(days: 14)),
      'startTime': '11:00 AM',
      'endTime': '01:00 PM',
      'address': '202 Maple St, Anytown, CA 12345',
      'status': 'Cancelled',
      'notes': 'Client cancelled due to personal emergency.',
      'earnings': 0.0,
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
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

            // Client Info
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
                      booking['clientName'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (!isUpcoming && booking['status'] == 'Completed')
                      Text(
                        'Earnings: \$${booking['earnings']}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
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
            const SizedBox(height: 8),

            // Notes
            if (booking['notes'] != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking['notes'],
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

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
                if (isUpcoming && booking['status'] == 'Confirmed')
                  OutlinedButton(
                    onPressed: () {
                      // Navigate to client's location
                    },
                    child: const Text('Navigate'),
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

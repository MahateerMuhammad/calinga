// ignore_for_file: unused_import, deprecated_member_use, use_super_parameters

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../utils/constants.dart';
import 'availability_status_indicator.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onRate;
  final bool showActions;
  final bool isCompact;

  const BookingCard({
    Key? key,
    required this.booking,
    this.onTap,
    this.onCancel,
    this.onRate,
    this.showActions = true,
    this.isCompact = false,
  }) : super(key: key);

  // Helper method to safely extract substring
  String _getSafeSubstring(String? text, int maxLength) {
    if (text == null || text.isEmpty) {
      return 'N/A';
    }
    return text.length > maxLength ? text.substring(0, maxLength) : text;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Care Service',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStatusChip(),
                      ],
                    ),
                  ),
                  if (showActions && !isCompact) ...[
                    if (booking.isPending || booking.isConfirmed)
                      IconButton(
                        onPressed: onCancel,
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'Cancel Booking',
                      ),
                    if (booking.canBeRated)
                      IconButton(
                        onPressed: onRate,
                        icon: const Icon(Icons.star, color: Colors.amber),
                        tooltip: 'Rate Service',
                      ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Caregiver info
              _buildCaregiverInfo(),

              const SizedBox(height: 12),

              // Service details
              _buildServiceDetails(),

              const SizedBox(height: 12),

              // Schedule
              _buildScheduleInfo(),

              const SizedBox(height: 12),

              // Location
              _buildLocationInfo(),

              // Special requirements
              if (booking.specialRequirements != null &&
                  booking.specialRequirements!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildSpecialRequirements(),
              ],

              // Rating (if completed)
              if (booking.rating != null) ...[
                const SizedBox(height: 12),
                _buildRatingInfo(),
              ],

              // Actions for compact view
              if (showActions && isCompact) ...[
                const SizedBox(height: 12),
                _buildCompactActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color chipColor;
    String statusText;
    IconData statusIcon;

    switch (booking.status) {
      case 'pending':
        chipColor = Colors.orange;
        statusText = 'Pending';
        statusIcon = Icons.schedule;
        break;
      case 'confirmed':
        chipColor = Colors.blue;
        statusText = 'Confirmed';
        statusIcon = Icons.check_circle;
        break;
      case 'in-progress':
        chipColor = Colors.purple;
        statusText = 'In Progress';
        statusIcon = Icons.play_circle;
        break;
      case 'completed':
        chipColor = Colors.green;
        statusText = 'Completed';
        statusIcon = Icons.done_all;
        break;
      case 'cancelled':
        chipColor = Colors.red;
        statusText = 'Cancelled';
        statusIcon = Icons.cancel;
        break;
      default:
        chipColor = Colors.grey;
        statusText = 'Unknown';
        statusIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: chipColor, size: 14),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaregiverInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[300],
          backgroundImage: booking.caregiver['profileImage'] != null
              ? NetworkImage(booking.caregiver['profileImage'])
              : null,
          child: booking.caregiver['profileImage'] == null
              ? const Icon(Icons.person, color: Colors.grey)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.caregiver['name'] ?? 'Unknown Caregiver',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                booking.caregiver['role'] ?? 'Caregiver',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
        ),
        if (booking.caregiver['isAvailable'] != null)
          AvailabilityStatusIndicator(
            isAvailable: booking.caregiver['isAvailable'],
            status: booking.caregiver['isAvailable'] ? 'online' : 'offline',
          ),
      ],
    );
  }

  Widget _buildServiceDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.medical_services, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceDetails['type'] ?? 'Care Service',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${booking.serviceDetails['duration']?.toString() ?? '0'} hours',
                  style: TextStyle(color: Colors.blue[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '\$${(booking.serviceDetails['totalCost'] ?? 0).toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleInfo() {
    final date = booking.schedule['date'] is DateTime
        ? booking.schedule['date'] as DateTime
        : DateTime.now(); // Fallback
    final startTime = booking.schedule['startTime'] ?? '00:00';
    final endTime = booking.schedule['endTime'] ?? '00:00';

    return Row(
      children: [
        Icon(Icons.schedule, color: Colors.grey[600], size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(date),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$startTime - $endTime',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return Row(
      children: [
        Icon(Icons.location_on, color: Colors.grey[600], size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            booking.location['address'] ?? 'Location not specified',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialRequirements() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.note, color: Colors.amber[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Special Requirements',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber[700],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.specialRequirements!,
                  style: TextStyle(color: Colors.amber[800], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingInfo() {
    return Row(
      children: [
        Icon(Icons.star, color: Colors.amber, size: 20),
        const SizedBox(width: 8),
        Text(
          '${booking.rating!.toStringAsFixed(1)}/5.0',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        if (booking.review != null && booking.review!.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '"${booking.review!}"',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (booking.isPending || booking.isConfirmed)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel, size: 16),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        if (booking.canBeRated) ...[
          if (booking.isPending || booking.isConfirmed)
            const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onRate,
              icon: const Icon(Icons.star, size: 16),
              label: const Text('Rate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// Compact booking card for list views
class CompactBookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onTap;

  const CompactBookingCard({Key? key, required this.booking, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Caregiver avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                backgroundImage: booking.caregiver['profileImage'] != null
                    ? NetworkImage(booking.caregiver['profileImage'])
                    : null,
                child: booking.caregiver['profileImage'] == null
                    ? const Icon(Icons.person, color: Colors.grey, size: 16)
                    : null,
              ),
              const SizedBox(width: 12),

              // Booking details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.caregiver['name'] ?? 'Unknown Caregiver',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM d, yyyy').format(
                        booking.schedule['date'] is DateTime
                            ? booking.schedule['date'] as DateTime
                            : DateTime.now(),
                      ),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Price
              Text(
                '\$${(booking.serviceDetails['totalCost'] ?? 0).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (booking.status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'in-progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

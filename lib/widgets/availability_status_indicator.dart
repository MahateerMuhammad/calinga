// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AvailabilityStatusIndicator extends StatelessWidget {
  final bool isAvailable;
  final String status;
  final double size;

  const AvailabilityStatusIndicator({
    super.key,
    required this.isAvailable,
    required this.status,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'online':
        statusColor = Colors.green;
        statusIcon = Icons.circle;
        break;
      case 'busy':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'offline':
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.circle_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: size,
          ),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontSize: size - 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
} 
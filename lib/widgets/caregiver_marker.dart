// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class CaregiverMarker extends StatelessWidget {
  final Map<String, dynamic> caregiver;
  final VoidCallback? onTap;
  final bool isSelected;
  final double size;

  const CaregiverMarker({
    super.key,
    required this.caregiver,
    this.onTap,
    this.isSelected = false,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Profile image or default icon
            Center(
              child: caregiver['profileImage'] != null
                  ? ClipOval(
                      child: Image.network(
                        caregiver['profileImage'],
                        width: size - 8,
                        height: size - 8,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultIcon();
                        },
                      ),
                    )
                  : _buildDefaultIcon(),
            ),
            
            // Availability indicator
            if (caregiver['isAvailable'] != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: caregiver['isAvailable'] ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            
            // Role badge
            Positioned(
              bottom: -2,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRoleColor(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  caregiver['role'] ?? 'CG',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Icon(
      Icons.person,
      size: size * 0.6,
      color: Colors.grey[600],
    );
  }

  Color _getRoleColor() {
    final role = caregiver['role']?.toString().toLowerCase() ?? '';
    
    switch (role) {
      case 'cna':
        return Colors.blue;
      case 'lvn':
        return Colors.purple;
      case 'rn':
        return Colors.indigo;
      case 'np':
        return Colors.deepPurple;
      case 'pt':
        return Colors.teal;
      case 'hha':
        return Colors.orange;
      case 'private caregiver':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// Cluster marker for multiple caregivers in the same area
class CaregiverClusterMarker extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  final bool isSelected;

  const CaregiverClusterMarker({
    super.key,
    required this.count,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? Colors.blue : Colors.orange,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// Custom marker info window
class CaregiverInfoWindow extends StatelessWidget {
  final Map<String, dynamic> caregiver;
  final VoidCallback? onTap;
  final VoidCallback? onBook;

  const CaregiverInfoWindow({
    super.key,
    required this.caregiver,
    this.onTap,
    this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with profile image and name
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                backgroundImage: caregiver['profileImage'] != null
                    ? NetworkImage(caregiver['profileImage'])
                    : null,
                child: caregiver['profileImage'] == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caregiver['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      caregiver['role'] ?? 'Caregiver',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Rating
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                '${(caregiver['rating'] ?? 0.0).toStringAsFixed(1)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${caregiver['formattedDistance'] ?? '0 km'} away',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Price
          Text(
            '\$${(caregiver['hourlyRate'] ?? 0).toStringAsFixed(0)}/hour',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.green,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onTap,
                  child: const Text(
                    'View',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Book',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Marker legend widget
class MarkerLegend extends StatelessWidget {
  const MarkerLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final roles = [
      {'role': 'CNA', 'color': Colors.blue},
      {'role': 'LVN', 'color': Colors.purple},
      {'role': 'RN', 'color': Colors.indigo},
      {'role': 'NP', 'color': Colors.deepPurple},
      {'role': 'PT', 'color': Colors.teal},
      {'role': 'HHA', 'color': Colors.orange},
      {'role': 'Private', 'color': Colors.green},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Caregiver Types',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...roles.map((role) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: role['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  role['role'] as String,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
} 
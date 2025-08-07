import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/availability_provider.dart';
import '../utils/constants.dart';

class AvailabilityToggle extends StatelessWidget {
  final bool showStatusText;
  final bool showIcon;
  final double? width;
  final double? height;

  const AvailabilityToggle({
    Key? key,
    this.showStatusText = true,
    this.showIcon = true,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AvailabilityProvider>(
      builder: (context, availabilityProvider, child) {
        final isAvailable = availabilityProvider.isAvailable;
        final statusText = availabilityProvider.statusDisplayText;
        final isLoading = availabilityProvider.isLoading;
        final error = availabilityProvider.error;

        return Container(
          width: width,
          height: height,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error message
              if (error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Toggle switch
              GestureDetector(
                onTap: isLoading ? null : () => availabilityProvider.toggleAvailability(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isAvailable ? Colors.green[50] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAvailable ? Colors.green[200]! : Colors.grey[300]!,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status icon
                      if (showIcon) ...[
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isAvailable ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          child: isAvailable
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 8,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Status text
                      if (showStatusText) ...[
                        Text(
                          statusText,
                          style: TextStyle(
                            color: isAvailable ? Colors.green[700] : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Toggle switch
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isAvailable ? Colors.green : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            // Toggle thumb
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 200),
                              left: isAvailable ? 26 : 2,
                              top: 2,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Loading indicator
                      if (isLoading) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isAvailable ? Colors.green : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Additional status info
              if (showStatusText && isAvailable)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'You are visible to care seekers',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Compact availability toggle for use in app bars or small spaces
class CompactAvailabilityToggle extends StatelessWidget {
  const CompactAvailabilityToggle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AvailabilityProvider>(
      builder: (context, availabilityProvider, child) {
        final isAvailable = availabilityProvider.isAvailable;
        final isLoading = availabilityProvider.isLoading;

        return GestureDetector(
          onTap: isLoading ? null : () => availabilityProvider.toggleAvailability(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAvailable ? Colors.green[50] : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isAvailable ? Colors.green[200]! : Colors.grey[300]!,
              ),
            ),
            child: Stack(
              children: [
                Icon(
                  isAvailable ? Icons.visibility : Icons.visibility_off,
                  color: isAvailable ? Colors.green : Colors.grey,
                  size: 20,
                ),
                if (isLoading)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isAvailable ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Availability status indicator for profile cards
class AvailabilityStatusIndicator extends StatelessWidget {
  final bool isAvailable;
  final String status;
  final double size;

  const AvailabilityStatusIndicator({
    Key? key,
    required this.isAvailable,
    required this.status,
    this.size = 12,
  }) : super(key: key);

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
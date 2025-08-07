import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AvailabilityModel {
  final String userId;
  final bool isAvailable;
  final DateTime lastAvailabilityUpdate;
  final String availabilityStatus; // 'online', 'offline', 'busy'
  final Map<String, dynamic>? schedule; // Future enhancement for scheduling

  AvailabilityModel({
    required this.userId,
    required this.isAvailable,
    required this.lastAvailabilityUpdate,
    required this.availabilityStatus,
    this.schedule,
  });

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityModel(
      userId: json['userId'] ?? '',
      isAvailable: json['isAvailable'] ?? false,
      lastAvailabilityUpdate: (json['lastAvailabilityUpdate'] as Timestamp).toDate(),
      availabilityStatus: json['availabilityStatus'] ?? 'offline',
      schedule: json['schedule'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'isAvailable': isAvailable,
      'lastAvailabilityUpdate': Timestamp.fromDate(lastAvailabilityUpdate),
      'availabilityStatus': availabilityStatus,
      'schedule': schedule,
    };
  }

  AvailabilityModel copyWith({
    String? userId,
    bool? isAvailable,
    DateTime? lastAvailabilityUpdate,
    String? availabilityStatus,
    Map<String, dynamic>? schedule,
  }) {
    return AvailabilityModel(
      userId: userId ?? this.userId,
      isAvailable: isAvailable ?? this.isAvailable,
      lastAvailabilityUpdate: lastAvailabilityUpdate ?? this.lastAvailabilityUpdate,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      schedule: schedule ?? this.schedule,
    );
  }

  // Helper methods
  bool get isOnline => availabilityStatus == 'online';
  bool get isOffline => availabilityStatus == 'offline';
  bool get isBusy => availabilityStatus == 'busy';
  
  String get statusDisplayText {
    switch (availabilityStatus) {
      case 'online':
        return 'Available';
      case 'offline':
        return 'Unavailable';
      case 'busy':
        return 'Busy';
      default:
        return 'Unknown';
    }
  }

  Color get statusColor {
    switch (availabilityStatus) {
      case 'online':
        return Colors.green;
      case 'offline':
        return Colors.grey;
      case 'busy':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
} 
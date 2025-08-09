import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String bookingId;
  final String careSeekerId;
  final Map<String, dynamic> caregiver;
  final Map<String, dynamic> serviceDetails;
  final Map<String, dynamic> schedule;
  final Map<String, dynamic> location;
  final String status;
  final String? specialRequirements;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? rating;
  final String? review;

  BookingModel({
    required this.bookingId,
    required this.careSeekerId,
    required this.caregiver,
    required this.serviceDetails,
    required this.schedule,
    required this.location,
    required this.status,
    this.specialRequirements,
    required this.createdAt,
    required this.updatedAt,
    this.rating,
    this.review,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId: json['bookingId'] ?? '',
      careSeekerId: json['careSeekerId'] ?? '',
      caregiver: json['caregiver'] ?? {},
      serviceDetails: json['serviceDetails'] ?? {},
      schedule: json['schedule'] ?? {},
      location: json['location'] ?? {},
      status: json['status'] ?? 'pending',
      specialRequirements: json['specialRequirements'],
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      rating: json['rating']?.toDouble(),
      review: json['review'],
    );
  }

  // Helper method to safely parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
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

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'careSeekerId': careSeekerId,
      'caregiver': caregiver,
      'serviceDetails': serviceDetails,
      'schedule': schedule,
      'location': location,
      'status': status,
      'specialRequirements': specialRequirements,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'rating': rating,
      'review': review,
    };
  }

  BookingModel copyWith({
    String? bookingId,
    String? careSeekerId,
    Map<String, dynamic>? caregiver,
    Map<String, dynamic>? serviceDetails,
    Map<String, dynamic>? schedule,
    Map<String, dynamic>? location,
    String? status,
    String? specialRequirements,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? rating,
    String? review,
  }) {
    return BookingModel(
      bookingId: bookingId ?? this.bookingId,
      careSeekerId: careSeekerId ?? this.careSeekerId,
      caregiver: caregiver ?? this.caregiver,
      serviceDetails: serviceDetails ?? this.serviceDetails,
      schedule: schedule ?? this.schedule,
      location: location ?? this.location,
      status: status ?? this.status,
      specialRequirements: specialRequirements ?? this.specialRequirements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rating: rating ?? this.rating,
      review: review ?? this.review,
    );
  }

  // Helper methods
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isInProgress => status == 'in-progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get canBeRated => isCompleted && rating == null;
}

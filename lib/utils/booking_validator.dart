import 'package:intl/intl.dart';

class BookingValidator {
  // Validation error messages
  static const String _requiredField = 'This field is required';
  static const String _invalidEmail = 'Please enter a valid email address';
  static const String _invalidPhone = 'Please enter a valid phone number';
  static const String _invalidDate = 'Please select a valid date';
  static const String _invalidTime = 'Please select a valid time';
  static const String _invalidDuration = 'Duration must be at least 1 hour';
  static const String _invalidAddress = 'Please enter a valid address';
  static const String _invalidRate = 'Hourly rate must be greater than 0';
  static const String _pastDate = 'Date cannot be in the past';
  static const String _invalidCoordinates = 'Invalid coordinates';

  /// Validate email address
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return _requiredField;
    }

    // Basic email regex pattern
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return _invalidEmail;
    }

    return null;
  }

  /// Validate phone number
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return _requiredField;
    }

    // Remove all non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it's a valid US phone number (10 digits)
    if (digitsOnly.length != 10) {
      return _invalidPhone;
    }

    return null;
  }

  /// Validate date
  static String? validateDate(DateTime? date) {
    if (date == null) {
      return _requiredField;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (selectedDate.isBefore(today)) {
      return _pastDate;
    }

    return null;
  }

  /// Validate time
  static String? validateTime(String? time) {
    if (time == null || time.isEmpty) {
      return _requiredField;
    }

    // Check if time is in HH:MM format
    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(time)) {
      return _invalidTime;
    }

    return null;
  }

  /// Validate duration (in hours)
  static String? validateDuration(double? duration) {
    if (duration == null) {
      return _requiredField;
    }

    if (duration < 1) {
      return _invalidDuration;
    }

    if (duration > 24) {
      return 'Duration cannot exceed 24 hours';
    }

    return null;
  }

  /// Validate address
  static String? validateAddress(String? address) {
    if (address == null || address.isEmpty) {
      return _requiredField;
    }

    if (address.length < 10) {
      return 'Address is too short';
    }

    return null;
  }

  /// Validate coordinates
  static String? validateCoordinates(double? lat, double? lon) {
    if (lat == null || lon == null) {
      return _requiredField;
    }

    if (lat < -90 || lat > 90) {
      return 'Invalid latitude';
    }

    if (lon < -180 || lon > 180) {
      return 'Invalid longitude';
    }

    return null;
  }

  /// Validate hourly rate
  static String? validateHourlyRate(double? rate) {
    if (rate == null) {
      return _requiredField;
    }

    if (rate <= 0) {
      return _invalidRate;
    }

    if (rate > 1000) {
      return 'Hourly rate seems too high';
    }

    return null;
  }

  /// Validate booking date and time combination
  static String? validateBookingDateTime(DateTime? date, String? time) {
    final dateError = validateDate(date);
    if (dateError != null) {
      return dateError;
    }

    final timeError = validateTime(time);
    if (timeError != null) {
      return timeError;
    }

    // Check if booking is at least 2 hours in the future
    if (date != null && time != null) {
      final now = DateTime.now();
      final bookingDateTime = _parseDateTime(date, time);
      
      if (bookingDateTime != null) {
        final difference = bookingDateTime.difference(now);
        if (difference.inHours < 2) {
          return 'Booking must be at least 2 hours in advance';
        }
      }
    }

    return null;
  }

  /// Validate special requirements
  static String? validateSpecialRequirements(String? requirements) {
    if (requirements == null || requirements.isEmpty) {
      return null; // Optional field
    }

    if (requirements.length > 500) {
      return 'Special requirements cannot exceed 500 characters';
    }

    return null;
  }

  /// Validate caregiver selection
  static String? validateCaregiver(Map<String, dynamic>? caregiver) {
    if (caregiver == null) {
      return 'Please select a caregiver';
    }

    if (caregiver['id'] == null || caregiver['id'].toString().isEmpty) {
      return 'Invalid caregiver selection';
    }

    return null;
  }

  /// Validate service details
  static String? validateServiceDetails(Map<String, dynamic>? serviceDetails) {
    if (serviceDetails == null) {
      return 'Service details are required';
    }

    final type = serviceDetails['type'];
    final specialization = serviceDetails['specialization'];
    final duration = serviceDetails['duration'];
    final totalCost = serviceDetails['totalCost'];

    if (type == null || type.toString().isEmpty) {
      return 'Service type is required';
    }

    if (specialization == null || specialization.toString().isEmpty) {
      return 'Service specialization is required';
    }

    final durationError = validateDuration(duration?.toDouble());
    if (durationError != null) {
      return durationError;
    }

    final costError = validateHourlyRate(totalCost?.toDouble());
    if (costError != null) {
      return costError;
    }

    return null;
  }

  /// Validate complete booking data
  static Map<String, String?> validateBookingData({
    required Map<String, dynamic> caregiver,
    required Map<String, dynamic> serviceDetails,
    required DateTime date,
    required String startTime,
    required String endTime,
    required String address,
    required Map<String, dynamic> location,
    String? specialRequirements,
  }) {
    return {
      'caregiver': validateCaregiver(caregiver),
      'serviceDetails': validateServiceDetails(serviceDetails),
      'date': validateDate(date),
      'startTime': validateTime(startTime),
      'endTime': validateTime(endTime),
      'address': validateAddress(address),
      'location': validateCoordinates(
        location['latitude']?.toDouble(),
        location['longitude']?.toDouble(),
      ),
      'specialRequirements': validateSpecialRequirements(specialRequirements),
    };
  }

  /// Check if booking data is valid
  static bool isBookingDataValid(Map<String, String?> validationResults) {
    return validationResults.values.every((error) => error == null);
  }

  /// Get first validation error
  static String? getFirstValidationError(Map<String, String?> validationResults) {
    for (String? error in validationResults.values) {
      if (error != null) {
        return error;
      }
    }
    return null;
  }

  /// Validate time range (start time must be before end time)
  static String? validateTimeRange(String startTime, String endTime) {
    final startError = validateTime(startTime);
    if (startError != null) {
      return startError;
    }

    final endError = validateTime(endTime);
    if (endError != null) {
      return endError;
    }

    // Parse times and compare
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);

    if (start != null && end != null) {
      if (start.isAfter(end)) {
        return 'Start time must be before end time';
      }

      final difference = end.difference(start);
      if (difference.inMinutes < 60) {
        return 'Booking must be at least 1 hour long';
      }
    }

    return null;
  }

  /// Parse time string to DateTime
  static DateTime? _parseTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return DateTime(2024, 1, 1, hour, minute);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Parse date and time to DateTime
  static DateTime? _parseDateTime(DateTime date, String time) {
    try {
      final timeParts = time.split(':');
      if (timeParts.length == 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        return DateTime(date.year, date.month, date.day, hour, minute);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// Format date for display
  static String formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  /// Format time for display
  static String formatTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
      }
    } catch (e) {
      return time;
    }
    return time;
  }

  /// Calculate total cost based on duration and hourly rate
  static double calculateTotalCost(double duration, double hourlyRate) {
    return duration * hourlyRate;
  }

  /// Validate booking cancellation
  static String? validateCancellation(DateTime bookingDateTime) {
    final now = DateTime.now();
    final difference = bookingDateTime.difference(now);

    if (difference.isNegative) {
      return 'Cannot cancel past bookings';
    }

    if (difference.inHours < 2) {
      return 'Cancellations must be made at least 2 hours in advance';
    }

    return null;
  }
} 
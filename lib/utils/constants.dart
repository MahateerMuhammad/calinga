import 'package:flutter/material.dart';

class AppConstants {
  // App Colors
  static const Color primaryColor = Color(0xFF1976D2); // Blue
  static const Color splashBackgroundColor = Color(0xFF1976D2); // Background for splash screen
  static const Color accentColor = Color(0xFFFF5722); // Orange
  static const Color backgroundColor = Color(0xFFF5F5F5); // Light Grey
  static const Color textColor = Color(0xFF212121); // Dark Grey
  static const Color lightTextColor = Color(0xFF757575); // Medium Grey
  
  // App Strings
  static const String appName = 'CALiNGA';
  static const String appTagline = 'ON-DEMAND CARE';
  
  // User Roles
  static const String roleCaregiver = 'CALiNGApro';
  static const String roleCareseeker = 'CareSeeker';
  
  // Routes
  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String otpRoute = '/otp';
  static const String caregiverHomeRoute = '/caregiver/home';
  static const String careseekerHomeRoute = '/careseeker/home';
  
  // Validation
  static const List<String> allowedCountryCodes = ['+1', '+63', '+92'];
  
  // Caregiver Roles
  static const List<String> caregiverRoles = [
    'CNA',
    'LVN',
    'RN',
    'NP',
    'PT',
    'HHA',
    'Private Caregiver',
  ];
  
  // Assets
  static const String logoPath = 'assets/images/logo.png';
  
  // Shared Preferences Keys
  static const String userTokenKey = 'user_token';
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userNameKey = 'user_name';
}
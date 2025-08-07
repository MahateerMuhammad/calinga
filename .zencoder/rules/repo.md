---
description: Repository Information Overview
alwaysApply: true
---

# CALiNGA Mobile Application Information

## Summary
CALiNGA is a Flutter-based mobile application for on-demand care services. The platform connects families (CareSeekers) with caregiving professionals (CALiNGApros), featuring role-based user experiences, authentication flows, and specialized screens for different user types.

## Structure
- **android/**: Android platform-specific code and configuration
- **ios/**: iOS platform-specific code and configuration
- **lib/**: Main Dart source code for the application
- **macos/**: macOS platform-specific code
- **web/**: Web platform-specific code
- **windows/**: Windows platform-specific code
- **linux/**: Linux platform-specific code
- **build/**: Generated build files

## Language & Runtime
**Language**: Dart
**Version**: SDK ^3.8.1
**Framework**: Flutter
**Build System**: Gradle (Android), Xcode (iOS/macOS), CMake (Windows/Linux)
**Package Manager**: pub (Dart package manager)

## Dependencies
**Main Dependencies**:
- flutter (SDK)
- firebase_core: ^2.24.2
- firebase_database: ^10.4.0
- connectivity_plus: ^5.0.2

**Development Dependencies**:
- flutter_test (SDK)
- flutter_lints: ^5.0.0

## Firebase Integration
**Project ID**: callinga-d6829
**Configuration**: Multi-platform setup (Android, iOS, Web, macOS, Windows)
**Services**: Firebase Core, Realtime Database
**Configuration Files**:
- lib/firebase_options.dart
- android/app/google-services.json
- firebase.json

## Build & Installation
```bash
# Get dependencies
flutter pub get

# Run in development mode
flutter run

# Build release APK (Android)
flutter build apk --release

# Build iOS app
flutter build ios --release
```

## Application Structure
**Entry Point**: lib/main.dart
**Main Components**:
- Firebase initialization
- Connection checking functionality
- Material app setup

## Planned Features
- Role-based authentication (CareSeeker and CALiNGApro)
- OTP verification via Firebase
- Role-specific navigation drawers
- Profile management
- Booking system
- Document upload and verification for professionals
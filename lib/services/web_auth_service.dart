import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

class WebAuthService {
  static Future<void> configureRecaptcha() async {
    if (kIsWeb) {
      // Web-specific Firebase Auth configuration
      debugPrint('Firebase Auth configured for web platform');
    }
  }

  static RecaptchaVerifier createRecaptchaVerifier() {
    return RecaptchaVerifier(
      auth: FirebaseAuthPlatform.instance,
      container: 'recaptcha-container',
      size: RecaptchaVerifierSize.compact,
      theme: RecaptchaVerifierTheme.light,
      onSuccess: () => debugPrint('reCAPTCHA verification successful'),
      onError: (FirebaseAuthException error) {
        debugPrint('reCAPTCHA verification failed: ${error.message}');
      },
      onExpired: () => debugPrint('reCAPTCHA verification expired'),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../careseeker/careseeker_home.dart';
import '../caregiver/caregiver_home.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String email;
  final String userRole;
  final String? fullName;
  final String? password;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.email,
    required this.userRole,
    this.fullName,
    this.password,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _authService = AuthService();
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  bool _recaptchaLoaded = false;
  String _errorMessage = '';
  String _verificationId = '';
  int _resendToken = 0;
  int _remainingTime = 60;
  ConfirmationResult? _webConfirmationResult;
  RecaptchaVerifier? _recaptchaVerifier;

  @override
  void initState() {
    super.initState();
    _initializeRecaptcha();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _recaptchaVerifier?.clear();
    super.dispose();
  }

  Future<void> _initializeRecaptcha() async {
    if (kIsWeb) {
      try {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });

        // Wait longer for the DOM and Firebase to be ready
        await Future.delayed(const Duration(milliseconds: 1500));

        // Clear any existing reCAPTCHA
        if (_recaptchaVerifier != null) {
          try {
            _recaptchaVerifier!.clear();
          } catch (e) {
            debugPrint('Error clearing previous reCAPTCHA: $e');
          }
        }

        _recaptchaVerifier = RecaptchaVerifier(
          auth: FirebaseAuthPlatform.instance,
          container: 'recaptcha-container',
          size: RecaptchaVerifierSize.compact, // Use compact reCAPTCHA
          theme: RecaptchaVerifierTheme.light,
          onSuccess: () {
            debugPrint('reCAPTCHA verification successful');
            setState(() {
              _recaptchaLoaded = true;
              _isLoading = false;
            });
          },
          onError: (FirebaseAuthException error) {
            debugPrint('reCAPTCHA verification failed: ${error.message}');
            setState(() {
              _errorMessage =
                  'reCAPTCHA verification failed. Please try again.';
              _isLoading = false;
            });
          },
          onExpired: () {
            debugPrint('reCAPTCHA verification expired');
            setState(() {
              _errorMessage =
                  'reCAPTCHA verification expired. Please try again.';
              _recaptchaLoaded = false;
              _isLoading = false;
            });
          },
        );

        // Try to render the reCAPTCHA
        await _recaptchaVerifier!.render();

        setState(() {
          _isLoading = false;
          _recaptchaLoaded = true;
        });

        debugPrint('reCAPTCHA initialized successfully');
      } catch (e) {
        debugPrint('Error initializing reCAPTCHA: $e');
        setState(() {
          _errorMessage =
              'reCAPTCHA initialization failed. Trying alternative method...';
          _isLoading = false;
        });

        // Try alternative approach without reCAPTCHA container
        _tryAlternativeWebAuth();
      }
    } else {
      // For mobile platforms, directly send OTP
      _sendOTP();
      _startCountdown();
    }
  }

  Future<void> _tryAlternativeWebAuth() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = 'Trying alternative verification method...';
      });

      // Create a new reCAPTCHA verifier without container
      _recaptchaVerifier = RecaptchaVerifier(
        auth: FirebaseAuthPlatform.instance,
        size: RecaptchaVerifierSize.compact,
        theme: RecaptchaVerifierTheme.light,
      );

      setState(() {
        _recaptchaLoaded = true;
        _isLoading = false;
        _errorMessage = '';
      });

      debugPrint('Alternative reCAPTCHA method initialized');
    } catch (e) {
      debugPrint('Alternative method also failed: $e');
      setState(() {
        _errorMessage =
            'Verification setup failed. Please refresh the page and try again.';
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
        _startCountdown();
      }
    });
  }

  String _formatPhoneNumber(String phoneNumber) {
    // Ensure the phone number is in E.164 format
    String formatted = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (!formatted.startsWith('+')) {
      // If it doesn't start with +, assume it needs a country code
      if (formatted.startsWith('63')) {
        formatted = '+$formatted';
      } else if (formatted.startsWith('0')) {
        // Remove leading 0 and add Philippines country code as default
        formatted = '+63${formatted.substring(1)}';
      } else {
        formatted = '+63$formatted';
      }
    }

    debugPrint('Formatted phone number: $formatted');
    return formatted;
  }

  Future<void> _sendOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String formattedPhone = _formatPhoneNumber(widget.phoneNumber);

      if (kIsWeb) {
        // Web platform - use signInWithPhoneNumber with reCAPTCHA
        if (_recaptchaVerifier == null) {
          throw Exception('reCAPTCHA verifier not initialized');
        }

        debugPrint('Sending OTP to: $formattedPhone');
        _webConfirmationResult = await FirebaseAuth.instance
            .signInWithPhoneNumber(formattedPhone, _recaptchaVerifier!);

        setState(() {
          _isLoading = false;
        });

        _startCountdown();
        debugPrint('OTP sent successfully via web platform');
      } else {
        // Mobile platforms - use verifyPhoneNumber
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: formattedPhone,
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-verification completed (Android only)
            debugPrint('Auto verification completed');
            await _verifyOTP(credential);
          },
          verificationFailed: (FirebaseAuthException e) {
            debugPrint('Verification failed: ${e.code} - ${e.message}');
            setState(() {
              _isLoading = false;
              switch (e.code) {
                case 'invalid-phone-number':
                  _errorMessage = 'Invalid phone number format.';
                  break;
                case 'too-many-requests':
                  _errorMessage = 'Too many requests. Please try again later.';
                  break;
                case 'quota-exceeded':
                  _errorMessage = 'SMS quota exceeded. Please try again later.';
                  break;
                default:
                  _errorMessage = 'Verification failed: ${e.message}';
              }
            });
          },
          codeSent: (String verificationId, int? resendToken) {
            debugPrint('Code sent successfully');
            setState(() {
              _verificationId = verificationId;
              if (resendToken != null) {
                _resendToken = resendToken;
              }
              _isLoading = false;
            });
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            setState(() {
              _verificationId = verificationId;
            });
          },
          timeout: const Duration(seconds: 60),
          forceResendingToken: _resendToken != 0 ? _resendToken : null,
        );
      }
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      setState(() {
        _isLoading = false;
        if (e.toString().contains('auth/argument-error')) {
          _errorMessage =
              'Invalid phone number format. Please check and try again.';
        } else if (e.toString().contains('auth/too-many-requests')) {
          _errorMessage = 'Too many requests. Please wait and try again.';
        } else if (e.toString().contains('auth/app-not-authorized')) {
          _errorMessage = 'App not authorized for SMS. Please contact support.';
        } else if (e.toString().contains('recaptcha')) {
          _errorMessage =
              'reCAPTCHA verification required. Please refresh and try again.';
        } else {
          _errorMessage =
              'Failed to send OTP. Please check your phone number and try again.';
        }
      });
    }
  }

  Future<void> _verifyOTP([PhoneAuthCredential? credential]) async {
    String otpCode = _otpController.text.trim();

    if (credential == null && otpCode.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the OTP code.';
      });
      return;
    }

    if (credential == null && otpCode.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit OTP code.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      UserCredential? phoneUserCredential;

      if (kIsWeb && _webConfirmationResult != null) {
        // Web platform - confirm the result with OTP
        phoneUserCredential = await _webConfirmationResult!.confirm(otpCode);
      } else {
        // Mobile platforms - use credential
        PhoneAuthCredential authCredential =
            credential ??
            PhoneAuthProvider.credential(
              verificationId: _verificationId,
              smsCode: otpCode,
            );

        phoneUserCredential = await FirebaseAuth.instance.signInWithCredential(
          authCredential,
        );
      }

      // If this is a new signup (has fullName and password), create the user account
      if (widget.fullName != null && widget.password != null) {
        if (phoneUserCredential.user != null) {
          try {
            // Create email/password credential
            AuthCredential emailCredential = EmailAuthProvider.credential(
              email: widget.email,
              password: widget.password!,
            );

            // Link the email credential to the phone-authenticated user
            await phoneUserCredential.user!.linkWithCredential(emailCredential);

            // Update user profile and save to database
            await _authService.updateUserProfile(
              fullName: widget.fullName!,
              phoneNumber: widget.phoneNumber,
              role: widget.userRole,
            );
          } catch (linkError) {
            debugPrint('Error linking credentials: $linkError');
            // If linking fails, still proceed but create user with phone auth only
            await _authService.updateUserProfile(
              fullName: widget.fullName!,
              phoneNumber: widget.phoneNumber,
              role: widget.userRole,
            );
          }
        }
      }

      if (!mounted) return;

      // Navigate based on user role
      if (widget.userRole == AppConstants.roleCaregiver) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const CaregiverHome()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const CareseekerHome()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Exception: ${e.code} - ${e.message}');
      setState(() {
        _isLoading = false;
        switch (e.code) {
          case 'invalid-verification-code':
            _errorMessage = 'Invalid OTP code. Please try again.';
            break;
          case 'session-expired':
            _errorMessage = 'OTP session expired. Please request a new code.';
            break;
          case 'email-already-in-use':
            _errorMessage = 'The email address is already in use.';
            break;
          case 'weak-password':
            _errorMessage = 'The password is too weak.';
            break;
          case 'invalid-email':
            _errorMessage = 'The email address is invalid.';
            break;
          case 'provider-already-linked':
            _errorMessage =
                'This phone number is already linked to another account.';
            break;
          case 'credential-already-in-use':
            _errorMessage =
                'This phone number is already associated with another account.';
            break;
          default:
            _errorMessage = 'Verification failed: ${e.message}';
        }
      });
    } catch (e) {
      debugPrint('General error: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  void _resendOTP() {
    if (_remainingTime == 0) {
      setState(() {
        _remainingTime = 60;
        _recaptchaLoaded = false;
      });

      if (kIsWeb) {
        // Clear and reinitialize reCAPTCHA for web
        _recaptchaVerifier?.clear();
        _initializeRecaptcha();
      } else {
        _startCountdown();
        _sendOTP();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OTP Verification')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.sms, size: 64, color: AppConstants.primaryColor),
              const SizedBox(height: 24),

              Text(
                'Verification Code',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                'We have sent a verification code to ${widget.phoneNumber}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // reCAPTCHA container for web
              if (kIsWeb)
                Container(
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoading && !_recaptchaLoaded)
                        const CircularProgressIndicator()
                      else if (_recaptchaLoaded)
                        const Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Verification ready! You can now send OTP.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            const Icon(
                              Icons.security,
                              color: Colors.grey,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Initializing security verification...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: _initializeRecaptcha,
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

              // Send OTP Button (for web)
              if (kIsWeb && _recaptchaLoaded && _webConfirmationResult == null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOTP,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Send OTP'),
                  ),
                ),

              // OTP Input Field
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                enabled: kIsWeb ? (_webConfirmationResult != null) : true,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(8),
                  fieldHeight: 50,
                  fieldWidth: 40,
                  activeFillColor: Colors.white,
                  inactiveFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                  activeColor: AppConstants.primaryColor,
                  inactiveColor: Colors.grey,
                  selectedColor: AppConstants.primaryColor,
                  disabledColor: Colors.grey.shade300,
                ),
                enableActiveFill: true,
                keyboardType: TextInputType.number,
                onCompleted: (value) {
                  if (kIsWeb && _webConfirmationResult != null) {
                    _verifyOTP();
                  } else if (!kIsWeb) {
                    _verifyOTP();
                  }
                },
                onChanged: (value) {
                  if (_errorMessage.isNotEmpty) {
                    setState(() {
                      _errorMessage = '';
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Resend OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive the code?"),
                  TextButton(
                    onPressed: _remainingTime == 0 ? _resendOTP : null,
                    child: Text(
                      _remainingTime > 0
                          ? 'Resend in $_remainingTime s'
                          : 'Resend OTP',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Error Message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Verify Button
              ElevatedButton(
                onPressed:
                    _isLoading || (kIsWeb && _webConfirmationResult == null)
                    ? null
                    : () => _verifyOTP(),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verify OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

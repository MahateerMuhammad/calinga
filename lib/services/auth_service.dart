import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String role,
  }) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Create user model
      UserModel userModel = UserModel(
        uid: userCredential.user!.uid,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        role: role,
      );

      // Save user data to Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toJson());

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Send OTP to phone number
  Future<String> sendOTP({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
    Function(PhoneAuthCredential)? onVerificationCompleted,
  }) async {
    try {
      String? verificationId;

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
          if (onVerificationCompleted != null) {
            onVerificationCompleted(credential);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onVerificationFailed(e);
        },
        codeSent: (String verId, int? resendToken) {
          verificationId = verId;
          onCodeSent(verId);
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId = verId;
        },
      );

      return verificationId ?? '';
    } catch (e) {
      rethrow;
    }
  }

  // Verify OTP
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      if (_auth.currentUser != null) {
        // Link phone number to existing account
        return await _auth.currentUser!.linkWithCredential(credential);
      } else {
        // Sign in with phone number
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user role
  Future<String?> getUserRole() async {
    try {
      if (currentUser != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        if (doc.exists) {
          return doc.get('role') as String?;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Update user profile (for phone auth linking)
  Future<void> updateUserProfile({
    required String fullName,
    required String phoneNumber,
    required String role,
  }) async {
    try {
      if (currentUser != null) {
        // Update display name
        await currentUser!.updateDisplayName(fullName);

        // Create or update user document in Firestore
        UserModel userModel = UserModel(
          uid: currentUser!.uid,
          fullName: fullName,
          email: currentUser!.email ?? '',
          phoneNumber: phoneNumber,
          role: role,
        );

        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .set(userModel.toJson(), SetOptions(merge: true));
      }
    } catch (e) {
      rethrow;
    }
  }
}

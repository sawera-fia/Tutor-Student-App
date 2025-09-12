import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    UserModel? userModel, // Add optional userModel parameter
  }) async {
    try {
      print('🚀 Starting signup process for: $email');

      // First, create the Firebase Auth user
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Firebase Auth user created: ${result.user?.uid}');

      if (result.user != null) {
        try {
          // Use the provided userModel if available, otherwise create a basic one
          final finalUserModel =
              userModel ??
              UserModel(
                id: result.user!.uid,
                email: email,
                name: name,
                role: role,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

          // Ensure the ID is set correctly
          final finalUserModelWithId = finalUserModel.copyWith(
            id: result.user!.uid,
          );

          print('📝 Creating Firestore document...');
          print('📝 User data to save: ${finalUserModelWithId.toJson()}');

          await _firestore
              .collection('users')
              .doc(result.user!.uid)
              .set(finalUserModelWithId.toJson());

          print('✅ Firestore document created successfully!');
          return finalUserModelWithId;
        } catch (firestoreError) {
          print('❌ Firestore error: $firestoreError');
          // If Firestore fails, delete the Firebase Auth user
          await result.user!.delete();
          throw Exception('Failed to create user profile: $firestoreError');
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print('🔥 Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('💥 Unexpected Error during signup: $e');
      throw Exception('An unexpected error occurred during signup: $e');
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('�� Attempting sign in for: $email');

      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Firebase auth successful for: ${result.user?.uid}');

      if (result.user != null) {
        try {
          // Get user data from Firestore
          final userData = await _firestore
              .collection('users')
              .doc(result.user!.uid)
              .get();

          print('📄 Firestore data exists: ${userData.exists}');

          if (userData.exists && userData.data() != null) {
            final userModel = UserModel.fromJson(userData.data()!);
            print(
              '�� User model created: ${userModel.name} (${userModel.role})',
            );
            return userModel;
          } else {
            print('❌ No user data found in Firestore');
            throw Exception('User profile not found in database');
          }
        } catch (firestoreError) {
          print('❌ Firestore error during signin: $firestoreError');
          throw Exception('Failed to retrieve user profile: $firestoreError');
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      print('🔥 Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('💥 Unexpected Error during signin: $e');
      throw Exception('An unexpected error occurred during signin: $e');
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      print('�� Fetching user data for UID: $uid');

      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      print('📄 Document exists: ${doc.exists}');

      if (doc.exists && doc.data() != null) {
        final userModel = UserModel.fromJson(
          doc.data() as Map<String, dynamic>,
        );
        print('👤 User data retrieved: ${userModel.name}');
        return userModel;
      }
      return null;
    } catch (e) {
      print('❌ Error getting user data: $e');
      throw Exception('Failed to get user data: $e');
    }
  }

  // Update user data
  Future<void> updateUserData(UserModel user) async {
    try {
      print('�� Updating user data for: ${user.name}');

      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.copyWith(updatedAt: DateTime.now()).toJson());

      print('✅ User data updated successfully');
    } catch (e) {
      print('❌ Error updating user data: $e');
      throw Exception('Failed to update user data: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('🚪 Signing out user');
      await _auth.signOut();
      print('✅ User signed out successfully');
    } catch (e) {
      print('❌ Error signing out: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      print('📧 Sending password reset email to: $email');

      await _auth.sendPasswordResetEmail(email: email);

      print('✅ Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      print(
        '🔥 Firebase Auth Error during password reset: ${e.code} - ${e.message}',
      );
      throw _handleAuthException(e);
    } catch (e) {
      print('💥 Unexpected Error during password reset: $e');
      throw Exception('Failed to send password reset email: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    print('🔍 Handling Firebase Auth Exception: ${e.code}');

    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      case 'configuration-not-found':
        return 'Firebase configuration error. Please check your setup.';
      default:
        print('⚠️ Unknown Firebase Auth error code: ${e.code}');
        return e.message ?? 'An unknown authentication error occurred.';
    }
  }
}

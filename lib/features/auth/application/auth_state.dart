import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../data/auth_service.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Current Firebase user provider
final firebaseUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current user data provider
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final firebaseUser = await ref.watch(firebaseUserProvider.future);
  if (firebaseUser == null) return null;
  
  final authService = ref.watch(authServiceProvider);
  return authService.getUserData(firebaseUser.uid);
});

// Auth state notifier
class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() async {
    print('🔄 Initializing AuthNotifier');
    _authService.authStateChanges.listen((user) async {
      print('🔄 Firebase auth state changed: ${user?.uid ?? 'null'}');
      
      if (user == null) {
        print('🔄 User signed out, setting state to null');
        state = const AsyncValue.data(null);
      } else {
        try {
          print('�� Fetching user data for: ${user.uid}');
          final userData = await _authService.getUserData(user.uid);
          print('�� User data fetched: ${userData?.name ?? 'null'}');
          state = AsyncValue.data(userData);
        } catch (e, stackTrace) {
          print('❌ Error fetching user data: $e');
          state = AsyncValue.error(e, stackTrace);
        }
      }
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      print('🔄 Starting signup process');
      state = const AsyncValue.loading();
      
      final user = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      
      print('�� Signup successful: ${user?.name}');
      // Don't set state here - let the auth state listener handle it
    } catch (e, stackTrace) {
      print('❌ Signup error: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔄 Starting signin process');
      state = const AsyncValue.loading();
      
      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('�� Signin successful: ${user?.name}');
      // Don't set state here - let the auth state listener handle it
    } catch (e, stackTrace) {
      print('❌ Signin error: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> signOut() async {
    try {
      print('🔄 Starting signout process');
      await _authService.signOut();
      // Don't set state here - let the auth state listener handle it
    } catch (e, stackTrace) {
      print('❌ Signout error: $e');
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile(UserModel user) async {
    try {
      await _authService.updateUserData(user);
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Auth notifier provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
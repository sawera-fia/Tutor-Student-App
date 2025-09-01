import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/application/auth_state.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/student/presentation/student_dashboard.dart';
import '../features/tutor/presentation/tutor_dashboard.dart';
import '../shared/models/user_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      
      print('🔄 Router redirect check - Auth state: ${authState.toString()}');
      
      final isLoggedIn = authState.hasValue && authState.value != null;
      final isOnAuthScreen = state.matchedLocation == '/login' || 
                            state.matchedLocation == '/signup';

      print('🔄 Is logged in: $isLoggedIn, Is on auth screen: $isOnAuthScreen');

      // If not logged in and not on auth screens, redirect to login
      if (!isLoggedIn && !isOnAuthScreen) {
        print('🔄 Redirecting to login - not authenticated');
        return '/login';
      }

      // If logged in and on auth screens, redirect to appropriate dashboard
      if (isLoggedIn && isOnAuthScreen) {
        final user = authState.value!;
        final targetRoute = user.role == UserRole.student 
            ? '/student-dashboard' 
            : '/tutor-dashboard';
        print('🔄 Redirecting to dashboard: $targetRoute');
        return targetRoute;
      }

      print('�� No redirect needed');
      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/student-dashboard',
        name: 'student-dashboard',
        builder: (context, state) => const StudentDashboard(),
      ),
      GoRoute(
        path: '/tutor-dashboard',
        name: 'tutor-dashboard',
        builder: (context, state) => const TutorDashboard(),
      ),
      GoRoute(
        path: '/',
        name: 'home',
        redirect: (context, state) {
          final authState = ref.read(authNotifierProvider);
          if (authState.hasValue && authState.value != null) {
            final user = authState.value!;
            return user.role == UserRole.student 
                ? '/student-dashboard' 
                : '/tutor-dashboard';
          }
          return '/login';
        },
        builder: (context, state) => const LoginScreen(),
      ),
    ],
    // Add this to refresh the router when auth state changes
    refreshListenable: _GoRouterRefreshStream(ref),
  );
});

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Ref ref) {
    ref.listen(authNotifierProvider, (previous, next) {
      print('�� Auth state changed, notifying router');
      notifyListeners();
    });
  }
}
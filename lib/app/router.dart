import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_state.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/student/presentation/student_dashboard_screen.dart';
import '../features/tutor/presentation/tutor_dashboard.dart';
import '../features/student/screens/chat_list_screen.dart';
import '../features/student/screens/chat_screen.dart';
import '../shared/models/user_model.dart';


final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',

    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);

      final isLoggedIn = authState.hasValue && authState.value != null;
      final isOnAuthScreen =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      // If not logged in and not on auth screens → go to login
      if (!isLoggedIn && !isOnAuthScreen) {
        return '/login';
      }

      // If logged in and on auth screens → go to dashboard
      if (isLoggedIn && isOnAuthScreen) {
        final user = authState.value!;
        return user.role == UserRole.student
            ? '/student-dashboard'
            : '/tutor-dashboard';
      }

      return null;
    },

    routes: [
      // 🔑 Auth routes
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

      // 🧑‍🎓 Student dashboard
      GoRoute(
        path: '/student-dashboard',
        name: 'student-dashboard',
        builder: (context, state) => const StudentDashboardScreen(),
      ),

      // 👨‍🏫 Tutor dashboard
      GoRoute(
        path: '/tutor-dashboard',
        name: 'tutor-dashboard',
        builder: (context, state) => const TutorDashboard(),
      ),

      // 💬 Chat list (list of all chats)
      GoRoute(
        path: '/chatList',
        name: 'chatList',
        builder: (context, state) => ChatListScreen(),
      ),

      // 💭 Individual chat screen
      GoRoute(
        path: '/chatScreen',
        name: 'chatScreen',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          return ChatScreen(
            chatId: extra?['chatId'] ?? '',
            tutor: extra?['tutor'] ??
            UserModel(
              id: 'unknown',
              email: 'unknown@example.com',
              name: 'Unknown',
              role: UserRole.teacher,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),

            currentUserId: extra?['currentUserId'] ?? '',
          );
        },
      ),

      // 🏠 Root redirect
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

    refreshListenable: _GoRouterRefreshStream(ref),
  );
});

/// 🔁 Keeps router updated when auth state changes
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Ref ref) {
    ref.listen(authNotifierProvider, (previous, next) {
      notifyListeners();
    });
  }
}

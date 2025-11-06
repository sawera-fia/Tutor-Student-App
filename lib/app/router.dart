import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/application/auth_state.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/student/presentation/student_dashboard_screen.dart';
import '../features/tutor/presentation/tutor_dashboard.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../shared/models/user_model.dart';
import '../features/scheduling/presentation/pending_requests_screen.dart';
import '../features/scheduling/presentation/tutor_schedule_screen.dart';
import '../features/scheduling/presentation/student_schedule_screen.dart';
import '../features/profile/presentation/view_profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',

    /// 🔁 Redirect logic with null-safety fixes
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final user = authState.valueOrNull; // ✅ safe read
      final isLoggedIn = user != null;
      final isOnAuthScreen =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      // If not logged in and not on auth screens → go to login
      if (!isLoggedIn && !isOnAuthScreen) {
        debugPrint('🔐 Redirect → Not logged in, sending to /login');
        return '/login';
      }

      // If logged in and on auth screens → go to dashboard
      if (isLoggedIn && isOnAuthScreen) {
        debugPrint('✅ Redirect → Logged in user detected, going to dashboard');
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
        builder: (context, state) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) {
            debugPrint('❌ Tried to open ChatList without login');
            return const Scaffold(
              body: Center(child: Text('Please log in first.')),
            );
          }
          debugPrint('💬 Opening ChatList for user: ${currentUser.uid}');
          return ChatListScreen();
        },
      ),

      // 💭 Individual chat screen
      GoRoute(
        path: '/chatScreen',
        name: 'chatScreen',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          final chatId = extra?['chatId'] ?? '';
          final tutor =
              extra?['tutor'] ??
              UserModel(
                id: 'unknown',
                email: 'unknown@example.com',
                name: 'Unknown',
                role: UserRole.teacher,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
          final currentUserId = extra?['currentUserId'] ?? '';

          debugPrint(
            '➡️ Navigating to ChatScreen | chatId: $chatId | tutor: ${tutor.name} | currentUserId: $currentUserId',
          );

          return ChatScreen(
            chatId: chatId,
            tutor: tutor,
            currentUserId: currentUserId,
          );
        },
      ),

      // 👤 Edit Profile
      GoRoute(
        path: '/edit-profile',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),

      // 📅 Pending Requests
      GoRoute(
        path: '/pending-requests',
        name: 'pending-requests',
        builder: (context, state) => const PendingRequestsScreen(),
      ),

      // 🗓️ Tutor Schedule (accepted sessions)
      GoRoute(
        path: '/tutor-schedule',
        name: 'tutor-schedule',
        builder: (context, state) => const TutorScheduleScreen(),
      ),

      // 🗓️ Student Schedule (accepted sessions)
      GoRoute(
        path: '/student-schedule',
        name: 'student-schedule',
        builder: (context, state) => const StudentScheduleScreen(),
      ),

      // 👤 View Profile
      GoRoute(
        path: '/view-profile/:userId',
        name: 'view-profile',
        builder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          return ViewProfileScreen(userId: userId);
        },
      ),

      // 🏠 Root redirect
      GoRoute(
        path: '/',
        name: 'home',
        redirect: (context, state) {
          final authState = ref.read(authNotifierProvider);
          final user = authState.valueOrNull;

          if (user != null) {
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
      debugPrint('🔁 Auth state changed → refreshing router');
      notifyListeners();
    });
  }
}

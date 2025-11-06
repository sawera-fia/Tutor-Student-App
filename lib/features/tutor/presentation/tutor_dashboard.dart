import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/application/auth_state.dart';
import '../../../shared/models/user_model.dart';
import '../../scheduling/presentation/tutor_propose_session_quick_sheet.dart';

class TutorDashboard extends ConsumerWidget {
  const TutorDashboard({super.key});

  double _calculateProfileCompletion(UserModel user) {
    int completedFields = 0;
    int totalFields = 5;

    if (user.bio != null && user.bio!.isNotEmpty) completedFields++;
    if (user.subjects != null && user.subjects!.isNotEmpty) completedFields++;
    if (user.hourlyRate != null && user.hourlyRate! > 0) completedFields++;
    if (user.city != null && user.city!.isNotEmpty) completedFields++;
    if (user.teachingModes != null && user.teachingModes!.isNotEmpty)
      completedFields++;

    return completedFields / totalFields;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      data: (user) => _buildDashboard(context, ref, user),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref, UserModel? user) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in.')));
    }

    final profileCompletion = _calculateProfileCompletion(user);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, ref, user, profileCompletion),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickStats(context, user, profileCompletion),
                    _buildQuickActions(context),
                    _buildProfileCompletion(context, user, profileCompletion),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Header Section (Welcome + Icons)
  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
    double profileCompletion,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Theme.of(context).primaryColor,
            backgroundImage: user.profileImageUrl != null
                ? NetworkImage(user.profileImageUrl!)
                : null,
            child: user.profileImageUrl == null
                ? const Icon(Icons.person, color: Colors.white, size: 30)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                ),
              ],
            ),
          ),
          // 💬 Chat Icon
          IconButton(
            onPressed: () {
              context.go('/chatList');
            },
            icon: const Icon(Icons.chat_bubble_outline),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            tooltip: 'Messages',
          ),
          const SizedBox(width: 8),
          // 📅 Schedule Icon
          IconButton(
            onPressed: () {
              context.go('/tutor-schedule');
            },
            icon: const Icon(Icons.calendar_today),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            tooltip: 'My Schedule',
          ),
          const SizedBox(width: 8),
          // 📋 Requests Icon
          IconButton(
            onPressed: () {
              context.go('/pending-requests');
            },
            icon: const Icon(Icons.notifications_outlined),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            tooltip: 'Student Requests',
          ),
          const SizedBox(width: 8),
          // ⚙️ Settings Menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authNotifierProvider.notifier).signOut();
              } else if (value == 'profile') {
                context.go('/edit-profile');
              } else if (value == 'schedule') {
                context.go('/tutor-schedule');
              } else if (value == 'requests') {
                context.go('/pending-requests');
              } else if (value == 'settings') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings feature coming soon!'),
                  ),
                );
              }
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.more_vert, color: Colors.grey),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'schedule',
                child: ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text('My Schedule'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'requests',
                child: ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text('Student Requests'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 Quick Stats Section
  Widget _buildQuickStats(
    BuildContext context,
    UserModel user,
    double profileCompletion,
  ) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              'Profile',
              '${(profileCompletion * 100).toInt()}%',
              Icons.person,
              profileCompletion >= 0.8
                  ? Colors.green
                  : profileCompletion >= 0.5
                      ? Colors.orange
                      : Colors.red,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              context,
              'Subjects',
              '${user.subjects?.length ?? 0}',
              Icons.subject,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              context,
              'Rating',
              user.rating != null && user.rating! > 0
                  ? user.rating!.toStringAsFixed(1)
                  : 'N/A',
              Icons.star,
              Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Quick Actions Section
  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildActionCard(
                context,
                'Edit Profile',
                'Update your details',
                Icons.edit,
                Colors.orange,
                () => context.go('/edit-profile'),
              ),
              _buildActionCard(
                context,
                'My Schedule',
                'View sessions',
                Icons.schedule,
                Colors.purple,
                () => context.go('/tutor-schedule'),
              ),
              _buildActionCard(
                context,
                'Propose Session',
                'Send proposal',
                Icons.event_available,
                Colors.green,
                () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (ctx) => const TutorProposeSessionQuickSheet(),
                  );
                },
              ),
              _buildActionCard(
                context,
                'Student Requests',
                'View requests',
                Icons.notifications,
                Colors.red,
                () => context.go('/pending-requests'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔹 Profile Completion Section
  Widget _buildProfileCompletion(
    BuildContext context,
    UserModel user,
    double profileCompletion,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Setup',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profile Completion',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${(profileCompletion * 100).toInt()}%',
                      style: TextStyle(
                        color: profileCompletion >= 0.8
                            ? Colors.green
                            : profileCompletion >= 0.5
                                ? Colors.orange
                                : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: profileCompletion,
                    minHeight: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      profileCompletion >= 0.8
                          ? Colors.green
                          : profileCompletion >= 0.5
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Complete your profile to start receiving student requests:',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProfileItem(
                  'Write a bio',
                  user.bio != null && user.bio!.isNotEmpty,
                ),
                _buildProfileItem(
                  'Add subjects you teach',
                  user.subjects != null && user.subjects!.isNotEmpty,
                ),
                _buildProfileItem(
                  'Set your hourly rate',
                  user.hourlyRate != null && user.hourlyRate! > 0,
                ),
                _buildProfileItem(
                  'Add your location',
                  user.city != null && user.city!.isNotEmpty,
                ),
                _buildProfileItem(
                  'Set teaching modes',
                  user.teachingModes != null && user.teachingModes!.isNotEmpty,
                ),
                const SizedBox(height: 12),
                if (profileCompletion < 1.0)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/edit-profile'),
                      icon: const Icon(Icons.edit),
                      label: const Text('Complete Profile'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String title, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: isCompleted ? Colors.green : Colors.grey[400],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isCompleted ? Colors.grey[800] : Colors.grey[600],
                fontSize: 14,
                fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    int totalFields = 5; // Total fields to complete for tutors

    // Check each field
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${user?.name ?? 'Teacher'}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authNotifierProvider.notifier).signOut();
              } else if (value == 'profile') {
                context.go('/edit-profile');
              } else if (value == 'settings') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings feature coming soon!'),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Start Teaching Today',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete your profile and connect with students',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.person_pin, size: 48, color: Colors.white),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Profile Complete',
                    '${(_calculateProfileCompletion(user!) * 100).toInt()}%',
                    Icons.person,
                    _calculateProfileCompletion(user) >= 0.8
                        ? Colors.green
                        : Colors.orange,
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
              ],
            ),

            const SizedBox(height: 24),

            // Quick Actions
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
                  'Complete Profile',
                  'Add subjects & details',
                  Icons.edit,
                  Colors.orange,
                  () {
                    context.go('/edit-profile');
                  },
                ),
                _buildActionCard(
                  context,
                  'My Schedule',
                  'Manage availability',
                  Icons.schedule,
                  Colors.purple,
                  () {
                    context.go('/pending-requests');
                  },
                ),
                _buildActionCard(
                  context,
                  'Propose Session',
                  'Send a session proposal',
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
                  'View new requests',
                  Icons.notifications,
                  Colors.red,
                  () {
                    context.go('/pending-requests');
                  },
                ),
                _buildActionCard(
                  context,
                  'Messages',
                  'Chat with students',
                  Icons.message,
                  Colors.blue,
                  () {
                    context.go('/chatList');
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Profile Completion
            Text(
              'Profile Setup',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
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
                        '${(_calculateProfileCompletion(user) * 100).toInt()}%',
                        style: TextStyle(
                          color: _calculateProfileCompletion(user) >= 0.8
                              ? Colors.green
                              : _calculateProfileCompletion(user) >= 0.5
                              ? Colors.orange
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _calculateProfileCompletion(user),
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _calculateProfileCompletion(user) >= 0.8
                          ? Colors.green
                          : _calculateProfileCompletion(user) >= 0.5
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Complete your profile to start receiving student requests:',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
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
                    user.teachingModes != null &&
                        user.teachingModes!.isNotEmpty,
                  ),
                ],
              ),
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
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
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
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
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String title, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isCompleted ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: isCompleted ? Colors.green : Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

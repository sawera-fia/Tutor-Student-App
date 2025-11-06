import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/application/auth_state.dart';
import '../application/student_dashboard_state.dart';
import '../widgets/enhanced_tutor_card.dart';
import '../widgets/filter_bottom_sheet.dart';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Filter states
  String? _selectedSubject;
  double? _maxHourlyRate;
  String? _selectedTeachingMode;
  String? _selectedLocation;
  double? _minRating;

  @override
  void initState() {
    super.initState();
    debugPrint('📱 StudentDashboardScreen initialized');
    _loadTutors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    debugPrint('🧹 Disposing StudentDashboardScreen');
    super.dispose();
  }

  Future<void> _loadTutors() async {
    debugPrint('🔄 Loading tutors...');
    try {
      await ref.read(studentDashboardNotifierProvider.notifier).loadTutors();
      debugPrint('✅ Tutors loaded successfully');
    } catch (e) {
      debugPrint('❌ Error while loading tutors: $e');
    }
  }

  void _showFilters() {
    debugPrint('🎛 Opening filter bottom sheet');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        selectedSubject: _selectedSubject,
        maxHourlyRate: _maxHourlyRate,
        selectedTeachingMode: _selectedTeachingMode,
        selectedLocation: _selectedLocation,
        minRating: _minRating,
        onApplyFilters: (filters) {
          debugPrint('✅ Filters applied: $filters');
          setState(() {
            _selectedSubject = filters['subject'];
            _maxHourlyRate = filters['maxHourlyRate'];
            _selectedTeachingMode = filters['teachingMode'];
            _selectedLocation = filters['location'];
            _minRating = filters['minRating'];
          });
          _applyFilters();
        },
      ),
    );
  }

  void _applyFilters() {
    debugPrint(
      '🔍 Applying filters: subject=$_selectedSubject, rate=$_maxHourlyRate, mode=$_selectedTeachingMode, location=$_selectedLocation, minRating=$_minRating',
    );
    ref
        .read(studentDashboardNotifierProvider.notifier)
        .applyFilters(
          subject: _selectedSubject,
          maxHourlyRate: _maxHourlyRate,
          teachingMode: _selectedTeachingMode,
          location: _selectedLocation,
          minRating: _minRating,
        );
  }

  void _searchTutors(String query) {
    debugPrint('🔎 Searching tutors for query: "$query"');
    if (query.trim().isEmpty) {
      debugPrint('🧹 Empty query → reloading all tutors');
      _loadTutors();
    } else {
      ref.read(studentDashboardNotifierProvider.notifier).searchTutors(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(studentDashboardNotifierProvider);
    debugPrint('🧩 Building StudentDashboardScreen');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilters(),
            Expanded(child: _buildListView(dashboardState)),
          ],
        ),
      ),
    );
  }

  // 🔹 Header Section (Welcome + Icons)
  Widget _buildHeader() {
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
            child: const Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                Text(
                  'Find your perfect tutor',
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
              debugPrint('💬 Chat icon pressed → navigating to /chatList');
              context.go('/chatList');
            },
            icon: const Icon(Icons.chat_bubble_outline),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 📅 My Schedule Icon
          IconButton(
            onPressed: () {
              debugPrint('📅 My Schedule pressed → navigating to /student-schedule');
              context.go('/student-schedule');
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
          // 📋 Pending Requests Icon
          IconButton(
            onPressed: () {
              debugPrint('📋 Pending Requests pressed → navigating to /pending-requests');
              context.go('/pending-requests');
            },
            icon: const Icon(Icons.pending_actions),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            tooltip: 'Pending Requests',
          ),
          const SizedBox(width: 8),
          // ⚙️ Settings Menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authNotifierProvider.notifier).signOut();
              } else if (value == 'profile') {
                debugPrint('👤 Profile pressed → navigating to /edit-profile');
                context.go('/edit-profile');
              } else if (value == 'sessions') {
                debugPrint('📅 My Sessions pressed → navigating to /student-schedule');
                context.go('/student-schedule');
              } else if (value == 'requests') {
                debugPrint('📋 Pending Requests pressed → navigating to /pending-requests');
                context.go('/pending-requests');
              } else if (value == 'settings') {
                debugPrint('⚙️ Settings pressed (TODO: implement settings)');
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
                value: 'sessions',
                child: ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text('My Schedule'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'requests',
                child: ListTile(
                  leading: Icon(Icons.pending_actions),
                  title: Text('Pending Requests'),
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

  // 🔹 Search + Filter bar
  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search tutors by name, subject, or location...',
                  prefixIcon: const Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: _searchTutors,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _showFilters,
            icon: const Icon(Icons.filter_list),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Tutor List
  Widget _buildListView(AsyncValue<List<UserModel>> dashboardState) {
    return dashboardState.when(
      data: (tutors) {
        debugPrint('📋 Tutor list loaded: ${tutors.length} tutors found');
        return tutors.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: tutors.length,
                itemBuilder: (context, index) {
                  final tutor = tutors[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: EnhancedTutorCard(
                      tutor: tutor,
                      onTap: () {
                        context.go('/view-profile/${tutor.id}');
                      },
                    ),
                  );
                },
              );
      },
      loading: () {
        debugPrint('⏳ Tutors are loading...');
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, stack) {
        debugPrint('❌ Dashboard error: $error');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Error loading tutors',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTutors,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔹 Empty State
  Widget _buildEmptyState() {
    debugPrint('📭 No tutors found – showing empty state');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No tutors found',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search criteria',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _showFilters,
            child: const Text('Adjust Filters'),
          ),
        ],
      ),
    );
  }

  // 🔹 Tutor Detail Snackbar (temp)
  void _showTutorDetails(UserModel tutor) {
    debugPrint('👤 Tutor tapped: ${tutor.name}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing details for ${tutor.name}'),
        action: SnackBarAction(
          label: 'View Profile',
          onPressed: () {
            debugPrint('➡️ Navigating to profile of ${tutor.name}');
            // TODO: Navigate to tutor profile
          },
        ),
      ),
    );
  }
}

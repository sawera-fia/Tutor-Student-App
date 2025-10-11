import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
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
  double? _maxDistance;

  @override
  void initState() {
    super.initState();
    _loadTutors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTutors() async {
    await ref.read(studentDashboardNotifierProvider.notifier).loadTutors();
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        selectedSubject: _selectedSubject,
        maxHourlyRate: _maxHourlyRate,
        selectedTeachingMode: _selectedTeachingMode,
        selectedLocation: _selectedLocation,
        maxDistance: _maxDistance,
        onApplyFilters: (filters) {
          setState(() {
            _selectedSubject = filters['subject'];
            _maxHourlyRate = filters['maxHourlyRate'];
            _selectedTeachingMode = filters['teachingMode'];
            _selectedLocation = filters['location'];
            _maxDistance = filters['maxDistance'];
          });
          _applyFilters();
        },
      ),
    );
  }

  void _applyFilters() {
    ref
        .read(studentDashboardNotifierProvider.notifier)
        .applyFilters(
          subject: _selectedSubject,
          maxHourlyRate: _maxHourlyRate,
          teachingMode: _selectedTeachingMode,
          location: _selectedLocation,
          maxDistance: _maxDistance,
        );
  }

  void _searchTutors(String query) {
    if (query.trim().isEmpty) {
      _loadTutors();
    } else {
      ref.read(studentDashboardNotifierProvider.notifier).searchTutors(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(studentDashboardNotifierProvider);

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
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildListView(AsyncValue<List<UserModel>> dashboardState) {
    return dashboardState.when(
      data: (tutors) => tutors.isEmpty
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
                    onTap: () => _showTutorDetails(tutor),
                  ),
                );
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
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
            ElevatedButton(onPressed: _loadTutors, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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

  void _showTutorDetails(UserModel tutor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing details for ${tutor.name}'),
        action: SnackBarAction(
          label: 'View Profile',
          onPressed: () {
            // TODO: Navigate to tutor profile
          },
        ),
      ),
    );
  }
}

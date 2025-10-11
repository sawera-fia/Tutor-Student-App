import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_model.dart';
import '../data/student_dashboard_service.dart';

// Service provider
final studentDashboardServiceProvider = Provider<StudentDashboardService>((
  ref,
) {
  return StudentDashboardService();
});

// Dashboard state notifier
class StudentDashboardNotifier
    extends StateNotifier<AsyncValue<List<UserModel>>> {
  final StudentDashboardService _service;

  StudentDashboardNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> loadTutors() async {
    try {
      state = const AsyncValue.loading();
      final tutors = await _service.getAvailableTutors();
      state = AsyncValue.data(tutors);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> applyFilters({
    String? subject,
    double? maxHourlyRate,
    String? teachingMode,
    String? location,
    double? maxDistance,
  }) async {
    try {
      state = const AsyncValue.loading();
      final tutors = await _service.getFilteredTutors(
        subject: subject,
        maxHourlyRate: maxHourlyRate,
        teachingMode: teachingMode,
        location: location,
        maxDistance: maxDistance,
      );
      state = AsyncValue.data(tutors);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> searchTutors(String query) async {
    try {
      state = const AsyncValue.loading();
      final tutors = await _service.searchTutors(query);
      state = AsyncValue.data(tutors);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

// Dashboard notifier provider
final studentDashboardNotifierProvider =
    StateNotifierProvider<
      StudentDashboardNotifier,
      AsyncValue<List<UserModel>>
    >((ref) {
      final service = ref.watch(studentDashboardServiceProvider);
      return StudentDashboardNotifier(service);
    });

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_state.dart';
import '../data/availability_service.dart';
import '../data/booking_service.dart';
import '../../../shared/models/booking_model.dart';

final availabilityServiceProvider = Provider<AvailabilityService>((ref) {
  return AvailabilityService();
});

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService();
});

// Watch bookings for the current user
final userBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final service = ref.watch(bookingServiceProvider);
  final user = userAsync.asData?.value;
  if (user == null) {
    return const Stream.empty();
  }
  return service.watchForUser(user.id);
});



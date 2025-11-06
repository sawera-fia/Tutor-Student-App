import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_state.dart';
import '../application/scheduling_providers.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/user_model.dart';

class TutorScheduleScreen extends ConsumerWidget {
  const TutorScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final bookingService = ref.watch(bookingServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Schedule')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) return const Center(child: Text('Please sign in.'));
          if (user.role != UserRole.teacher) {
            return const Center(child: Text('Schedule is for tutors only.'));
          }

          return StreamBuilder<List<BookingModel>>(
            stream: bookingService.watchAcceptedForTutor(user.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final bookings = snapshot.data ?? const [];
              if (bookings.isEmpty) {
                return const Center(child: Text('No accepted sessions yet'));
              }

              final now = DateTime.now().toUtc();
              final upcoming = bookings.where((b) => b.endAtUtc.isAfter(now)).toList();
              final past = bookings.where((b) => b.endAtUtc.isBefore(now)).toList();

              return DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(tabs: [
                      Tab(text: 'Upcoming'),
                      Tab(text: 'Past'),
                    ]),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _ScheduleList(bookings: upcoming, emptyText: 'No upcoming sessions'),
                          _ScheduleList(bookings: past, emptyText: 'No past sessions'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ScheduleList extends StatelessWidget {
  final List<BookingModel> bookings;
  final String emptyText;
  const _ScheduleList({required this.bookings, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(child: Text(emptyText));
    }
    return ListView.separated(
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final b = bookings[index];
        return ListTile(
          leading: Icon(b.mode.name == 'online' ? Icons.videocam : Icons.location_on_outlined),
          title: Text(b.subject),
          subtitle: Text('${b.startAtUtc.toLocal()} - ${b.endAtUtc.toLocal()}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: open booking details or join link when available
          },
        );
      },
    );
  }
}



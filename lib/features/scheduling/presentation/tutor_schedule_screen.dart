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
      appBar: AppBar(
        title: const Text('My Schedule'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $e', style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
        data: (user) {
          if (user == null) return const Center(child: Text('Please sign in.'));
          if (user.role != UserRole.teacher) {
            return SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, size: 64, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text('Schedule is for tutors only.', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            );
          }

          return StreamBuilder<List<BookingModel>>(
            stream: bookingService.watchAcceptedForTutor(user.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                );
              }
              final bookings = snapshot.data ?? const [];
              if (bookings.isEmpty) {
                return SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No accepted sessions yet',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Accepted sessions will appear here',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
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
      return SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  emptyText,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final b = bookings[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: b.mode.name == 'online' ? Colors.blue.shade100 : Colors.green.shade100,
            child: Icon(
              b.mode.name == 'online' ? Icons.videocam : Icons.location_on_outlined,
              color: b.mode.name == 'online' ? Colors.blue : Colors.green,
            ),
          ),
          title: Text(
            b.subject,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${b.startAtUtc.toLocal().toString().substring(0, 16)} - ${b.endAtUtc.toLocal().toString().substring(11, 16)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          isThreeLine: false,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: open booking details or join link when available
          },
        );
      },
    );
  }
}



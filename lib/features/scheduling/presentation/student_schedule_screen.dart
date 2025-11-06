import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/application/auth_state.dart';
import '../application/scheduling_providers.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/user_model.dart';
import '../../ratings/data/rating_service.dart';
import '../../ratings/presentation/rate_tutor_sheet.dart';

class StudentScheduleScreen extends ConsumerWidget {
  const StudentScheduleScreen({super.key});

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
          if (user.role != UserRole.student) {
            return SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, size: 64, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text('Schedule is for students only.', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            );
          }

          return StreamBuilder<List<BookingModel>>(
            stream: bookingService.watchAcceptedForStudent(user.id),
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
                          _ScheduleList(bookings: upcoming, emptyText: 'No upcoming sessions', studentId: user.id),
                          _ScheduleList(bookings: past, emptyText: 'No past sessions', studentId: user.id),
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
  final String studentId;
  const _ScheduleList({required this.bookings, required this.emptyText, required this.studentId});

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
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(b.tutorId).get(),
          builder: (context, snapshot) {
            String tutorName = 'Loading...';
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              tutorName = data?['name'] as String? ?? 'Unknown Tutor';
            }
            
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
                      'With: $tutorName',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${b.startAtUtc.toLocal().toString().substring(0, 16)} - ${b.endAtUtc.toLocal().toString().substring(11, 16)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rate button for past sessions
                  if (b.endAtUtc.isBefore(DateTime.now().toUtc()) &&
                      b.status == BookingStatus.completed)
                    FutureBuilder<bool>(
                      future: RatingService().hasRated(b.id, studentId),
                      builder: (context, hasRatedSnap) {
                        if (!hasRatedSnap.hasData) {
                          return const SizedBox.shrink();
                        }
                        final hasRated = hasRatedSnap.data ?? false;
                        return IconButton(
                          icon: Icon(
                            hasRated ? Icons.star : Icons.star_border,
                            color: hasRated ? Colors.amber : Colors.grey,
                          ),
                          onPressed: () async {
                            // Get tutor data
                            final tutorDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(b.tutorId)
                                .get();
                            if (tutorDoc.exists) {
                              final tutorData = tutorDoc.data()!;
                              final tutor = UserModel.fromJson({
                                ...tutorData,
                                'id': tutorDoc.id,
                                'createdAt': tutorData['createdAt'],
                                'updatedAt': tutorData['updatedAt'],
                              });
                              if (context.mounted) {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                  ),
                                  builder: (ctx) => RateTutorSheet(
                                    tutor: tutor,
                                    bookingId: b.id,
                                  ),
                                );
                              }
                            }
                          },
                          tooltip: hasRated ? 'Update Rating' : 'Rate Tutor',
                        );
                      },
                    ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () {
                context.go('/view-profile/${b.tutorId}');
              },
            );
          },
        );
      },
    );
  }
}


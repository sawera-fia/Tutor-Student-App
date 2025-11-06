import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/application/auth_state.dart';
import '../application/scheduling_providers.dart';

class PendingRequestsScreen extends ConsumerWidget {
  const PendingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final bookingsAsync = ref.watch(userBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Requests')),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please sign in.'));
          }
          return bookingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, stackTrace) {
              // ignore: avoid_print
              print('[PendingRequestsScreen] ERROR loading bookings: $e');
              // ignore: avoid_print
              print('[PendingRequestsScreen] Stack trace: $stackTrace');
              if (e.toString().contains('failed-precondition') || e.toString().contains('index')) {
                // ignore: avoid_print
                print('[PendingRequestsScreen] ⚠️ INDEX REQUIRED! Check console for index creation link.');
              }
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: $e', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Check console for details', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              );
            },
            data: (bookings) {
              final needsYourAction = bookings.where((b) =>
                  b.status == BookingStatus.pending &&
                  b.requiresAcceptanceBy == user.id);
              final yourRequests = bookings.where((b) =>
                  b.status == BookingStatus.pending && b.initiatorId == user.id);

              return DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    const TabBar(tabs: [
                      Tab(text: 'Needs Your Action'),
                      Tab(text: 'Your Requests'),
                    ]),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _RequestsList(
                            bookings: needsYourAction.toList(),
                            currentUser: user,
                            canAct: true,
                          ),
                          _RequestsList(
                            bookings: yourRequests.toList(),
                            currentUser: user,
                            canAct: false,
                          ),
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

class _RequestsList extends ConsumerWidget {
  final List<BookingModel> bookings;
  final UserModel currentUser;
  final bool canAct;

  const _RequestsList({
    required this.bookings,
    required this.currentUser,
    required this.canAct,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookings.isEmpty) {
      return const Center(child: Text('No pending requests'));
    }
    final bookingService = ref.watch(bookingServiceProvider);
    return ListView.separated(
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final b = bookings[index];
        final isTutorSide = b.tutorId == currentUser.id;
        final counterpartId = isTutorSide ? b.studentId : b.tutorId;
        return ListTile(
          title: Text('${b.subject} • ${b.mode.name}'),
          subtitle: Text(
            '${b.startAtUtc.toLocal()} - ${b.endAtUtc.toLocal()}\nFrom: ${b.initiatorId == currentUser.id ? 'You' : 'Them'}',
          ),
          isThreeLine: true,
          trailing: canAct
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await bookingService.accept(b.id, currentUser.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request accepted')),
                          );
                        }
                      },
                      child: const Text('Accept'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await bookingService.decline(b.id, currentUser.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request declined')),
                          );
                        }
                      },
                      child: const Text('Decline'),
                    ),
                  ],
                )
              : Text('Waiting for ${b.requiresAcceptanceBy == currentUser.id ? 'you' : 'them'}'),
          onTap: () {
            // TODO: open details / chat
          },
        );
      },
    );
  }
}



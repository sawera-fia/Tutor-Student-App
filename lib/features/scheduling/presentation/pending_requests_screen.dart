import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
                    TabBar(tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Needs Your Action'),
                            if (needsYourAction.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${needsYourAction.length}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ),
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
        final isProposal = b.initiatorId != currentUser.id; // Someone else initiated
        final counterpartId = isTutorSide ? b.studentId : b.tutorId;
        
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(counterpartId).get(),
          builder: (context, snapshot) {
            final counterpartName = snapshot.hasData && snapshot.data!.exists
                ? (snapshot.data!.data() as Map<String, dynamic>?)?['name'] ?? 'Unknown'
                : 'Loading...';
            
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isProposal ? Colors.green.shade100 : Colors.blue.shade100,
                child: Icon(
                  isProposal ? Icons.event_available : Icons.send,
                  color: isProposal ? Colors.green : Colors.blue,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text('${b.subject} • ${b.mode.name}'),
                  ),
                  if (isProposal)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Proposal',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    isProposal
                        ? 'Proposal from: $counterpartName'
                        : 'Your request to: $counterpartName',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${b.startAtUtc.toLocal().toString().substring(0, 16)} - ${b.endAtUtc.toLocal().toString().substring(11, 16)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: canAct
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () async {
                            try {
                              await bookingService.accept(b.id, currentUser.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isProposal
                                        ? 'Proposal accepted!'
                                        : 'Request accepted'),
                                  ),
                                );
                              }
                            } catch (e) {
                              // ignore: avoid_print
                              print('[PendingRequestsScreen] accept error: $e');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Unable to accept: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Accept'),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              await bookingService.decline(b.id, currentUser.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isProposal
                                        ? 'Proposal declined'
                                        : 'Request declined'),
                                  ),
                                );
                              }
                            } catch (e) {
                              // ignore: avoid_print
                              print('[PendingRequestsScreen] decline error: $e');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Unable to decline: $e')),
                                );
                              }
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
      },
    );
  }
}



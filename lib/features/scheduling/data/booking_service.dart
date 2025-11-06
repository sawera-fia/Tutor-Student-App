import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/models/booking_model.dart';
import '../../../shared/models/availability_model.dart' show TeachingMode;
import '../services/notification_service.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('bookings');

  Future<BookingModel?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return BookingModel.fromFirestore(doc.id, doc.data()!);
  }

  Stream<List<BookingModel>> watchForUser(String userId) {
    // ignore: avoid_print
    print('[BookingService.watchForUser] userId=$userId');
    return _col
        .where('participants', arrayContains: userId)
        .orderBy('startAt', descending: true)
        .snapshots()
        .handleError((error) {
      // ignore: avoid_print
      print('[BookingService.watchForUser] ERROR: $error');
      if (error is FirebaseException) {
        // ignore: avoid_print
        print('[BookingService.watchForUser] FirebaseException code=${error.code} message=${error.message}');
        if (error.code == 'failed-precondition') {
          // ignore: avoid_print
          print('[BookingService.watchForUser] ⚠️ INDEX REQUIRED! Check Firebase Console for index creation link.');
          // ignore: avoid_print
          print('[BookingService.watchForUser] Error details: ${error.toString()}');
          // Try to extract the index link from the error message if available
          if (error.message != null && error.message!.contains('https://')) {
            final uriMatch = RegExp(r'https://[^\s]+').firstMatch(error.message!);
            if (uriMatch != null) {
              // ignore: avoid_print
              print('[BookingService.watchForUser] 🔗 Index creation link: ${uriMatch.group(0)}');
            }
          }
        }
      }
      throw error;
    })
        .map((snap) {
      // ignore: avoid_print
      print('[BookingService.watchForUser] snapshot received: ${snap.docs.length} docs');
      return snap.docs
          .map((d) => BookingModel.fromFirestore(d.id, d.data()))
          .toList();
    });
  }

  Stream<List<BookingModel>> watchAcceptedForTutor(String tutorId) {
    // ignore: avoid_print
    print('[BookingService.watchAcceptedForTutor] tutorId=$tutorId');
    return _col
        .where('tutorId', isEqualTo: tutorId)
        .where('status', isEqualTo: BookingStatus.accepted.name)
        .orderBy('startAt')
        .snapshots()
        .handleError((error) {
      // ignore: avoid_print
      print('[BookingService.watchAcceptedForTutor] ERROR: $error');
      if (error is FirebaseException) {
        // ignore: avoid_print
        print('[BookingService.watchAcceptedForTutor] FirebaseException code=${error.code} message=${error.message}');
      }
      throw error;
    }).map((snap) {
      // ignore: avoid_print
      print('[BookingService.watchAcceptedForTutor] snapshot: ${snap.docs.length}');
      return snap.docs
          .map((d) => BookingModel.fromFirestore(d.id, d.data()))
          .toList();
    });
  }

  Stream<List<BookingModel>> watchAcceptedForStudent(String studentId) {
    // ignore: avoid_print
    print('[BookingService.watchAcceptedForStudent] studentId=$studentId');
    return _col
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: BookingStatus.accepted.name)
        .orderBy('startAt')
        .snapshots()
        .handleError((error) {
      // ignore: avoid_print
      print('[BookingService.watchAcceptedForStudent] ERROR: $error');
      if (error is FirebaseException) {
        // ignore: avoid_print
        print('[BookingService.watchAcceptedForStudent] FirebaseException code=${error.code} message=${error.message}');
      }
      throw error;
    }).map((snap) {
      // ignore: avoid_print
      print('[BookingService.watchAcceptedForStudent] snapshot: ${snap.docs.length}');
      return snap.docs
          .map((d) => BookingModel.fromFirestore(d.id, d.data()))
          .toList();
    });
  }

  Future<bool> _hasConflict({
    required String tutorId,
    required DateTime startUtc,
    required DateTime endUtc,
    String? excludeBookingId,
  }) async {
    final statuses = ['pending', 'accepted'];
    try {
      // Debug: show params
      // ignore: avoid_print
      print('[BookingService._hasConflict] tutorId=$tutorId start=$startUtc end=$endUtc exclude=$excludeBookingId');
      final q = await _col
          .where('tutorId', isEqualTo: tutorId)
          .where('status', whereIn: statuses)
          .where('startAt', isLessThan: Timestamp.fromDate(endUtc))
          .get();
      // ignore: avoid_print
      print('[BookingService._hasConflict] fetched=${q.docs.length}');
      for (final doc in q.docs) {
        // Skip the booking we're checking (when accepting, exclude itself)
        if (excludeBookingId != null && doc.id == excludeBookingId) {
          // ignore: avoid_print
          print('[BookingService._hasConflict] skipping excluded booking ${doc.id}');
          continue;
        }
        final data = doc.data();
        final s = (data['startAt'] as Timestamp).toDate().toUtc();
        final e = (data['endAt'] as Timestamp).toDate().toUtc();
        final overlaps = s.isBefore(endUtc) && e.isAfter(startUtc);
        if (overlaps) {
          // ignore: avoid_print
          print('[BookingService._hasConflict] overlap with ${doc.id} ($s - $e)');
          return true;
        }
      }
      return false;
    } on FirebaseException catch (e) {
      // ignore: avoid_print
      print('[BookingService._hasConflict] FirebaseException code=${e.code} message=${e.message}');
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('[BookingService._hasConflict] Unexpected error: $e');
      rethrow;
    }
  }

  Future<String> createRequest({
    required String initiatorId,
    required String studentId,
    required String tutorId,
    required String subject,
    required TeachingMode mode,
    required DateTime startAtUtc,
    required DateTime endAtUtc,
    required int priceCents,
    String currency = 'USD',
  }) async {
    // Debug input
    // ignore: avoid_print
    print('[BookingService.createRequest] initiator=$initiatorId student=$studentId tutor=$tutorId subject=$subject mode=${mode.name} start=$startAtUtc end=$endAtUtc priceCents=$priceCents');
    try {
      if (await _hasConflict(
        tutorId: tutorId,
        startUtc: startAtUtc,
        endUtc: endAtUtc,
      )) {
        throw Exception('Time slot is no longer available.');
      }

      final now = FieldValue.serverTimestamp();
      final requiresAcceptanceBy = initiatorId == tutorId ? studentId : tutorId;
      final doc = await _col.add({
        'studentId': studentId,
        'tutorId': tutorId,
        'participants': [studentId, tutorId],
        'subject': subject,
        'mode': mode.name,
        'startAt': Timestamp.fromDate(startAtUtc.toUtc()),
        'endAt': Timestamp.fromDate(endAtUtc.toUtc()),
        'status': BookingStatus.pending.name,
        'priceCents': priceCents,
        'currency': currency,
        'initiatorId': initiatorId,
        'requiresAcceptanceBy': requiresAcceptanceBy,
        'createdAt': now,
        'updatedAt': now,
      });
      // ignore: avoid_print
      print('[BookingService.createRequest] created booking ${doc.id}');
      return doc.id;
    } on FirebaseException catch (e) {
      // ignore: avoid_print
      print('[BookingService.createRequest] FirebaseException code=${e.code} message=${e.message}');
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('[BookingService.createRequest] Unexpected error: $e');
      rethrow;
    }
  }

  Future<void> accept(String bookingId, String actorUserId) async {
    final ref = _col.doc(bookingId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Booking not found');
    final data = snap.data()!;
    if ((data['requiresAcceptanceBy'] ?? '') != actorUserId) {
      throw Exception('Not authorized to accept');
    }
    if ((data['status'] ?? '') != BookingStatus.pending.name) {
      throw Exception('Booking is not pending');
    }
    final startUtc = (data['startAt'] as Timestamp).toDate().toUtc();
    final endUtc = (data['endAt'] as Timestamp).toDate().toUtc();
    final tutorId = (data['tutorId'] ?? '') as String;

    // Check conflicts BEFORE transaction to avoid async inside tx
    if (await _hasConflict(tutorId: tutorId, startUtc: startUtc, endUtc: endUtc, excludeBookingId: bookingId)) {
      throw Exception('Time slot now conflicts');
    }

    await _firestore.runTransaction((tx) async {
      final latest = await tx.get(ref);
      if (!latest.exists) throw Exception('Booking not found');
      final latestStatus = (latest['status'] ?? '') as String;
      if (latestStatus != BookingStatus.pending.name) {
        throw Exception('Booking already updated');
      }
      tx.update(ref, {
        'status': BookingStatus.accepted.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    
    // Schedule notifications for both student and tutor
    try {
      final studentId = (data['studentId'] ?? '') as String;
      final tutorId = (data['tutorId'] ?? '') as String;
      final subject = (data['subject'] ?? 'Session') as String;
      
      // Get user names for notifications
      final studentDoc = await _firestore.collection('users').doc(studentId).get();
      final tutorDoc = await _firestore.collection('users').doc(tutorId).get();
      
      final studentName = studentDoc.exists ? (studentDoc.data()?['name'] ?? 'Student') as String : 'Student';
      final tutorName = tutorDoc.exists ? (tutorDoc.data()?['name'] ?? 'Tutor') as String : 'Tutor';
      
      final notificationService = NotificationService();
      
      // Convert bookingId string to a numeric ID for notifications
      final bookingIdInt = bookingId.hashCode.abs();
      
      // Schedule notifications for student
      await notificationService.scheduleSessionNotifications(
        bookingId: bookingIdInt,
        subject: subject,
        tutorOrStudentName: tutorName,
        sessionStartUtc: startUtc,
        sessionEndUtc: endUtc,
        isStudent: true,
      );
      
      // Schedule notifications for tutor (use different base to avoid conflicts)
      await notificationService.scheduleSessionNotifications(
        bookingId: bookingIdInt + 1000000, // Different ID base for tutor
        subject: subject,
        tutorOrStudentName: studentName,
        sessionStartUtc: startUtc,
        sessionEndUtc: endUtc,
        isStudent: false,
      );
      
      // ignore: avoid_print
      print('[BookingService.accept] Scheduled notifications for booking $bookingId');
    } catch (e) {
      // ignore: avoid_print
      print('[BookingService.accept] Error scheduling notifications: $e');
      // Don't throw - notifications are not critical
    }
    
    // ignore: avoid_print
    print('[BookingService.accept] bookingId=$bookingId accepted by $actorUserId');
  }

  Future<void> decline(String bookingId, String actorUserId, {String? reason}) async {
    final ref = _col.doc(bookingId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Booking not found');
    if ((snap['requiresAcceptanceBy'] ?? '') != actorUserId) {
      throw Exception('Not authorized to decline');
    }
    await ref.update({
      'status': BookingStatus.declined.name,
      if (reason != null) 'cancelReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // ignore: avoid_print
    print('[BookingService.decline] bookingId=$bookingId declined by $actorUserId reason=${reason ?? ''}');
  }

  Future<void> cancel(String bookingId, String actorUserId, {String? reason}) async {
    final ref = _col.doc(bookingId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Booking not found');
    final participants = List<String>.from(snap['participants'] ?? []);
    if (!participants.contains(actorUserId)) throw Exception('Not authorized');
    await ref.update({
      'status': BookingStatus.cancelled.name,
      if (reason != null) 'cancelReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // ignore: avoid_print
    print('[BookingService.cancel] bookingId=$bookingId cancelled by $actorUserId reason=${reason ?? ''}');
  }

  Future<void> reschedule({
    required String bookingId,
    required String requesterId,
    required DateTime newStartUtc,
    required DateTime newEndUtc,
  }) async {
    final ref = _col.doc(bookingId);
    final snap = await ref.get();
    if (!snap.exists) throw Exception('Booking not found');
    final data = snap.data()!;
    final participants = List<String>.from(data['participants'] ?? []);
    if (!participants.contains(requesterId)) throw Exception('Not authorized');

    final tutorId = (data['tutorId'] ?? '') as String;
    if (await _hasConflict(tutorId: tutorId, startUtc: newStartUtc, endUtc: newEndUtc)) {
      throw Exception('New time conflicts with another booking');
    }
    await ref.update({
      'startAt': Timestamp.fromDate(newStartUtc.toUtc()),
      'endAt': Timestamp.fromDate(newEndUtc.toUtc()),
      'status': BookingStatus.pending.name, // require re-accept
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // ignore: avoid_print
    print('[BookingService.reschedule] bookingId=$bookingId requested by $requesterId newStart=$newStartUtc newEnd=$newEndUtc');
  }
}


